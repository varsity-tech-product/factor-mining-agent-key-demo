#!/usr/bin/env bash
set -euo pipefail

MARKETPLACE_SOURCE="${FACTOR_MINING_DEMO_SOURCE:-varsity-tech-product/factor-mining-demo}"
MARKETPLACE_REF="${FACTOR_MINING_DEMO_REF:-main}"
MARKETPLACE_NAME="${FACTOR_MINING_DEMO_MARKETPLACE:-factor-mining-demo-marketplace}"
PLUGIN_NAME="${FACTOR_MINING_DEMO_PLUGIN:-factor-mining-demo}"
START_MODE="${FACTOR_MINING_DEMO_START_MODE:-cli}"
SKIP_SETUP="${FACTOR_MINING_DEMO_SKIP_SETUP:-0}"
FORCE_SETUP="${FACTOR_MINING_DEMO_FORCE_SETUP:-0}"
WORKSPACE_PATH="${FACTOR_MINING_DEMO_WORKSPACE:-.}"
CODEX_PROMPT="${FACTOR_MINING_DEMO_PROMPT:-Use the Factor Mining Demo plugin. Verify Factor Mining status, then show me the Factor Mining public task list. Do not create a session until I choose a public task or provide a custom idea. Then write a valid plugin.py locally, upload it, wait for the backtest, fetch the default factor card if available, and summarize the result. If I need to use a different vt_ Agent API Key, run python3 scripts/factor_setup.py --browser and do not ask me to paste the key into chat.}"

if [[ "${FACTOR_MINING_DEMO_START_CODEX:-1}" == "0" ]]; then
  START_MODE="none"
fi

usage() {
  cat <<'USAGE'
Usage: install-codex.sh [options]

Options:
  --desktop       Install and configure, then open Codex Desktop for this workspace.
  --no-start      Install and configure without starting Codex.
  --install-only  Install the demo plugin without configuring Factor Mining or starting Codex.
  --setup-only    Install the demo plugin and run Factor Mining setup without starting Codex.
  --force-setup   Run setup even if the demo is already configured.
  --skip-setup    Install and start without configuring Factor Mining.
  -h, --help      Show this help.

Inside an existing Codex session, switch Agent API Keys with:
  python3 scripts/factor_setup.py --browser
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --desktop)
      START_MODE="desktop"
      ;;
    --no-start)
      START_MODE="none"
      ;;
    --install-only)
      START_MODE="none"
      SKIP_SETUP="1"
      ;;
    --setup-only)
      START_MODE="none"
      FORCE_SETUP="1"
      ;;
    --force-setup)
      FORCE_SETUP="1"
      ;;
    --skip-setup)
      SKIP_SETUP="1"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if ! command -v codex >/dev/null 2>&1; then
  echo "Codex CLI is required. Install or update Codex, then run this script again." >&2
  exit 1
fi

marketplace_configured() {
  codex plugin marketplace list 2>/dev/null | awk 'NR > 1 { print $1 }' | grep -Fxq "${MARKETPLACE_NAME}"
}

plugin_installed() {
  codex plugin list --marketplace "${MARKETPLACE_NAME}" 2>/dev/null \
    | grep -E "^${PLUGIN_NAME}@${MARKETPLACE_NAME}[[:space:]]+installed, enabled" >/dev/null
}

plugin_root() {
  local listed_path
  listed_path="$(codex plugin list --marketplace "${MARKETPLACE_NAME}" 2>/dev/null \
    | awk -v plugin="${PLUGIN_NAME}@${MARKETPLACE_NAME}" '$1 == plugin { print $NF; exit }'
  )"
  if [[ -n "${listed_path}" && -d "${listed_path}" ]]; then
    printf '%s\n' "${listed_path}"
    return
  fi

  local cache_root="${CODEX_HOME:-${HOME}/.codex}/plugins/cache/${MARKETPLACE_NAME}/${PLUGIN_NAME}"
  if [[ -d "${cache_root}" ]]; then
    find "${cache_root}" -mindepth 1 -maxdepth 1 -type d -print | sort | tail -n 1
  fi
}

