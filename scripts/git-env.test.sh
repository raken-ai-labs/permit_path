#!/usr/bin/env bash
# raken-dev-standard v0.6.15: git-env.test.sh
# sha256: 05b482d77cb3dcc65a0e71b6c2bbb54d05325ee4a88ed0831ded5d337bfc0470
# Las suites no deben tocar el repo que las corre cuando un hook les exporta GIT_DIR (#80):
# corre check-tree.test.sh y merge.test.sh (dos que crean repos con git init) con GIT_DIR apuntando
# a un repo señuelo y verifica que el señuelo no cambia. Dos suites bastan: cada una limpia el entorno
# con el mismo unset, y correr todas multiplicaba el tiempo de run-tests.sh.
# También: pre-push.test.sh pasa aunque un core.hooksPath global apunte a un hook que falla.
#   bash git-env.test.sh
set -uo pipefail
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX
HERE="$(cd "$(dirname "$0")" && pwd)"
SUITES_DIR="${SUITES_DIR:-$HERE}"   # SUITES_DIR permite correr copias sin los unset (prueba de la prueba)
pass=0; fail=0
ok() { pass=$((pass + 1)); }
no() { fail=$((fail + 1)); echo "FAIL: $1"; [ -n "${2:-}" ] && echo "$2"; }

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
D="$T/decoy"; mkdir -p "$D" && git -C "$D" init -q -b main && git -C "$D" commit -q --allow-empty -m señuelo
snap() { printf '%s\n%s\n%s\n%s\n' "$(git -C "$D" rev-parse HEAD)" "$(git -C "$D" config --local --list | sort)" "$(git -C "$D" for-each-ref)" "$(git -C "$D" reflog | wc -l)"; }
before=$(snap)

for n in check-tree.test.sh merge.test.sh; do
  out=$(cd "$T" && GIT_DIR="$D/.git" GIT_WORK_TREE="$D" GIT_INDEX_FILE="$D/.git/index" LC_ALL=C bash "$SUITES_DIR/$n" 2>&1); rc=$?
  after=$(snap)
  if [ "$after" = "$before" ]; then ok; else no "$n con GIT_DIR exportado cambió el repo señuelo"; before="$after"; fi
  [ "$rc" = 0 ] && ok || no "$n falló con GIT_DIR exportado" "$(printf '%s\n' "$out" | tail -5)"
done

# core.hooksPath global que bloquea cualquier commit: pre-push.test.sh debe pasar igual
mkdir -p "$T/badhooks"; printf '#!/bin/sh\nexit 1\n' > "$T/badhooks/pre-commit"; chmod +x "$T/badhooks/pre-commit"
printf '[core]\n\thooksPath = %s\n' "$T/badhooks" > "$T/gitconfig"
out=$(GIT_CONFIG_GLOBAL="$T/gitconfig" LC_ALL=C bash "$SUITES_DIR/pre-push.test.sh" 2>&1); rc=$?
[ "$rc" = 0 ] && ok || no "pre-push.test.sh falla con un core.hooksPath propio" "$(printf '%s\n' "$out" | tail -5)"

echo ""
if (( fail == 0 )); then echo "✅ git-env: $pass passed"; else echo "❌ git-env: $fail failed, $pass passed"; exit 1; fi
