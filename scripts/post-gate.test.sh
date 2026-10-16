#!/usr/bin/env bash
# raken-dev-standard v0.6.15: post-gate.test.sh
# sha256: b1b15f32c73384099babb14fc6a04700ad77fc26ee88eb2e845a1187fad9f3a9
# Pruebas sin red: bash post-gate.test.sh. GitHub se reemplaza con un `gh` falso.
# Una negativa sale con 2 y un error de GitHub con 1 (#26).
set -uo pipefail
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX  # un hook los exporta (#80)
cd "$(dirname "$0")" || exit 1
export GATE_REVIEWERS_LINE="5 reviewers ran" # fijo: las pruebas no leen el .githooks/config del repo que las aloja
# shellcheck source=./post-gate.sh
source ./post-gate.sh
# shellcheck source=./check-gate.sh
source ./check-gate.sh

pass=0; fail=0
check() { # check <label> <exit-esperado> <subcadena> <salida> <exit>
  if [ "$2" = "$5" ] && [[ "$4" == *"$3"* ]]; then pass=$((pass + 1));
  else fail=$((fail + 1)); echo "FAIL: $1"; echo "  expected: exit $2, *$3*"; echo "  actual:   exit $5, $4"; fi
}

HEAD=736fa56314a38740ba025ecaf5094e57ed7f883f
STUB=$(mktemp -d); trap 'rm -rf "$STUB"' EXIT
cat > "$STUB/gh" <<'GH'
#!/usr/bin/env bash
case "$1 $2" in
  "repo view") [ -n "${STUB_CWD_REPO:-}" ] || exit 1; echo "$STUB_CWD_REPO" ;;
  "pr view") [ "${STUB_FAIL:-}" = view ] && exit 1; echo "$STUB_HEAD" ;;
  "pr comment") [ "${STUB_FAIL:-}" = comment ] && exit 1; shift 2; printf '%s\0' "$@" > "$STUB_LOG" ;;
  *) exit 1 ;;
esac
GH
chmod +x "$STUB/gh"
export PATH="$STUB:$PATH" STUB_HEAD=$HEAD STUB_LOG="$STUB/log" STUB_CWD_REPO=o/r
p() { # p <label> <exit> <subcadena> <args…>
  local l="$1" e="$2" s="$3" out rc; shift 3
  rm -f "$STUB_LOG"; out=$(post_gate_main "$@" 2>&1 </dev/null); rc=$?; check "$l" "$e" "$s" "$out" "$rc"; }
posted() { [ -f "$STUB_LOG" ]; }

p "hallazgos vacíos: se niega" 2 "empty findings" 12 --findings "  " --yes
posted && check "hallazgos vacíos: no publica" 0 x posted 1
p "sin --findings: se niega" 2 "empty findings" 12 --yes
p "hallazgos sin puntaje: se niega" 2 "lack «N findings ≥" 12 --findings "No issues found." --yes
STUB_CWD_REPO=o/otro p "-R desde el checkout de otro repo: funciona" 0 "Gate comment for o/r#12" -R o/r 12 --findings "0 findings ≥ 80" --dry-run
STUB_CWD_REPO= p "sin -R fuera de un repo: se niega" 1 "pasa -R" 12 --findings "0 findings ≥ 80" --dry-run
p "dry-run imprime con el head de GitHub" 0 "Head SHA reviewed: $HEAD · 5 reviewers ran · 0 findings ≥ 80" 12 --findings "0 findings ≥ 80" --dry-run
posted && check "dry-run: no publica" 0 x posted 1
p "--yes publica" 0 "Gate comment for o/r#12" 12 --findings "2 findings ≥ 80: a, 90; b, 85" --yes
posted || check "--yes: publicó" 0 x "no publicó" 1

# Ida y vuelta: lo que publica post-gate lo acepta check-gate (una sola constante).
body=""; prev=""
while IFS= read -r -d '' a; do [ "$prev" = --body ] && body="$a"; prev="$a"; done < "$STUB_LOG"
out=$(gate_record 2026-10-09T00:00:00Z "$body" | check_gate_verdict "$HEAD" "2026-10-08T00:00:00Z"); rc=$?
check "ida y vuelta: check-gate acepta el comentario publicado" 0 "GATED: head 736fa563" "$out" "$rc"
GATE_REVIEWERS_LINE="3 reviewers ran" p "línea de revisores de la configuración" 0 "· 3 reviewers ran ·" 12 --findings "0 findings ≥ 80" --dry-run
p "--expect-head igual al head: publica" 0 "Gate comment for o/r#12" 12 --findings "0 findings ≥ 80" --expect-head $HEAD --yes
p "--expect-head distinto: se niega" 2 "changed since the review" 12 --findings "0 findings ≥ 80" --expect-head 23d5b5fd6e60f1b45a5ac14ba22edf881ac850ac --yes
posted && check "--expect-head distinto: no publica" 0 x posted 1
p "sin terminal ni --yes: se niega" 2 "no terminal to confirm" 12 --findings "0 findings ≥ 80"
posted && check "sin terminal: no publica" 0 x posted 1

# Negativa (2) y error de GitHub (1) se distinguen (#26).
STUB_FAIL=view p "GitHub ilegible: error, no negativa" 1 "could not read PR" 12 --findings "0 findings ≥ 80" --yes
STUB_FAIL=comment p "GitHub no acepta el comentario: error, no negativa" 1 "could not post" 12 --findings "0 findings ≥ 80" --yes
p "sin número de PR: uso" 1 "usage" --findings "0 findings ≥ 80" --yes

echo ""
if (( fail == 0 )); then echo "✅ post-gate: $pass passed"; else echo "❌ post-gate: $fail failed, $pass passed"; exit 1; fi
