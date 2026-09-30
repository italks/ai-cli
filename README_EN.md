# AI CLI One-Click Installer / Uninstaller

A cross-platform command-line tool that helps you quickly install and manage mainstream AI terminal (CLI) coding assistants. On launch it auto-detects your operating system, lists available tools grouped by **Domestic (China) / International**, shows their install status, and then — once you pick one — automatically handles dependency detection, dependency installation, and tool installation. One-click uninstall is also supported.

---

## Features

- 🖥️ **Auto OS detection**: Detects the running environment (Windows / macOS / Linux) and CPU architecture on startup
- 🌍 **Domestic / International grouping**: Presents 10 mainstream AI CLI tools in two clear groups
- ✅ **Install status detection**: Each tool is tagged `[installed]` / `[not installed]` in real time
- 📦 **One-click install**: Install by number; supports multiple selection (`1 3 8`) and install-all (`all`)
- 🗑️ **One-click uninstall**: `u + number` to uninstall, with precise handling of npm / pip / native-binary installs
- 🔧 **Automatic dependency bootstrap**: Detects curl / git / Node.js / npm / Python / pip before installing, and installs anything missing
- 🔒 **User-level install**: Dependencies like Node are installed to the user directory where possible — no admin rights needed, no system pollution

---

## Supported Tools

### International

| # | Tool | Vendor |
|---|---|---|
| 1 | Claude Code | Anthropic |
| 2 | Codex CLI | OpenAI |
| 3 | Gemini CLI | Google |
| 4 | OpenCode | Open Source |
| 5 | Aider | Open Source |
| 6 | Goose | Block (open source) |
| 7 | Cline CLI | Cline (open source) |

### China (Domestic)

| # | Tool | Vendor |
|---|---|---|
| 8 | CodeBuddy Code | Tencent |
| 9 | Qoder CN (Tongyi Lingma) | Alibaba Cloud |
| 10 | Kimi Code | Moonshot AI |

---

## How to Run on Each Platform

### Windows (native PowerShell, no Git Bash required)

**Option 1: Double-click**

Simply double-click `install-ai-cli.bat`.

**Option 2: Command line**

Run in PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\install-ai-cli.ps1
```

Or right-click `install-ai-cli.ps1` → "Run with PowerShell".

> Prerequisites:
> - Windows 10 / 11 ships with PowerShell and `curl.exe`
> - `winget` (bundled since Windows 10 1809+) is used to auto-install Node.js / Python; if `winget` is absent, the script falls back to downloading official binaries
> - Installing **Kimi Code** additionally requires [Git for Windows](https://git-scm.com/download/win) (that tool itself depends on Git Bash as its runtime shell)

### macOS

Open Terminal, `cd` into the script directory, then run:

```bash
bash install-ai-cli.sh
```

> Prerequisites: curl is bundled with macOS; if Homebrew is missing it will be auto-installed, and Node.js / Python are bootstrapped via Homebrew.

### Linux

Open a terminal, `cd` into the script directory, then run:

```bash
bash install-ai-cli.sh
```

> Prerequisites: the script auto-detects `apt` / `dnf` / `yum` / `apk` / `pacman` package managers; installing system-level dependencies (curl / git / python) requires sudo privileges.

---

## Usage

After launching, the script shows a menu like:

```
—— 国外 (International) ——
   1. Claude Code          (Anthropic) [未安装]
   2. Codex CLI            (OpenAI)    [未安装]
   ...

—— 国内 (China) ——
   8. CodeBuddy Code       (腾讯)       [未安装]
   ...

  输入编号安装 (如: 1 3 8) | u+编号卸载 (如: u 2) | all 全装 | q 退出
```

| Action | Example | Description |
|---|---|---|
| Install one / several | `1 3 8` | Install multiple tools at once, space-separated |
| Install all | `all` | Install all 10 tools |
| Uninstall | `u 2 5` | `u` + number(s) to uninstall |
| Quit | `q` | Exit the script |

---

## Uninstall Behavior

The script uninstalls precisely according to how each tool was installed:

- **npm installs** (Gemini CLI, OpenCode, Cline CLI, Qoder CN): runs `npm uninstall -g`
- **pip installs** (Aider): runs `pip uninstall`
- **Native binary installs** (Claude Code, Codex, Goose, CodeBuddy Code, Kimi Code): locates and deletes the executable

During uninstall it asks whether to also remove config directories (e.g. `~\.claude`, `~\.codex`). They are **kept by default** to avoid deleting your API keys and session history.

---

## Notes

1. After installation, **reopen the terminal** (or run `source ~/.bashrc`) for PATH changes to take effect.
2. Each tool still requires **manual login / API-key setup on first run** — the script cannot complete account authorization for you.
3. Some tools (e.g. Claude Code) require a paid subscription or API credits; a successful install does not mean instant usability.
4. The script installs over the network; if your environment cannot reach overseas domains, configure a proxy for the terminal.

---

## Directory Structure

```
.
├── install-ai-cli.ps1   # Native PowerShell for Windows (recommended)
├── install-ai-cli.bat   # Double-click entry point for Windows
└── install-ai-cli.sh    # bash version for Linux / macOS
```