prompt_agent_key() {
  local key
  if [[ -n "${FACTOR_MINING_AGENT_API_KEY:-}" ]]; then
    printf '%s\n' "${FACTOR_MINING_AGENT_API_KEY}"
    return
  fi
  if [[ ! -r /dev/tty ]]; then
    echo "A terminal is required to enter the Factor Mining Agent API Key securely." >&2
    echo "Run this script from an interactive terminal, or set FACTOR_MINING_DEMO_SKIP_SETUP=1 and configure setup later." >&2
    exit 1
  fi
  printf 'Paste Factor Mining Agent API Key (input hidden): ' >/dev/tty
  IFS= read -r -s key </dev/tty
  printf '\n' >/dev/tty
  if [[ -z "${key}" ]]; then
    echo "A Factor Mining Agent API Key is required for setup." >&2
    exit 1
  fi
  printf '%s\n' "${key}"
}

configure_factor_mining() {
  local root="$1"
  if [[ "${SKIP_SETUP}" == "1" ]]; then
    echo "Skipping Factor Mining setup because FACTOR_MINING_DEMO_SKIP_SETUP=1."
    return
  fi
  if [[ "${FORCE_SETUP}" != "1" ]] && python3 "${root}/scripts/factor_status.py" >/dev/null 2>&1; then
    echo "Factor Mining Demo is already configured."
    return
  fi

  echo "Configuring Factor Mining Agent API access."
  echo "Paste the vt_ Agent API Key at the next prompt. It is hidden, not passed as a command argument, and not sent to Codex chat."
  local agent_key
  agent_key="$(prompt_agent_key)"
  printf '%s\n' "${agent_key}" | python3 "${root}/scripts/factor_setup.py" --api-key-stdin
  unset agent_key
}

echo "Configuring Codex marketplace: ${MARKETPLACE_NAME}"
if marketplace_configured; then
  echo "Marketplace already configured; refreshing if it is Git-backed."
  codex plugin marketplace upgrade "${MARKETPLACE_NAME}" >/dev/null 2>&1 || true
else
  if [[ -d "${MARKETPLACE_SOURCE}" ]]; then
    codex plugin marketplace add "${MARKETPLACE_SOURCE}"
  else
    codex plugin marketplace add "${MARKETPLACE_SOURCE}" --ref "${MARKETPLACE_REF}"
  fi
fi

echo "Installing Codex plugin: ${PLUGIN_NAME}@${MARKETPLACE_NAME}"
if plugin_installed; then
  echo "Plugin already installed."
else
  codex plugin add "${PLUGIN_NAME}@${MARKETPLACE_NAME}"
fi

PLUGIN_ROOT="$(plugin_root)"
if [[ -z "${PLUGIN_ROOT}" || ! -d "${PLUGIN_ROOT}" ]]; then
  echo "Could not locate installed plugin root for ${PLUGIN_NAME}@${MARKETPLACE_NAME}." >&2
  exit 1
fi

configure_factor_mining "${PLUGIN_ROOT}"

if [[ "${START_MODE}" == "none" ]]; then
  echo "Codex plugin is installed. Start it with:"
  printf 'codex %q\n' "${CODEX_PROMPT}"
  echo "For Codex Desktop, run:"
  printf 'codex app %q\n' "${WORKSPACE_PATH}"
  exit 0
fi

if [[ "${START_MODE}" == "desktop" ]]; then
  echo "Opening Codex Desktop."
  echo "Start a new chat with this prompt:"
  printf '%s\n' "${CODEX_PROMPT}"
  exec codex app "${WORKSPACE_PATH}"
fi

echo "Starting Codex CLI."
exec codex "${CODEX_PROMPT}"
