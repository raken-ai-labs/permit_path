#!/usr/bin/env bash
# raken-dev-standard v0.6.15: check-label.sh
# sha256: 8c8c02344870bf75120ca84f490b914ce1dc0da54a8d2136bf96d8df76e66aad
#
# ¿El cuerpo vigente del issue está autorizado? Solo lee: nunca aplica ni quita etiquetas.
#
#   check-label.sh [-R owner/repo] <issue#>   0 = autorizado
#                                             2 = no autorizado (imprime el motivo)
#                                             1 = no pudo leer GitHub, o repo distinto
#
# Autoriza el último evento `labeled` de `ready-for-agent` si no lo siguió un
# `unlabeled` y es posterior (estrictamente) a la última edición del cuerpo.
# Mismo patrón que check-gate.sh: veredicto puro + lector delgado.
set -uo pipefail
# shellcheck source=./gate-format.sh
source "$(dirname "${BASH_SOURCE[0]}")/gate-format.sh"

LABEL_NAME="ready-for-agent"

# check_label_verdict <last_edited_at o vacío>
#   stdin: un evento por línea «<labeled|unlabeled>\t<created_at>\t<etiqueta>», del más viejo al más nuevo.
#   Imprime una línea de veredicto; devuelve 0 (autorizado) o 2 (no autorizado).
check_label_verdict() {
  local edited="$1" kind at name state="" label_at=""
  while IFS=$'\t' read -r kind at name; do
    [ "$name" = "$LABEL_NAME" ] || continue
    case "$kind" in
      labeled)   state=on;  label_at="$at" ;;
      unlabeled) state=off; label_at="" ;;
    esac
  done
  if [ "$state" != on ]; then
    echo "NOT AUTHORIZED: no current «${LABEL_NAME}» label on the issue"; return 2
  fi
  if [ -n "$edited" ] && ! [[ "$label_at" > "$edited" ]]; then
    echo "NOT AUTHORIZED: body edited at $edited, «${LABEL_NAME}» applied at $label_at — the authority has not seen the current body"; return 2
  fi
  echo "AUTHORIZED: «${LABEL_NAME}» applied at $label_at, body last edited ${edited:-never}"
  return 0
}

check_label_main() {
  local want="" issue=""
  while [ $# -gt 0 ]; do
    case "$1" in
      -R) want="${2:-}"; shift 2 ;;
      -h|--help) echo "usage: check-label.sh [-R owner/repo] <issue#>"; return 0 ;;
      *) issue="$1"; shift ;;
    esac
  done
  [ -z "$issue" ] && { echo "usage: check-label.sh [-R owner/repo] <issue#>" >&2; return 1; }
  local repo edited events
  repo=$(gate_resolve_repo "$want") || return 1
  # Leer todo antes del veredicto: si gh falla, es 1 y no un «no autorizado».
  # El --jq de gh deja la primera línea con lastEditedAt y un evento por línea (#48).
  events=$(gh api graphql -F owner="${repo%%/*}" -F name="${repo##*/}" -F number="$issue" -f query='
    query($owner:String!,$name:String!,$number:Int!){repository(owner:$owner,name:$name){issue(number:$number){
      lastEditedAt
      timelineItems(last:100,itemTypes:[LABELED_EVENT,UNLABELED_EVENT]){nodes{__typename
        ... on LabeledEvent{createdAt label{name}} ... on UnlabeledEvent{createdAt label{name}}}}}}}' \
    --jq '.data.repository.issue // error("no issue")
      | (.lastEditedAt // ""),
        (.timelineItems.nodes[] | (if .__typename == "LabeledEvent" then "labeled" else "unlabeled" end) + "\t" + .createdAt + "\t" + .label.name)') \
    || { echo "ERROR: could not read $repo#$issue (does the issue exist?)" >&2; return 1; }
  edited=$(printf '%s\n' "$events" | head -n1)
  printf '%s\n' "$events" | tail -n +2 | check_label_verdict "$edited"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  check_label_main "$@"
fi
