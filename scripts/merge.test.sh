#!/usr/bin/env bash
# raken-dev-standard v0.6.15: merge.test.sh
# sha256: 3b242bea12e7112a417784d05812708753a185dfd38b000ea6adc69bd7d3f49b
# Pruebas sin red: bash merge.test.sh. GitHub es un `gh` falso; origin, un repo bare local.
# Verifica el plan, los rechazos (sin compuerta, sin etiqueta, árbol equivocado,
# GitHub ilegible) y que ningún rechazo llegue a comentar ni fusionar.
set -uo pipefail
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX  # un hook los exporta (#80)
HERE="$(cd "$(dirname "$0")" && pwd)"
export GATE_REVIEWERS_LINE="5 reviewers ran" # fijo: las pruebas no leen el .githooks/config del repo que las aloja
# shellcheck source=./gate-format.sh
source "$HERE/gate-format.sh"
pass=0; fail=0
check() { # check <label> <exit-esperado> <subcadena> <salida> <exit>
  if [ "$2" = "$5" ] && [[ "$4" == *"$3"* ]]; then pass=$((pass + 1));
  else fail=$((fail + 1)); echo "FAIL: $1"; echo "  expected: exit $2, *$3*"; echo "  actual:   exit $5, $4"; fi
}
HEAD=736fa56314a38740ba025ecaf5094e57ed7f883f
OTHER=23d5b5fd6e60f1b45a5ac14ba22edf881ac850ac
HEAD_AT=2026-10-08T21:48:55Z

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
git init -q --bare -b main "$T/origin.git"
git clone -q "$T/origin.git" "$T/w" 2>/dev/null; cd "$T/w" || exit 1
git checkout -q -b main 2>/dev/null; echo a > a; git add a; git commit -qm a; git push -q -u origin main
git remote set-head origin main >/dev/null 2>&1

cat > "$T/gh" <<'GH'
#!/usr/bin/env bash
# gh falso. STUB_FAIL=view|api|graphql|merge|policy|comment|compare, STUB_COMPARE (status de la comparación base...head), STUB_STATE, STUB_BODY,
# STUB_CLOSING (closingIssuesReferences), STUB_HEAD, STUB_HEAD_LATER (head de la lectura final), STUB_COMMENTS, STUB_LABEL
echo "$*" >> "$STUB_LOG"
case "$1 $2" in
  "repo view") echo "o/r" ;;
  "pr view")
    [ "${STUB_FAIL:-}" = view ] && exit 1
    case "$*" in
      *baseRefName*) echo main ;;
      *headRefOid,commits*) echo "$STUB_HEAD $STUB_HEAD_AT" ;;
      *headRefOid,state*) echo "$STUB_HEAD ${STUB_STATE:-OPEN}" ;;
      *closingIssuesReferences*) [ -z "${STUB_CLOSING:-}" ] || printf '%s\n' "$STUB_CLOSING" ;;
      *"--json body"*) printf '%s\n' "$STUB_BODY" ;;
      *) echo "${STUB_HEAD_LATER:-$STUB_HEAD}" ;;
    esac ;;
  "pr comment") [ "${STUB_FAIL:-}" = comment ] && exit 1; echo "COMMENT: $*" >> "$STUB_LOG.act" ;;
  "pr merge") [ "${STUB_FAIL:-}" = merge ] && exit 1
    if [ "${STUB_FAIL:-}" = policy ]; then
      echo "X Pull request o/r#42 is not mergeable: the base branch policy prohibits the merge." >&2
      echo "To use administrator privileges to immediately merge the pull request, add the \`--admin\` flag." >&2; exit 1
    fi
    echo "MERGE: $*" >> "$STUB_LOG.act" ;;
  "api graphql") [ "${STUB_FAIL:-}" = graphql ] && exit 1; cat "$STUB_LABEL" ;;
  "api repos/o/r/compare/"*) [ "${STUB_FAIL:-}" = compare ] && exit 1; echo "${STUB_COMPARE:-ahead}" ;;
  api*) [ "${STUB_FAIL:-}" = api ] && exit 1; cat "$STUB_COMMENTS" ;;
  *) exit 1 ;;
esac
GH
chmod +x "$T/gh"
# Las respuestas del gh falso ya vienen filtradas, como las deja el --jq de cada script.
J() { printf '%s\n%s\n\036\n' "$1" "$2"; } # un registro de comentario (check_gate_verdict)
J 2026-10-08T21:53:51Z "$(gate_format_body "$HEAD" "0 findings ≥ 80")" > "$T/gate-ok"
J 2026-10-08T21:53:51Z "$(gate_format_body "$OTHER" "0 findings ≥ 80")" > "$T/gate-stale"
: > "$T/gate-none"
label() { # label <file> <labeled|none> [lastEditedAt]
  { printf '%s\n' "${3:-}"
    [ "$2" = none ] || printf 'labeled\t2026-10-08T20:00:00Z\tready-for-agent\n'; } > "$1"; }
