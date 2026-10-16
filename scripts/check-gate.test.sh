#!/usr/bin/env bash
# raken-dev-standard v0.6.15: check-gate.test.sh
# sha256: a8b5054d2675c9c72c8f4c0fb1b2156685691dbb0b8b6dcf007e319bd4b519bb
# Pruebas de tabla del veredicto, sin red: bash check-gate.test.sh
# GitHub se reemplaza con un `gh` falso en el PATH. fixtures/ trae casos de
# historia real anonimizados: SHAs y fechas reales, textos neutros.
set -uo pipefail
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX  # un hook los exporta (#80)
cd "$(dirname "$0")" || exit 1
export GATE_REVIEWERS_LINE="5 reviewers ran" # fijo: las pruebas no leen el .githooks/config del repo que las aloja
# shellcheck source=./check-gate.sh
source ./check-gate.sh

pass=0; fail=0
check() { # check <label> <exit-esperado> <subcadena> <salida> <exit>
  if [ "$2" = "$5" ] && [[ "$4" == *"$3"* ]]; then pass=$((pass + 1));
  else fail=$((fail + 1)); echo "FAIL: $1"; echo "  expected: exit $2, *$3*"; echo "  actual:   exit $5, $4"; fi
}

HEAD=736fa56314a38740ba025ecaf5094e57ed7f883f
OLD=23d5b5fd6e60f1b45a5ac14ba22edf881ac850ac
HEAD_AT=2026-10-08T21:48:55Z
c() { gate_record "$1" "$2"; }
GOOD=$(gate_format_body "$HEAD" "0 findings ≥ 80 (highest: x, 50)")
OLDGOOD=$(gate_format_body "$OLD" "0 findings ≥ 80")

t() { # t <label> <exit> <subcadena>   (comentarios por stdin)
  local out rc; out=$(check_gate_verdict "$HEAD" "$HEAD_AT"); rc=$?; check "$1" "$2" "$3" "$out" "$rc"; }

# --- Tabla del veredicto ---
t "sin comentarios" 2 "no «### Code review»" < /dev/null
t "solo conversación" 2 "no «### Code review»" < <(c 2026-10-08T21:00:00Z "Both fixes are in and pushed.")
t "sin línea de SHA" 2 "no «Head SHA reviewed" < <(c 2026-10-08T21:50:00Z "$(printf '### Code review\n\nNo issues found.')")
t "head anterior" 2 "reviewed 23d5b5fd, PR head is 736fa563" < <(c 2026-10-08T21:43:46Z "$OLDGOOD")
t "anterior y luego vigente: gana el último" 0 "GATED: head 736fa563" < <(c 2026-10-08T21:43:46Z "$OLDGOOD"; c 2026-10-08T21:53:51Z "$GOOD")
t "vigente y luego anterior: no gateado" 2 "re-run the gate" < <(c 2026-10-08T21:53:51Z "$GOOD"; c 2026-10-08T21:55:00Z "$OLDGOOD")
t "sin línea de revisores" 2 "lacks «5 reviewers ran»" < <(c 2026-10-08T21:53:51Z "$(printf '### Code review\nHead SHA reviewed: %s · 0 findings ≥ 80' $HEAD)")
t "3 revisores" 2 "lacks «5 reviewers ran»" < <(c 2026-10-08T21:53:51Z "$(printf '### Code review\nHead SHA reviewed: %s · 3 reviewers ran · 0 findings ≥ 80' $HEAD)")
t "sin hallazgos" 2 "no scored findings" < <(c 2026-10-08T21:53:51Z "$(printf '### Code review\nHead SHA reviewed: %s · 5 reviewers ran' $HEAD)")
t "comentario anterior al commit" 2 "predates the head commit" < <(c 2026-10-08T21:40:00Z "$GOOD")
t "gateado" 0 "GATED: head 736fa563 · 5 reviewers ran" < <(c 2026-10-08T21:53:51Z "$GOOD")
t "dos compuertas sobre el mismo head: aviso" 0 "2 gate comments on this same head" < <(c 2026-10-08T21:50:00Z "$GOOD"; c 2026-10-08T21:53:51Z "$GOOD")
t "SHA corto en el comentario" 0 "GATED" < <(c 2026-10-08T21:53:51Z "$(gate_format_body "${HEAD:0:8}" "0 findings ≥ 80")")
t "cuerpo multilínea con tab" 0 "GATED" < <(c 2026-10-08T21:53:51Z "$(printf '%s\n\n\tfoo\tbar' "$GOOD")")
GATE_REVIEWERS_LINE="3 reviewers ran" t "línea de revisores configurada" 0 "3 reviewers ran" < <(c 2026-10-08T21:53:51Z "$(printf '### Code review\nHead SHA reviewed: %s · 3 reviewers ran · 0 findings ≥ 80' $HEAD)")

