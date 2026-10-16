#!/usr/bin/env bash
# raken-dev-standard v0.6.15: gate.sh
# sha256: 120bb85d98f18f7118e68714854b33ac4cf0fbb7be972a48a7198540621a0dc1
#
# La compuerta sin ventana: corre el revisor con `claude -p` y publica los
# hallazgos con post-gate.sh, sin preguntar: correr gate.sh es el sí (#59, #71).
# Una compuerta limpia y una sucia se publican igual; el PR necesita el registro.
#
#   gate.sh [-R owner/repo] <PR#> [--dry-run]
#   gate.sh <PR#> --print-prompt
#
# Requisitos, además de bash, git y gh: el CLI `claude` y el plugin code-review.
# 1. Se niega si el revisor configurado (GATE_REVIEWER_CMD) no es
#    /code-review:code-review: es el único que gate.sh sabe correr (#71).
# 2. Lee el head del PR desde GitHub.
# 2b. Con GATE_EXTRA_CHECK_CMD (entorno o .githooks/config; vacía por omisión), la
#    corre sobre ese head como precondición, antes de claude -p: recibe
#    `-R <owner/repo> <PR#> <head>` y lee GitHub con `gh`, no el árbol local. Si
#    sale distinto de 0, imprime cada línea de su salida bajo «Pega esto al
#    worker:», no corre revisores, no publica nada y sale con 2 (#95). Si sale con 2
#    («no se pudo verificar», no un defecto del worker) imprime REFUSED con su
#    salida, sin el bloque «Paste this to the worker:», y también sale con 2 (#135). No entra
#    en la línea Findings: ni cambia el formato del comentario de compuerta.
# 3. `claude -p --effort low --strict-mcp-config --no-chrome` con
#    /code-review:code-review <PR#> y el prompt de gate-format.sh (exención por
#    tamaño desactivada, plain Agent calls, un solo puntuador Haiku, «post
#    nothing»). Corre con los modelos del plugin; GATE_MODEL (entorno o
#    .githooks/config) fuerza el del coordinador con --model (#124). Concede
#    lectura (gh pr view/diff/checkout, git) con --allowedTools y niega
#    `gh pr comment`, `gh pr review` y `gh api` (#125).
#    Con GATE_CLAUDE_CONFIG_DIR (entorno o .githooks/config) corre con ese
#    perfil (CLAUDE_CONFIG_DIR); vacío = el perfil por omisión, sin fijar la
#    variable (nombrar ~/.claude cambia la entrada del llavero). Antes de
#    claude -p corre `claude auth status` con ese mismo entorno y, si no hay
#    sesión, se niega con el comando de login del perfil (#93). Mientras corre imprime un latido cada
#    GATE_HEARTBEAT_SECS segundos (30 por defecto) con el tiempo transcurrido.
#    Probado el 2026-10-11 sobre el PR #66: 5 revisores Sonnet, 8 puntuadores
#    Haiku, nada publicado. Al volver claude, deja el checkout en la rama donde
#    lo encontró y borra la rama local pr<N> que dejó el fetch de un revisor si
#    no existía antes (#78, #93). Si la salida ya trae las tres líneas finales
#    (gate_ready) y claude sigue vivo, espera GATE_SETTLE_SECS segundos (15 por
#    defecto) por una repetición tardía, termina el proceso y sigue como si
#    hubiera salido con 0; sin el bloque, la espera no cambia (#145).
# 4. Guarda la salida completa en .reviews/PR-<n>-<sha>.md (la carpeta se
#    ignora a sí misma) y la imprime. El archivo aparece solo al terminar
#    (mientras corre se escribe en .partial) y su última línea es el veredicto
#    con la URL del comentario, o la línea REFUSED (#142).
# 5. Se niega, sin llamar a post-gate.sh, si claude falla, si la salida no
#    trae el bloque final, si el número de revisores no es el de
#    GATE_REVIEWERS_LINE (menos: exención tomada; más: el comentario contaría
#    de menos), si la salida declara puntajes provisionales o una
#    re-verificación fallida (GATE_PROVISIONAL_RE), si revisó otro SHA, si con 0 hallazgos ≥ umbral la línea no
#    nombra los más altos o si el head cambió.
# 6. post-gate.sh --findings … --expect-head <sha> --yes: imprime y publica el
#    comentario. Con --dry-run, post-gate.sh lo imprime sin publicar.
# 7. Termina con una línea de veredicto, la única decisión que le queda a la
#    persona: «GATE CLEAN → run scripts/ship.sh <PR#>» o «GATE BLOCKED → N
#    hallazgos ≥ <umbral>, de vuelta al worker». Con GATE BLOCKED, antes del
#    veredicto imprime el bloque «Paste this to the worker:» (un hallazgo por línea y
#    el comando de re-compuerta), que la persona pega en la ventana del worker
#    sin pasar por el orquestador (#78).
# --print-prompt es el respaldo cuando claude -p no corre (p. ej. sesión
# OAuth vencida): imprime «escribe esto» y «pega esto» para una ventana.
# Salida: 0 = publicado (o --dry-run, o --print-prompt), 1 = no se publicó,
# 2 = la verificación previa (GATE_EXTRA_CHECK_CMD) devolvió algo que corregir.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./gate-format.sh
source "$HERE/gate-format.sh"

