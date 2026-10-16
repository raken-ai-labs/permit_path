#!/usr/bin/env bash
# raken-dev-standard v0.6.15: gate.test.sh
# sha256: 614716ebb00ea4eda67c6d9607978236f49ec23f5dbd33aa34d1fe20eb083065
# Sin --dry-run publica sin preguntar y termina con GATE CLEAN o GATE BLOCKED.
# Pruebas sin red: bash gate.test.sh. GitHub es un `gh` falso y la revisión, un
# `claude` falso. Verifica que gate.sh se niegue, sin llamar a post-gate.sh,
# cuando el head cambia, cuando corrieron menos o más revisores que la línea
# configurada, cuando la salida no trae el bloque final o no nombra los hallazgos
# más altos; que deje .reviews/PR-N-<sha>.md, bloquee gh pr comment, gh pr review
# y gh api, imprima un latido y corra con el perfil de GATE_CLAUDE_CONFIG_DIR;
# que con GATE BLOCKED imprima el bloque «Paste this to the worker:» y que borre la
# rama pr<N> que dejó la revisión, sin tocar una que ya existía (#78).
set -uo pipefail
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX  # un hook los exporta (#80)
HERE="$(cd "$(dirname "$0")" && pwd)"
export GATE_REVIEWERS_LINE="5 reviewers ran" # fijo: las pruebas no leen el .githooks/config del repo que las aloja
unset GATE_REVIEWER_CMD GATE_EXTRA_CHECK_CMD GATE_CLAUDE_CONFIG_DIR GATE_MODEL CLAUDE_CONFIG_DIR GATE_HEARTBEAT_SECS GATE_SETTLE_SECS
pass=0; fail=0
check() { # check <label> <exit-esperado> <subcadena> <salida> <exit>
  if [ "$2" = "$5" ] && [[ "$4" == *"$3"* ]]; then pass=$((pass + 1));
  else fail=$((fail + 1)); echo "FAIL: $1"; echo "  expected: exit $2, *$3*"; echo "  actual:   exit $5, $4"; fi
}
HEAD=736fa56314a38740ba025ecaf5094e57ed7f883f
OTHER=23d5b5fd6e60f1b45a5ac14ba22edf881ac850ac

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
git init -q "$T/w"; cd "$T/w" || exit 1
git -c commit.gpgsign=false commit -q --allow-empty -m inicio # una rama necesita un commit

cat > "$T/gh" <<'GH'
#!/usr/bin/env bash
# gh falso. STUB_HEADS: heads que devuelve cada lectura del PR, en orden; la
# última se repite. STUB_FAIL=view. Cada llamada queda en STUB_LOG.
echo "$*" >> "$STUB_LOG"
case "$1 $2" in
  "repo view") echo "o/r" ;;
  "pr view")
    [ "${STUB_FAIL:-}" = view ] && exit 1
    n=$(cat "$STUB_LOG.n" 2>/dev/null || echo 0); n=$((n + 1)); echo "$n" > "$STUB_LOG.n"
    set -- $STUB_HEADS; [ "$n" -gt $# ] && n=$#; eval "echo \${$n}" ;;
  "pr comment") echo "COMMENT: $*" >> "$STUB_LOG.act"; echo "https://github.com/o/r/pull/42#issuecomment-7" ;;
  *) exit 1 ;;
esac
GH
cat > "$T/claude" <<'CL'
#!/usr/bin/env bash
# claude falso: imprime STUB_OUT y sale con STUB_RC tras STUB_SLEEP segundos;
# guarda los argumentos y el CLAUDE_CONFIG_DIR con que corrió. STUB_BRANCH=1 crea
# la rama pr42 como el fetch de un revisor; STUB_BRANCH=checkout además la saca.
if [ "${1:-}" = auth ]; then # claude auth status: STUB_AUTH=false → sin sesión
  printf '%s' "${CLAUDE_CONFIG_DIR-<sin fijar>}" > "$STUB_LOG.authenv"
  echo "{\"loggedIn\": ${STUB_AUTH:-true}}"; [ "${STUB_AUTH:-true}" = true ] && exit 0 || exit 1
