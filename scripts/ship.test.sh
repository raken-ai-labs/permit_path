#!/usr/bin/env bash
# raken-dev-standard v0.6.15: ship.test.sh
# sha256: 7ae87a18ab4ed9c04ddbc220890d07265fb53d8463456b092578123a632b9c09
# Pruebas sin red: bash ship.test.sh. GitHub es un `gh` falso; origin, un repo
# bare local; merge.sh es el real. Verifica el sí único, que --admin solo se
# corra cuando la política de la rama base rechaza y que un rechazo de las
# verificaciones no llegue a preguntar, comentar ni fusionar.
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

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
git init -q --bare -b main "$T/origin.git"
git clone -q "$T/origin.git" "$T/w" 2>/dev/null; cd "$T/w" || exit 1
git checkout -q -b main 2>/dev/null; echo a > a; git add a; git commit -qm a; git push -q -u origin main
git remote set-head origin main >/dev/null 2>&1

cat > "$T/gh" <<'GH'
#!/usr/bin/env bash
# gh falso. STUB_FAIL=merge|policy|admin, STUB_COMMENTS, STUB_LABEL, STUB_HEAD.
echo "$*" >> "$STUB_LOG"
case "$1 $2" in
  "repo view") echo "o/r" ;;
  "pr view")
    case "$*" in
      *baseRefName*) echo main ;;
      *headRefOid,commits*) echo "$STUB_HEAD 2026-10-08T21:48:55Z" ;;
      *headRefOid,state*) echo "$STUB_HEAD ${STUB_STATE:-OPEN}" ;;
      *"--json body"*) printf 'Resumen.\n\nCloses #18\n' ;;
      *) echo "$STUB_HEAD" ;;
    esac ;;
  "pr comment") echo "COMMENT: $*" >> "$STUB_LOG.act" ;;
  "pr merge")
    case "$*" in
      *--admin*) [ "${STUB_FAIL:-}" = admin ] && exit 1; echo "ADMIN: $*" >> "$STUB_LOG.act" ;;
      *) [ "${STUB_FAIL:-}" = merge ] && { echo "X merge conflict" >&2; exit 1; }
        if [ "${STUB_FAIL:-}" = policy ] || [ "${STUB_FAIL:-}" = admin ]; then
          echo "X Pull request o/r#42 is not mergeable: the base branch policy prohibits the merge." >&2; exit 1
        fi
        echo "MERGE: $*" >> "$STUB_LOG.act" ;;
    esac ;;
  "api graphql") cat "$STUB_LABEL" ;;
  "api repos/o/r/compare/"*) echo ahead ;;
  api*) cat "$STUB_COMMENTS" ;;
  *) exit 1 ;;
esac
GH
chmod +x "$T/gh"
printf '%s\n%s\n\036\n' 2026-10-08T21:53:51Z "$(gate_format_body "$HEAD" "0 findings ≥ 80")" > "$T/gate-ok"
: > "$T/gate-none"
printf '\nlabeled\t2026-10-08T20:00:00Z\tready-for-agent\n' > "$T/label-ok"

export PATH="$T:$PATH" STUB_HEAD=$HEAD STUB_LOG="$T/log" STUB_COMMENTS="$T/gate-ok" STUB_LABEL="$T/label-ok"
reset() { : > "$T/log"; : > "$T/log.act"; }
s() { # s <label> <exit> <subcadena> <args…>
  local l="$1" e="$2" st="$3" out rc; shift 3; reset
  out=$("$HERE/ship.sh" "$@" 2>&1 </dev/null); rc=$?; check "$l" "$e" "$st" "$out" "$rc"; LAST="$out"; }
