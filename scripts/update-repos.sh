#!/usr/bin/env bash
set -euo pipefail

# AutoEver monorepo helper: bulk update multiple Git repos
# - Discovers local repos by pattern (default: _4EVER_BE_*) under a root directory
# - Fetches from remote, checks out the default or specified branch, and updates

show_help() {
  cat <<'EOF'
Usage: scripts/update-repos.sh [options]

Options:
  -r, --root DIR         Root directory to search (default: current directory)
  -p, --pattern GLOB     Repo folder pattern (default: _4EVER_BE_*)
  -b, --branch NAME      Target branch to checkout/pull (default: origin HEAD)
      --remote NAME      Remote name (default: origin)
      --no-rebase        Use merge instead of rebase (default: rebase)
      --stash            Stash local changes before updating
      --pop-stash        Pop the stash after successful update
      --force            Hard reset to remote/branch (discards local changes)
      --submodules       Update git submodules (recursive, remote)
  -n, --dry-run          Print actions without executing
  -q, --quiet            Reduce output
  -h, --help             Show this help

Examples:
  scripts/update-repos.sh
  scripts/update-repos.sh -r . -p "_4EVER_BE_*" --branch develop --stash
  scripts/update-repos.sh --root "$HOME/workspace" --pattern "_4EVER_BE_*"
EOF
}

ROOT="$(pwd)"
PATTERN="_4EVER_BE_*"
BRANCH=""
REMOTE="origin"
REBASE=1
STASH=0
POP_STASH=0
FORCE=0
SUBMODULES=0
DRY_RUN=0
QUIET=0

# Failure tracking (Bash 3.2 compatible)
failed_repos=()
failed_msgs=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--root) ROOT="$2"; shift 2;;
    -p|--pattern) PATTERN="$2"; shift 2;;
    -b|--branch) BRANCH="$2"; shift 2;;
    --remote) REMOTE="$2"; shift 2;;
    --no-rebase) REBASE=0; shift;;
    --stash) STASH=1; shift;;
    --pop-stash) POP_STASH=1; shift;;
    --force) FORCE=1; shift;;
    --submodules) SUBMODULES=1; shift;;
    -n|--dry-run) DRY_RUN=1; shift;;
    -q|--quiet) QUIET=1; shift;;
    -h|--help) show_help; exit 0;;
    *) echo "Unknown option: $1" >&2; show_help; exit 2;;
  esac
done

# Colors
if [[ -t 1 ]]; then
  C_RESET='\033[0m'; C_GREEN='\033[32m'; C_YELLOW='\033[33m'; C_RED='\033[31m'; C_BLUE='\033[34m'
else
  C_RESET=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_BLUE=''
fi

run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[dry-run] $*"
  else
    eval "$@"
  fi
}

# Execute a command and capture its combined stderr/stdout
# Prints command output to stdout for capture by caller
exec_capture() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[dry-run] $*"
    return 0
  fi
  "$@" 2>&1
}

info() { [[ $QUIET -eq 0 ]] && echo -e "$*" || true; }
warn() { echo -e "${C_YELLOW}WARN${C_RESET} $*"; }
err()  { echo -e "${C_RED}ERR ${C_RESET} $*"; }
ok()   { [[ $QUIET -eq 0 ]] && echo -e "${C_GREEN}OK  ${C_RESET} $*" || true; }

add_failure() {
  failed_repos+=("$1")
  failed_msgs+=("$2")
}

if [[ ! -d "$ROOT" ]]; then
  err "Root directory not found: $ROOT"
  exit 1
fi

shopt -s nullglob
dirs=( "$ROOT"/$PATTERN )
shopt -u nullglob

