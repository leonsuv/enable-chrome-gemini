#!/usr/bin/env bash
# enable-chrome-gemini.sh
#
# Enables Gemini in Chrome (Glic) on macOS by configuring com.google.Chrome
# defaults, patching Chrome's Local State (when permitted), installing a
# persistent ~/Applications/Chrome Gemini.app launcher, and relaunching Chrome.

set -euo pipefail

CHROME_DOMAIN="com.google.Chrome"
CHROME_APP="/Applications/Google Chrome.app"
CHROME_PROCESS_NAME="Google Chrome"
CHROME_LOCAL_STATE="${HOME}/Library/Application Support/Google/Chrome/Local State"
LOCAL_STATE_BACKUP="${CHROME_LOCAL_STATE}.enable-chrome-gemini.bak"
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

Enable Gemini in Chrome (Glic) on macOS.

Options:
  --dry-run   Print planned actions without modifying files, defaults, or Chrome
  --disable   Disable Gemini in Chrome policies, revert Local State flags,
              remove Chrome Gemini.app, and relaunch Chrome normally
  --reset     Remove all defaults and launcher app added by this script,
              restore Local State, and relaunch Chrome normally
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

patch_local_state() {
  local mode="$1" # enable | disable | reset
  if [[ "${DRY_RUN}" == "true" ]]; then
    printf '[dry-run] patch %q (mode=%s, if accessible)\n' "${CHROME_LOCAL_STATE}" "${mode}"
    return 0
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "Note: python3 not found; skipping Local State patch."
    return 0
  fi

  if [[ ! -r "${CHROME_LOCAL_STATE}" || ! -w "${CHROME_LOCAL_STATE}" ]]; then
    echo "Note: Cannot access ${CHROME_LOCAL_STATE} (macOS app data permission)."
    echo "      Run this script from Terminal.app (and allow access) to persist across normal Chrome launches,"
    echo "      or launch Chrome using ${LAUNCHER_APP}."
    return 0
  fi

  if [[ "${mode}" == "enable" && ! -f "${LOCAL_STATE_BACKUP}" ]]; then
    cp "${CHROME_LOCAL_STATE}" "${LOCAL_STATE_BACKUP}"
  fi

  python3 - "${CHROME_LOCAL_STATE}" "${LOCAL_STATE_BACKUP}" "${mode}" "${VARIATIONS_COUNTRY}" <<'PY'
import json, os, sys

path, backup_path, mode, country = sys.argv[1:5]
glic_labs = {"glic@1", "glic-side-panel@1", "glic-unified-fre-screen@1"}

with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

browser = data.setdefault("browser", {})
labs = list(browser.get("enabled_labs_experiments", []))
profiles = data.get("profile", {}).get("info_cache", {})

if mode == "enable":
    data["variations_country"] = country
    vpcc = data.get("variations_permanent_consistency_country")
    if isinstance(vpcc, list) and len(vpcc) >= 2:
        data["variations_permanent_consistency_country"] = [vpcc[0], country]
    else:
        data["variations_permanent_consistency_country"] = ["", country]

    for lab in sorted(glic_labs):
        if lab not in labs:
            labs.append(lab)
    browser["enabled_labs_experiments"] = labs

    for p in profiles.values():
        if isinstance(p, dict):
            p["is_glic_eligible"] = True

elif mode in ("disable", "reset"):
    browser["enabled_labs_experiments"] = [x for x in labs if x not in glic_labs]

    if mode == "disable":
        for p in profiles.values():
            if isinstance(p, dict):
                p["is_glic_eligible"] = False
    elif mode == "reset":
        if os.path.exists(backup_path):
            with open(backup_path, "r", encoding="utf-8") as bf:
                orig = json.load(bf)
            for key in ("variations_country", "variations_permanent_consistency_country"):
                if key in orig:
                    data[key] = orig[key]
                else:
                    data.pop(key, None)
            orig_profiles = orig.get("profile", {}).get("info_cache", {})
            for name, p in profiles.items():
                if isinstance(p, dict):
                    if name in orig_profiles and "is_glic_eligible" in orig_profiles[name]:
                        p["is_glic_eligible"] = orig_profiles[name]["is_glic_eligible"]
                    else:
                        p.pop("is_glic_eligible", None)
        else:
            data.pop("variations_country", None)
            data.pop("variations_permanent_consistency_country", None)

tmp_path = path + ".tmp"
with open(tmp_path, "w", encoding="utf-8") as f:
    json.dump(data, f, separators=(",", ":"))
os.replace(tmp_path, path)
PY

  if [[ "${mode}" == "reset" && -f "${LOCAL_STATE_BACKUP}" ]]; then
    rm -f "${LOCAL_STATE_BACKUP}"
  fi
  echo "Updated ${CHROME_LOCAL_STATE} (${mode})."
}

install_launcher_app() {
  local contents_dir="${LAUNCHER_APP}/Contents"
  local macos_dir="${contents_dir}/MacOS"
  local resources_dir="${contents_dir}/Resources"
  local exec_path="${macos_dir}/chrome-gemini"
  local plist_path="${contents_dir}/Info.plist"
  local chrome_icon="${CHROME_APP}/Contents/Resources/app.icns"

  echo "Installing launcher at ${LAUNCHER_APP}..."
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

if [[ ! -d "${CHROME_APP}" ]]; then
  echo "Error: Google Chrome not found at ${CHROME_APP}" >&2
  exit 1
fi

if [[ "${DISABLE_MODE}" == "true" ]]; then
  echo "Disabling Gemini in Chrome..."
  run_cmd defaults write "${CHROME_DOMAIN}" GeminiSettings -int 1
  run_cmd defaults write "${CHROME_DOMAIN}" GeminiActOnWebSettings -int 1

  quit_chrome_cleanly
  patch_local_state disable
  remove_launcher_app

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
  patch_local_state reset
  remove_launcher_app

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
patch_local_state enable
install_launcher_app

echo "Launching Google Chrome with Gemini (Glic) flags..."
run_cmd open -a "${CHROME_APP}" --args \
  --enable-features="${CHROME_FEATURES}" \
  --variations-override-country="${VARIATIONS_COUNTRY}"

echo "Done."