USAGE='usage: gate.sh [-R owner/repo] <PR#> [--dry-run] | gate.sh <PR#> --print-prompt'
# Lo que la revisión necesita leer, concedido sin depender del settings.json del perfil.
GATE_ALLOWED=('Bash(gh pr view:*)' 'Bash(gh pr diff:*)' 'Bash(gh pr checkout:*)' 'Bash(git:*)')
# Lo que claude -p no puede correr: «post nothing» no depende solo del prompt.
GATE_DENIED=('Bash(gh pr comment:*)' 'Bash(gh pr review:*)' 'Bash(gh api:*)')
# Con 0 hallazgos ≥ umbral, la línea nombra el más alto con su puntaje (o «none»).
# El nombre puede llevar comas: el puntaje es el último «, <número>» (#78).
GATE_HIGHEST_RE='^0 findings? ≥ *[0-9]+ *\(highest: *(none\)|.*[[:alpha:]].*, *[0-9]+)'

# gate_last <salida> <etiqueta> → el valor de la última línea «<etiqueta>: …»,
# sin el markdown que el modelo a veces pone alrededor de la línea (`, **);
# el contenido queda intacto: va tal cual al comentario de compuerta
gate_last() {
  printf '%s\n' "$1" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s/^\*\*(.*)\*\*$/\1/; s/^`(.*)`$/\1/' | grep -E "^$2:" | tail -n1 | sed -E "s/^$2:[[:space:]]*//"
}

# gate_env → llena GATE_PRE, el prefijo de entorno con que corren `claude auth status`
# y `claude -p`: CLAUDE_CONFIG_DIR solo cuando la clave no está vacía (el perfil por
# omisión es la variable ausente: Claude Code elige la entrada del llavero por su valor)
gate_env() {
  local ccd="${GATE_CLAUDE_CONFIG_DIR:-}"
  ccd="${ccd/#\~/$HOME}"
  GATE_PRE=()
  [ -n "$ccd" ] && GATE_PRE=(env "CLAUDE_CONFIG_DIR=$ccd")
  return 0
}

# gate_profile → el perfil efectivo, para los mensajes
gate_profile() {
  local ccd="${GATE_CLAUDE_CONFIG_DIR:-}"
  if [ -n "$ccd" ]; then printf '%s' "$ccd"
  else printf '%s (default)' "${CLAUDE_CONFIG_DIR:-~/.claude}"; fi
}

# gate_restore <rama o sha> → deja el checkout donde estaba al empezar
gate_restore() {
  local orig="$1" cur
  [ -n "$orig" ] || return 0
  cur=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse HEAD 2>/dev/null || true)
  [ "$cur" = "$orig" ] && return 0
  git checkout -q "$orig" >/dev/null 2>&1 || echo "WARNING: could not return to $orig; the checkout is on ${cur}" >&2
  return 0
}

# gate_run <archivo> <prompt> [<rama original>] → corre claude -p con la salida en <archivo> e
# imprime un latido en stderr mientras corre; devuelve el código de salida de claude
# gate_seal <archivo> <línea> → cierra el registro: añade la línea final (veredicto o
# REFUSED) a <archivo>.partial y lo renombra a <archivo>. Mientras la revisión corre,
# .reviews/PR-<n>-<sha>.md no existe; cuando existe, su última línea dice cómo terminó (#142).
gate_seal() { printf '%s\n' "$2" >> "$1.partial"; mv -f "$1.partial" "$1"; }
# gate_refuse <archivo> <mensaje> → sella el registro con <mensaje> y lo imprime en stderr.
gate_refuse() { gate_seal "$1" "$2"; echo "$2" >&2; }

