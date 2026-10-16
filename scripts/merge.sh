#!/usr/bin/env bash
# raken-dev-standard v0.6.15: merge.sh
# sha256: 5bff31b9887160bf1079fc929fe8d7f8034dfcda5e071342cc7b4b777a6c86e3
#
# Fusiona un PR solo si pasa check-tree, check-gate y check-label (ADR 0004).
#
#   merge.sh [-R owner/repo] <PR#> [--issue N]… [--sin-contrato] [--dry-run] [--yes]
#
# Llama a check-tree.sh, check-gate.sh y check-label.sh de esta carpeta; no
# reimplementa ninguno. Con salida 1 o 2 de cualquiera se niega, y no hay
# --force: el único atajo es el botón de la interfaz de GitHub, que es un
# bypass y deja el PR sin «Merge gated: <sha>» en su head.
# Los issues salen de «Cierra/Closes/Fixes/Resuelve #N» en el cuerpo del PR,
# o de --issue. Un PR que no cierra ningún issue solo se fusiona con
# --sin-contrato (el comentario lleva «· sin contrato»). Imprime el plan y espera un sí (regla 2); --yes solo después
# de que la persona dijo que sí. Squash por gh, nunca con --admin: si gh se
# niega, imprime el comando exacto para que lo corra la persona; si la causa es
# la política de la rama base, ese comando impreso lleva --admin.
# Un PR que no está OPEN, o cuyo head no contiene el tip actual de la base, se niega también con --dry-run.
# Salida: 0 = fusionado (o --dry-run con todo en verde), 1 = no se fusionó.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./gate-format.sh
source "$HERE/gate-format.sh"

USAGE='usage: merge.sh [-R owner/repo] <PR#> [--issue N]... [--sin-contrato] [--dry-run] [--yes]'
BYPASS_NOTE='There is no --force. The only shortcut is the merge button in the GitHub UI, which is a bypass: it leaves the PR without «Merge gated: <sha>».'

merge_refuse() { echo "REFUSED: $1" >&2; echo "$BYPASS_NOTE" >&2; return 1; }