fi
printf '%s\0' "$@" > "$STUB_LOG.claude"
case "${STUB_BRANCH:-}" in
  1) git branch pr42 ;;
  checkout) git checkout -q -b pr42 ;;
  dash) git branch pr-42; git branch pr-42-review; git branch pr-43 ;;
esac
printf '%s' "${CLAUDE_CONFIG_DIR:-}" > "$STUB_LOG.env"
ls .reviews/PR-*.md > "$STUB_LOG.during" 2>/dev/null # registro visible durante la corrida (#142)
sleep "${STUB_SLEEP:-0}"
cat "$STUB_OUT"
[ -n "${STUB_HANG:-}" ] && exec sleep 600 # se queda bloqueado tras imprimir el bloque (#145)
exit "${STUB_RC:-0}"
CL
chmod +x "$T/gh" "$T/claude"

out5() { # out5 <revisores> <sha> <línea de hallazgos> → salida de la revisión
  printf 'Revisé el PR #42.\n\n| # | Hallazgo | Puntaje |\n|---|---|---|\n| A | algo | 50 |\n\n'
  printf 'Head SHA reviewed: %s\nReviewers: %s\nFindings: %s\n' "$2" "$1" "$3"; }
TOP2="0 findings ≥ 80 (highest: a.sh:3 sin llaves, 75; b.sh:9 sin prueba, 50)"
out5 5 "$HEAD" "$TOP2" > "$T/ok"
out5 3 "$HEAD" "$TOP2" > "$T/three"
out5 7 "$HEAD" "$TOP2" > "$T/seven"
out5 5 "$OTHER" "$TOP2" > "$T/othersha"
out5 5 "$HEAD" "0 findings ≥ 80 (highest 75)" > "$T/unnamed"
out5 5 "$HEAD" "0 findings ≥ 80" > "$T/bare"
out5 5 "$HEAD" "0 findings ≥ 80 (highest: none)" > "$T/none"
out5 5 "$HEAD" "No issues found." > "$T/noscore"
printf '`Head SHA reviewed: %s`\n**Reviewers: 5**\n**Findings: 1 finding ≥ 80: a.sh:3 rompe, 85**\n' "$HEAD" > "$T/markdown"
printf 'Revisé el PR. Sin bloque final.\n' > "$T/noblock"
printf 'Failed to authenticate\n' > "$T/auth"

export PATH="$T:$PATH" STUB_HEADS="$HEAD" STUB_LOG="$T/log" STUB_OUT="$T/ok"
reset() { : > "$T/log"; : > "$T/log.act"; rm -f "$T/log.n" "$T/log.during" "$T/log.claude" "$T/log.env" "$T/log.authenv"; rm -rf .reviews; }
g() { # g <label> <exit> <subcadena> <args…>
  local l="$1" e="$2" s="$3" out rc; shift 3; reset
  out=$("$HERE/gate.sh" "$@" 2>&1 </dev/null); rc=$?; check "$l" "$e" "$s" "$out" "$rc"; LAST="$out"; }
nopost() { # nopost <label>: post-gate no corrió y nada se publicó
  if [ -s "$T/log.act" ] || [[ "$LAST" == *"Gate comment for"* ]]; then
    fail=$((fail + 1)); echo "FAIL: $1 — llamó a post-gate"; else pass=$((pass + 1)); fi; }