if (( ${#dirs[@]} == 0 )); then
  warn "No directories match pattern '$PATTERN' under '$ROOT'"
  exit 0
fi

info "${C_BLUE}Bulk updating repos under:${C_RESET} $ROOT"
info "${C_BLUE}Pattern:${C_RESET} $PATTERN  ${C_BLUE}Remote:${C_RESET} $REMOTE  ${C_BLUE}Branch:${C_RESET} ${BRANCH:-'(origin HEAD)'}"
[[ $DRY_RUN -eq 1 ]] && info "${C_YELLOW}Dry-run enabled (no changes will be made)${C_RESET}"
[[ $FORCE -eq 1 ]] && info "${C_YELLOW}Force reset enabled${C_RESET}"
[[ $STASH -eq 1 ]] && info "Stashing local changes before update"
[[ $SUBMODULES -eq 1 ]] && info "Will update submodules recursively"

updated=0; skipped=0; failed=0

for dir in "${dirs[@]}"; do
  rel=$(basename "$dir")
  if [[ ! -d "$dir" ]]; then
    warn "Skip (not a dir): $dir"
    ((skipped++))
    continue
  fi

  if [[ ! -d "$dir/.git" ]]; then
    warn "Skip (not a git repo): $dir"
    ((skipped++))
    continue
  fi

  echo ""
  info "${C_BLUE}==> Updating:${C_RESET} $rel"

  # Determine target branch if not provided
  target_branch="$BRANCH"
  if [[ -z "$target_branch" ]]; then
    # Try origin/HEAD
    if head_ref=$(git -C "$dir" symbolic-ref --quiet --short "refs/remotes/${REMOTE}/HEAD" 2>/dev/null); then
      target_branch="${head_ref#${REMOTE}/}"
    else
      # Fallback to current branch
      target_branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD)
    fi
  fi

  # Local changes check
  dirty="$(git -C "$dir" status --porcelain)" || dirty=""
  if [[ -n "$dirty" && $FORCE -eq 0 && $STASH -eq 0 ]]; then
    warn "Uncommitted changes detected. Use --stash or --force to proceed. Skipping $rel"
    ((skipped++))
    continue
  fi

  # Fetch
  if ! out=$(exec_capture git -C "$dir" fetch --all --prune --tags); then
    err "Fetch failed: $rel"
    add_failure "$rel" "Fetch failed\n$(echo "$out" | sed -n '1,4p')"
    ((failed++))
    continue
  fi

  # Stash if requested
  stashed_ref=""
  if [[ -n "$dirty" && $STASH -eq 1 ]]; then
    if st=$(run git -C "$dir" stash push -u -m "autoever-bulk-update $(date +%F_%T)" 2>&1); then
      [[ $DRY_RUN -eq 0 ]] && stashed_ref="1"
      info "Stashed local changes"
    else
      warn "Stash failed: $st"
    fi
  fi

  # Checkout target branch
  current_branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD)
  if [[ "$current_branch" != "$target_branch" ]]; then
    if ! out=$(exec_capture git -C "$dir" checkout "$target_branch"); then
      err "Checkout failed: $rel ($target_branch)"
      add_failure "$rel" "Checkout '$target_branch' failed\n$(echo "$out" | sed -n '1,4p')"
      ((failed++))
      continue
    fi
  fi

  # Update to latest
  if [[ $FORCE -eq 1 ]]; then
    if ! out=$(exec_capture git -C "$dir" reset --hard "${REMOTE}/${target_branch}"); then
      err "Hard reset failed: $rel"
      add_failure "$rel" "Reset to ${REMOTE}/${target_branch} failed\n$(echo "$out" | sed -n '1,4p')"
      ((failed++))
      continue
    fi
  else
    if [[ $REBASE -eq 1 ]]; then
      if ! out=$(exec_capture git -C "$dir" pull --rebase "$REMOTE" "$target_branch"); then
        err "Pull (rebase) failed: $rel"
        add_failure "$rel" "Pull --rebase failed\n$(echo "$out" | sed -n '1,4p')"
        ((failed++))
        continue
      fi
    else
      if ! out=$(exec_capture git -C "$dir" pull "$REMOTE" "$target_branch"); then
        err "Pull (merge) failed: $rel"
        add_failure "$rel" "Pull (merge) failed\n$(echo "$out" | sed -n '1,4p')"
        ((failed++))
        continue
      fi
    fi
  fi

  # Update submodules if requested
  if [[ $SUBMODULES -eq 1 ]]; then
    if ! out=$(exec_capture git -C "$dir" submodule update --init --recursive --remote); then
      warn "Submodule update failed: $rel"
      add_failure "$rel" "Submodule update failed\n$(echo "$out" | sed -n '1,4p')"
    fi
  fi

  # Optionally pop stash
  if [[ -n "$stashed_ref" && $POP_STASH -eq 1 && $FORCE -eq 0 ]]; then
    if ! out=$(exec_capture git -C "$dir" stash pop); then
      warn "Stash pop had conflicts in $rel; resolve manually"
      add_failure "$rel" "Stash pop conflicts\n$(echo "$out" | sed -n '1,4p')"
    fi
  fi

  ok "$rel updated -> ${target_branch}"
  ((updated++))
done

echo ""
info "${C_BLUE}Summary:${C_RESET} updated=$updated skipped=$skipped failed=$failed"
if [[ $failed -gt 0 ]]; then
  echo ""
  echo "Failures:"
  i=0
  while [[ $i -lt ${#failed_repos[@]} ]]; do
    repo="${failed_repos[$i]}"
    msg="${failed_msgs[$i]}"
    echo "- ${repo}:"
    echo "$msg" | sed 's/^/    /'
    i=$((i+1))
  done
  exit 1
fi
exit 0
