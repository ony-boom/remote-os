#!/usr/bin/env bash
set -euo pipefail  # Exit on error, undefined vars, and pipe failures

COMMIT=$1
REPO=$2
ENV="${ENV:-dev}"  # Default to dev if not set
declare -A REPO_INPUT_MAP=(
  ["ony.world"]="ony-world"
)

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

error() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
  exit 1
}

# Validation
[[ -z "${COMMIT:-}" ]] && error "Commit ID not provided"
[[ -z "${REPO:-}" ]] && error "Repository name not provided"

log "Starting deployment for ${REPO} (commit: ${COMMIT:0:7})"
log "Environment: ${ENV}"

log "Pulling latest changes..."
if ! git pull; then
  error "Failed to pull from git"
fi

INPUT_NAME=${REPO_INPUT_MAP["$REPO"]:-$REPO}
log "Updating flake input: ${INPUT_NAME}"

if ! nix flake update "$INPUT_NAME"; then
  error "Failed to update flake input: ${INPUT_NAME}"
fi

# Check if there are changes to commit
if git diff --quiet && git diff --cached --quiet; then
  log "No changes detected, skipping deployment"
  exit 0
fi

log "Committing changes..."
git add .
git commit -m "chore: updated ${REPO} to ${COMMIT:0:7}"

log "Pushing changes..."
if ! git push; then
  error "Failed to push changes"
fi

# Only redeploy if there were actual changes
log "Changes detected, running deployment for environment: ${ENV}"
if [[ $ENV == "server" ]]; then
  if ! sudo make local; then
    error "Make local failed"
  fi
else
  if ! make; then
    error "Make failed"
  fi
fi

log "Deployment completed successfully!"
