#!/usr/bin/env bash
# raken-dev-standard v0.6.15: check-label.test.sh
# sha256: 6a3704fc5a7ff87cbe980e6f6956a490a80991686c42fa5200999d9f9e11600e
# Pruebas de tabla del veredicto, sin red: bash check-label.test.sh
# GitHub se reemplaza con un `gh` falso en el PATH. fixtures/label-real-*.tsv
# es historia real anonimizada (bafar-pricing-ui #460): tipos de evento y fechas
# reales, nombres de etiqueta distintos de ready-for-agent reemplazados. Está en el
# formato que deja el --jq de check_label_main: lastEditedAt y un evento por línea.
set -uo pipefail
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX  # un hook los exporta (#80)
cd "$(dirname "$0")" || exit 1
# shellcheck source=./check-label.sh
source ./check-label.sh

pass=0; fail=0
check() { # check <label> <exit-esperado> <subcadena> <salida> <exit>
  if [ "$2" = "$5" ] && [[ "$4" == *"$3"* ]]; then pass=$((pass + 1));
  else fail=$((fail + 1)); echo "FAIL: $1"; echo "  expected: exit $2, *$3*"; echo "  actual:   exit $5, $4"; fi
}
R=ready-for-agent
ev() { printf '%s\t%s\t%s\n' "$@"; }
t() { # t <label> <exit> <subcadena> <last_edited_at>   (eventos por stdin)
  local out rc; out=$(check_label_verdict "$4"); rc=$?; check "$1" "$2" "$3" "$out" "$rc"; }

# --- Tabla del veredicto ---
t "etiqueta antes de la edición" 2 "has not seen the current body" 2026-10-02T10:00:00Z < <(ev labeled 2026-10-01T10:00:00Z $R)
t "etiqueta después de la edición" 0 "AUTHORIZED" 2026-10-01T10:00:00Z < <(ev labeled 2026-10-02T10:00:00Z $R)
t "quitar y volver a aplicar después de la edición" 0 "AUTHORIZED: «ready-for-agent» applied at 2026-10-03" 2026-10-02T10:00:00Z \
  < <(ev labeled 2026-10-01T10:00:00Z $R; ev unlabeled 2026-10-02T11:00:00Z $R; ev labeled 2026-10-03T10:00:00Z $R)
t "quitar y volver a aplicar, pero antes de la edición" 2 "has not seen the current body" 2026-10-04T10:00:00Z \
  < <(ev labeled 2026-10-01T10:00:00Z $R; ev unlabeled 2026-10-02T11:00:00Z $R; ev labeled 2026-10-03T10:00:00Z $R)
t "sin etiqueta" 2 "no current" 2026-10-01T10:00:00Z < /dev/null
t "etiquetada y quitada" 2 "no current" "" < <(ev labeled 2026-10-01T10:00:00Z $R; ev unlabeled 2026-10-02T10:00:00Z $R)
t "otra etiqueta no autoriza" 2 "no current" "" < <(ev labeled 2026-10-01T10:00:00Z needs-info)
t "cuerpo nunca editado" 0 "body last edited never" "" < <(ev labeled 2026-10-01T10:00:00Z $R)
t "misma marca de tiempo: no autoriza" 2 "has not seen the current body" 2026-10-01T10:00:00Z < <(ev labeled 2026-10-01T10:00:00Z $R)
t "otra etiqueta quitada no revoca" 0 "AUTHORIZED" "" < <(ev labeled 2026-10-01T10:00:00Z $R; ev unlabeled 2026-10-02T10:00:00Z needs-info)

# --- Historia real anonimizada (sin red) ---
fxj() { # fxj <archivo> [corte] → la fixture, solo con los eventos anteriores al corte
  local cut="${2:-}" kind at name
  sed -n 1p "$1"
  tail -n +2 "$1" | while IFS=$'\t' read -r kind at name; do
    if [ -z "$cut" ] || [[ "$at" < "$cut" ]]; then printf '%s\t%s\t%s\n' "$kind" "$at" "$name"; fi
  done; }
fxv() { # fxv <label> <exit> <subcadena> <archivo> [corte]
  local lines edited out rc; lines=$(fxj "$4" "${5:-}"); edited=$(printf '%s\n' "$lines" | head -n1)
  out=$(printf '%s\n' "$lines" | tail -n +2 | check_label_verdict "$edited"); rc=$?; check "$1" "$2" "$3" "$out" "$rc"; }
FX=fixtures/label-real-relabeled-after-edit.tsv
fxv "real: reaplicada después de la última edición" 0 "AUTHORIZED: «ready-for-agent» applied at 2026-09-26T10:51:26Z" $FX
# Derivado de la misma historia: sin el quita-y-reaplica de las 10:27 (corte antes), la
# etiqueta de las 18:54 del 09-25 es anterior a la edición de las 10:49 del 09-26.
fxv "real, sin la reaplicación: etiqueta anterior a la edición" 2 "has not seen the current body" $FX 2026-09-26T10:27:00Z
fxv "real, tras quitar la etiqueta y antes de reaplicar" 2 "no current" $FX 2026-09-26T10:51:00Z

# --- check_label_main con un gh falso ---
STUB=$(mktemp -d); trap 'rm -rf "$STUB"' EXIT
cat > "$STUB/gh" <<'GH'
#!/usr/bin/env bash
# gh falso: STUB_CWD_REPO (vacío = no es repo), STUB_FAIL=api, STUB_RESPONSE (archivo, ya filtrado por --jq)
case "$1 $2" in
  "repo view") [ -n "${STUB_CWD_REPO:-}" ] || exit 1; echo "$STUB_CWD_REPO" ;;
  api*) [ "${STUB_FAIL:-}" = api ] && exit 1; cat "$STUB_RESPONSE" ;;
  *) exit 1 ;;
esac
GH
chmod +x "$STUB/gh"
export PATH="$STUB:$PATH" STUB_RESPONSE="$FX"
m() { # m <label> <exit> <subcadena> <args…>   (salida y stderr juntos)
  local l="$1" e="$2" s="$3" out rc; shift 3
  out=$(check_label_main "$@" 2>&1); rc=$?; check "$l" "$e" "$s" "$out" "$rc"; }
STUB_CWD_REPO=acme/app m "main: autorizado desde el repo correcto" 0 "AUTHORIZED" 460
STUB_CWD_REPO=acme/app m "main: -R igual al cwd" 0 "AUTHORIZED" -R acme/app 460
STUB_CWD_REPO=acme/otro m "main: repo distinto falla en lugar de verificar otro issue" 1 "no es el repo del issue o PR" -R acme/app 460
STUB_CWD_REPO= m "main: cwd fuera de un repo y sin -R" 1 "pasa -R" 460
STUB_CWD_REPO= m "main: cwd fuera de un repo con -R" 0 "AUTHORIZED" -R acme/app 460
STUB_CWD_REPO=o/r STUB_FAIL=api m "main: gh falla → 1, no «no autorizado»" 1 "could not read" 460
STUB_CWD_REPO=o/r m "main: sin número de issue" 1 "usage"

echo ""
if (( fail == 0 )); then echo "✅ check-label: $pass passed"; else echo "❌ check-label: $fail failed, $pass passed"; exit 1; fi
