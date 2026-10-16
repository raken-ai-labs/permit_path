#!/usr/bin/env bash
# raken-dev-standard v0.6.15: pre-push.test.sh
# sha256: 7afb862eea9fda85234bf0130d75b845eee55831b7959a5712e7efbb0771c473
# Pruebas del hook pre-push en un repo git temporal, sin red: bash pre-push.test.sh
set -uo pipefail
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX  # un hook los exporta (#80)
# El hook exporta el config del repo que lo corre (set -a): las claves heredadas no deben colarse en el repo de prueba.
unset PREPUSH_TEST_CMD "${!DELETED_REFS_@}" "${!GATE_@}"
cd "$(dirname "$0")" || exit 1
HERE=$(pwd)

pass=0; fail=0
check() { # check <label> <exit-esperado> <subcadena> <salida> <exit>
  if [ "$2" = "$5" ] && [[ "$4" == *"$3"* ]]; then pass=$((pass + 1));
  else fail=$((fail + 1)); echo "FAIL: $1"; echo "  expected: exit $2, *$3*"; echo "  actual:   exit $5, $4"; fi
}

R=$(mktemp -d); trap 'rm -rf "$R"' EXIT
g() { git -C "$R" -c core.hooksPath=/dev/null -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false "$@" >/dev/null 2>&1; }
g init -q
mkdir -p "$R/scripts" "$R/.githooks" "$R/src"
# En el plugin el hook está en githooks/; vendorizado por bootstrap, en .githooks/.
HOOK="$HERE/../githooks/pre-push"; [ -f "$HOOK" ] || HOOK="$HERE/../.githooks/pre-push"
# En un repo instalado, .githooks/pre-push puede ser un hook propio (sin cabecera del estándar): no es lo que esta suite prueba.
if ! sed -n 1,2p "$HOOK" | grep -q 'raken-dev-standard'; then echo "✅ pre-push: omitida (el .githooks/pre-push de este repo no es el vendorizado)"; exit 0; fi
cp "$HERE/check-deleted-refs.sh" "$R/scripts/"; cp "$HOOK" "$R/.githooks/"
printf 'export function Gone() {}\n' > "$R/src/gone.ts"
printf 'import { Gone } from "./gone"\n' > "$R/src/user.ts"
g add -A; g commit -qm base
BASE=$(git -C "$R" rev-parse HEAD)
hook() { local out rc; out=$(cd "$R" && bash .githooks/pre-push origin "$R" </dev/null 2>&1); rc=$?; check "$1" "$2" "$3" "$out" "$rc"; }
cfg() { printf 'DELETED_REFS_BASE=%s\n%s\n' "$BASE" "${1:-}" > "$R/.githooks/config"; }

cfg
hook "sin borrados, sin comando de pruebas: pasa y avisa" 0 "PREPUSH_TEST_CMD not configured"
cfg 'PREPUSH_TEST_CMD=true'
hook "pruebas en verde: pasa" 0 "✓ tests passed"
cfg 'PREPUSH_TEST_CMD="exit 3"'
hook "pruebas en rojo: bloquea" 1 "✗ tests failed"
g rm -q src/gone.ts; g commit -qm borrado
cfg 'PREPUSH_TEST_CMD=true'
hook "referencia colgante: bloquea aunque las pruebas pasen" 1 "src/user.ts:1"
cfg "PREPUSH_TEST_CMD=true"$'\n'"DELETED_REFS_SRC_RE='\.py\$'"
hook "regex de fuentes desde .githooks/config" 0 "no deleted source files"
printf 'DELETED_REFS_BASE=no-such-ref\nPREPUSH_TEST_CMD=true\n' > "$R/.githooks/config"
hook "base ilegible: bloquea" 1 "could not read base"

# --- #85: toda clave del config llega a los hijos (set -a), no solo las que el hook exporta
cfg 'PREPUSH_TEST_CMD='"'"'echo "GATEKEY=$GATE_REVIEWERS_LINE"'"'"$'\n''GATE_REVIEWERS_LINE="7 reviewers ran"'$'\n'"DELETED_REFS_SRC_RE='\.py\$'"
hook "una clave del config llega al comando hijo (set -a)" 0 "GATEKEY=7 reviewers ran"