# --- Historia real anonimizada (fixtures/<caso>.records, sin red) ---
# Línea 1: head; línea 2: fecha del commit; después, los comentarios tal como los
# deja el --jq de check_gate_main (created_at, cuerpo, línea con el byte RS).
fx() { # fx <label> <exit> <subcadena> <caso>
  local h a out rc f="fixtures/$4.records"
  h=$(sed -n 1p "$f"); a=$(sed -n 2p "$f")
  out=$(comments_of "$f" | check_gate_verdict "$h" "$a"); rc=$?; check "$1" "$2" "$3" "$out" "$rc"; }
comments_of() { tail -n +3 "$1"; }
fx "compuerta genuina" 0 "GATED: head 736fa563" gated
fx "merge sobre head anterior" 2 "reviewed 23d5b5fd, PR head is 736fa563" stale-head
fx "compuerta falsa «No issues found» sin SHA" 2 "no «Head SHA reviewed" no-sha-line
fx "compuerta falsa con firma, sin SHA" 2 "no «Head SHA reviewed" no-sha-line-trailer

# --- check_gate_main con un gh falso ---
STUB=$(mktemp -d); trap 'rm -rf "$STUB"' EXIT
cat > "$STUB/gh" <<'GH'
#!/usr/bin/env bash
# gh falso: STUB_CWD_REPO (vacío = no es repo), STUB_FAIL=view|api, STUB_COMMENTS (archivo)
case "$1 $2" in
  "repo view") [ -n "${STUB_CWD_REPO:-}" ] || exit 1; echo "$STUB_CWD_REPO" ;;
  "pr view") [ "${STUB_FAIL:-}" = view ] && exit 1
    echo "$STUB_HEAD $STUB_HEAD_AT" ;;
  "pr comment") echo "$*" >> "$STUB_LOG" ;;
  api*) [ "${STUB_FAIL:-}" = api ] && exit 1; cat "$STUB_COMMENTS" ;;
  *) exit 1 ;;
esac
GH
chmod +x "$STUB/gh"
comments_of fixtures/gated.records > "$STUB/comments"
export PATH="$STUB:$PATH" STUB_HEAD=$HEAD STUB_HEAD_AT=$HEAD_AT STUB_COMMENTS="$STUB/comments" STUB_LOG="$STUB/log"
m() { # m <label> <exit> <subcadena> <args…>   (salida y stderr juntos)
  local l="$1" e="$2" s="$3" out rc; shift 3
  out=$(check_gate_main "$@" 2>&1); rc=$?; check "$l" "$e" "$s" "$out" "$rc"; }
STUB_CWD_REPO=acme/app m "main: gateado desde el repo correcto" 0 "GATED" 42
STUB_CWD_REPO=acme/app m "main: -R igual al cwd" 0 "GATED" -R acme/app 42
STUB_CWD_REPO=acme/otro m "main: -R desde el checkout de otro repo verifica el PR de -R" 0 "GATED" -R acme/app 42
STUB_CWD_REPO= m "main: cwd fuera de un repo y sin -R" 1 "pasa -R" 42
STUB_CWD_REPO= m "main: cwd fuera de un repo con -R" 0 "GATED" -R acme/app 42
STUB_CWD_REPO=o/r STUB_FAIL=view m "main: gh pr view falla → 1" 1 "could not read PR" 42
STUB_CWD_REPO=o/r STUB_FAIL=api m "main: gh api falla → 1, no «no gateado»" 1 "could not read comments" 42
STUB_CWD_REPO=o/r m "main: sin número de PR" 1 "usage" 

echo ""
if (( fail == 0 )); then echo "✅ check-gate: $pass passed"; else echo "❌ check-gate: $fail failed, $pass passed"; exit 1; fi
