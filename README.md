<div align="center">

# ✨ enable-chrome-gemini

**Enable native Gemini in Chrome (Glic) on macOS in one command.**  
*Zero dependencies. No `Local State` JSON hacks. Fully reversible.*

[![macOS](https://img.shields.io/badge/macOS-000000?style=flat-square&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Google Chrome](https://img.shields.io/badge/Chrome-141%2B-4285F4?style=flat-square&logo=googlechrome&logoColor=white)](https://www.google.com/chrome/)
[![Shell](https://img.shields.io/badge/Bash-4EAA25?style=flat-square&logo=gnubash&logoColor=white)](enable-chrome-gemini.sh)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)

[Quick Start](#-quick-start) • [Options](#-options) • [How It Works](#-how-it-works) • [Revert](#-reverting)

</div>

---

## Why?

Gemini in Chrome (`Glic`) is gated by Chrome policies, UI language (`en-US`), and variations country — and manually editing Chrome's `Local State` JSON is fragile, gets overwritten, and often hits macOS TCC (`Operation not permitted`) errors.

`enable-chrome-gemini` takes the clean route: it sets the documented `com.google.Chrome` macOS preferences, switches Chrome's UI language to `en-US`, cleanly quits Chrome, and relaunches it with the native Glic feature and variations flags.

---

## 🚀 Quick Start

### Run directly

```bash
curl -fsSL https://raw.githubusercontent.com/leonsuv/enable-chrome-gemini/main/enable-chrome-gemini.sh | bash
```

### Or clone & run locally

```bash
git clone https://github.com/leonsuv/enable-chrome-gemini.git
cd enable-chrome-gemini
./enable-chrome-gemini.sh
```

Want to preview every command first without touching Chrome?

```bash
./enable-chrome-gemini.sh --dry-run
```

> [!TIP]
> **Make it a one-word command:** Add an alias to your `~/.zshrc` so you can relaunch Chrome with Gemini anytime after a full `Cmd + Q`:
> ```bash
> echo 'alias chrome-gemini="$HOME/dev/enable-chrome-gemini/enable-chrome-gemini.sh"' >> ~/.zshrc
> ```

---

## ⚙️ Options

| Flag | Description |
| :--- | :--- |
| *(none)* | Apply `com.google.Chrome` defaults, quit Chrome cleanly, and relaunch with Gemini enabled. |
| `--dry-run` | Print every command that would run without modifying `defaults` or restarting Chrome. |
| `--reset` | Delete all `com.google.Chrome` keys written by this script and relaunch Chrome normally. |
| `-h`, `--help` | Show usage help and exit. |

---

## 🔍 How It Works

1. **Enables Chrome AI policies** via macOS `defaults write com.google.Chrome`.
2. **Sets Chrome's UI locale** to `en-US` (required for Gemini in Chrome).
3. **Cleanly quits Chrome** via AppleScript (`osascript`) with a 15-second timeout so tabs/sessions close gracefully.
4. **Relaunches Chrome** with Glic feature flags and US variations country enabled.

<details>
<summary><strong>View exact defaults &amp; launch flags</strong></summary>

<br>

**macOS `defaults` (`com.google.Chrome`)**

| Key | Value | Purpose |
| :--- | :--- | :--- |
| `GeminiSettings` | `0` | Allow Gemini in Chrome |
| `GeminiActOnWebSettings` | `0` | Allow Gemini agentic web actions |
| `GenAiDefaultSettings` | `0` | Allow Chrome generative AI features |
| `GenAILocalFoundationalModelSettings` | `0` | Allow local on-device model download |
| `AppleLanguages` | `("en-US")` | Set Chrome UI language to English (US) |

**Chrome Launch Flags**

```bash
open -a "/Applications/Google Chrome.app" --args \
  --enable-features="Glic,GlicSidePanel,GlicUnifiedFreScreen" \
  --variations-override-country="us"
```

</details>

---

## 📋 Requirements & Notes

- **macOS** with **Google Chrome 141+** installed at `/Applications/Google Chrome.app` *(tested on Chrome 158)*.
- A **personal Google Account (18+)** or a **Google Workspace** account with Gemini enabled.

> [!NOTE]
> The `defaults` preferences persist across restarts, while the `--enable-features` and `--variations-override-country` flags apply to the launched session. If you fully quit Chrome (`Cmd + Q`) and reopen it from Dock/Spotlight and Gemini disappears, just run `./enable-chrome-gemini.sh` again.

---

## ↩️ Reverting

To undo all changes made by this script and relaunch Chrome normally:

```bash
./enable-chrome-gemini.sh --reset
```

---

## Disclaimer

This script only uses documented macOS `defaults` preferences and standard Chromium/Chrome launch flags. Feature availability remains subject to Google Chrome's regional rollout, account eligibility, and Google's Terms of Service.

## License

Released under the [MIT License](LICENSE) © 2026 [leonsuv](https://github.com/leonsuv).