label "$T/label-ok" labeled
label "$T/label-none" none
label "$T/label-edited" labeled 2026-10-08T20:30:00Z

export PATH="$T:$PATH" STUB_HEAD=$HEAD STUB_HEAD_AT=$HEAD_AT STUB_LOG="$T/log" \
  STUB_COMMENTS="$T/gate-ok" STUB_LABEL="$T/label-ok" STUB_BODY="Resumen.

Cierra #18"
reset() { : > "$T/log"; : > "$T/log.act"; }
m() { # m <label> <exit> <subcadena> <args…>
  local l="$1" e="$2" s="$3" out rc; shift 3; reset
  out=$("$HERE/merge.sh" "$@" 2>&1); rc=$?; check "$l" "$e" "$s" "$out" "$rc"; }
noact() { # noact <label>: ningún comentario ni merge
  if [ -s "$T/log.act" ]; then fail=$((fail + 1)); echo "FAIL: $1 — actuó: $(cat "$T/log.act")"; else pass=$((pass + 1)); fi; }

# --- Plan ---
m "dry-run: plan con comentario y merge" 0 "Merge gated: $HEAD, check-gate GATED, label check ok (#18)" 42 --dry-run
m "dry-run: comando de merge squash con head fijo" 0 "gh pr merge 42 -R o/r --squash --match-head-commit $HEAD" 42 --dry-run
noact "dry-run no actúa"
m "dry-run: --issue explícito sin «Cierra»" 0 "(#7)" 42 --issue 7 --dry-run
FENCED='Resumen.

```
printf '"'"'Resumen.\n\nCloses #18\n'"'"'
```

Closes #162'
STUB_BODY="$FENCED" STUB_CLOSING=162 m "closingIssuesReferences: «Closes #18» en un bloque de código no cuenta (#137)" 0 "label check ok (#162)" 42 --dry-run
out=$(STUB_BODY="$FENCED" STUB_CLOSING=162 "$HERE/merge.sh" 42 --dry-run 2>&1)
[[ "$out" == *"#18"* ]] && { fail=$((fail + 1)); echo "FAIL: resolvió #18 dentro del bloque"; } || pass=$((pass + 1))
STUB_BODY="sin issue" m "sin issue cerrado" 1 "closes no issue" 42 --dry-run
STUB_BODY="sin issue" m "sin issue y sin --sin-contrato: se niega y sugiere la bandera" 1 "--sin-contrato" 42 --yes; noact "sin issue ni bandera"
STUB_BODY="sin issue" m "--sin-contrato: fusiona" 0 "Plan for o/r#42" 42 --sin-contrato --yes
grep -q -- "--body Merge gated: $HEAD · sin contrato" "$T/log.act" && grep -q "^MERGE" "$T/log.act" && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL: --sin-contrato comenta con la marca y fusiona: $(cat "$T/log.act")"; }
STUB_STATE=MERGED m "dry-run sobre un PR ya fusionado: se niega, no sale en verde" 1 "not OPEN" 42 --dry-run
STUB_STATE=CLOSED m "dry-run sobre un PR cerrado: se niega" 1 "not OPEN" 42 --dry-run

