#!/usr/bin/env bash
# =============================================================================
#  AI CLI 一键安装/卸载脚本 (Linux / macOS 版)
#  说明: Windows 请使用 install-ai-cli.ps1 (纯 PowerShell 原生, 不依赖 Git Bash)
#
#  功能:
#   1. 启动时选择语言 (中文 / English), 全程双语输出
#   2. 自动识别运行环境 (Linux / macOS)
#   3. 按「国内 / 国外」分组列出 AI 终端 CLI, 并标注 [已安装]/[未安装]
#   4. 输入编号一键安装; u+编号 一键卸载; 支持批量与 all
#   5. 安装前自动检测依赖 (curl/git/node/npm/python3/pip), 缺失自动补装
#   6. 卸载时定位二进制并删除, 配置目录询问后清理
#
#  用法: bash install-ai-cli.sh
# =============================================================================

set -euo pipefail

C_GREEN='\033[0;32m'; C_YELLOW='\033[1;33m'; C_RED='\033[0;31m'
C_CYAN='\033[0;36m'; C_BOLD='\033[1m'; C_DIM='\033[2m'; C_RESET='\033[0m'

LANG_UI="zh"

# 双语函数: t "中文" "English"
t() { if [ "$LANG_UI" = "zh" ]; then echo "$1"; else echo "$2"; fi; }

info() { echo -e "${C_CYAN}[$(t 信息 Info)]${C_RESET} $*"; }
ok()   { echo -e "${C_GREEN}[$(t 完成 Done)]${C_RESET} $*"; }
warn() { echo -e "${C_YELLOW}[$(t 警告 Warn)]${C_RESET} $*"; }
err()  { echo -e "${C_RED}[$(t 错误 Error)]${C_RESET} $*"; }
step() { echo -e "${C_BOLD}▶ $*${C_RESET}"; }

INSTALL_ROOT="$HOME/.local/ai-cli-toolbox"
NODE_HOME="$INSTALL_ROOT/node"
NODE_VERSION="${NODE_VERSION:-22.12.0}"

has_cmd() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------- 语言选择 --------------------------------
choose_language() {
  echo ""
  echo "  请选择语言 / Choose language:"
  echo "    1. 中文 (Chinese)"
  echo "    2. English"
  echo ""
  read -r -p "  输入 / Enter (1/2, 默认中文 / default 1): " c
  if [ "$c" = "2" ]; then LANG_UI="en"; else LANG_UI="zh"; fi
}

# ---------------------------- 系统识别 --------------------------------
detect_os() {
  case "$(uname -s)" in
    Darwin) OS="macos" ;;
    Linux)  OS="linux" ;;
    *)      OS="windows" ;;   # 兜底, Windows 建议用 PowerShell 版
  esac
}

detect_arch() {
  case "$(uname -m)" in
    arm64|aarch64) ARCH="arm64" ;;
    *)             ARCH="x64" ;;
  esac
}

detect_pkg_manager() {
  PKG=""
  if   has_cmd apt-get; then PKG="apt"
  elif has_cmd dnf;     then PKG="dnf"
  elif has_cmd yum;     then PKG="yum"
  elif has_cmd apk;     then PKG="apk"
  elif has_cmd pacman;  then PKG="pacman"
  elif has_cmd zypper;  then PKG="zypper"
  fi
}

as_root() { if [ "$(id -u)" = "0" ]; then "$@"; else sudo "$@"; fi; }

pkg_install() {
  case "$PKG" in
    apt)    as_root apt-get update -y && as_root apt-get install -y "$@" ;;
    dnf)    as_root dnf install -y "$@" ;;
    yum)    as_root yum install -y "$@" ;;
    apk)    as_root apk add "$@" ;;
    pacman) as_root pacman -S --noconfirm "$@" ;;
    zypper) as_root zypper install -y "$@" ;;
    *) return 1 ;;
  esac
}

extract() {
  local file="$1" dest="$2"
  case "$file" in
    *.tar.xz)      tar -xJf "$file" -C "$dest" ;;
    *.tar.gz|*.tgz) tar -xzf "$file" -C "$dest" ;;
    *) err "$(t '不支持的压缩格式' 'Unsupported archive format'): $file"; return 1 ;;
  esac
}

