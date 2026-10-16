#!/usr/bin/env bash
# raken-dev-standard v0.6.15: check-deleted-refs.test.sh
# sha256: db2dcf5885c61439e2794fc2227f4f57c3dfcb6e6deb9a56c4a38eb17f28a0e0
# Pruebas de tabla del extractor de claves y del escaneo, sin red:
#   bash check-deleted-refs.test.sh
# fixtures/deleted-refs/ trae un borrado real anonimizado: el estado
# antes del borrado y el estado después del commit que lo arregló. Los fuentes
# llevan .txt al final para que el tsc, jest, vitest o knip del repo que los
# vendoriza no los recoja (#51); fx_copy les quita el .txt al armar el árbol.
set -uo pipefail
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX  # un hook los exporta (#80)
cd "$(dirname "$0")" || exit 1
unset DELETED_REFS_SRC_RE DELETED_REFS_SKIP_RE DELETED_REFS_GENERIC
# shellcheck source=./check-deleted-refs.sh
source ./check-deleted-refs.sh
HERE=$(pwd)

pass=0; fail=0
check() { if [ "$2" = "$3" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: $1"; echo "  expected: $2"; echo "  actual:   $3"; fi; }

# --- Claves ---
k=$(printf 'import x\nexport function OldWidget() {}\nexport const useBanner = 1\nexport default class Foo {}\nconst hidden = 2\n' | deleted_refs_keys src/components/old-widget.tsx | tr '\n' ' ')
check "nombre base + símbolos exportados, no los privados" "old-widget OldWidget useBanner Foo " "$k"
k=$(printf 'export const a = 1\n' | deleted_refs_keys src/lib/foo/index.ts | tr '\n' ' ')
check "un barrel index aporta solo símbolos" "a " "$k"
k=$(printf 'it("x",()=>{})\n' | deleted_refs_keys src/x.test.ts | tr '\n' ' ')
check "una prueba no aporta nada" "" "$k"
k=$(printf 'def f():\n  pass\n' | deleted_refs_keys app/__init__.py | tr '\n' ' ')
check "__init__ sin exports no aporta nada" "" "$k"
# Un nombre base genérico coincide en todo el árbol: no es clave; sus exports sí (#30).
for n in page utils types layout route; do
  k=$(printf 'export function Real%s() {}\n' "$n" | deleted_refs_keys "src/app/x/$n.tsx" | tr '\n' ' ')
  check "nombre genérico «${n}»: solo sus exports" "Real${n} " "$k"
done
k=$(printf 'const a = 1\n' | deleted_refs_keys src/ui.ts | tr '\n' ' ')
check "nombre base de menos de 3 caracteres: no es clave" "" "$k"
k=$(printf 'const a = 1\n' | deleted_refs_keys src/api.ts | tr '\n' ' ')
check "nombre base de 3 caracteres: es clave" "api " "$k"
k=$(printf 'const a = 1\n' | DELETED_REFS_GENERIC="api" deleted_refs_keys src/api.ts | tr '\n' ' ')
check "configurable: DELETED_REFS_GENERIC del repo manda" "" "$k"
k=$(printf 'const a = 1\n' | DELETED_REFS_GENERIC="" deleted_refs_keys src/page.tsx | tr '\n' ' ')
check "configurable: lista vacía busca también los genéricos" "page " "$k"

# --- Regex de fuentes ---
src() { printf '%s\n' "$1" | grep -cE "$DELETED_REFS_SRC_RE"; }
check "por defecto: .tsx en cualquier carpeta es fuente" 1 "$(src lib/ui/x.tsx)"
check "por defecto: .py en la raíz es fuente" 1 "$(src tool.py)"
check "por defecto: .md no es fuente" 0 "$(src docs/x.md)"
check "configurable: la regex del repo manda" 0 "$(DELETED_REFS_SRC_RE='^src/' bash -c 'source ./check-deleted-refs.sh; printf "lib/x.ts\n" | grep -cE "$DELETED_REFS_SRC_RE"')"

# --- Escaneo ---
T=$(mktemp -d); H=$(mktemp -d); R=$(mktemp -d); trap 'rm -rf "$T" "$H" "$R"' EXIT
mkdir -p "$T/src/a" "$T/.claude/rules" "$T/node_modules/pkg"
printf 'export function Gone() {}\n' > "$T/src/a/gone.tsx"
printf 'import { Gone } from "./gone"\n' > "$T/src/a/user.tsx"
printf 'Reuse `gone.tsx` for banners.\n' > "$T/.claude/rules/ui.md"
printf '## 0.1.0\n- removed gone.tsx\n' > "$T/CHANGELOG.md"
printf 'Gone Gone Gone\n' > "$T/node_modules/pkg/x.js"
printf 'src/a/gone.tsx\n' > "$H/deleted"
printf 'gone\nGone\n' > "$H/keys"

out=$(deleted_refs_scan "$T" "$H/deleted" "$H/keys"); rc=$?
check "referencias → exit 2" 2 "$rc"
check "encuentra el import"         1 "$(grep -c 'src/a/user.tsx:1' <<<"$out")"
check "encuentra la regla"          1 "$(grep -c '.claude/rules/ui.md:1' <<<"$out")"
check "ignora CHANGELOG"            0 "$(grep -c 'CHANGELOG' <<<"$out")"
check "ignora node_modules"         0 "$(grep -c 'node_modules' <<<"$out")"
check "ignora el propio borrado"    0 "$(grep -c '^src/a/gone.tsx:' <<<"$out")"
mkdir -p "$T/xsrc/a"; printf '// see /dist/ Gone\n' > "$T/xsrc/a/gone.tsx"
out=$(deleted_refs_scan "$T" "$H/deleted" "$H/keys")
check "el filtro de borrados es por ruta exacta, no subcadena" 1 "$(grep -c '^xsrc/a/gone.tsx:1' <<<"$out")"
rm -r "$T/xsrc" "$T/src/a/user.tsx" "$T/.claude/rules/ui.md"
out=$(deleted_refs_scan "$T" "$H/deleted" "$H/keys"); rc=$?
check "árbol limpio → exit 0" 0 "$rc"
: > "$H/keys"
out=$(deleted_refs_scan "$T" "$H/deleted" "$H/keys"); rc=$?
check "sin claves → exit 0, nunca grep de nada" 0 "$rc"

# --- Historia real (anonimizada) a través de git, sin red ---
F="$HERE/fixtures/deleted-refs"
g() { git -C "$R" -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false "$@" >/dev/null 2>&1; }
fx_copy() { # fx_copy <origen> <destino>: copia el árbol y quita el .txt de los fuentes
  local f; cp -R "$1/." "$2/"
  find "$2/src" -name '*.txt' | while IFS= read -r f; do mv "$f" "${f%.txt}"; done
}
g init -q
fx_copy "$F/before" "$R"; g add -A; g commit -qm before
BASE=$(git -C "$R" rev-parse HEAD)
g rm -q src/components/panel/notice-strip.tsx src/components/panel/__tests__/notice-strip.test.tsx; g commit -qm borrado
out=$(cd "$R" && check_deleted_refs_main "$BASE"); rc=$?
check "antes + borrado → exit 2" 2 "$rc"
check "antes + borrado → 6 referencias" 6 "$(grep -cE '^  src/app/' <<<"$out")"
check "ningún fixture vendorizado tiene extensión de fuente (#51)" "" "$(find "$F" -type f | grep -E '\.(ts|tsx|js|jsx)$')"
check "las claves son nombre base + 3 exports" "keys: NoticeStrip NoticeStripView notice-strip noticePause " "$(grep '^keys:' <<<"$out")"
check "encuentra el vi.mock por ruta"   1 "$(grep -c 'log-page.test.tsx:3:' <<<"$out")"
check "encuentra el uso en JSX"         1 "$(grep -c 'src/app/panel/page.tsx:6:' <<<"$out")"
rm -rf "${R:?}/src" "$R/CHANGELOG.md"; fx_copy "$F/after" "$R"; g add -A; g commit -qm arreglo
out=$(cd "$R" && check_deleted_refs_main "$BASE"); rc=$?
check "después (referencias arregladas) → exit 0" 0 "$rc"
check "después → sin referencias" 1 "$(grep -c 'no dangling references' <<<"$out")"
FIXED=$(git -C "$R" rev-parse HEAD)
g mv src/app/panel/page.tsx src/app/panel/home.tsx; printf 'import { PanelPage } from "./page"\n' > "$R/src/app/panel/index.tsx"; g add -A; g commit -qm renombre
out=$(cd "$R" && check_deleted_refs_main "$BASE"); rc=$?
check "un renombre cuenta como borrado de la ruta vieja" 1 "$(grep -c 'src/app/panel/index.tsx:1' <<<"$out")"
# <sha> (#32): se verifican los commits de ese sha y se busca en su árbol, no en el del checkout
out=$(cd "$R" && check_deleted_refs_main "$BASE" "$FIXED"); rc=$?
check "<sha> limpio con el checkout en un HEAD colgante → exit 0" 0 "$rc"
out=$(cd "$R" && check_deleted_refs_main "$BASE" HEAD); rc=$?
check "<sha> = HEAD colgante → exit 2" 2 "$rc"
out=$(cd "$R" && check_deleted_refs_main "$BASE" "$(git -C "$R" rev-parse HEAD)"); rc=$?
check "<sha> escrito como sha completo del HEAD → exit 2" 2 "$rc"
out=$(cd "$R" && check_deleted_refs_main "$BASE" no-such-sha 2>&1); rc=$?
check "<sha> ilegible → exit 1, no «limpio»" 1 "$rc"
out=$(cd "$R" && check_deleted_refs_main HEAD); rc=$?
check "sin borrados desde la base → exit 0" 0 "$rc"
out=$(cd "$R" && check_deleted_refs_main no-such-ref 2>&1); rc=$?
check "base ilegible → exit 1, no «limpio»" 1 "$rc"
out=$(cd "$H" && check_deleted_refs_main HEAD 2>&1); rc=$?
check "fuera de un repo git → exit 1" 1 "$rc"

echo ""
if (( fail == 0 )); then echo "✅ check-deleted-refs: $pass passed"; else echo "❌ check-deleted-refs: $fail failed, $pass passed"; exit 1; fi