# gate_ready <archivo> → 0 si la salida ya trae las tres líneas finales:
# «Head SHA reviewed:», «Reviewers: N» y una «Findings:» con el formato de compuerta
gate_ready() {
  local o; o=$(cat "$1" 2>/dev/null) || return 1
  [ -n "$(gate_last "$o" 'Head SHA reviewed')" ] || return 1
  [[ "$(gate_last "$o" Reviewers)" =~ ^[0-9]+$ ]] || return 1
  gate_has_findings "$(gate_last "$o" Findings)"
}

gate_run() {
  local file="$1" prompt="$2" orig="${3:-}" beat="${GATE_HEARTBEAT_SECS:-30}" settle="${GATE_SETTLE_SECS:-15}"
  local -a cmd=(claude -p "$prompt")
  gate_env
  [ -n "${GATE_MODEL:-}" ] && cmd+=(--model "$GATE_MODEL")
  cmd+=(--effort low --strict-mcp-config --no-chrome --allowedTools "${GATE_ALLOWED[@]}" --disallowedTools "${GATE_DENIED[@]}")
  [ "${#GATE_PRE[@]}" -gt 0 ] && cmd=("${GATE_PRE[@]}" "${cmd[@]}")
  local start=$SECONDS next pid="" rc ready=""
  # Un proceso en segundo plano ignora Ctrl-C: si la persona corta, se lleva a claude.
  # La trampa va antes de lanzarlo para que no quede un hueco sin ella.
  trap '[ -n "$pid" ] && kill "$pid" 2>/dev/null; gate_restore "$orig"; exit 130' INT TERM
  "${cmd[@]}" </dev/null > "$file" & pid=$!
  next=$((start + beat))
  while kill -0 "$pid" 2>/dev/null; do
    sleep 1
    if (( SECONDS >= next )); then
      echo "  … reviewing, $((SECONDS - start)) s elapsed" >&2; next=$((next + beat))
    fi
    if [ -z "$ready" ]; then
      gate_ready "$file" && ready=$SECONDS
    elif (( SECONDS - ready >= settle )); then
      echo "  … the output has the three final lines; stopping claude -p after ${settle} s of grace" >&2
      kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
      trap - INT TERM
      return 0
    fi
  done
  wait "$pid"; rc=$?
  trap - INT TERM
  return "$rc"
}

# gate_drop_branch <rama> <existía-antes> → (rama pr<N>, pr-<N> o pr-<N>-review de este PR) borra la rama local que dejó el fetch
# de un revisor de claude -p. Una que ya existía es de la persona; la del
# checkout no se puede borrar. Avisa en stderr y nunca cambia el código de salida.
gate_drop_branch() {
  local b="$1" had="$2" cur
  (( had )) && return 0
  git rev-parse --verify --quiet "refs/heads/$b" >/dev/null 2>&1 || return 0
  cur=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)
  if [ "$cur" = "$b" ]; then
    echo "WARNING: the review left local branch $b and it is the checkout's branch; not deleted" >&2; return 0
  fi
  if git branch -D -q "$b" >/dev/null 2>&1; then echo "Deleted local branch $b left by the review" >&2
  else echo "WARNING: could not delete local branch $b left by the review" >&2; fi
  return 0
}