ok_() { if eval "$2"; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: $1"; fi; }

# --- Camino feliz (post-gate en --dry-run: sin terminal no hay confirmación) ---
g "5 revisores: llama a post-gate con los dos hallazgos más altos nombrados" 0 "Head SHA reviewed: $HEAD · 5 reviewers ran · $TOP2" 42 --dry-run
ok_ "deja .reviews/PR-42-<sha>.md con la salida" "grep -q '| A | algo | 50 |' .reviews/PR-42-$HEAD.md && grep -q 'Head SHA reviewed: $HEAD' .reviews/PR-42-$HEAD.md"
ok_ ".reviews/ se ignora a sí misma" "[ \"\$(cat .reviews/.gitignore)\" = '*' ]"
ok_ "post-gate recibe el head revisado" "grep -q 'Gate comment for o/r#42 (head 736fa563)' <<< \"\$LAST\""
ok_ "imprime la salida de la revisión" "[[ \"\$LAST\" == *'| A | algo | 50 |'* ]]"
ok_ "el prompt invoca la skill con el PR" "tr '\0' '\n' < '$T/log.claude' | grep -qx '/code-review:code-review 42'"
ok_ "el prompt desactiva la exención por tamaño" "tr '\0' '\n' < '$T/log.claude' | grep -q 'size exemption does not apply'"
ok_ "el prompt pide plain Agent calls y no publicar" "tr '\0' '\n' < '$T/log.claude' | grep -q 'plain Agent calls' && tr '\0' '\n' < '$T/log.claude' | grep -q 'Post nothing'"
ok_ "sin GATE_MODEL: claude no lleva --model" "! tr '\0' '\n' < '$T/log.claude' | grep -qx -- --model"
ok_ "claude lleva --effort low, --strict-mcp-config y --no-chrome" "tr '\0' '\n' < '$T/log.claude' | grep -qx -- --effort && tr '\0' '\n' < '$T/log.claude' | grep -qx low && tr '\0' '\n' < '$T/log.claude' | grep -qx -- --strict-mcp-config && tr '\0' '\n' < '$T/log.claude' | grep -qx -- --no-chrome"
ok_ "claude concede la lectura con --allowedTools" "tr '\0' '\n' < '$T/log.claude' | grep -qx -- --allowedTools && for t in 'Bash(gh pr view:*)' 'Bash(gh pr diff:*)' 'Bash(gh pr checkout:*)' 'Bash(git:*)'; do tr '\0' '\n' < '$T/log.claude' | grep -qxF \"\$t\" || exit 1; done"
ok_ "el prompt pide un solo puntuador Haiku" "tr '\0' '\n' < '$T/log.claude' | grep -q 'single Haiku agent that scores all the findings in one call'"
ok_ "claude sin gh pr comment" "tr '\0' '\n' < '$T/log.claude' | grep -qxF 'Bash(gh pr comment:*)'"
ok_ "claude sin gh pr review" "tr '\0' '\n' < '$T/log.claude' | grep -qxF 'Bash(gh pr review:*)'"
ok_ "claude sin gh api" "tr '\0' '\n' < '$T/log.claude' | grep -qxF 'Bash(gh api:*)'"
ok_ "el prompt pide nombrar los dos hallazgos más altos" "tr '\0' '\n' < '$T/log.claude' | grep -q 'naming the two highest-scored findings'"
ok_ "el prompt trae la frase del head anterior" "tr '\0' '\n' < '$T/log.claude' | grep -q 'does not make the current head ineligible'"
ok_ "sin GATE_CLAUDE_CONFIG_DIR no fija CLAUDE_CONFIG_DIR" "[ ! -s '$T/log.env' ]"
ok_ "la línea «Revisando…» nombra el perfil por omisión" "[[ \"\$LAST\" == *'profile ~/.claude (default)'* ]]"
ok_ "auth status corre sin CLAUDE_CONFIG_DIR con la clave vacía" "[ \"\$(cat '$T/log.authenv')\" = '<sin fijar>' ]"
GATE_MODEL=sonnet g "GATE_MODEL en el entorno: --model sonnet" 0 "--model sonnet" 42 --dry-run
ok_ "GATE_MODEL: claude recibe --model sonnet" "tr '\\0' '\\n' < '$T/log.claude' | grep -x -A1 -- --model | grep -qx sonnet"
mkdir -p .githooks; printf "GATE_MODEL='haiku'\n" > .githooks/config
g "GATE_MODEL desde .githooks/config" 0 "--model haiku" 42 --dry-run
ok_ "config: claude recibe --model haiku" "tr '\\0' '\\n' < '$T/log.claude' | grep -x -A1 -- --model | grep -qx haiku"
GATE_MODEL=sonnet g "GATE_MODEL del entorno gana a .githooks/config" 0 "--model sonnet" 42 --dry-run
rm -rf .githooks
STUB_OUT="$T/none" g "sin ningún hallazgo: «highest: none» se acepta" 0 "· 0 findings ≥ 80 (highest: none)" 42 --dry-run

# --- Latido: claude tarda y gate.sh no se queda callado ---
STUB_HANG=1 GATE_SETTLE_SECS=1 g "claude imprime las tres líneas y se bloquea: GATE CLEAN sin esperarlo" 0 "GATE CLEAN" 42 --dry-run
ok_ "bloqueado: el registro .reviews/ queda sellado" "[ -f .reviews/PR-42-$HEAD.md ] && [ ! -f .reviews/PR-42-$HEAD.md.partial ]"
ok_ "bloqueado: no queda el claude falso vivo" "! pgrep -f 'sleep 600' >/dev/null"
STUB_SLEEP=3 GATE_HEARTBEAT_SECS=1 g "latido mientras claude corre" 0 "s elapsed" 42 --dry-run

# --- Perfil de Claude: GATE_CLAUDE_CONFIG_DIR llega como CLAUDE_CONFIG_DIR ---
mkdir -p .githooks; printf "GATE_CLAUDE_CONFIG_DIR='~/.claude-raken'\n" > .githooks/config
g "perfil desde .githooks/config" 0 "profile ~/.claude-raken" 42 --dry-run
ok_ "perfil puesto: la línea nombra ese perfil, no el de omisión" "[[ \"\$LAST\" == *', profile ~/.claude-raken;'* && \"\$LAST\" != *'(default)'* ]]"
ok_ "perfil puesto: auth status corre bajo el mismo CLAUDE_CONFIG_DIR" "[ \"\$(cat '$T/log.authenv')\" = \"\$HOME/.claude-raken\" ]"
ok_ "perfil desde .githooks/config: claude corre con CLAUDE_CONFIG_DIR, ~ expandido" "[ \"\$(cat '$T/log.env')\" = \"\$HOME/.claude-raken\" ]"
GATE_CLAUDE_CONFIG_DIR=/otro/perfil g "perfil del entorno gana a .githooks/config" 0 "profile /otro/perfil" 42 --dry-run
ok_ "perfil del entorno: claude lo recibe" "[ \"\$(cat '$T/log.env')\" = /otro/perfil ]"
rm -rf .githooks

# --- Sin sesión: se niega antes de revisar y nombra el login del perfil (#93) ---
STUB_AUTH=false g "sin sesión (perfil por omisión): se niega" 1 "REFUSED: profile ~/.claude (default) has no claude session" 42 --dry-run; nopost "sin sesión"
ok_ "sin sesión: el login es el comando pelado" "[[ \"\$LAST\" == *'Log in with: claude auth login.'* ]]"
ok_ "sin sesión: auth status corrió sin CLAUDE_CONFIG_DIR" "[ \"\$(cat '$T/log.authenv')\" = '<sin fijar>' ]"
ok_ "sin sesión: no corrió claude -p" "[ ! -f '$T/log.claude' ]"
GATE_CLAUDE_CONFIG_DIR='~/.claude-raken' STUB_AUTH=false g "sin sesión (perfil puesto): login con el perfil" 1 "Log in with: CLAUDE_CONFIG_DIR=$HOME/.claude-raken claude auth login" 42 --dry-run
ok_ "sin sesión (perfil puesto): auth status corrió bajo ese perfil, sin caer en otro" "[ \"\$(cat '$T/log.authenv')\" = \"\$HOME/.claude-raken\" ] && [ ! -f '$T/log.claude' ]"
ok_ "sin sesión: nombra GATE_CLAUDE_CONFIG_DIR como remedio" "[[ \"\$LAST\" == *'GATE_CLAUDE_CONFIG_DIR=<dir>'* ]]"

# --- claude -p sale ≠ 0: el REFUSED nombra el perfil y el remedio (#93) ---
STUB_OUT="$T/auth" STUB_RC=1 g "claude -p falla: REFUSED con perfil por omisión y remedio" 1 "with profile ~/.claude (default)" 42 --dry-run
ok_ "claude -p falla: nombra GATE_CLAUDE_CONFIG_DIR" "[[ \"\$LAST\" == *'GATE_CLAUDE_CONFIG_DIR=<dir>'* ]]"
GATE_CLAUDE_CONFIG_DIR=/otro/perfil STUB_OUT="$T/auth" STUB_RC=1 g "claude -p falla con perfil puesto: lo nombra" 1 "with profile /otro/perfil" 42 --dry-run

# --- El checkout vuelve a la rama donde estaba (#93) ---
orig_branch=$(git symbolic-ref --short HEAD)
STUB_BRANCH=checkout g "la revisión cambia de rama: gate.sh vuelve a la original" 0 "Gate comment for" 42 --dry-run
ok_ "checkout restaurado a $orig_branch" "[ \"\$(git symbolic-ref --short HEAD)\" = '$orig_branch' ]"
ok_ "la rama pr42 que creó la revisión ya no existe" "! git rev-parse --verify --quiet refs/heads/pr42 >/dev/null"
STUB_BRANCH=checkout STUB_OUT="$T/three" g "REFUSED tras cambiar de rama: también restaura" 1 "3 reviewers ran, 5 expected" 42 --dry-run
ok_ "REFUSED: checkout restaurado" "[ \"\$(git symbolic-ref --short HEAD)\" = '$orig_branch' ]"

# --- Puntajes provisionales o re-verificación fallida: no publica (#125) ---
{ printf 'Five of the eight scorers could not read the PR code, so those scores are provisional.\n'; cat "$T/ok"; } > "$T/prov"
{ printf 'The eligibility re-check failed because the final gh pr view call needed approval.\n'; cat "$T/ok"; } > "$T/recheck"
STUB_OUT="$T/prov" g "puntajes provisionales: se niega" 1 "provisional scores" 42; nopost "provisionales"
ok_ "provisionales: bloque «Paste this to the worker:» vacío" "[[ \"\$LAST\" == *\$'Paste this to the worker:\\n-----\\n-----'* ]]"
ok_ "provisionales: la salida queda guardada, cerrada con REFUSED" "[[ \"\$(tail -n1 .reviews/PR-42-$HEAD.md)\" == 'REFUSED: '*'provisional'* ]]"
STUB_OUT="$T/recheck" g "re-verificación fallida: se niega" 1 "failed eligibility re-check" 42 --dry-run; nopost "re-verificación"
g "salida normal: sin falso positivo" 0 "Gate comment for" 42 --dry-run

# --- Revisor configurado: gate.sh solo corre /code-review:code-review ---
GATE_REVIEWER_CMD=/code-review:code-review g "revisor configurado = code-review: corre" 0 "Gate comment for" 42 --dry-run
GATE_REVIEWER_CMD=/otro-revisor g "revisor configurado distinto: se niega" 1 "the configured reviewer is «/otro-revisor»" 42 --dry-run; nopost "otro revisor"
ok_ "revisor distinto: no corrió claude" "[ ! -f '$T/log.claude' ]"
GATE_REVIEWER_CMD=/otro-revisor g "revisor distinto: --print-prompt también se niega" 1 "only runs /code-review:code-review" 42 --print-prompt
STUB_OUT="$T/markdown" g "bloque con markdown alrededor: se acepta" 0 "· 1 finding ≥ 80: a.sh:3 rompe, 85" 42 --dry-run
CODE='1 finding ≥ 80: `*.sh` sin **llaves**, 85'
out5 5 "$HEAD" "$CODE" > "$T/code"
STUB_OUT="$T/code" g "hallazgos con código y asteriscos: llegan intactos a post-gate" 0 "· ${CODE}" 42 --dry-run

# --- Sin --dry-run: publica sin preguntar y termina con el veredicto (#71) ---
g "compuerta limpia: publica sin preguntar" 0 "GATE CLEAN → run scripts/ship.sh 42" 42
ok_ "compuerta limpia: el comentario se publicó" "grep -q '^COMMENT: pr comment 42 -R o/r --body' '$T/log.act'"
ok_ "compuerta limpia: no pregunta" "[[ \"\$LAST\" != *'[y/N]'* ]]"
# --- El registro .reviews/ dice cómo terminó la corrida (#142) ---
REC=".reviews/PR-42-$HEAD.md"
ok_ "registro: no existe mientras corre la revisión" "[ ! -s '$T/log.during' ]"
ok_ "registro limpia: última línea = veredicto y URL del comentario" "[ \"\$(tail -n1 $REC)\" = 'GATE CLEAN → run scripts/ship.sh 42 · https://github.com/o/r/pull/42#issuecomment-7' ]"
ok_ "registro: no queda .partial" "[ ! -e $REC.partial ]"
out5 5 "$HEAD" "2 findings ≥ 80: a.sh:3 rompe, 90; b.sh:9 sin prueba, 85" > "$T/dirty"
STUB_OUT="$T/dirty" g "compuerta sucia: publica igual" 0 "GATE BLOCKED → 2 findings ≥ 80, back to the worker" 42
ok_ "compuerta sucia: el comentario se publicó con los hallazgos" "grep -q 'a.sh:3 rompe, 90' '$T/log.act'"
ok_ "registro sucia: última línea = GATE BLOCKED y URL" "[[ \"\$(tail -n1 $REC)\" == 'GATE BLOCKED → 2 findings ≥ 80'*'#issuecomment-7' ]]"
g "dry-run: veredicto sin publicar" 0 "GATE CLEAN → run scripts/ship.sh 42 (dry-run: not posted)" 42 --dry-run
ok_ "dry-run: nada publicado" "[ ! -s '$T/log.act' ]"
ok_ "registro dry-run: veredicto sin URL" "[ \"\$(tail -n1 .reviews/PR-42-$HEAD.md)\" = 'GATE CLEAN → run scripts/ship.sh 42 (dry-run: not posted)' ]"
STUB_HEADS="$HEAD $HEAD $OTHER" g "post-gate se niega: sin veredicto" 1 "no verdict" 42
ok_ "post-gate se niega: no imprime GATE" "[[ \"\$LAST\" != *'GATE CLEAN'* ]]"
ok_ "registro post-gate se niega: última línea REFUSED" "[[ \"\$(tail -n1 $REC)\" == 'REFUSED: '* ]]"

# --- GATE BLOCKED: el bloque para el worker va directo de la terminal (#78) ---
STUB_OUT="$T/dirty" g "sucia: imprime «Paste this to the worker:»" 0 "Paste this to the worker:" 42
ok_ "sucia: una línea por hallazgo, con ruta:línea, descripción y puntaje" "grep -qxF -- '- a.sh:3 rompe, 90' <<< \"\$LAST\" && grep -qxF -- '- b.sh:9 sin prueba, 85' <<< \"\$LAST\""
ok_ "sucia: cierra con el comando de re-compuerta con repo y número" "grep -qF 'Fix only these findings, push, and print \`scripts/gate.sh -R o/r 42\`' <<< \"\$LAST\""
ok_ "sucia: el veredicto sigue siendo la última línea" "[[ \"\$(tail -n1 <<< \"\$LAST\")\" == 'GATE BLOCKED → 2 findings ≥ 80'* ]]"
g "limpia: sin bloque para el worker" 0 "GATE CLEAN" 42
ok_ "limpia: no imprime «Paste this to the worker:»" "[[ \"\$LAST\" != *'Paste this to the worker'* ]]"
STUB_OUT="$T/dirty" g "sucia con --dry-run: también imprime el bloque" 0 "Paste this to the worker:" 42 --dry-run
ok_ "sucia con --dry-run: el veredicto es la última línea" "[[ \"\$(tail -n1 <<< \"\$LAST\")\" == *'(dry-run: not posted)' ]]"
COMMA="0 findings ≥ 80 (highest: a.sh:3 sin llaves, ni prueba, 75; b.sh:9 sin prueba, 50)"
out5 5 "$HEAD" "$COMMA" > "$T/comma"
STUB_OUT="$T/comma" g "coma en el nombre del hallazgo más alto: se acepta" 0 "· ${COMMA}" 42 --dry-run

# --- Rama pr<N> que deja la revisión: se borra si la creó la corrida (#78) ---
pr42() { git rev-parse --verify --quiet refs/heads/pr42 >/dev/null; }
STUB_BRANCH=1 g "pr42 creada por la revisión: se borra" 0 "Deleted local branch pr42" 42 --dry-run
ok_ "pr42 creada por la revisión: no queda" "! pr42"
git branch pr42
STUB_BRANCH=1 g "pr42 previa: se conserva" 0 "Gate comment for" 42 --dry-run
ok_ "pr42 previa: sigue ahí" "pr42"
ok_ "pr42 previa: no avisa de un borrado" "[[ \"\$LAST\" != *'Deleted local branch'* ]]"
git branch -D -q pr42
STUB_BRANCH=1 STUB_OUT="$T/three" g "REFUSED: también borra la pr42 de la corrida" 1 "3 reviewers ran, 5 expected" 42 --dry-run
ok_ "REFUSED: no queda pr42" "! pr42"

# --- Ramas pr-<N> y pr-<N>-review: solo las de este PR (#86) ---
STUB_BRANCH=dash g "ramas con guion de este PR: se borran" 0 "Deleted local branch pr-42-review" 42 --dry-run
ok_ "pr-42 y pr-42-review no quedan" "! git rev-parse --verify --quiet refs/heads/pr-42 >/dev/null && ! git rev-parse --verify --quiet refs/heads/pr-42-review >/dev/null"
ok_ "pr-43 de otro PR se conserva" "git rev-parse --verify --quiet refs/heads/pr-43 >/dev/null"
git branch pr-42
STUB_BRANCH=dash g "pr-42 previa: se conserva" 0 "Gate comment for" 42 --dry-run
ok_ "pr-42 previa: sigue ahí" "git rev-parse --verify --quiet refs/heads/pr-42 >/dev/null"
git branch -D -q pr-42 pr-43

# --- Rechazos: ninguno llama a post-gate ---
STUB_HEADS="$HEAD $OTHER" g "head cambiado entre la lectura y post-gate: se niega" 1 "changed during the review" 42 --dry-run; nopost "head cambiado"
ok_ "head cambiado: la salida queda guardada, cerrada con REFUSED" "[[ \"\$(tail -n1 .reviews/PR-42-$HEAD.md)\" == 'REFUSED: PR head changed'* ]]"
STUB_HEADS="$HEAD $HEAD $OTHER" g "head cambiado justo antes de publicar: post-gate se niega" 1 "changed since the review" 42 --dry-run
grep -q "^COMMENT" "$T/log.act" && { fail=$((fail + 1)); echo "FAIL: publicó con el head cambiado"; } || pass=$((pass + 1))
STUB_OUT="$T/three" g "3 revisores (exención tomada): se niega" 1 "3 reviewers ran, 5 expected" 42 --dry-run; nopost "3 revisores"
STUB_OUT="$T/seven" g "7 revisores con la línea de 5: se niega, el comentario contaría de menos" 1 "would undercount" 42 --dry-run; nopost "7 revisores"
GATE_REVIEWERS_LINE="3 reviewers ran" g "línea de 3 y corrieron 5: se niega" 1 "5 reviewers ran and the configured line says «3 reviewers ran»" 42 --dry-run; nopost "línea de 3"
STUB_OUT="$T/unnamed" g "0 hallazgos sin nombrar el más alto: se niega" 1 "must name the two highest" 42 --dry-run; nopost "sin nombre"
STUB_OUT="$T/bare" g "0 hallazgos sin «highest»: se niega" 1 "must name the two highest" 42 --dry-run; nopost "sin highest"
STUB_OUT="$T/noblock" g "sin línea Reviewers: se niega" 1 "has no «Reviewers: N»" 42 --dry-run; nopost "sin bloque"
STUB_OUT="$T/othersha" g "SHA revisado distinto del head: se niega" 1 "reviewed $OTHER" 42 --dry-run; nopost "otro SHA"
STUB_OUT="$T/noscore" g "hallazgos sin puntaje: se niega" 1 "Findings:" 42 --dry-run; nopost "sin puntaje"
STUB_OUT="$T/auth" STUB_RC=1 g "claude falla: se niega y ofrece --print-prompt" 1 "--print-prompt" 42 --dry-run; nopost "claude falla"
STUB_FAIL=view g "GitHub ilegible: se niega antes de revisar" 1 "could not read PR" 42 --dry-run
ok_ "GitHub ilegible: no corrió claude" "[ ! -f '$T/log.claude' ]"
g "repo distinto: se niega" 1 "no es el repo del issue o PR" -R o/otro 42 --dry-run
g "sin número de PR" 1 "usage" --dry-run
g "-R sin valor no cuelga" 1 "usage" 42 -R

# --- Verificación previa: GATE_EXTRA_CHECK_CMD corre antes de claude -p (#95) ---
cat > "$T/extra-ok" <<'X'
#!/usr/bin/env bash
printf '%s\n' "$*" > "$STUB_LOG.extra"; exit 0
X
cat > "$T/extra-bad" <<'X'
#!/usr/bin/env bash
printf '%s\n' "$*" > "$STUB_LOG.extra"; echo "falta el encabezado QA"; echo "el head no coincide" >&2; exit 1
X
cat > "$T/extra-cant" <<'X'
#!/usr/bin/env bash
printf '%s\n' "$*" > "$STUB_LOG.extra"; echo "no pude descargar el head"; exit 2
X
chmod +x "$T/extra-ok" "$T/extra-bad" "$T/extra-cant"
g "clave vacía: sin cambio, corre claude" 0 "Gate comment for" 42 --dry-run
ok_ "clave vacía: no hay verificación previa" "[ ! -f '$T/log.extra' ] && [ -f '$T/log.claude' ]"
GATE_EXTRA_CHECK_CMD="$T/extra-ok" g "verificación sale 0: sigue a claude -p" 0 "Gate comment for" 42 --dry-run
ok_ "sale 0: recibe -R, el PR y el head" "[ \"\$(cat '$T/log.extra')\" = '-R o/r 42 $HEAD' ]"
ok_ "sale 0: claude corrió" "[ -f '$T/log.claude' ]"
GATE_EXTRA_CHECK_CMD="$T/extra-bad" g "verificación sale 1: sale con 2" 2 "Paste this to the worker:" 42
ok_ "sale 1: cada línea de la salida va en el bloque" "grep -qx 'falta el encabezado QA' <<< \"\$LAST\" && grep -qx 'el head no coincide' <<< \"\$LAST\""
nopost "verificación sale 1"
ok_ "sale 1: no corrió claude ni dejó .reviews" "[ ! -f '$T/log.claude' ] && [ ! -d .reviews ]"
ok_ "sale 1: recibió el head leído de GitHub" "[ \"\$(cat '$T/log.extra')\" = '-R o/r 42 $HEAD' ]"
GATE_EXTRA_CHECK_CMD="$T/extra-cant" g "verificación sale 2: REFUSED, sale con 2" 2 "REFUSED: the pre-check" 42
ok_ "sale 2: imprime la salida del script" "grep -qx 'no pude descargar el head' <<< \"\$LAST\""
ok_ "sale 2: sin bloque «Paste this to the worker:»" "[[ \"\$LAST\" != *'Paste this to the worker:'* ]]"
nopost "verificación sale 2"
ok_ "sale 2: no corrió claude ni dejó .reviews" "[ ! -f '$T/log.claude' ] && [ ! -d .reviews ]"
mkdir -p .githooks; printf "GATE_EXTRA_CHECK_CMD='%s'\n" "$T/extra-bad" > .githooks/config
g "verificación desde .githooks/config" 2 "Paste this to the worker:" 42 --dry-run
rm -rf .githooks

# --- Respaldo: --print-prompt no corre nada ---
g "--print-prompt imprime los dos bloques" 0 "type this" 42 --print-prompt
ok_ "--print-prompt: bloque «pega esto» con la exención" "[[ \"\$LAST\" == *'paste this'* && \"\$LAST\" == *'size exemption does not apply'* ]]"
ok_ "--print-prompt: no corrió claude" "[ ! -f '$T/log.claude' ]"

echo ""
if (( fail == 0 )); then echo "✅ gate: $pass passed"; else echo "❌ gate: $fail failed, $pass passed"; exit 1; fi
