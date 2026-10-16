#!/usr/bin/env bash
# raken-dev-standard v0.6.15: check-deleted-refs.sh
# sha256: b0636d55fea3bdbba3f9175802d3bfd1626d9ef957c528fa4ee30474c2e7605d
#
# ¿Se borró un archivo? Nada en el árbol puede seguir nombrándolo.
#
#   check-deleted-refs.sh [<base> [<sha>]]
#       base por defecto: origin/main; <sha> por defecto: HEAD del checkout
#       (con <sha> se verifican los commits de ese sha y se busca en su árbol,
#       no en el del checkout: así el hook pre-push verifica lo que empuja)
#       0 = sin referencias colgantes
#       2 = referencias impresas (corregirlas en el mismo cambio)
#       1 = no pudo leer git (base inexistente, fuera de un repo)
#
# Por cada fuente borrada desde <base> busca su nombre base sin extensión (salvo
# un nombre genérico o de menos de 3 caracteres, que coincide en todo el árbol)
# y cada símbolo exportado del blob borrado, en todo el árbol salvo el propio borrado y
# los archivos con forma de historia (CHANGELOG, DECISIONS, lockfiles, build).
# La historia puede recordar; el código, las reglas y los comentarios no.
#
# Configuración del repo (variables de entorno, o .githooks/config vía el hook):
#   DELETED_REFS_SRC_RE   qué rutas borradas cuentan como fuente (por extensión)
#   DELETED_REFS_SKIP_RE  qué rutas pueden seguir nombrándolas
#   DELETED_REFS_GENERIC  nombres base que no se buscan, separados por espacios
#                         (vacío = se buscan todos; sus exports se buscan siempre)
#
# Extractor y escaneo puros + lector delgado de git; prueba de tabla en
# check-deleted-refs.test.sh sin red.
set -uo pipefail

DELETED_REFS_SRC_RE="${DELETED_REFS_SRC_RE:-\.(ts|tsx|js|jsx|mjs|cjs|py|sh|sql|sqlx|go|rb|rs|java|kt)$}"
DELETED_REFS_GENERIC="${DELETED_REFS_GENERIC-page layout route loading error template default utils util helpers helper types type constants config main app lib common shared mod}"
DELETED_REFS_SKIP_RE="${DELETED_REFS_SKIP_RE:-(^|/)(CHANGELOG\.md|DECISIONS\.md|package-lock\.json|pnpm-lock\.yaml|yarn\.lock|uv\.lock|poetry\.lock|\.git|node_modules|\.next|\.venv|dist|coverage)(/|$)}"

# deleted_refs_keys <ruta>   (stdin: contenido del blob borrado)
#   Imprime las claves de búsqueda de un archivo borrado, una por línea.
deleted_refs_keys() {
  local path="$1" base
  base=$(basename "$path"); base="${base%.*}"
  # las pruebas, los barrels index, los nombres genéricos (#30) y los de menos
  # de 3 caracteres no nombran nada que valga buscar: coinciden en todo el árbol
  case "$base" in
    index|__init__|*.test|*.spec|test_*|*_test) ;;
    *) if [ "${#base}" -ge 3 ] && [[ " ${DELETED_REFS_GENERIC} " != *" ${base} "* ]]; then printf '%s\n' "$base"; fi ;;
  esac
  grep -oE '^export[[:space:]]+(default[[:space:]]+)?(async[[:space:]]+)?(function|const|let|class|type|interface|enum)[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' \
    | awk '{print $NF}'
  true
}

# deleted_refs_scan <raíz> <archivo-de-borrados> <archivo-de-claves>
#   Busca cada clave en <raíz>, salvo los borrados y la historia (filtros sobre
#   la ruta, nunca sobre el texto de la línea).
#   Imprime `ruta:línea: texto` por referencia; devuelve 2 si hay alguna, 0 si no.
deleted_refs_scan() {
  local root="$1" deleted="$2" keys="$3" hits
  [ -s "$keys" ] || return 0
  hits=$(cd "$root" && LC_ALL=C grep -rnIF -f "$keys" . \
      --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=".next*" --exclude-dir=.venv \
      --exclude-dir=.terraform --exclude-dir=dist --exclude-dir=coverage \
      2>/dev/null \
    | sed 's#^\./##' \
    | DELETED="$deleted" SKIP="$DELETED_REFS_SKIP_RE" awk -F: '
        BEGIN { while ((getline d < ENVIRON["DELETED"]) > 0) gone[d] = 1 }
        !($1 in gone) && $1 !~ ENVIRON["SKIP"]' \
    || true)
  [ -z "$hits" ] && return 0
  printf '%s\n' "$hits"
  return 2
}

check_deleted_refs_main() {
  local base="${1:-origin/main}" sha="${2:-HEAD}" tmp out rc p root mb
  case "$base" in -h|--help) echo "usage: check-deleted-refs.sh [<base> [<sha>]]   (default origin/main, HEAD)"; return 0 ;; esac
  if ! git rev-parse --verify --quiet "$base^{commit}" >/dev/null 2>&1; then
    echo "ERROR: could not read base «${base}» (missing git fetch, or not a git repo?)" >&2
    return 1
  fi
  if ! git rev-parse --verify --quiet "$sha^{commit}" >/dev/null 2>&1; then
    echo "ERROR: could not read commit «${sha}»" >&2
    return 1
  fi
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' RETURN
  if ! git diff --no-renames --name-only --diff-filter=D "$base...$sha" > "$tmp/all" 2>/dev/null; then
    echo "ERROR: git diff $base...$sha failed" >&2; return 1
  fi
  grep -E "$DELETED_REFS_SRC_RE" "$tmp/all" > "$tmp/deleted" || true
  [ -s "$tmp/deleted" ] || { echo "✓ no deleted source files since $base"; return 0; }
  echo "deleted since $base:"; sed 's/^/  /' "$tmp/deleted"
  # el blob borrado se lee del ancestro común: con un push no fast-forward la base
  # (el sha remoto) puede ya no tener el archivo
  mb=$(git merge-base "$base" "$sha" 2>/dev/null || echo "$base")
  while IFS= read -r p; do
    git show "$mb:$p" 2>/dev/null | deleted_refs_keys "$p"
  done < "$tmp/deleted" | LC_ALL=C sort -u > "$tmp/keys"
  echo "keys: $(tr '\n' ' ' < "$tmp/keys")"
  root=$(git rev-parse --show-toplevel)
  if [ "$(git rev-parse "$sha^{commit}")" != "$(git rev-parse HEAD 2>/dev/null)" ]; then
    # un sha que no es el HEAD del checkout: se busca en su árbol, no en el de trabajo
    mkdir "$tmp/tree"
    if ! git archive "$sha" | tar -x -C "$tmp/tree" 2>/dev/null; then
      echo "ERROR: could not extract the tree of $sha" >&2; return 1
    fi
    root="$tmp/tree"
  fi
  out=$(deleted_refs_scan "$root" "$tmp/deleted" "$tmp/keys"); rc=$?
  if (( rc == 2 )); then
    echo "✗ still referenced after deletion:"; printf '%s\n' "$out" | sed 's/^/  /'
  else
    echo "✓ no dangling references"
  fi
  return $rc
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  check_deleted_refs_main "$@"
fi
