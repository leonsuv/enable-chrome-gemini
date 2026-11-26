#!/usr/bin/env bash
# enable-chrome-gemini.sh
#
# Enables Gemini in Chrome (Glic) on macOS by configuring com.google.Chrome
# defaults, installing a persistent ~/Applications/Chrome Gemini.app launcher,
# and relaunching Chrome with the required feature and variations flags.

set -euo pipefail

CHROME_DOMAIN="com.google.Chrome"
CHROME_APP="/Applications/Google Chrome.app"
CHROME_PROCESS_NAME="Google Chrome"
QUIT_TIMEOUT_SECONDS=15

LAUNCHER_APP="${HOME}/Applications/Chrome Gemini.app"
CHROME_FEATURES="Glic,GlicSidePanel,GlicUnifiedFreScreen"
VARIATIONS_COUNTRY="us"

DRY_RUN=false
RESET_MODE=false
DISABLE_MODE=false

usage() {
  cat <<'EOF'
Usage: enable-chrome-gemini.sh [OPTIONS]

Enable Gemini in Chrome (Glic) on macOS by setting com.google.Chrome defaults,
creating a persistent ~/Applications/Chrome Gemini.app launcher, and
relaunching Google Chrome with Glic feature and US variations flags.

Options:
  --dry-run   Print the actions that would be performed without making changes
  --disable   Explicitly disable Gemini in Chrome policies, remove the launcher
              app, and relaunch Chrome normally
  --reset     Remove all com.google.Chrome defaults and launcher app created by
              this script, then relaunch Chrome normally
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

install_launcher_app() {
  local contents_dir="${LAUNCHER_APP}/Contents"
  local macos_dir="${contents_dir}/MacOS"
  local resources_dir="${contents_dir}/Resources"
  local exec_path="${macos_dir}/chrome-gemini"
  local plist_path="${contents_dir}/Info.plist"
  local chrome_icon="${CHROME_APP}/Contents/Resources/app.icns"

  echo "Installing persistent launcher at ${LAUNCHER_APP}..."
  if [[ "${DRY_RUN}" == "true" ]]; then
    printf '[dry-run] mkdir -p %q %q\n' "${macos_dir}" "${resources_dir}"
    printf '[dry-run] write %q (Info.plist)\n' "${plist_path}"
    printf '[dry-run] write %q (launcher executable)\n' "${exec_path}"
    if [[ -f "${chrome_icon}" ]]; then
      printf '[dry-run] cp %q %q\n' "${chrome_icon}" "${resources_dir}/app.icns"
    fi
    return 0
  fi

  mkdir -p "${macos_dir}" "${resources_dir}"

  cat > "${plist_path}" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>Chrome Gemini</string>
  <key>CFBundleDisplayName</key>
  <string>Chrome Gemini</string>
  <key>CFBundleIdentifier</key>
  <string>com.leonsuv.chrome-gemini</string>
  <key>CFBundleVersion</key>
  <string>1.0</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleExecutable</key>
  <string>chrome-gemini</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleIconFile</key>
  <string>app.icns</string>
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
EOF

  cat > "${exec_path}" <<EOF
#!/usr/bin/env bash
exec open -a "${CHROME_APP}" --args \\
  --enable-features="${CHROME_FEATURES}" \\
  --variations-override-country="${VARIATIONS_COUNTRY}"
EOF
  chmod +x "${exec_path}"

  if [[ -f "${chrome_icon}" ]]; then
    cp "${chrome_icon}" "${resources_dir}/app.icns"
  fi
}

remove_launcher_app() {
  if [[ "${DRY_RUN}" == "true" ]]; then
    printf '[dry-run] rm -rf %q (if present)\n' "${LAUNCHER_APP}"
    return 0
  fi
  if [[ -d "${LAUNCHER_APP}" ]]; then
    rm -rf "${LAUNCHER_APP}"
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
    --disable)
      DISABLE_MODE=true
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

if [[ "${DISABLE_MODE}" == "true" && "${RESET_MODE}" == "true" ]]; then
  echo "Error: --disable and --reset cannot be used together." >&2
  exit 1
fi

if [[ ! -d "${CHROME_APP}" ]]; then
  echo "Error: Google Chrome not found at ${CHROME_APP}" >&2
  exit 1
fi

if [[ "${DISABLE_MODE}" == "true" ]]; then
  echo "Disabling Gemini in Chrome (${CHROME_DOMAIN}) and removing launcher app..."
  # 1 = disable Gemini in Chrome and agentic web actions
  run_cmd defaults write "${CHROME_DOMAIN}" GeminiSettings -int 1
  run_cmd defaults write "${CHROME_DOMAIN}" GeminiActOnWebSettings -int 1

  remove_launcher_app
  quit_chrome_cleanly

  echo "Relaunching Google Chrome normally..."
  run_cmd open -a "${CHROME_APP}"
  echo "Done. Gemini in Chrome disabled and launcher app removed."
  exit 0
fi

if [[ "${RESET_MODE}" == "true" ]]; then
  echo "Resetting ${CHROME_DOMAIN} Gemini/Glic defaults and launcher app..."
  for key in \
    GeminiSettings \
    GeminiActOnWebSettings \
    GenAiDefaultSettings \
    GenAILocalFoundationalModelSettings \
    AppleLanguages; do
    delete_default_if_present "${key}"
  done

  remove_launcher_app
  quit_chrome_cleanly

  echo "Relaunching Google Chrome normally..."
  run_cmd open -a "${CHROME_APP}"
  echo "Done. Chrome defaults and launcher app removed."
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

install_launcher_app
quit_chrome_cleanly

echo "Launching Google Chrome with Gemini (Glic) flags..."
run_cmd open -a "${CHROME_APP}" --args \
  --enable-features="${CHROME_FEATURES}" \
  --variations-override-country="${VARIATIONS_COUNTRY}"

echo "Done. Chrome relaunched and persistent launcher installed at ${LAUNCHER_APP}."
echo "Tip: Launch \"Chrome Gemini\" from Spotlight or pin it to your Dock to keep flags active after reboots."
