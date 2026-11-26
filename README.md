# enable-chrome-gemini

[![macOS](https://img.shields.io/badge/platform-macOS-black?logo=apple)](https://www.apple.com/macos/)
[![Google Chrome](https://img.shields.io/badge/Google%20Chrome-141%2B-4285F4?logo=googlechrome&logoColor=white)](https://www.google.com/chrome/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A lightweight, single-file Bash utility to enable **Gemini in Chrome (Glic)** on macOS by configuring `com.google.Chrome` defaults and relaunching Chrome with the required feature and variations flags.

## Quick Start

```bash
git clone https://github.com/leonsuv/enable-chrome-gemini.git
cd enable-chrome-gemini
./enable-chrome-gemini.sh
```

Or run directly after downloading:

```bash
chmod +x enable-chrome-gemini.sh
./enable-chrome-gemini.sh
```

## CLI Options

| Option | Description |
| :--- | :--- |
| `--dry-run` | Print every command that would run without modifying `defaults` or restarting Chrome. |
| `--reset` | Delete the `com.google.Chrome` keys written by this script and relaunch Chrome normally. |
| `-h`, `--help` | Display usage information and exit. |

## What It Does

| Step | Target / Flag | Value | Purpose |
| :--- | :--- | :--- | :--- |
| Policy | `GeminiSettings` | `0` | Allows Gemini in Chrome integration. |
| Policy | `GeminiActOnWebSettings` | `0` | Allows agentic web actions in Gemini. |
| Policy | `GenAiDefaultSettings` | `0` | Allows Chrome generative AI features. |
| Policy | `GenAILocalFoundationalModelSettings` | `0` | Allows local on-device model download. |
| Locale | `AppleLanguages` | `("en-US")` | Sets Chrome UI language to English (US). |
| Restart | `osascript` quit | `15s` timeout | Cleanly quits Chrome if currently running. |
| Launch | `--enable-features` | `Glic,GlicSidePanel,GlicUnifiedFreScreen` | Enables Glic UI, side panel, and first-run experience. |
| Launch | `--variations-override-country` | `us` | Overrides variations country to `us` for the session. |

## Requirements

- **macOS** with **Google Chrome** installed at `/Applications/Google Chrome.app` (Chrome 141+ recommended; tested on Chrome 158).
- A **personal Google Account** (18+) or a **Google Workspace** account where Gemini in Chrome is permitted.

## Persistence & Troubleshooting

- **`defaults` persist across launches**, while `--enable-features` and `--variations-override-country` apply to the launched Chrome session. If you quit Chrome and reopen it normally from Dock/Spotlight later, re-run `./enable-chrome-gemini.sh` to relaunch with the CLI flags.
- **No `Local State` file edits needed:** This script avoids touching `~/Library/Application Support/Google/Chrome/Local State`, which is protected by macOS TCC permissions in many terminal/agent environments.
- **Reverting:** Run `./enable-chrome-gemini.sh --reset` to remove all `com.google.Chrome` keys added by this script and restart Chrome cleanly.

## Disclaimer

This script only uses documented macOS `defaults` preferences and standard Chrome launch flags. Feature availability remains subject to Google Chrome's regional rollout, account eligibility, and Google's Terms of Service.

## License

[MIT](LICENSE) © 2026 [leonsuv](https://github.com/leonsuv)