# --- Merge ---
m "merge: comenta antes de fusionar" 0 "Plan for o/r#42" 42 --yes
if [ "$(cut -d: -f1 "$T/log.act" | paste -sd, -)" = "COMMENT,MERGE" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: orden comentario→merge: $(cat "$T/log.act")"; fi
grep -q -- "--body Merge gated: $HEAD" "$T/log.act" && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL: comentario lleva el head leído de GitHub"; }
grep -q -- "--squash" "$T/log.act" && ! grep -q -- "--admin" "$T/log" && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL: squash sin --admin"; }
STUB_STATE=MERGED m "merge: PR ya fusionado se niega" 1 "not OPEN" 42 --yes; noact "PR fusionado no actúa"
m "merge: sin terminal ni --yes" 1 "no terminal" 42
STUB_FAIL=merge m "merge: falla genérica → imprime el comando exacto, exit 1" 1 "  gh pr merge 42 -R o/r --squash --match-head-commit $HEAD" 42 --yes
out=$(STUB_FAIL=merge "$HERE/merge.sh" 42 --yes 2>&1)
if [[ "$out" == *--admin* ]]; then fail=$((fail + 1)); echo "FAIL: falla genérica sugiere --admin"; else pass=$((pass + 1)); fi
STUB_FAIL=policy m "merge: política de la rama base → el comando impreso lleva --admin" 1 "  gh pr merge 42 -R o/r --squash --match-head-commit $HEAD --admin" 42 --yes
grep -q -- "--admin" "$T/log" && { fail=$((fail + 1)); echo "FAIL: merge.sh llamó a gh con --admin"; } || pass=$((pass + 1))
STUB_FAIL=comment m "merge: comentario falla → no fusiona" 1 "nothing merged" 42 --yes
grep -q MERGE "$T/log.act" && { fail=$((fail + 1)); echo "FAIL: fusionó sin comentario"; } || pass=$((pass + 1))

# --- Rechazos: ninguno comenta ni fusiona; todos nombran el atajo de la interfaz ---
STUB_COMMENTS="$T/gate-none" m "rechazo: sin compuerta (2)" 1 "check-gate exited 2" 42 --yes; noact "sin compuerta"
STUB_COMMENTS="$T/gate-none" m "rechazo: el mensaje nombra la interfaz como bypass" 1 "merge button in the GitHub UI, which is a bypass" 42 --yes
STUB_COMMENTS="$T/gate-stale" m "rechazo: compuerta sobre head anterior" 1 "re-run the gate" 42 --yes; noact "head anterior"
STUB_FAIL=api m "rechazo: GitHub ilegible en check-gate (1)" 1 "check-gate exited 1" 42 --yes; noact "gate ilegible"
STUB_LABEL="$T/label-none" m "rechazo: sin etiqueta" 1 "check-label #18 exited 2" 42 --yes; noact "sin etiqueta"
STUB_LABEL="$T/label-edited" m "rechazo: cuerpo editado tras la etiqueta" 1 "body edited" 42 --yes; noact "editado"
STUB_FAIL=graphql m "rechazo: GitHub ilegible en check-label (1)" 1 "check-label #18 exited 1" 42 --yes; noact "label ilegible"
STUB_FAIL=view m "rechazo: GitHub ilegible al leer el PR" 1 "could not read PR" 42 --yes; noact "pr ilegible"
STUB_HEAD_LATER=$OTHER m "rechazo: el head cambió durante las verificaciones" 1 "changed during the checks" 42 --yes; noact "head cambió"
for st in behind diverged; do
  STUB_COMPARE=$st m "rechazo: main avanzó ($st), con --dry-run" 1 "main moved since the gate: in the worker, \`git merge origin/main\`, push, new gate" 42 --dry-run; noact "main avanzó ($st)"
  STUB_COMPARE=$st m "rechazo: main avanzó ($st), con --yes" 1 "main moved since the gate" 42 --yes; noact "main avanzó ($st) con --yes"
done
STUB_COMPARE=identical m "al día: head idéntico a main, sin cambio" 0 "Plan for o/r#42" 42 --dry-run
STUB_FAIL=compare m "rechazo: comparación ilegible" 1 "could not compare" 42 --yes; noact "comparación ilegible"
grep -q "compare/main...$HEAD" "$T/log" && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL: compara base...head: $(cat "$T/log")"; }
echo b > b; m "rechazo: árbol sucio" 1 "check-tree exited 2" 42 --yes; noact "árbol sucio"; rm b
git checkout -q -b feat; m "rechazo: rama equivocada" 1 "expected «main»" 42 --yes; noact "rama equivocada"; git checkout -q main
# main local detrás de origin/main: el plan muestra el aviso y sigue (#53)
git clone -q "$T/origin.git" "$T/w2" 2>/dev/null; (cd "$T/w2" && git checkout -q main && git commit -q --allow-empty -m up && git push -q origin main)
m "main detrás de origin: no se niega" 0 "Plan for o/r#42" 42 --dry-run
m "main detrás de origin: el plan muestra el aviso" 0 "check-tree:  TREE OK (warning)" 42 --dry-run
git reset -q --hard origin/main
m "-R de otro repo desde este checkout: se niega (check-tree necesita el checkout)" 1 "no es el repo del issue o PR" -R o/otro 42 --dry-run; noact "checkout equivocado"
m "--issue sin valor no cuelga" 1 "usage" 42 --issue
m "sin número de PR" 1 "usage"

echo ""
if (( fail == 0 )); then echo "✅ merge: $pass passed"; else echo "❌ merge: $fail failed, $pass passed"; exit 1; fi
