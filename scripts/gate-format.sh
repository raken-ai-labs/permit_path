#!/usr/bin/env bash
# raken-dev-standard v0.6.15: gate-format.sh
# sha256: 8bde63c6660aa4807aedf6a639ad020ec5d154b54bed6b7310621ace69e9786a
#
# Única fuente del contrato de compuerta (ADR 0002). La sourcean post-gate.sh
# y check-gate.sh; ninguno de los dos escribe estas cadenas por su cuenta.
#
#   ### Code review
#
#   Head SHA reviewed: <sha> · <GATE_REVIEWERS_LINE> · <hallazgos>
#
# <hallazgos> lleva puntaje o «0 findings ≥ <umbral>» (GATE_FINDINGS_RE).
# También es la única fuente del prompt de la compuerta (gate_prompt_rest): lo
# usan gate.sh, su --print-prompt y el bloque de CLAUDE.md que escribe bootstrap.

GATE_HEADING="### Code review"
GATE_SHA_LABEL="Head SHA reviewed:"
GATE_SEP=" · "
GATE_SHA_RE='Head SHA reviewed: *[0-9a-f]{7,40}'
GATE_FINDINGS_RE='[0-9]+ findings? ≥ *[0-9]+'
# La salida del revisor declara que no pudo leer el PR: puntajes provisionales o
# la re-verificación de elegibilidad fallida (#125). gate.sh se niega a publicar.
GATE_PROVISIONAL_RE='provisional|eligibility re-?check (failed|could not)|could not (read|fetch|access) the PR'
# Configuración del repo, del entorno o, si no está, de .githooks/config del repo
# (lo escribe bootstrap):
#   GATE_REVIEWERS_LINE     la línea de revisores que el revisor configurado corre
#   GATE_REVIEWER_CMD       el revisor configurado (gate.sh solo corre GATE_SKILL)
#   GATE_CLAUDE_CONFIG_DIR  el perfil de Claude con que gate.sh corre claude -p (vacío = el
#                           perfil por omisión: nunca nombrar ~/.claude, cambia la entrada del llavero)
#   GATE_MODEL              fuerza el modelo del coordinador (vacío = el del perfil)
#   GATE_EXTRA_CHECK_CMD    verificación mecánica previa a claude -p (vacía = ninguna)
GATE_SKILL="/code-review:code-review"
_gate_cfg="$(git rev-parse --show-toplevel 2>/dev/null)/.githooks/config"
for _gate_v in GATE_REVIEWERS_LINE GATE_REVIEWER_CMD GATE_CLAUDE_CONFIG_DIR GATE_MODEL GATE_EXTRA_CHECK_CMD; do
  eval "_gate_set=\${${_gate_v}+x}"
  if [ -z "$_gate_set" ] && [ -f "$_gate_cfg" ]; then
    _gate_val=$(bash -c 'source "$1" >/dev/null 2>&1; eval "printf %s \"\${$2:-}\""' _ "$_gate_cfg" "$_gate_v")
    [ -n "$_gate_val" ] && eval "${_gate_v}=\$_gate_val"
  fi
done
unset _gate_cfg _gate_v _gate_set _gate_val
GATE_REVIEWERS_LINE="${GATE_REVIEWERS_LINE:-5 reviewers ran}"

# gate_prompt_instructions → el párrafo que acompaña a la línea de la skill
gate_prompt_instructions() {
  printf '%s\n' 'The size exemption does not apply in this repo: run all five reviewers and the scoring on every PR. Use plain Agent calls for the scorers, and launch a single Haiku agent that scores all the findings in one call (not one agent per finding). An earlier «### Code review» comment on an older head does not make the current head ineligible. Post nothing; print the head SHA reviewed, the reviewer count and the scored findings, then stop.'
}

# gate_prompt_rest → las instrucciones que van después de la línea de la skill
gate_prompt_rest() {
  gate_prompt_instructions
  cat <<'EOF'

End your answer with exactly these three lines and nothing after them:
Head SHA reviewed: <full 40-character head SHA>
Reviewers: <number of reviewer agents that ran>
Findings: <N> findings ≥ 80: <path>:<line> <one-line description>, <score>; <path>:<line> <one-line description>, <score>   (or, with none ≥ 80: 0 findings ≥ 80 (highest: <path>:<line> <one-line description>, <score>; <path>:<line> <one-line description>, <score>), naming the two highest-scored findings; with no findings at all: 0 findings ≥ 80 (highest: none))
EOF
}

# gate_format_body <sha> <hallazgos>  → imprime el comentario completo
gate_format_body() {
  printf '%s\n\n%s %s%s%s%s%s\n' "$GATE_HEADING" "$GATE_SHA_LABEL" "$1" \
    "$GATE_SEP" "$GATE_REVIEWERS_LINE" "$GATE_SEP" "$2"
}

# gate_is_gate_comment <cuerpo>  → 0 si el comentario es (o intenta ser) una compuerta
gate_is_gate_comment() {
  case "$1" in *"$GATE_HEADING"*|*"$GATE_SHA_LABEL"*) return 0 ;; esac
  return 1
}

# gate_sha_of <cuerpo>  → imprime el SHA revisado, o nada
gate_sha_of() {
  printf '%s' "$1" | grep -oE "$GATE_SHA_RE" | head -n1 | grep -oE '[0-9a-f]{7,40}$' || true
}

# gate_has_findings <texto>  → 0 si trae hallazgos con puntaje o «0 ≥ umbral»
gate_has_findings() {
  printf '%s' "$1" | grep -qE "$GATE_FINDINGS_RE"
}

# gate_resolve_repo <-R o vacío> [explicit]  → imprime owner/repo del PR, o sale con 1.
# Falla si el repo del cwd no es el repo pedido: un check-gate corrido desde
# otro checkout verificó en silencio el PR con el mismo número de otro repo.
# Con «explicit» (post-gate.sh y check-gate.sh), un -R basta: ninguno de los dos
# lee el checkout, así que el cwd no importa (#58). merge.sh, ship.sh y gate.sh
# no lo pasan: check-tree y el revisor trabajan sobre el checkout.
gate_resolve_repo() {
  local want="$1" cwd
  if [ -n "$want" ] && [ "${2:-}" = explicit ]; then echo "$want"; return 0; fi
  cwd=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null) || cwd=""
  if [ -z "$want" ]; then
    [ -n "$cwd" ] && { echo "$cwd"; return 0; }
    echo "ERROR: el cwd no es un repo de GitHub; pasa -R owner/repo" >&2; return 1
  fi
  if [ -n "$cwd" ] && [ "$(printf '%s' "$cwd" | tr '[:upper:]' '[:lower:]')" != "$(printf '%s' "$want" | tr '[:upper:]' '[:lower:]')" ]; then
    echo "ERROR: el repo del cwd ($cwd) no es el repo del issue o PR ($want); corre desde un checkout de $want" >&2
    return 1
  fi
  echo "$want"
}
