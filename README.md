<div align="center">

# ✨ enable-chrome-gemini

**Enable native Gemini in Chrome (Glic) on macOS in one command.**  
*Zero dependencies. Persistent launcher app included. Fully reversible.*

[![macOS](https://img.shields.io/badge/macOS-000000?style=flat-square&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Google Chrome](https://img.shields.io/badge/Chrome-141%2B-4285F4?style=flat-square&logo=googlechrome&logoColor=white)](https://www.google.com/chrome/)
[![Shell](https://img.shields.io/badge/Bash-4EAA25?style=flat-square&logo=gnubash&logoColor=white)](enable-chrome-gemini.sh)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)

[Quick Start](#-quick-start) • [Options](#-options) • [How It Works](#-how-it-works) • [Disable / Revert](#-disabling--reverting)

</div>

---

## Why?

Gemini in Chrome (`Glic`) is gated by Chrome policies, UI language (`en-US`), and variations country — and manually editing Chrome's `Local State` JSON is fragile, gets overwritten, and often hits macOS TCC (`Operation not permitted`) errors.

`enable-chrome-gemini` takes the clean route: it sets the documented `com.google.Chrome` macOS preferences, switches Chrome's UI language to `en-US`, installs a persistent **`~/Applications/Chrome Gemini.app`** launcher for reboots, and relaunches Chrome with the native Glic feature and variations flags.

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
> **Persist across reboots:** Running the script automatically creates **`~/Applications/Chrome Gemini.app`**. Open **Chrome Gemini** from Spotlight or drag it to your Dock / Login Items so Chrome always launches with the Gemini flags after a reboot.

---

## ⚙️ Options

| Flag | Description |
| :--- | :--- |
| *(none)* | Apply `com.google.Chrome` defaults, install `~/Applications/Chrome Gemini.app`, quit Chrome cleanly, and relaunch with Gemini enabled. |
| `--dry-run` | Print every command that would run without modifying `defaults`, creating the app, or restarting Chrome. |
| `--disable` | Explicitly disable Gemini in Chrome (`GeminiSettings=1`, `GeminiActOnWebSettings=1`), remove `~/Applications/Chrome Gemini.app`, and relaunch Chrome normally. |
| `--reset` | Delete all `com.google.Chrome` keys and `~/Applications/Chrome Gemini.app`, then relaunch Chrome normally. |
| `-h`, `--help` | Show usage help and exit. |

---

## 🔍 How It Works

1. **Enables Chrome AI policies** via macOS `defaults write com.google.Chrome`.
2. **Sets Chrome's UI locale** to `en-US` (required for Gemini in Chrome).
3. **Installs `~/Applications/Chrome Gemini.app`** — a lightweight launcher bundle (using Chrome's icon, with `LSUIElement=true`) so you can open Chrome with the required flags anytime from Dock or Spotlight.
4. **Cleanly quits & relaunches Chrome** via AppleScript (`osascript`) with Glic feature flags and US variations country enabled.

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

> [!IMPORTANT]
> **Regional availability:** This script unlocks the Gemini in Chrome **client UI** (toolbar button and side panel). However, the Gemini side panel itself connects to Google's servers, which enforce **server-side regional availability** based on your IP/account location. If you are outside a supported rollout region, the side panel will still display *"Gemini in Chrome isn't available"* until Google enables your region.

---

## ↩️ Disabling & Reverting

Explicitly disable Gemini in Chrome and remove `~/Applications/Chrome Gemini.app`:

```bash
./enable-chrome-gemini.sh --disable
```

Or remove all `com.google.Chrome` defaults added by this script and restore Chrome to stock:

```bash
./enable-chrome-gemini.sh --reset
```

---

## Disclaimer

This script only uses documented macOS `defaults` preferences and standard Chromium/Chrome launch flags. Feature availability remains subject to Google Chrome's regional rollout, account eligibility, and Google's Terms of Service.

## License

Released under the [MIT License](LICENSE) © 2026 [leonsuv](https://github.com/leonsuv).
