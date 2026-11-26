#!/usr/bin/env bash
# enable-chrome-gemini.sh
#
# Enables Gemini in Chrome (Glic) on macOS by configuring com.google.Chrome
# defaults, backing up /Applications/Google Chrome.app, and installing a
# transparent wrapper at /Applications/Google Chrome.app that launches the
# original Chrome bundle with the required feature and variations flags.

set -euo pipefail

CHROME_DOMAIN="com.google.Chrome"
CHROME_APP="/Applications/Google Chrome.app"
CHROME_BACKUP_APP="/Applications/.Google Chrome Original.app"
WRAPPER_MARKER="${CHROME_APP}/Contents/.enable-chrome-gemini-wrapper"
LEGACY_LAUNCHER_APP="${HOME}/Applications/Chrome Gemini.app"
CHROME_PROCESS_NAME="Google Chrome"
QUIT_TIMEOUT_SECONDS=15

CHROME_FEATURES="Glic,GlicSidePanel,GlicUnifiedFreScreen"
VARIATIONS_COUNTRY="us"

DRY_RUN=false
RESET_MODE=false
DISABLE_MODE=false

usage() {
  cat <<'EOF'
Usage: enable-chrome-gemini.sh [OPTIONS]

Enable Gemini in Chrome (Glic) on macOS persistently across Cmd+Q and reboots
by backing up /Applications/Google Chrome.app to
/Applications/.Google Chrome Original.app and installing a launcher wrapper at
/Applications/Google Chrome.app.

Options:
  --dry-run   Print planned actions without modifying apps, defaults, or Chrome
  --disable   Disable Gemini in Chrome policies, restore the original
              /Applications/Google Chrome.app, and relaunch Chrome normally
  --reset     Remove all defaults added by this script, restore the original
              /Applications/Google Chrome.app, and relaunch Chrome normally
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

is_wrapper_installed() {
  [[ -f "${WRAPPER_MARKER}" && -d "${CHROME_BACKUP_APP}" ]]
}

install_wrapper_app() {
  local contents_dir="${CHROME_APP}/Contents"
  local macos_dir="${contents_dir}/MacOS"
  local resources_dir="${contents_dir}/Resources"
  local exec_path="${macos_dir}/Google Chrome"
  local plist_path="${contents_dir}/Info.plist"
  local chrome_icon="${CHROME_BACKUP_APP}/Contents/Resources/app.icns"

  if is_wrapper_installed; then
    echo "Wrapper already installed; updating ${CHROME_APP}..."
  else
    if [[ -d "${CHROME_BACKUP_APP}" ]]; then
      echo "Error: Backup already exists at ${CHROME_BACKUP_APP}, but ${CHROME_APP} is not a wrapper." >&2
      echo "       Refusing to overwrite backup. Inspect /Applications manually." >&2
      exit 1
    fi
    echo "Backing up ${CHROME_APP} -> ${CHROME_BACKUP_APP}..."
    run_cmd mv "${CHROME_APP}" "${CHROME_BACKUP_APP}"
  fi

  echo "Installing wrapper at ${CHROME_APP}..."
  if [[ "${DRY_RUN}" == "true" ]]; then
    printf '[dry-run] mkdir -p %q %q\n' "${macos_dir}" "${resources_dir}"
    printf '[dry-run] write %q (Info.plist)\n' "${plist_path}"
    printf '[dry-run] write %q (wrapper executable)\n' "${exec_path}"
    printf '[dry-run] cp %q %q\n' "${chrome_icon}" "${resources_dir}/app.icns"
    printf '[dry-run] touch %q\n' "${WRAPPER_MARKER}"
    return 0
  fi

  rm -rf "${CHROME_APP}"
  mkdir -p "${macos_dir}" "${resources_dir}"

  cat > "${plist_path}" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>Google Chrome</string>
  <key>CFBundleDisplayName</key>
  <string>Google Chrome</string>
  <key>CFBundleIdentifier</key>
  <string>com.leonsuv.chrome-gemini-wrapper</string>
  <key>CFBundleVersion</key>
  <string>1.0</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleExecutable</key>
  <string>Google Chrome</string>
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
exec open -a "${CHROME_BACKUP_APP}" --args \\
  --enable-features="${CHROME_FEATURES}" \\
  --variations-override-country="${VARIATIONS_COUNTRY}" \\
  "\$@"
EOF
  chmod +x "${exec_path}"

  if [[ -f "${chrome_icon}" ]]; then
    cp "${chrome_icon}" "${resources_dir}/app.icns"
  fi

  touch "${WRAPPER_MARKER}"
  touch "${CHROME_APP}"

  if [[ -d "${LEGACY_LAUNCHER_APP}" ]]; then
    rm -rf "${LEGACY_LAUNCHER_APP}"
  fi
}

restore_original_app() {
  if is_wrapper_installed; then
    echo "Restoring ${CHROME_BACKUP_APP} -> ${CHROME_APP}..."
    run_cmd rm -rf "${CHROME_APP}"
    run_cmd mv "${CHROME_BACKUP_APP}" "${CHROME_APP}"
    if [[ "${DRY_RUN}" != "true" ]]; then
      touch "${CHROME_APP}"
    fi
  elif [[ -d "${CHROME_BACKUP_APP}" ]]; then
    echo "Warning: ${CHROME_BACKUP_APP} exists but ${CHROME_APP} is not marked as a wrapper; leaving both untouched." >&2
  fi

  if [[ -d "${LEGACY_LAUNCHER_APP}" ]]; then
    run_cmd rm -rf "${LEGACY_LAUNCHER_APP}"
  fi
}

quit_chrome_cleanly() {
  if ! pgrep -x "${CHROME_PROCESS_NAME}" >/dev/null 2>&1; then
    return 0
  fi

  echo "Quitting Google Chrome..."
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

if [[ ! -d "${CHROME_APP}" && ! -d "${CHROME_BACKUP_APP}" ]]; then
  echo "Error: Google Chrome not found at ${CHROME_APP}" >&2
  exit 1
fi

if [[ "${DISABLE_MODE}" == "true" ]]; then
  echo "Disabling Gemini in Chrome..."
  run_cmd defaults write "${CHROME_DOMAIN}" GeminiSettings -int 1
  run_cmd defaults write "${CHROME_DOMAIN}" GeminiActOnWebSettings -int 1

  quit_chrome_cleanly
  restore_original_app

  echo "Relaunching Google Chrome..."
  run_cmd open -a "${CHROME_APP}"
  echo "Done."
  exit 0
fi

if [[ "${RESET_MODE}" == "true" ]]; then
  echo "Resetting Chrome Gemini configuration..."
  for key in \
    GeminiSettings \
    GeminiActOnWebSettings \
    GenAiDefaultSettings \
    GenAILocalFoundationalModelSettings \
    AppleLanguages; do
    delete_default_if_present "${key}"
  done

  quit_chrome_cleanly
  restore_original_app

  echo "Relaunching Google Chrome..."
  run_cmd open -a "${CHROME_APP}"
  echo "Done."
  exit 0
fi

echo "Configuring ${CHROME_DOMAIN} defaults..."
run_cmd defaults write "${CHROME_DOMAIN}" GeminiSettings -int 0
run_cmd defaults write "${CHROME_DOMAIN}" GeminiActOnWebSettings -int 0
run_cmd defaults write "${CHROME_DOMAIN}" GenAiDefaultSettings -int 0
run_cmd defaults write "${CHROME_DOMAIN}" GenAILocalFoundationalModelSettings -int 0
run_cmd defaults write "${CHROME_DOMAIN}" AppleLanguages -array en-US

quit_chrome_cleanly
install_wrapper_app

echo "Launching Google Chrome with Gemini (Glic) flags..."
run_cmd open -a "${CHROME_APP}"
echo "Done."
