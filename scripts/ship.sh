#!/usr/bin/env bash
# raken-dev-standard v0.6.15: ship.sh
# sha256: 1b290bc6bf008ecd9e85b1b1b9bb271a0ed2c5ca4c5b8aa0de0a256fc8799a86
#
# El cierre de un PR en un comando, con un solo sí de la persona (#59).
#
#   ship.sh [-R owner/repo] <PR#> [--issue N]… [--sin-contrato] [--dry-run] [--yes]
#
# 1. merge.sh --dry-run: si alguna verificación se niega, para sin preguntar.
# 2. Imprime el plan y pide un sí (regla 2) con una pregunta que nombra el
#    bypass --admin; --yes solo después de que la persona dijo que sí.
# 3. merge.sh --yes: publica «Merge gated: <sha>» y fusiona con squash.
# 4. Si la política de la rama base lo rechaza, corre la línea --admin que
#    merge.sh imprime, solo si es exactamente `gh pr merge <PR#> -R <repo>
#    --squash --match-head-commit <sha> --admin` para este PR. Cualquier otro
#    fallo se queda en el fallo de merge.sh. Con un ruleset sin bypass_actors
#    merge.sh no imprime --admin y este paso no ocurre. Mientras ese ruleset no
#    esté activo, ADR 0004 permite este paso tras el sí explícito.
# 5. Tras fusionar, adelanta el main local (checkout en main y limpio) o imprime
#    `git pull --ff-only origin main` (#86).
# Salida: 0 = fusionado (o --dry-run con todo en verde), 1 = no se fusionó.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./gate-format.sh
source "$HERE/gate-format.sh"

USAGE='usage: ship.sh [-R owner/repo] <PR#> [--issue N]... [--sin-contrato] [--dry-run] [--yes]'
SHIP_QUESTION='Post the comment and merge, with the --admin bypass if the base branch policy rejects it? [y/N] '

# ship_synced <PR#> → tras un merge exitoso, deja el main local en el commit del
# merge si el checkout está en main y limpio; si no, imprime el comando que la
# persona debe correr. Nunca cambia el código de salida (#86).
SHIP_PULL='git pull --ff-only origin main'
ship_synced() {
  echo "ship: merged PR $1"
  local cur dirty
  cur=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)
  dirty=$(git status --porcelain 2>/dev/null)
  if [ "$cur" = main ] && [ -z "$dirty" ] && git fetch -q origin main 2>/dev/null \
     && git merge -q --ff-only FETCH_HEAD >/dev/null 2>&1; then
    echo "ship: local main is now at $(git rev-parse --short main)"; return 0
  fi
  echo "ship: local main may be behind the merge; before any other command run: $SHIP_PULL"
  return 0
}

ship_main() {
  local want="" pr="" dry=0 yes=0 extra=()
  while [ $# -gt 0 ]; do
    case "$1" in
      -R|--issue) [ $# -ge 2 ] || { echo "$USAGE" >&2; return 1; }
        if [ "$1" = -R ]; then want="$2"; else extra+=(--issue "$2"); fi; shift 2 ;;
      --sin-contrato) extra+=(--sin-contrato); shift ;;
      --dry-run) dry=1; shift ;;
      --yes) yes=1; shift ;;
      -h|--help) echo "$USAGE"; return 0 ;;
      *) pr="$1"; shift ;;
    esac
  done
  [ -z "$pr" ] && { echo "$USAGE" >&2; return 1; }
  local repo out rc
  repo=$(gate_resolve_repo "$want") || return 1
  local -a margs=(-R "$repo" "$pr" ${extra[@]+"${extra[@]}"})

  out=$("$HERE/merge.sh" "${margs[@]}" --dry-run 2>&1); rc=$?
  printf '%s\n' "$out"
  [ "$rc" -ne 0 ] && { echo "REFUSED: merge.sh --dry-run refused; nothing posted or merged" >&2; return 1; }
  echo ""; echo "ship: on yes, runs merge.sh --yes (comment and squash); if the base branch policy"
  echo "      rejects it, runs the same merge with the --admin that merge.sh prints."
  (( dry )) && { echo "dry-run: nothing posted or merged"; return 0; }
  if (( ! yes )); then
    local answer=""
    printf '%s' "$SHIP_QUESTION" >&2
    if ! { exec 3</dev/tty; } 2>/dev/null; then
      echo "" >&2; echo "REFUSED: no terminal to confirm; re-run with --yes after the person says yes" >&2; return 1
    fi
    read -r answer <&3; exec 3<&-
    case "$answer" in y|Y|yes|sí|si|s) ;; *) echo "not merged"; return 1 ;; esac
  fi

  out=$("$HERE/merge.sh" "${margs[@]}" --yes 2>&1); rc=$?
  printf '%s\n' "$out"
  [ "$rc" -eq 0 ] && { ship_synced "$pr"; return 0; }
  local sha
  sha=$(printf '%s\n' "$out" | sed -nE 's/^  gh pr merge [0-9]+ -R [^ ]+ --squash --match-head-commit ([0-9a-f]{40}) --admin$/\1/p' | tail -n1)
  local -a cmd=(gh pr merge "$pr" -R "$repo" --squash --match-head-commit "$sha" --admin)
  if [ -z "$sha" ] || ! printf '%s\n' "$out" | grep -qxF "  ${cmd[*]}"; then
    echo "REFUSED: merge.sh did not merge and it was not the base branch policy; ship.sh does nothing more" >&2; return 1
  fi
  echo "ship: the base branch policy rejected the merge; running: ${cmd[*]}"
  "${cmd[@]}" || { echo "ERROR: gh could not merge with --admin; the comment is already posted" >&2; return 1; }
  ship_synced "$pr"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  ship_main "$@"
fi
