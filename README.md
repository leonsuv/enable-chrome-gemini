# enable-chrome-gemini

Enable native Gemini in Chrome (Glic) on macOS persistently across `Cmd+Q` and reboots.

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
| *(none)* | Enable Chrome AI defaults, back up `/Applications/Google Chrome.app`, install the wrapper app, and relaunch Chrome. |
| `--dry-run` | Print planned actions without making any changes. |
| `--disable` | Set `GeminiSettings=1` and `GeminiActOnWebSettings=1`, restore the original `Google Chrome.app`, and relaunch Chrome. |
| `--reset` | Delete all `com.google.Chrome` defaults added by this script, restore the original `Google Chrome.app`, and relaunch Chrome. |
| `-h`, `--help` | Show help and exit. |

## How it persists across `Cmd+Q` and reboots

1. Moves `/Applications/Google Chrome.app` to `/Applications/.Google Chrome Original.app` (hidden from Finder, Spotlight, and Launchpad).
2. Installs a lightweight wrapper bundle at `/Applications/Google Chrome.app` (with Chrome's icon and `LSUIElement=true`) that launches `/Applications/.Google Chrome Original.app` with the Glic and US variations flags.
3. Every normal launch of **Google Chrome** from the Dock, Spotlight, or Login Items automatically passes the flags.

Running `--disable` or `--reset` deletes the wrapper and moves `/Applications/.Google Chrome Original.app` right back to `/Applications/Google Chrome.app`.

## What it changes

<details>
<summary>macOS defaults, app wrapper, and launch flags</summary>

**`defaults write com.google.Chrome`**

- `GeminiSettings` = `0`
- `GeminiActOnWebSettings` = `0`
- `GenAiDefaultSettings` = `0`
- `GenAILocalFoundationalModelSettings` = `0`
- `AppleLanguages` = `("en-US")`

**App wrapper**

- Original app moved to `/Applications/.Google Chrome Original.app`
- Wrapper installed at `/Applications/Google Chrome.app`
- Marker file at `/Applications/Google Chrome.app/Contents/.enable-chrome-gemini-wrapper` (prevents overwriting the backup on re-runs)

**Launch flags**

```bash
open -a "/Applications/.Google Chrome Original.app" --args \
  --enable-features="Glic,GlicSidePanel,GlicUnifiedFreScreen" \
  --variations-override-country="us"
```

</details>

## Notes

- **Requirements:** macOS with Google Chrome 141+ at `/Applications/Google Chrome.app` (tested on Chrome 158) and a personal Google Account (18+) or permitted Workspace account.
- **Chrome updates:** Before running a major Chrome update (or if Chrome's updater complains), run `./enable-chrome-gemini.sh --reset`, update Chrome, then re-run `./enable-chrome-gemini.sh`.
- **Regional availability:** This script enables Chrome's client-side Gemini UI. The Gemini side panel itself connects to Google's servers, which enforce server-side regional availability based on IP/account location.
- **Disclaimer:** Uses only documented macOS `defaults` and Chromium launch flags. Subject to Google's Terms of Service and regional rollout.

## License

[MIT](LICENSE)