# ---------------------------- 依赖 --------------------------------
ensure_curl() {
  if has_cmd curl; then return 0; fi
  warn "$(t '未检测到 curl, 正在安装...' 'curl not found, installing...')"; detect_pkg_manager
  if [ "$OS" = "macos" ]; then ensure_brew; brew install curl; else pkg_install curl; fi
}

ensure_git() {
  if has_cmd git; then return 0; fi
  warn "$(t '未检测到 git, 正在安装...' 'git not found, installing...')"; detect_pkg_manager
  if [ "$OS" = "macos" ]; then ensure_brew; brew install git; else pkg_install git; fi
}

ensure_brew() {
  has_cmd brew && return 0
  warn "$(t '未检测到 Homebrew, 正在安装...' 'Homebrew not found, installing...')"
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/null
  if [ -f /opt/homebrew/bin/brew ]; then export PATH="/opt/homebrew/bin:$PATH"
  elif [ -f /usr/local/bin/brew ]; then export PATH="/usr/local/bin:$PATH"; fi
  has_cmd brew || { err "$(t 'Homebrew 安装失败' 'Homebrew install failed')"; return 1; }
}

node_ver() { if has_cmd node; then node --version 2>/dev/null | tr -d 'v'; else echo ""; fi; }

persist_path() {
  local dir="$1" line="export PATH=\"$dir:\$PATH\""
  for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    [ -f "$rc" ] || continue
    grep -qF "$dir" "$rc" 2>/dev/null || echo "$line" >> "$rc"
  done
}

install_node() {
  step "$(t '安装 Node.js' 'Installing Node.js') v${NODE_VERSION} ($(t '用户级' 'user-level'))"
  ensure_curl || return 1
  local pkg
  if [ "$OS" = "macos" ]; then pkg="node-v${NODE_VERSION}-darwin-${ARCH}.tar.gz"
  else pkg="node-v${NODE_VERSION}-linux-${ARCH}.tar.xz"; fi
  local url="https://nodejs.org/dist/v${NODE_VERSION}/${pkg}" tmp="$INSTALL_ROOT/.tmp-node"
  rm -rf "$tmp"; mkdir -p "$tmp"
  info "$(t '下载' 'Downloading') $url"
  curl -fsSL "$url" -o "$tmp/$pkg" || { err "$(t '下载 Node 失败' 'Node download failed')"; return 1; }
  extract "$tmp/$pkg" "$tmp" || return 1
  local top; top="$(find "$tmp" -maxdepth 1 -type d -name 'node-v*' | head -1)"
  [ -n "$top" ] || { err "$(t '未找到解压目录' 'Extracted dir not found')"; return 1; }
  rm -rf "$NODE_HOME"; mkdir -p "$INSTALL_ROOT"
  mv "$top" "$NODE_HOME"; rm -rf "$tmp"
  persist_path "$NODE_HOME/bin"
  export PATH="$NODE_HOME/bin:$PATH"
  ok "$(t 'Node.js 安装完成' 'Node.js installed'): $(node_ver)"
}

ensure_node() {
  local v; v="$(node_ver)"
  if [ -n "$v" ]; then
    local major="${v%%.*}"
    [ "$major" -ge 18 ] && return 0
    warn "$(t 'Node 版本过旧' 'Node version too old') (v${v})"
  else
    warn "$(t '未检测到 Node.js' 'Node.js not found')"
  fi
  install_node
}

ensure_python() {
  if has_cmd python3 && (has_cmd pip3 || python3 -m pip --version >/dev/null 2>&1); then return 0; fi
  warn "$(t '未检测到 Python3/pip, 正在安装...' 'Python3/pip not found, installing...')"
  detect_pkg_manager
  if [ "$OS" = "macos" ]; then ensure_brew; brew install python3; else pkg_install python3 python3-pip; fi
  has_cmd python3 || { err "$(t 'Python3 安装失败' 'Python3 install failed')"; return 1; }
}