merge_main() {
  local want="" pr="" dry=0 yes=0 nocontract=0 issues=()
  while [ $# -gt 0 ]; do
    case "$1" in
      -R|--issue) [ $# -ge 2 ] || { echo "$USAGE" >&2; return 1; }
        if [ "$1" = -R ]; then want="$2"; else issues+=("$2"); fi; shift 2 ;;
      --sin-contrato) nocontract=1; shift ;;
      --dry-run) dry=1; shift ;;
      --yes) yes=1; shift ;;
      -h|--help) echo "$USAGE"; return 0 ;;
      *) pr="$1"; shift ;;
    esac
  done
  [ -z "$pr" ] && { echo "$USAGE" >&2; return 1; }
  local repo rc out
  repo=$(gate_resolve_repo "$want") || return 1
  local -a rargs=(-R "$repo")

  out=$("$HERE/check-tree.sh") ; rc=$?
  echo "check-tree:  $out"
  [ "$rc" -ne 0 ] && { merge_refuse "check-tree exited $rc"; return 1; }

  local head1 head2 state body closing
  local pr_line
  pr_line=$(gh pr view "$pr" "${rargs[@]}" --json headRefOid,state -q '.headRefOid + " " + .state') \
    || { echo "ERROR: could not read PR $repo#$pr" >&2; return 1; }
  read -r head1 state <<< "$pr_line"
  [ -z "$head1" ] && { echo "ERROR: empty head SHA for $repo#$pr" >&2; return 1; }

  out=$("$HERE/check-gate.sh" "${rargs[@]}" "$pr") ; rc=$?
  echo "check-gate:  $out"
  [ "$rc" -ne 0 ] && { merge_refuse "check-gate exited $rc"; return 1; }

  if [ ${#issues[@]} -eq 0 ]; then
    # Fuente: closingIssuesReferences de GitHub, que ignora los bloques de código (#137).
    closing=$(gh pr view "$pr" "${rargs[@]}" --json closingIssuesReferences -q '.closingIssuesReferences[].number') \
      || { echo "ERROR: could not read PR closing issues" >&2; return 1; }
    while IFS= read -r n; do [ -n "$n" ] && issues+=("$n"); done < <(printf '%s\n' "$closing" | grep -oE '^[0-9]+$' | sort -un)
  fi
  if [ ${#issues[@]} -eq 0 ]; then # respaldo: GitHub no devolvió ninguno
    body=$(gh pr view "$pr" "${rargs[@]}" --json body -q .body) || { echo "ERROR: could not read PR body" >&2; return 1; }
    while IFS= read -r n; do [ -n "$n" ] && issues+=("$n"); done < <(
      printf '%s\n' "$body" | grep -oiE '(cierra|cierran|closes?|fix(es)?|resuelve) +#[0-9]+' | grep -oE '[0-9]+$' | sort -un)
  fi
  if [ ${#issues[@]} -eq 0 ] && (( ! nocontract )); then
    merge_refuse "the PR closes no issue (no «Closes #N» in the body and no --issue): no contract to verify. If intentional, --sin-contrato"; return 1
  fi
  local i
  for i in ${issues[@]+"${issues[@]}"}; do
    out=$("$HERE/check-label.sh" "${rargs[@]}" "$i") ; rc=$?
    echo "check-label: #$i $out"
    [ "$rc" -ne 0 ] && { merge_refuse "check-label #$i exited $rc"; return 1; }
  done

  # El head se lee de GitHub antes del merge y debe ser el que check-gate verificó.
  head2=$(gh pr view "$pr" "${rargs[@]}" --json headRefOid -q .headRefOid) || { echo "ERROR: could not re-read PR head" >&2; return 1; }
  [ "$head1" != "$head2" ] && { merge_refuse "PR head changed during the checks (${head1:0:8} → ${head2:0:8}); re-run the gate"; return 1; }

  local comment
  if [ ${#issues[@]} -eq 0 ]; then comment="Merge gated: $head1 · sin contrato, check-gate GATED"
  else comment="Merge gated: $head1, check-gate GATED, label check ok (#${issues[*]// /, #})"; fi
  local cmd="gh pr merge $pr -R $repo --squash --match-head-commit $head1"
  echo ""; echo "Plan for $repo#$pr (state $state, head ${head1:0:8}):"
  echo "  1. checks:   check-tree, check-gate, check-label → all green"
  echo "  2. comment:  $comment"
  echo "  3. merge:    $cmd"
  # Antes del dry-run: un PR ya fusionado o cerrado no puede salir en verde (#71).
  [ "$state" != OPEN ] && { echo "REFUSED: the PR is $state, not OPEN" >&2; return 1; }
  # También antes del dry-run: dos PRs paralelos con compuerta limpia pueden dejar main roto sin conflicto textual (#82).
  local base cmp
  base=$(gh pr view "$pr" "${rargs[@]}" --json baseRefName -q .baseRefName) && [ -n "$base" ] \
    || { echo "ERROR: could not read the base branch of $repo#$pr" >&2; return 1; }
  cmp=$(gh api "repos/$repo/compare/$base...$head1" --jq .status) \
    || { echo "ERROR: could not compare $base with the head of $repo#$pr" >&2; return 1; }
  case "$cmp" in
    ahead|identical) ;;
    *) echo "REFUSED: main moved since the gate: in the worker, \`git merge origin/main\`, push, new gate" >&2; return 1 ;;
  esac
  if (( dry )); then echo "dry-run: nothing posted or merged"; return 0; fi
  if (( ! yes )); then
    local answer=""
    if ! { exec 3</dev/tty; } 2>/dev/null; then
      echo "REFUSED: no terminal to confirm; re-run with --yes after the person says yes" >&2; return 1
    fi
    printf 'Post the comment and merge? [y/N] ' >&2; read -r answer <&3; exec 3<&-
    case "$answer" in y|Y|yes|sí|si|s) ;; *) echo "not merged"; return 1 ;; esac
  fi
  gh pr comment "$pr" "${rargs[@]}" --body "$comment" || { echo "ERROR: could not post the merge comment on $repo#$pr; nothing merged" >&2; return 1; }
  local err
  if ! err=$($cmd 2>&1); then
    printf '%s\n' "$err" >&2
    # La política de la rama base solo cede con --admin; merge.sh nunca lo pasa, lo corre la persona.
    if [[ "$err" == *"base branch policy"* ]]; then
      echo "ERROR: the base branch policy blocks the merge. The comment is already posted. Run this command yourself:" >&2
      echo "  $cmd --admin" >&2
    else
      echo "ERROR: gh could not merge. The comment is already posted. Run this command yourself:" >&2
      echo "  $cmd" >&2
    fi
    return 1
  fi
  if [ -n "$err" ]; then printf '%s\n' "$err"; fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  merge_main "$@"
fi
