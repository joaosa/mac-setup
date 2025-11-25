#!/usr/bin/env bash
# Common logging functions for mac-setup scripts

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Tracking variables (can be reset by sourcing script)
START_TIME="${START_TIME:-$(date +%s)}"
ITEMS_INSTALLED="${ITEMS_INSTALLED:-0}"
ITEMS_SKIPPED="${ITEMS_SKIPPED:-0}"
ITEMS_FAILED="${ITEMS_FAILED:-0}"

log_info() {
  echo -e "${BLUE}i${RESET}  $*"
}

log_success() {
  echo -e "${GREEN}✓${RESET}  $*"
  ((ITEMS_INSTALLED++)) || true
}

log_skip() {
  echo -e "${YELLOW}⊘${RESET}  $*"
  ((ITEMS_SKIPPED++)) || true
}

log_warn() {
  echo -e "${YELLOW}!${RESET}  $*"
}

log_error() {
  echo -e "${RED}x${RESET}  $*" >&2
  ((ITEMS_FAILED++)) || true
}

log_section() {
  local current="$1"
  local total="$2"
  local name="$3"
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${CYAN}[$current/$total] $name${RESET}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

log_skip_grouped() {
  local message="$1"
  shift
  local items=("$@")
  local count="${#items[@]}"

  if [ "$count" -eq 0 ]; then
    return
  fi

  echo -e "${YELLOW}⊘${RESET}  $message: ${items[*]}"
  ((ITEMS_SKIPPED += count)) || true
}