# ---------------------------- 卸载辅助 --------------------------------
uninstall_binary() {
  local cmd="$1" p
  p="$(command -v "$cmd" 2>/dev/null || true)"
  if [ -n "$p" ]; then rm -f "$p"; ok "$(t '已删除' 'removed') $cmd: $p"; else warn "$(t '未找到' 'not found') $cmd"; fi
}

clean_config() {
  local d ans
  for d in "$@"; do
    [ -e "$d" ] || continue
    read -r -p "  $(t '是否删除配置目录' 'Delete config directory') $d ? (y/N): " ans
    if [ "$ans" = "y" ] || [ "$ans" = "Y" ]; then rm -rf "$d"; ok "$(t '已删除' 'deleted') $d"; else info "$(t '已保留' 'kept') $d"; fi
  done
}

# 删除整个目录(若存在)
rm_tree() {
  local d
  for d in "$@"; do
    [ -e "$d" ] || continue
    rm -rf "$d"
    [ -e "$d" ] || ok "$(t '已删除目录' 'removed directory') $d"
  done
}

# ---------------------------- 工具定义 --------------------------------
# 格式: id|中文名|英文名|中文厂商|英文厂商|group|检测命令|安装函数|卸载函数
TOOLS=(
  "1|Claude Code|Claude Code|Anthropic|Anthropic|foreign|claude|install_claude_code|uninstall_claude_code"
  "2|Codex CLI|Codex CLI|OpenAI|OpenAI|foreign|codex|install_codex_cli|uninstall_codex_cli"
  "3|Gemini CLI|Gemini CLI|Google|Google|foreign|gemini|install_gemini_cli|uninstall_gemini_cli"
  "4|OpenCode|OpenCode|开源社区|Open Source|foreign|opencode|install_opencode|uninstall_opencode"
  "5|Aider|Aider|开源社区|Open Source|foreign|aider|install_aider|uninstall_aider"
  "6|Goose|Goose|Block(开源)|Block (open source)|foreign|goose|install_goose|uninstall_goose"
  "7|Cline CLI|Cline CLI|Cline(开源)|Cline (open source)|foreign|cline|install_cline_cli|uninstall_cline_cli"
  "8|CodeBuddy Code|CodeBuddy Code|腾讯|Tencent|domestic|codebuddy|install_codebuddy|uninstall_codebuddy"
  "9|Qoder CN 通义灵码|Qoder CN (Tongyi Lingma)|阿里云|Alibaba Cloud|domestic|qoder|install_qoder|uninstall_qoder"
  "10|Kimi Code|Kimi Code|月之暗面|Moonshot AI|domestic|kimi|install_kimi_code|uninstall_kimi_code"
)