acts() { cut -d: -f1 "$T/log.act" | paste -sd, -; }
want_acts() { # want_acts <label> <acciones esperadas, p. ej. COMMENT,MERGE>
  if [ "$(acts)" = "$2" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: $1 — acciones «$(acts)», se esperaba «$2»"; fi; }

# --- Plan y sí único ---
s "dry-run: plan de merge.sh y el paso --admin" 0 "if the base branch policy" 42 --dry-run; want_acts "dry-run no actúa" ""
s "sin terminal ni --yes: se niega" 1 "no terminal" 42; want_acts "sin sí no actúa" ""
[[ "$LAST" == *"merge, with the --admin bypass if the base branch policy rejects it? [y/N]"* ]] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL: la pregunta y/N nombra el bypass --admin"; echo "  actual: $LAST"; }
STUB_STATE=MERGED s "dry-run sobre un PR ya fusionado: no sale en verde" 1 "merge.sh --dry-run refused" 42 --dry-run; want_acts "PR fusionado no actúa" ""

# --- Merge ---
s "--yes: comenta y fusiona" 0 "Plan for o/r#42" 42 --yes; want_acts "orden comentario→merge, sin --admin" "COMMENT,MERGE"
STUB_FAIL=policy s "política de la rama base: corre la línea --admin" 0 "running: gh pr merge 42 -R o/r --squash --match-head-commit $HEAD --admin" 42 --yes
want_acts "política: comentario y merge con --admin" "COMMENT,ADMIN"
STUB_FAIL=merge s "falla genérica: no corre --admin" 1 "it was not the base branch policy" 42 --yes
want_acts "falla genérica: solo el comentario" "COMMENT"
grep -q -- "--admin" "$T/log" && { fail=$((fail + 1)); echo "FAIL: falla genérica llamó a gh con --admin"; } || pass=$((pass + 1))
STUB_FAIL=admin s "--admin también falla: sale con 1" 1 "could not merge with --admin" 42 --yes

# --- main local tras el merge (#86): el stub no fusiona, así que origin avanza a mano ---
advance() { git clone -q "$T/origin.git" "$T/o2" 2>/dev/null; (cd "$T/o2" && echo m >> a && git commit -qam merge && git push -q origin main); rm -rf "$T/o2"; }
advance; before=$(git rev-parse main)
s "--yes con main limpio: adelanta el main local" 0 "ship: merged PR 42" 42 --yes
[ "$(git rev-parse main)" = "$(git rev-parse origin/main)" ] && [ "$(git rev-parse main)" != "$before" ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL: main local no quedó en el merge commit"; }
advance
# check-tree rechaza antes un checkout fuera de main o sucio; ship_synced cubre el cambio posterior al merge
source "$HERE/ship.sh"; git fetch -q origin
git checkout -q -b otra; out=$(ship_synced 42 2>&1); check "fuera de main: avisa el comando" 0 "run: git pull --ff-only origin main" "$out" 0
[ "$(git rev-parse main)" != "$(git rev-parse origin/main)" ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL: movió main fuera de main"; }
git fetch -q origin; git checkout -q main; echo b > b2; out=$(ship_synced 42 2>&1); check "main sucio: avisa el comando" 0 "run: git pull --ff-only origin main" "$out" 0; rm b2
[ "$(git rev-parse main)" != "$(git rev-parse origin/main)" ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL: movió main sucio"; }
STUB_FAIL=merge s "merge fallido: no dice merged" 1 "it was not the base branch policy" 42 --yes
[[ "$LAST" == *"ship: merged"* ]] && { fail=$((fail + 1)); echo "FAIL: dijo merged tras un fallo"; } || pass=$((pass + 1))
git merge -q --ff-only origin/main 2>/dev/null

# --- Rechazos de las verificaciones: no pregunta, no comenta, no fusiona ---
STUB_COMMENTS="$T/gate-none" s "sin compuerta: se niega en el dry-run" 1 "merge.sh --dry-run refused" 42 --yes; want_acts "sin compuerta no actúa" ""
[[ "$LAST" == *"Post the comment"* ]] && { fail=$((fail + 1)); echo "FAIL: preguntó tras un rechazo"; } || pass=$((pass + 1))
echo b > b; s "árbol sucio: se niega" 1 "check-tree exited 2" 42 --yes; want_acts "árbol sucio no actúa" ""; rm b
s "repo distinto: se niega" 1 "no es el repo del issue o PR" -R o/otro 42 --yes
s "--issue sin valor no cuelga" 1 "usage" 42 --issue
s "sin número de PR" 1 "usage"

echo ""
if (( fail == 0 )); then echo "✅ ship: $pass passed"; else echo "❌ ship: $fail failed, $pass passed"; exit 1; fi
