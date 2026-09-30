# AI CLI 一键安装 / 卸载工具

一个跨平台的命令行工具，帮助你快速安装和管理主流的 AI 终端（CLI）编程助手。启动后自动识别操作系统，按「国内 / 国外」分组展示可用工具，标注已安装状态，选定后全自动完成依赖检测、依赖安装与工具安装；同时支持一键卸载。

---

## 🚀 一键运行（无需下载仓库）

不用 clone 仓库，直接复制下面命令到终端即可运行：

**Windows（PowerShell）**

```powershell
irm https://raw.githubusercontent.com/italks/ai-cli/main/install-ai-cli.ps1 | iex
```

**Linux / macOS**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/italks/ai-cli/main/install-ai-cli.sh)
```

> 若访问 GitHub 较慢或超时，请先为终端配置代理，再执行上述命令。

---

## 功能特性

- 🖥️ **自动识别系统**：启动即识别当前运行环境（Windows / macOS / Linux）与 CPU 架构
- 🌍 **国内外分组**：按「国外 / 国内」清晰分组展示 10 款主流 AI CLI 工具
- ✅ **安装状态检测**：每个工具实时标注 `[已安装]` / `[未安装]`
- 📦 **一键安装**：输入编号即可安装，支持多选（`1 3 8`）与全装（`all`）
- 🗑️ **一键卸载**：`u + 编号` 卸载，精准区分 npm / pip / 原生二进制三种安装方式
- 🔧 **依赖自动补装**：安装前自动检测 curl / git / Node.js / npm / Python / pip，缺失自动安装
- 🔒 **用户级安装**：Node 等依赖尽量装到用户目录，免管理员权限，不污染系统

---

## 支持的工具

### 国外（International）

| 编号 | 工具 | 厂商 |
|---|---|---|
| 1 | Claude Code | Anthropic |
| 2 | Codex CLI | OpenAI |
| 3 | Gemini CLI | Google |
| 4 | OpenCode | 开源社区 |
| 5 | Aider | 开源社区 |
| 6 | Goose | Block（开源） |
| 7 | Cline CLI | Cline（开源） |

### 国内（China）

| 编号 | 工具 | 厂商 |
|---|---|---|
| 8 | CodeBuddy Code | 腾讯 |
| 9 | Qoder CN 通义灵码 | 阿里云 |
| 10 | Kimi Code | 月之暗面 |

---

## 各系统运行方式

### Windows（原生 PowerShell，不依赖 Git Bash）

**方式一：双击运行**

直接双击 `install-ai-cli.bat` 即可。

**方式二：命令行运行**

在 PowerShell 中执行（用 `-Encoding UTF8` 读取以保证中文正常显示）：

```powershell
Get-Content -Raw -Encoding UTF8 .\install-ai-cli.ps1 | Invoke-Expression
```

> 说明：脚本为无 BOM 的 UTF-8 编码。若直接用 `powershell -File` 运行，PowerShell 5.1 可能按系统默认编码读取而导致中文乱码，故推荐上述 `Get-Content -Encoding UTF8` 方式，或直接使用一键命令（见文首）。

> 前置要求：
> - Windows 10 / 11 自带 PowerShell 与 `curl.exe`
> - `winget`（Windows 10 1809+ 自带）用于自动安装 Node.js / Python；若无 winget，脚本会改用下载官方二进制的方式
> - 安装 **Kimi Code** 需额外安装 [Git for Windows](https://git-scm.com/download/win)（该工具自身依赖 Git Bash 作为运行 shell）

### macOS

打开「终端」，进入脚本所在目录，执行：

```bash
bash install-ai-cli.sh
```

> 前置要求：系统自带 curl；若缺少 Homebrew 会自动安装，Node.js / Python 通过 Homebrew 自动补装。

### Linux

打开终端，进入脚本所在目录，执行：

```bash
bash install-ai-cli.sh
```

> 前置要求：脚本会自动识别 `apt` / `dnf` / `yum` / `apk` / `pacman` 等包管理器；安装系统级依赖（curl / git / python）时需要 sudo 权限。

---

## 使用说明

脚本启动后会显示类似如下菜单：

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

| 操作 | 输入示例 | 说明 |
|---|---|---|
| 安装单个/多个 | `1 3 8` | 一次安装多个，用空格分隔 |
| 全量安装 | `all` | 安装全部 10 款工具 |
| 卸载 | `u 2 5` | `u` + 编号，卸载对应工具 |
| 退出 | `q` | 结束脚本 |

---

## 卸载说明

脚本会根据工具的安装方式精准卸载：

- **npm 安装**（Gemini CLI、OpenCode、Cline CLI、Qoder CN）：执行 `npm uninstall -g`
- **pip 安装**（Aider）：执行 `pip uninstall`
- **原生二进制安装**（Claude Code、Codex、Goose、CodeBuddy Code、Kimi Code）：定位并删除可执行文件

卸载时会询问是否一并清理配置目录（如 `~\.claude`、`~\.codex` 等），**默认保留**，避免误删你的 API Key 与历史会话。

---

## 注意事项

1. 安装完成后请**重新打开终端**（或执行 `source ~/.bashrc`），使 PATH 生效。
2. 各工具**首次运行仍需自行登录 / 配置 API Key**，脚本无法代为完成账号授权。
3. 部分工具（如 Claude Code）需要付费订阅或 API 额度，安装成功不代表可直接使用。
4. 脚本为普通网络安装，若所在网络无法访问国外域名，请为终端配置代理。

---

## 目录结构

```
.
├── install-ai-cli.ps1   # Windows 原生 PowerShell 版（推荐 Windows 用户使用）
├── install-ai-cli.bat   # Windows 双击入口
└── install-ai-cli.sh    # Linux / macOS bash 版
```