# --- refs por stdin (#32): lo empujado, no el HEAD del checkout ---
Z=0000000000000000000000000000000000000000
hookin() { local out rc; out=$(cd "$R" && printf '%b' "$4" | bash .githooks/pre-push origin "$R" 2>&1); rc=$?; check "$1" "$2" "$3" "$out" "$rc"; }
nohook() { local out rc; out=$(cd "$R" && printf '%b' "$4" | bash .githooks/pre-push origin "$R" 2>&1); rc=$?; check "$1" "$2" "" "$out" "$rc"; [[ "$out" != *"$3"* ]] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL: $1 (no debía contener: $3)"; echo "  $out"; }; }
g checkout -q -b clean "$BASE"
g commit -q --allow-empty -m limpia; CLEAN=$(git -C "$R" rev-parse HEAD)
g checkout -q -    # de vuelta a la rama con el borrado y la referencia colgante
BAD=$(git -C "$R" rev-parse HEAD)
cfg 'PREPUSH_TEST_CMD=true'
hookin "un ref con colgante: bloquea" 1 "src/user.ts:1" "refs/heads/m $BAD refs/heads/m $BASE\n"
hookin "un ref limpio empujado desde un checkout sucio: pasa" 0 "no deleted source files" "refs/heads/clean $CLEAN refs/heads/clean $BASE\n"
hookin "varios refs, uno con colgante: bloquea" 1 "src/user.ts:1" "refs/heads/clean $CLEAN refs/heads/clean $BASE\nrefs/heads/m $BAD refs/heads/m $BASE\n"
hookin "varios refs: verifica cada uno" 1 "refs/heads/clean" "refs/heads/clean $CLEAN refs/heads/clean $BASE\nrefs/heads/m $BAD refs/heads/m $BASE\n"
hookin "rama nueva en el remoto: compara contra DELETED_REFS_BASE" 1 "src/user.ts:1" "refs/heads/n $BAD refs/heads/n $Z\n"
hookin "borrado de ref: no se verifica" 0 "borrado de ref" "(delete) $Z refs/heads/m $BAD\n"
nohook "borrado de ref: no corre pruebas ni verificaciones" 0 "check-deleted-refs" "(delete) $Z refs/heads/m $BAD\n"
hookin "sha remoto ausente del clon: cae a DELETED_REFS_BASE" 1 "src/user.ts:1" "refs/heads/m $BAD refs/heads/m 1111111111111111111111111111111111111111\n"
# el árbol del checkout es el sucio (HEAD=BAD): empujar CLEAN no debe ver su colgante
nohook "empujar otra rama: no mira el árbol del checkout" 0 "src/user.ts:1" "refs/heads/clean $CLEAN refs/heads/clean $BASE\n"
# variables para el comando de pruebas, una corrida por ref no borrado
cfg 'PREPUSH_TEST_CMD='"'"'echo "VARS $PREPUSH_REMOTE_REF $PREPUSH_LOCAL_SHA $PREPUSH_REMOTE_SHA"'"'"
hookin "exporta PREPUSH_* al comando de pruebas" 0 "VARS refs/heads/clean $CLEAN $BASE" "refs/heads/clean $CLEAN refs/heads/clean $BASE\n"
hookin "una corrida de pruebas por ref" 0 "VARS refs/heads/other $CLEAN $Z" "refs/heads/clean $CLEAN refs/heads/clean $BASE\nrefs/heads/other $CLEAN refs/heads/other $Z\n"
nohook "el borrado no corre el comando de pruebas" 0 "VARS" "(delete) $Z refs/heads/m $BAD\n"
hook "sin stdin: verifica el HEAD y exporta su sha" 1 "VARS HEAD $BAD"
check "el hook nunca sugiere --no-verify" 0 "" "" "$(grep -v '^#' "$HOOK" | grep -c -- '--no-verify')"

echo ""
if (( fail == 0 )); then echo "✅ pre-push: $pass passed"; else echo "❌ pre-push: $fail failed, $pass passed"; exit 1; fi
