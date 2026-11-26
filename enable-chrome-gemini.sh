#!/usr/bin/env bash
# enable-chrome-gemini.sh
#
# Enables Gemini in Chrome (Glic) on macOS by configuring com.google.Chrome
# defaults and relaunching Chrome with the required feature/variations flags.

set -euo pipefail

CHROME_DOMAIN="com.google.Chrome"
CHROME_APP="/Applications/Google Chrome.app"
CHROME_PROCESS_NAME="Google Chrome"
QUIT_TIMEOUT_SECONDS=15

CHROME_FEATURES="Glic,GlicSidePanel,GlicUnifiedFreScreen"
VARIATIONS_COUNTRY="us"

DRY_RUN=false
RESET_MODE=false

usage() {
  cat <<'EOF'
Usage: enable-chrome-gemini.sh [OPTIONS]

Enable Gemini in Chrome (Glic) on macOS by setting com.google.Chrome defaults
and relaunching Google Chrome with Glic feature and US variations flags.

Options:
  --dry-run   Print the actions that would be performed without making changes
  --reset     Remove the com.google.Chrome defaults set by this script and
              relaunch Chrome normally
  -h, --help  Show this help message and exit
EOF
}

run_cmd() {
  if [[ "${DRY_RUN}" == "true" ]]; then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

delete_default_if_present() {
  local key="$1"
  if [[ "${DRY_RUN}" == "true" ]]; then
    printf '[dry-run] defaults delete %q %q (if set)\n' "${CHROME_DOMAIN}" "${key}"
    return 0
  fi
  if defaults read "${CHROME_DOMAIN}" "${key}" >/dev/null 2>&1; then
    defaults delete "${CHROME_DOMAIN}" "${key}"
  fi
}

quit_chrome_cleanly() {
  if ! pgrep -x "${CHROME_PROCESS_NAME}" >/dev/null 2>&1; then
    return 0
  fi

  echo "Quitting running Google Chrome cleanly..."
  run_cmd osascript -e 'tell application "Google Chrome" to quit'

  if [[ "${DRY_RUN}" == "true" ]]; then
    return 0
  fi

  local elapsed=0
  while pgrep -x "${CHROME_PROCESS_NAME}" >/dev/null 2>&1; do
    if (( elapsed >= QUIT_TIMEOUT_SECONDS )); then
      echo "Error: Google Chrome did not exit within ${QUIT_TIMEOUT_SECONDS}s. Quit it manually and re-run." >&2
      exit 1
    fi
    sleep 1
    ((elapsed++))
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --reset)
      RESET_MODE=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -d "${CHROME_APP}" ]]; then
  echo "Error: Google Chrome not found at ${CHROME_APP}" >&2
  exit 1
fi

if [[ "${RESET_MODE}" == "true" ]]; then
  echo "Resetting ${CHROME_DOMAIN} Gemini/Glic defaults..."
  for key in \
    GeminiSettings \
    GeminiActOnWebSettings \
    GenAiDefaultSettings \
    GenAILocalFoundationalModelSettings \
    AppleLanguages; do
    delete_default_if_present "${key}"
  done

  quit_chrome_cleanly

  echo "Relaunching Google Chrome normally..."
  run_cmd open -a "${CHROME_APP}"
  echo "Done. Chrome defaults reset."
  exit 0
fi

echo "Configuring ${CHROME_DOMAIN} defaults for Gemini in Chrome..."
# 0 = allow Gemini in Chrome, agentic web actions, generative AI, and local model download
run_cmd defaults write "${CHROME_DOMAIN}" GeminiSettings -int 0
run_cmd defaults write "${CHROME_DOMAIN}" GeminiActOnWebSettings -int 0
run_cmd defaults write "${CHROME_DOMAIN}" GenAiDefaultSettings -int 0
run_cmd defaults write "${CHROME_DOMAIN}" GenAILocalFoundationalModelSettings -int 0

# Gemini in Chrome currently requires Chrome UI language to be en-US
run_cmd defaults write "${CHROME_DOMAIN}" AppleLanguages -array en-US

quit_chrome_cleanly

echo "Launching Google Chrome with Gemini (Glic) flags..."
run_cmd open -a "${CHROME_APP}" --args \
  --enable-features="${CHROME_FEATURES}" \
  --variations-override-country="${VARIATIONS_COUNTRY}"

echo "Done. Google Chrome relaunched with Gemini in Chrome enabled."
