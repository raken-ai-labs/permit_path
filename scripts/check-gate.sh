#!/usr/bin/env bash
# raken-dev-standard v0.6.15: check-gate.sh
# sha256: b9e37d0c4233ece3e662cfe99b0a47613084c3950275cb92a0e12af6d5bb4bf1
#
# ¿La compuerta corrió sobre el head vigente del PR?
#
#   check-gate.sh [-R owner/repo] <PR#>   0 = gateado en el head vigente
#                                         2 = no gateado (imprime el motivo)
#                                         1 = no pudo leer GitHub, o sin -R el cwd no es un repo
#
# Verifica forma y frescura del comentario (gate-format.sh), no que los
# revisores hayan corrido. Veredicto puro + lector delgado: el veredicto se
# prueba en tabla en check-gate.test.sh sin tocar GitHub.
set -uo pipefail
# shellcheck source=./gate-format.sh
source "$(dirname "${BASH_SOURCE[0]}")/gate-format.sh"

# gate_record <created_at> <cuerpo> → un registro en el formato que lee check_gate_verdict
gate_record() { printf '%s\n%s\n\036\n' "$1" "$2"; }

# check_gate_verdict <head_sha> <head_committed_at>
#   stdin: un registro por comentario, del más viejo al más nuevo: una línea con
#   created_at, las líneas del cuerpo tal cual y una línea con solo el byte RS
#   (\036). Así sale de gh --jq sin decodificar JSON en bash (#48).
#   Imprime una línea de veredicto; devuelve 0 (gateado) o 2 (no gateado).
check_gate_verdict() {
  local head="$1" head_at="$2"
  local n=0 last_body="" last_at="" same_head=0 sha at="" body="" line inside=0
  while IFS= read -r line; do
    if (( ! inside )); then at="$line"; body=""; inside=1; continue; fi
    if [ "$line" != $'\036' ]; then body+="${line}"$'\n'; continue; fi
    inside=0
    # Sin saltos de línea al final, como lo dejaba la sustitución $(…) de antes.
    while [[ "$body" == *$'\n' ]]; do body="${body%$'\n'}"; done
    gate_is_gate_comment "$body" || continue
    n=$((n + 1)); last_body="$body"; last_at="$at"
    sha=$(gate_sha_of "$body")
    [ -n "$sha" ] && [[ "$head" == "$sha"* ]] && same_head=$((same_head + 1))
  done
  if (( n == 0 )); then
    echo "NOT GATED: no «${GATE_HEADING}» comment on the PR"; return 2
  fi
  sha=$(gate_sha_of "$last_body")
  if [ -z "$sha" ]; then
    echo "NOT GATED: latest gate comment has no «${GATE_SHA_LABEL} <sha>» line (a window that read the diff by hand)"; return 2
  fi
  if [[ "$head" != "$sha"* ]]; then
    echo "NOT GATED: latest gate reviewed ${sha:0:8}, PR head is ${head:0:8} — re-run the gate on the new head"; return 2
  fi
  if ! printf '%s' "$last_body" | grep -qF "$GATE_REVIEWERS_LINE"; then
    echo "NOT GATED: latest gate comment lacks «${GATE_REVIEWERS_LINE}»"; return 2
  fi
  if ! gate_has_findings "$last_body"; then
    echo "NOT GATED: latest gate comment has no scored findings line («N findings ≥ threshold»)"; return 2
  fi
  if [ -n "$head_at" ] && [[ "$last_at" < "$head_at" ]]; then
    echo "NOT GATED: gate comment ($last_at) predates the head commit ($head_at)"; return 2
  fi
  local note=""
  (( same_head > 1 )) && note=" · $same_head gate comments on this same head — confirm the fixes actually landed"
  echo "GATED: head ${head:0:8} · $GATE_REVIEWERS_LINE · $last_at$note"
  return 0
}

check_gate_main() {
  local want="" pr=""
  while [ $# -gt 0 ]; do
    case "$1" in
      -R) want="${2:-}"; shift 2 ;;
      -h|--help) echo "usage: check-gate.sh [-R owner/repo] <PR#>"; return 0 ;;
      *) pr="$1"; shift ;;
    esac
  done
  [ -z "$pr" ] && { echo "usage: check-gate.sh [-R owner/repo] <PR#>" >&2; return 1; }
  local repo head head_at comments
  repo=$(gate_resolve_repo "$want" explicit) || return 1
  # Leer todo antes del veredicto: si gh falla, es 1 y no un «no gateado».
  local pr_line
  pr_line=$(gh pr view "$pr" -R "$repo" --json headRefOid,commits -q '.headRefOid + " " + .commits[-1].committedDate') || { echo "ERROR: could not read PR $repo#$pr" >&2; return 1; }
  read -r head head_at <<< "$pr_line"
  comments=$(gh api "repos/$repo/issues/$pr/comments" --paginate --jq '.[] | .created_at, (.body // ""), "\u001e"') || { echo "ERROR: could not read comments of $repo#$pr" >&2; return 1; }
  [ -z "$head" ] && { echo "ERROR: empty head SHA for $repo#$pr" >&2; return 1; }
  printf '%s\n' "$comments" | check_gate_verdict "$head" "$head_at"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  check_gate_main "$@"
fi
