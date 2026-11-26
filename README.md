# enable-chrome-gemini

Enable native Gemini in Chrome (Glic) on macOS with a single script.

[![macOS](https://img.shields.io/badge/macOS-14%2B-111111?style=flat-square)](https://www.apple.com/macos/)
[![Chrome](https://img.shields.io/badge/Chrome-141%2B-111111?style=flat-square)](https://www.google.com/chrome/)
[![License: MIT](https://img.shields.io/badge/license-MIT-111111?style=flat-square)](LICENSE)

## Usage

Run directly from Terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/leonsuv/enable-chrome-gemini/main/enable-chrome-gemini.sh | bash
```

Or clone and run locally:

```bash
git clone https://github.com/leonsuv/enable-chrome-gemini.git
cd enable-chrome-gemini
./enable-chrome-gemini.sh
```

### Options

| Flag | Description |
| :--- | :--- |
| *(none)* | Enable Chrome AI defaults, patch `Local State`, install `~/Applications/Chrome Gemini.app`, and relaunch Chrome. |
| `--dry-run` | Print planned actions without making any changes. |
| `--disable` | Set `GeminiSettings=1` and `GeminiActOnWebSettings=1`, clear Glic flags from `Local State`, remove `Chrome Gemini.app`, and relaunch Chrome. |
| `--reset` | Delete all `com.google.Chrome` defaults added by this script, restore `Local State` from backup, remove `Chrome Gemini.app`, and relaunch Chrome. |
| `-h`, `--help` | Show help and exit. |

## Persistence across `Cmd+Q` and reboots

Chrome's `defaults` persist automatically, while CLI launch flags only apply to the launched session. To keep Gemini active after quitting Chrome or rebooting, the script uses two mechanisms:

1. **`Local State` patch (automatic in Terminal.app):** When run from a terminal with permission to access Chrome's app data directory, the script backs up and updates `~/Library/Application Support/Google/Chrome/Local State` with `variations_country: "us"`, `is_glic_eligible: true`, and the Glic `chrome://flags` entries (`glic@1`, `glic-side-panel@1`, `glic-unified-fre-screen@1`). Regular Google Chrome launches will keep these settings after `Cmd+Q` and reboots.
2. **`~/Applications/Chrome Gemini.app`:** Also installed as a fallback launcher (using Chrome's icon, `LSUIElement=true`) that opens Chrome with the launch flags directly. Useful if macOS blocks `Local State` access in a sandboxed shell.

## What it changes

<details>
<summary>macOS defaults, Local State keys, and launch flags</summary>

**`defaults write com.google.Chrome`**

- `GeminiSettings` = `0`
- `GeminiActOnWebSettings` = `0`
- `GenAiDefaultSettings` = `0`
- `GenAILocalFoundationalModelSettings` = `0`
- `AppleLanguages` = `("en-US")`

**`~/Library/Application Support/Google/Chrome/Local State`**

- `variations_country` = `"us"`
- `variations_permanent_consistency_country` = `["<version>", "us"]`
- `browser.enabled_labs_experiments` += `glic@1`, `glic-side-panel@1`, `glic-unified-fre-screen@1`
- `profile.info_cache.<profile>.is_glic_eligible` = `true`

**Launch flags**

```bash
open -a "/Applications/Google Chrome.app" --args \
  --enable-features="Glic,GlicSidePanel,GlicUnifiedFreScreen" \
  --variations-override-country="us"
```

</details>

## Notes

- **Requirements:** macOS with Google Chrome 141+ at `/Applications/Google Chrome.app` (tested on Chrome 158) and a personal Google Account (18+) or permitted Workspace account.
- **Regional availability:** This script enables Chrome's client-side Gemini UI. The Gemini side panel itself connects to Google's servers, which enforce server-side regional availability based on IP/account location.
- **Disclaimer:** Uses only documented macOS `defaults`, Chrome preferences, and Chromium launch flags. Subject to Google's Terms of Service and regional rollout.

## License

[MIT](LICENSE)