# --- 安装函数 ---
install_claude_code() { step "$(t '正在安装' 'Installing') Claude Code"; ensure_curl || return 1; curl -fsSL https://claude.ai/install.sh | bash; }
install_codex_cli()    { step "$(t '正在安装' 'Installing') Codex CLI"; ensure_curl || return 1; curl -fsSL https://chatgpt.com/codex/install.sh | sh; }
install_gemini_cli()   { step "$(t '正在安装' 'Installing') Gemini CLI"; ensure_node || return 1; npm install -g @google/gemini-cli; }
install_opencode()     { step "$(t '正在安装' 'Installing') OpenCode"; ensure_curl || return 1; curl -fsSL https://opencode.ai/install | bash; }
install_aider()        { step "$(t '正在安装' 'Installing') Aider"; ensure_python || return 1; python3 -m pip install --user --upgrade aider-install aider-chat; }
install_goose()        { step "$(t '正在安装' 'Installing') Goose"; ensure_curl || return 1; curl -fsSL https://github.com/block/goose/releases/download/stable/download_cli.sh | bash; }
install_cline_cli()    { step "$(t '正在安装' 'Installing') Cline CLI"; ensure_node || return 1; npm install -g cline; }
install_codebuddy()    { step "$(t '正在安装' 'Installing') CodeBuddy Code"; ensure_curl || return 1; curl -fsSL https://copilot.tencent.com/cli/install.sh | bash; }
install_qoder()        { step "$(t '正在安装' 'Installing') Qoder CN"; ensure_node || return 1; npm install -g qoder-cli; }
install_kimi_code()    { step "$(t '正在安装' 'Installing') Kimi Code"; ensure_curl || return 1; curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash; }

# --- 卸载函数 ---
uninstall_claude_code() { uninstall_binary claude; rm -f "$HOME/.local/bin/claude"* 2>/dev/null || true; rm_tree "$HOME/.local/share/claude"; if has_cmd npm; then npm uninstall -g @anthropic-ai/claude-code 2>/dev/null || true; fi; clean_config "$HOME/.claude" "$HOME/.claude.json"; }
uninstall_codex_cli()   { uninstall_binary codex; rm -f "$HOME/.local/bin/codex"* 2>/dev/null || true; if has_cmd npm; then npm uninstall -g @openai/codex 2>/dev/null || true; fi; clean_config "$HOME/.codex"; }
uninstall_gemini_cli()  { step "$(t '正在卸载' 'Uninstalling') Gemini CLI"; if has_cmd npm; then npm uninstall -g @google/gemini-cli 2>/dev/null || true; fi; uninstall_binary gemini; }
uninstall_opencode()    { step "$(t '正在卸载' 'Uninstalling') OpenCode"; if has_cmd npm; then npm uninstall -g opencode-ai 2>/dev/null || true; fi; uninstall_binary opencode; }
uninstall_aider()       { step "$(t '正在卸载' 'Uninstalling') Aider"; python3 -m pip uninstall -y aider-chat aider-install 2>/dev/null || true; uninstall_binary aider; clean_config "$HOME/.aider"; }
uninstall_goose()       { uninstall_binary goose; rm_tree "$HOME/.config/goose"; clean_config "$HOME/.goose"; }
uninstall_cline_cli()   { step "$(t '正在卸载' 'Uninstalling') Cline CLI"; if has_cmd npm; then npm uninstall -g cline 2>/dev/null || true; fi; uninstall_binary cline; }
uninstall_codebuddy()   { uninstall_binary codebuddy; rm -f "$HOME/.local/bin/codebuddy"* 2>/dev/null || true; rm_tree "$HOME/.codebuddy/bin" "$HOME/.local/share/codebuddy"; if has_cmd npm; then npm uninstall -g @tencent-ai/codebuddy-code 2>/dev/null || true; fi; clean_config "$HOME/.codebuddy"; }
uninstall_qoder()       { step "$(t '正在卸载' 'Uninstalling') Qoder CN"; if has_cmd npm; then npm uninstall -g qoder-cli 2>/dev/null || true; fi; uninstall_binary qoder; }
uninstall_kimi_code()   { uninstall_binary kimi; rm -f "$HOME/.local/bin/kimi"* 2>/dev/null || true; if has_cmd npm; then npm uninstall -g @moonshot-ai/kimi-code 2>/dev/null || true; fi; clean_config "$HOME/.kimi-code"; }

# ---------------------------- 菜单与主流程 --------------------------------
find_tool() {
  local id="$1" t
  for t in "${TOOLS[@]}"; do
    IFS='|' read -r tid _ <<< "$t"
    [ "$tid" = "$id" ] && { echo "$t"; return 0; }
  done
  return 1
}

status_mark() { if has_cmd "$1"; then t '[已安装]' '[installed]'; else t '[未安装]' '[not installed]'; fi; }

print_banner() {
  echo -e "${C_BOLD}${C_CYAN}"
  echo "======================================================"
  echo "   $(t 'AI 终端 CLI 一键安装 / 卸载工具' 'AI CLI One-Click Installer / Uninstaller') ($OS)"
  echo "======================================================"
  echo -e "${C_RESET}$(t '当前系统' 'System'): ${C_BOLD}${OS}${C_RESET}  $(t '架构' 'Arch'): ${C_BOLD}${ARCH}${C_RESET}"
  echo ""
}

print_menu() {
  local t id name_zh name_en vendor_zh vendor_en group cmd name vendor
  echo -e "${C_BOLD}${C_CYAN}—— $(t '国外 (International)' 'International') ——${C_RESET}"
  for t in "${TOOLS[@]}"; do
    IFS='|' read -r id name_zh name_en vendor_zh vendor_en group cmd _ _ <<< "$t"
    [ "$group" = "foreign" ] || continue
    if [ "$LANG_UI" = "zh" ]; then name="$name_zh"; vendor="$vendor_zh"; else name="$name_en"; vendor="$vendor_en"; fi
    printf "  %2s. %-24s (%s) %s\n" "$id" "$name" "$vendor" "$(status_mark "$cmd")"
  done
  echo ""
  echo -e "${C_BOLD}${C_CYAN}—— $(t '国内 (China)' 'China (Domestic)') ——${C_RESET}"
  for t in "${TOOLS[@]}"; do
    IFS='|' read -r id name_zh name_en vendor_zh vendor_en group cmd _ _ <<< "$t"
    [ "$group" = "domestic" ] || continue
    if [ "$LANG_UI" = "zh" ]; then name="$name_zh"; vendor="$vendor_zh"; else name="$name_en"; vendor="$vendor_en"; fi
    printf "  %2s. %-24s (%s) %s\n" "$id" "$name" "$vendor" "$(status_mark "$cmd")"
  done
  echo ""
  echo -e "${C_DIM}  $(t '输入编号安装 (如: 1 3 8) | u+编号卸载 (如: u 2) | all 全装 | q 退出' 'Enter number(s) to install | u+number to uninstall | all | q to quit')${C_RESET}"
}

run_install() {
  local id="$1" t name_zh name_en
  t="$(find_tool "$id")" || { warn "$(t '无效编号' 'Invalid number'): $id"; return; }
  IFS='|' read -r _ name_zh name_en _ _ _ _ ifn _ <<< "$t"
  local name; if [ "$LANG_UI" = "zh" ]; then name="$name_zh"; else name="$name_en"; fi
  echo -e "\n${C_BOLD}════════ $name ════════${C_RESET}"
  if "$ifn"; then ok "$name $(t '安装完成' 'installation complete')"; else err "$name $(t '安装失败' 'installation failed')"; fi
}

run_uninstall() {
  local id="$1" t name_zh name_en cmd ufn
  t="$(find_tool "$id")" || { warn "$(t '无效编号' 'Invalid number'): $id"; return; }
  IFS='|' read -r _ name_zh name_en _ _ _ cmd _ ufn <<< "$t"
  local name; if [ "$LANG_UI" = "zh" ]; then name="$name_zh"; else name="$name_en"; fi
  if ! has_cmd "$cmd"; then warn "$name $(t '未安装, 无需卸载' 'not installed, nothing to uninstall')"; return; fi
  echo -e "\n${C_BOLD}════════ $name ════════${C_RESET}"
  if "$ufn"; then ok "$name $(t '卸载完成' 'uninstall complete')"; else err "$name $(t '卸载失败' 'uninstall failed')"; fi
}

main() {
  choose_language
  detect_os; detect_arch
  [ "$OS" = "windows" ] && warn "$(t '检测到 Windows 环境, 建议改用 install-ai-cli.ps1 (原生 PowerShell 版)' 'Windows detected, please use install-ai-cli.ps1 instead')"
  print_banner
  ensure_curl || exit 1

  while true; do
    print_menu
    echo ""
    read -r -p "$(t '请输入操作' 'Enter an action'): " choice
    [ -z "$choice" ] && continue
    choice="$(echo "$choice" | xargs)"
    [ "$choice" = "q" ] && { info "$(t '已退出' 'Exited')"; break; }

    if [ "$choice" = "all" ]; then
      for t in "${TOOLS[@]}"; do IFS='|' read -r id _ <<< "$t"; run_install "$id"; done
      continue
    fi

    if [[ "$choice" == u* ]]; then
      local ids; ids="${choice#u}"
      for id in $ids; do run_uninstall "$id"; done
      continue
    fi

    for id in $choice; do run_install "$id"; done
  done

  echo -e "\n${C_BOLD}${C_GREEN}════════ $(t '流程结束' 'Finished') ════════${C_RESET}"
  echo -e "${C_DIM}$(t '提示: 安装后请重新打开终端或执行 source ~/.bashrc 使 PATH 生效。' 'Tip: reopen the terminal or run source ~/.bashrc for PATH changes.')${C_RESET}"
}

main "$@"
