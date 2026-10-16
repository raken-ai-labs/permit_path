#!/usr/bin/env bash
# raken-dev-standard v0.6.15: check-tree.sh
# sha256: 8585094d1d8e89c9309f2ba8e884668361ab826091bbde36544f04c0ed942aee
#
# ¿El checkout es el esperado para fusionar? Rama por defecto (o la que se
# pida), árbol limpio y ningún commit local que no esté en origin/<rama>.
# Solo lee (hace `git fetch`). Un checkout detrás de origin/<rama> es aviso,
# no rechazo: el merge lo hace GitHub y el checkout local no cambia el
# resultado (#53). Adelante o divergido sí se rechaza: esos commits no van a
# GitHub.
#
#   check-tree.sh [<rama-esperada>]   0 = checkout correcto (igual o detrás, con aviso)
#                                     2 = checkout equivocado (imprime el motivo)
#                                     1 = no pudo leer git
set -uo pipefail

check_tree_main() {
  case "${1:-}" in -h|--help) echo "usage: check-tree.sh [<expected-branch>]"; return 0 ;; esac
  local want="${1:-}" top branch
  top=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "ERROR: not a git checkout" >&2; return 1; }
  if [ -z "$want" ]; then
    want=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null) && want="${want#origin/}"
    [ -z "$want" ] && want=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null)
    [ -z "$want" ] && { echo "ERROR: could not determine the default branch; pass it as an argument" >&2; return 1; }
  fi
  git fetch -q origin 2>/dev/null || { echo "ERROR: git fetch origin failed" >&2; return 1; }
  local remote_sha head_sha status
  remote_sha=$(git rev-parse --verify -q "origin/$want") || { echo "ERROR: origin/$want does not exist" >&2; return 1; }
  branch=$(git branch --show-current) || return 1
  if [ "$branch" != "$want" ]; then
    echo "WRONG TREE: $top is on «${branch:-detached HEAD}», expected «${want}»"; return 2
  fi
  status=$(git status --porcelain) || return 1
  if [ -n "$status" ]; then
    echo "WRONG TREE: $top has uncommitted changes ($(printf '%s\n' "$status" | wc -l | tr -d ' ') paths)"; return 2
  fi
  head_sha=$(git rev-parse HEAD) || return 1
  if [ "$head_sha" != "$remote_sha" ]; then
    if git merge-base --is-ancestor "$head_sha" "$remote_sha" 2>/dev/null; then
      local behind
      behind=$(git rev-list --count "$head_sha..$remote_sha") || return 1
      echo "TREE OK (warning): $top on $want, clean, ${behind} commits behind origin/$want (${head_sha:0:8} → ${remote_sha:0:8}); GitHub does the merge. To catch up: git pull --ff-only"
      return 0
    fi
    echo "WRONG TREE: local $want ${head_sha:0:8} has commits not in origin/$want ${remote_sha:0:8}"; return 2
  fi
  echo "TREE OK: $top on $want, clean, equal to origin/$want (${head_sha:0:8})"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  check_tree_main "$@"
fi