# gate_worker_block <repo> <PR#> <línea Findings> → el bloque que la persona pega
# al worker: cada hallazgo ≥ umbral en su línea y el comando de re-compuerta
gate_worker_block() {
  local item
  echo ""; echo "Paste this to the worker:"; echo "-----"
  printf '%s\n' "${3#*≥*:}" | tr ';' '\n' | while IFS= read -r item; do
    item=$(printf '%s' "$item" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
    [ -n "$item" ] && printf -- '- %s\n' "$item"
  done
  echo "Fix only these findings, push, and print \`scripts/gate.sh -R ${1} ${2}\`."
  echo "-----"
}

gate_main() {
  local want="" pr="" dry=0 printp=0
  while [ $# -gt 0 ]; do
    case "$1" in
      -R) [ $# -ge 2 ] || { echo "$USAGE" >&2; return 1; }; want="$2"; shift 2 ;;
      --dry-run) dry=1; shift ;;
      --print-prompt) printp=1; shift ;;
      -h|--help) echo "$USAGE"; return 0 ;;
      *) pr="$1"; shift ;;
    esac
  done
  [ -z "$pr" ] && { echo "$USAGE" >&2; return 1; }
  if [ "${GATE_REVIEWER_CMD:-$GATE_SKILL}" != "$GATE_SKILL" ]; then
    echo "REFUSED: the configured reviewer is «${GATE_REVIEWER_CMD}» (GATE_REVIEWER_CMD); gate.sh only runs ${GATE_SKILL}. Run that reviewer in a window, then scripts/post-gate.sh $pr --findings \"…\"" >&2
    return 1
  fi
  if (( printp )); then
    echo "Open a Claude Code window (Opus) in this repo, without reading the diff."
    echo ""; echo "--- type this (typed, not pasted: pasting does not invoke the skill) ---"
    echo "$GATE_SKILL $pr"
    echo ""; echo "--- paste this in the same message, on a new line ---"
    gate_prompt_rest
    echo ""; echo "Then: scripts/post-gate.sh $pr --findings \"<Findings line>\""
    return 0
  fi
  command -v claude >/dev/null 2>&1 || { echo "ERROR: claude not found in PATH; use gate.sh $pr --print-prompt" >&2; return 1; }

  local repo head1 head2
  repo=$(gate_resolve_repo "$want") || return 1
  head1=$(gh pr view "$pr" -R "$repo" --json headRefOid -q .headRefOid) || { echo "ERROR: could not read PR $repo#$pr" >&2; return 1; }
  [ -z "$head1" ] && { echo "ERROR: empty head SHA for $repo#$pr" >&2; return 1; }

  if [ -n "${GATE_EXTRA_CHECK_CMD:-}" ]; then
    local xout xrc
    xout=$(bash -c "$GATE_EXTRA_CHECK_CMD \"\$@\"" _ -R "$repo" "$pr" "$head1" 2>&1 </dev/null); xrc=$?
    if [ "$xrc" -ne 0 ]; then
      if [ "$xrc" -eq 2 ]; then
        echo "REFUSED: the pre-check (GATE_EXTRA_CHECK_CMD) exited 2 (could not verify; not a PR defect); no reviewers ran and nothing was posted"
        printf '%s\n' "$xout"
      else
        echo "REFUSED: the pre-check (GATE_EXTRA_CHECK_CMD) exited $xrc; no reviewers ran and nothing was posted"
        echo ""; echo "Paste this to the worker:"; echo "-----"
        printf '%s\n' "$xout"
        echo "-----"
      fi
      return 2
    fi
  fi

  local top dir file out rc msg profile=""
  top=$(git rev-parse --show-toplevel 2>/dev/null) || top=$(pwd)
  dir="$top/.reviews"; file="$dir/PR-$pr-$head1.md"
  mkdir -p "$dir" || return 1
  [ -f "$dir/.gitignore" ] || printf '*\n' > "$dir/.gitignore"

  profile=$(gate_profile)
  gate_env
  local st
  st=$("${GATE_PRE[@]+"${GATE_PRE[@]}"}" claude auth status 2>/dev/null </dev/null) || true
  if ! printf '%s' "$st" | grep -qE '"loggedIn": *true'; then
    local login="claude auth login"
    [ "${#GATE_PRE[@]}" -gt 0 ] && login="${GATE_PRE[1]} claude auth login"
    echo "REFUSED: profile ${profile} has no claude session (claude auth status does not say loggedIn true); no reviewer ran and nothing was posted. Log in with: ${login}. If you have another profile: GATE_CLAUDE_CONFIG_DIR=<dir> in the environment or in .githooks/config (empty = the default profile). Fallback: gate.sh $pr --print-prompt" >&2
    return 1
  fi
  local orig
  orig=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse HEAD 2>/dev/null || true)
  echo "Reviewing $repo#$pr (head ${head1:0:8}) with claude -p${GATE_MODEL:+ --model ${GATE_MODEL}}, profile ${profile}; takes several minutes. If the output has the three final lines, the gate comment is posted without asking…" >&2
  local -a drops=("pr$pr" "pr-$pr" "pr-$pr-review") hads=() b
  for b in "${drops[@]}"; do
    if git rev-parse --verify --quiet "refs/heads/$b" >/dev/null 2>&1; then hads+=(1); else hads+=(0); fi
  done
  gate_run "$file.partial" "$GATE_SKILL $pr"$'\n\n'"$(gate_prompt_rest)" "$orig"; rc=$?
  gate_restore "$orig"
  local i
  for i in "${!drops[@]}"; do gate_drop_branch "${drops[$i]}" "${hads[$i]}"; done
  out=$(cat "$file.partial")
  printf '%s\n' "$out"
  echo ""; echo "Output saved to ${file#"$top"/}"
  if [ "$rc" -ne 0 ]; then
    gate_refuse "$file" "REFUSED: claude -p exited $rc with profile ${profile}; nothing was posted. If authentication failed and you use another profile: GATE_CLAUDE_CONFIG_DIR=<dir> in the environment or in .githooks/config. Fallback: gate.sh $pr --print-prompt"; return 1
  fi
  if printf '%s\n' "$out" | grep -qiE "$GATE_PROVISIONAL_RE"; then
    msg="REFUSED: the reviewer output declares provisional scores or a failed eligibility re-check (could not read the PR); nothing was posted. Run gate.sh again"
    gate_seal "$file" "$msg"; echo "$msg"
    echo ""; echo "Paste this to the worker:"; echo "-----"; echo "-----"
    return 1
  fi

  local n want_n sha findings
  want_n=$(printf '%s' "$GATE_REVIEWERS_LINE" | grep -oE '^[0-9]+' || true); want_n="${want_n:-5}"
  n=$(gate_last "$out" Reviewers)
  case "$n" in
    ''|*[!0-9]*) gate_refuse "$file" "REFUSED: the output has no «Reviewers: N»; nothing was posted"; return 1 ;;
  esac
  if [ "$n" -lt "$want_n" ]; then
    gate_refuse "$file" "REFUSED: $n reviewers ran, ${want_n} expected (exemption taken?); nothing was posted"; return 1
  fi
  if [ "$n" -gt "$want_n" ]; then
    gate_refuse "$file" "REFUSED: $n reviewers ran and the configured line says «${GATE_REVIEWERS_LINE}»: the comment would undercount. Fix GATE_REVIEWERS_LINE in .githooks/config; nothing was posted"; return 1
  fi
  sha=$(gate_last "$out" 'Head SHA reviewed')
  if [ "$sha" != "$head1" ]; then
    gate_refuse "$file" "REFUSED: the review reviewed ${sha:-no SHA}, the head is $head1; nothing was posted"; return 1
  fi
  findings=$(gate_last "$out" Findings)
  if ! gate_has_findings "$findings"; then
    gate_refuse "$file" "REFUSED: the «Findings:» line has no «N findings ≥ <threshold>»: ${findings}"; return 1
  fi
  if [[ "$findings" == 0\ * ]] && ! printf '%s' "$findings" | grep -qE "$GATE_HIGHEST_RE"; then
    gate_refuse "$file" "REFUSED: with 0 findings ≥ threshold, the «Findings:» line must name the two highest with their score, «(highest: <finding>, <score>; …)», or «(highest: none)»: ${findings}"; return 1
  fi
  head2=$(gh pr view "$pr" -R "$repo" --json headRefOid -q .headRefOid) || { gate_seal "$file" "REFUSED: could not re-read PR head"; echo "ERROR: could not re-read PR head" >&2; return 1; }
  if [ "$head1" != "$head2" ]; then
    gate_refuse "$file" "REFUSED: PR head changed during the review (${head1:0:8} → ${head2:0:8}); re-run the gate"; return 1
  fi

  local -a pg=(-R "$repo" "$pr" --findings "$findings" --expect-head "$head1")
  if (( dry )); then pg+=(--dry-run); else pg+=(--yes); fi
  local pgout url
  pgout=$("$HERE/post-gate.sh" "${pg[@]}"); rc=$?
  [ -n "$pgout" ] && printf '%s\n' "$pgout"
  if [ "$rc" -eq 2 ]; then gate_refuse "$file" "REFUSED: post-gate.sh refused to post the comment; no verdict"; return 1; fi
  if [ "$rc" -ne 0 ]; then gate_seal "$file" "REFUSED: post-gate.sh could not post to GitHub; no verdict"; echo "ERROR: post-gate.sh could not post to GitHub; no verdict" >&2; return 1; fi

  url=$(printf '%s\n' "$pgout" | grep -oE 'https://[^[:space:]]+' | tail -n1 || true)
  local blocked threshold note="" verdict
  blocked=$(printf '%s' "$findings" | grep -oE '^[0-9]+')
  threshold=$(printf '%s' "$findings" | grep -oE '≥ *[0-9]+' | head -n1 | grep -oE '[0-9]+$')
  (( dry )) && note=" (dry-run: not posted)"
  (( blocked > 0 )) && gate_worker_block "$repo" "$pr" "$findings"
  echo ""
  if [ "$blocked" -eq 0 ]; then verdict="GATE CLEAN → run scripts/ship.sh ${pr}${note}"
  else verdict="GATE BLOCKED → ${blocked} findings ≥ ${threshold}, back to the worker${note}"; fi
  gate_seal "$file" "${verdict}${url:+ · $url}"
  echo "$verdict"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  gate_main "$@"
fi
