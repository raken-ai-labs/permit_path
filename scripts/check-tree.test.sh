#!/usr/bin/env bash
# raken-dev-standard v0.6.15: check-tree.test.sh
# sha256: a890761c5dac8666af884744811c390a773c839c33251ebbe20ac2eb2220294e
# Pruebas sin red: bash check-tree.test.sh. origin es un repo bare local.
set -uo pipefail
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX  # un hook los exporta (#80)
HERE="$(cd "$(dirname "$0")" && pwd)"
pass=0; fail=0
check() { # check <label> <exit-esperado> <subcadena> <salida> <exit>
  if [ "$2" = "$5" ] && [[ "$4" == *"$3"* ]]; then pass=$((pass + 1));
  else fail=$((fail + 1)); echo "FAIL: $1"; echo "  expected: exit $2, *$3*"; echo "  actual:   exit $5, $4"; fi
}
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
git init -q --bare -b main "$T/origin.git"
git clone -q "$T/origin.git" "$T/w" 2>/dev/null; cd "$T/w" || exit 1
git checkout -q -b main 2>/dev/null; echo a > a; git add a; git commit -qm a; git push -q -u origin main
git remote set-head origin main >/dev/null 2>&1
t() { local out rc; out=$("$HERE/check-tree.sh" "${@:4}" 2>&1); rc=$?; check "$1" "$2" "$3" "$out" "$rc"; }

t "limpio, en main, igual a origin" 0 "TREE OK"
t "rama esperada explícita" 0 "TREE OK" main
echo b > b; t "archivo sin seguimiento" 2 "uncommitted changes"; rm b
echo x >> a; t "archivo modificado" 2 "uncommitted changes"; git checkout -q a
git commit -q --allow-empty -m ahead; t "commit local sin push (adelante)" 2 "commits not in origin/main"
git reset -q --hard origin/main
git checkout -q -b feat; t "en otra rama" 2 "expected «main»"
git checkout -q --detach; t "HEAD desprendido" 2 "detached HEAD"
git checkout -q main
git clone -q "$T/origin.git" "$T/w2" 2>/dev/null; (cd "$T/w2" && git checkout -q main && git commit -q --allow-empty -m up && git push -q origin main)
t "origin avanzó (checkout detrás): aviso, no rechazo" 0 "1 commits behind origin/main"
t "detrás: sugiere ponerse al día" 0 "git pull --ff-only"
git commit -q --allow-empty -m local; t "divergida (local y origin avanzaron): se niega" 2 "commits not in origin/main"
git reset -q --hard origin/main; t "igual tras ponerse al día" 0 "TREE OK: "
t "rama esperada inexistente" 1 "does not exist" nope
cd "$T" && t "fuera de un repo" 1 "not a git checkout"

echo ""
if (( fail == 0 )); then echo "✅ check-tree: $pass passed"; else echo "❌ check-tree: $fail failed, $pass passed"; exit 1; fi
