#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-ap-northeast-2}"
PROJECT_TAG="${PROJECT_TAG:-codyssey-b6-1}"
STATE_FILE="${STATE_FILE:-.state/b6-1.env}"

log() { printf '[B6-1] %s\n' "$*"; }
die() { printf '[B6-1][ERROR] %s\n' "$*" >&2; exit 1; }

retry() {
  local attempts="$1" delay="$2"
  shift 2
  local n=1
  until "$@"; do
    if (( n >= attempts )); then
      return 1
    fi
    log "Retry $n/$attempts after ${delay}s: $*"
    sleep "$delay"
    n=$((n + 1))
  done
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

require_env() {
  local name="$1"
  [[ -n "${!name:-}" ]] || die "Required environment variable is missing: $name"
}

aws_cli() {
  local args=(--region "$AWS_REGION")
  if [[ -n "${AWS_PROFILE:-}" ]]; then
    args+=(--profile "$AWS_PROFILE")
  fi
  aws "${args[@]}" "$@"
}

aws_global() {
  local args=()
  if [[ -n "${AWS_PROFILE:-}" ]]; then
    args+=(--profile "$AWS_PROFILE")
  fi
  aws "${args[@]}" "$@"
}

ensure_state_dir() {
  mkdir -p "$(dirname "$STATE_FILE")"
  touch "$STATE_FILE"
  chmod 600 "$STATE_FILE" 2>/dev/null || true
}

set_state() {
  local key="$1" value="$2" tmp
  ensure_state_dir
  tmp="${STATE_FILE}.tmp"
  grep -v "^${key}=" "$STATE_FILE" > "$tmp" || true
  printf '%s=%q\n' "$key" "$value" >> "$tmp"
  mv "$tmp" "$STATE_FILE"
}

load_state() {
  [[ -f "$STATE_FILE" ]] || die "State file not found: $STATE_FILE"
  # shellcheck disable=SC1090
  source "$STATE_FILE"
}

require_seoul_region() {
  [[ "$AWS_REGION" == "ap-northeast-2" ]] || die "Mission requires ap-northeast-2; got $AWS_REGION"
}

require_non_root_identity() {
  local arn
  arn="$(aws_global sts get-caller-identity --query Arn --output text)"
  [[ "$arn" != *":root" ]] || die "Root account is prohibited by the mission"
  log "AWS identity: $arn"
}

validate_ssh_cidr() {
  require_env SSH_CIDR
  [[ "$SSH_CIDR" != "0.0.0.0/0" ]] || die "SSH_CIDR must never be 0.0.0.0/0"
  [[ "$SSH_CIDR" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[12][0-9]|3[0-2])$ ]] || die "SSH_CIDR must be an IPv4 CIDR"
}
