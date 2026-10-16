#!/usr/bin/env bash
# raken-dev-standard v0.6.15: post-gate.sh
# sha256: 857c010ca3be0e9d5d9419ae6d85894d5b468b0e164f27b532d7b1750e67754a
#
# Publica el comentario de compuerta en el PR, según gate-format.sh.
#
#   post-gate.sh [-R owner/repo] <PR#> --findings "<texto>" [--expect-head <sha>] [--dry-run] [--yes]
#
# El SHA sale del head del PR en GitHub, nunca del checkout local. Con
# --expect-head (lo pasa gate.sh) se niega si ese head ya no es el del PR.
# Se niega si los hallazgos no traen puntaje ni «0 findings ≥ <umbral>».
# Imprime el comentario y espera un sí (regla 2); --yes solo después de que la persona
# dijo que sí. Salida (spec §4, #26): 0 = publicado (o --dry-run), 2 = se negó
# (hallazgos vacíos o sin puntaje, head cambiado, sin terminal o sin sí), 1 = no
# pudo leer o escribir en GitHub, o uso incorrecto.
set -uo pipefail
# shellcheck source=./gate-format.sh
source "$(dirname "${BASH_SOURCE[0]}")/gate-format.sh"

USAGE='usage: post-gate.sh [-R owner/repo] <PR#> --findings "<N findings ≥ threshold …>" [--expect-head <sha>] [--dry-run] [--yes]'

post_gate_main() {
  local want="" pr="" findings="" expect="" dry=0 yes=0
  while [ $# -gt 0 ]; do
    case "$1" in
      -R) want="${2:-}"; shift 2 ;;
      --findings) findings="${2:-}"; shift 2 ;;
      --expect-head) expect="${2:-}"; shift 2 ;;
      --dry-run) dry=1; shift ;;
      --yes) yes=1; shift ;;
      -h|--help) echo "$USAGE"; return 0 ;;
      *) pr="$1"; shift ;;
    esac
  done
  [ -z "$pr" ] && { echo "$USAGE" >&2; return 1; }
  if [ -z "${findings//[[:space:]]/}" ]; then
    echo "REFUSED: empty findings block — pass scored findings or «0 findings ≥ <threshold>»" >&2; return 2
  fi
  if ! gate_has_findings "$findings"; then
    echo "REFUSED: findings lack «N findings ≥ <threshold>»: $findings" >&2; return 2
  fi
  local repo head body
  repo=$(gate_resolve_repo "$want" explicit) || return 1
  head=$(gh pr view "$pr" -R "$repo" --json headRefOid -q .headRefOid) || { echo "ERROR: could not read PR $repo#$pr" >&2; return 1; }
  [ -z "$head" ] && { echo "ERROR: empty head SHA for $repo#$pr" >&2; return 1; }
  if [ -n "$expect" ] && [ "$head" != "$expect" ]; then
    echo "REFUSED: PR head changed since the review (${expect:0:8} → ${head:0:8}); re-run the gate" >&2; return 2
  fi
  body=$(gate_format_body "$head" "$findings")

  echo "Gate comment for $repo#$pr (head ${head:0:8}):"
  echo "-----"; printf '%s\n' "$body"; echo "-----"
  (( dry )) && { echo "dry-run: not posted"; return 0; }
  if (( ! yes )); then
    local answer=""
    if ! { exec 3</dev/tty; } 2>/dev/null; then
      echo "REFUSED: no terminal to confirm; re-run with --yes after the person says yes" >&2; return 2
    fi
    printf 'Post it? [y/N] ' >&2; read -r answer <&3; exec 3<&-
    case "$answer" in y|Y|yes|sí|si|s) ;; *) echo "not posted"; return 2 ;; esac
  fi
  gh pr comment "$pr" -R "$repo" --body "$body" || { echo "ERROR: could not post on $repo#$pr" >&2; return 1; }
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  post_gate_main "$@"
fi
