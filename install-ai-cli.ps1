# =============================================================================
#  AI CLI 一键安装/卸载脚本 (Windows 原生 PowerShell 版)
#  完全使用 Windows 原生能力, 不依赖 Git Bash / WSL
#
#  功能:
#   1. 启动时选择语言 (中文 / English), 全程双语输出
#   2. 按「国内 / 国外」分组列出 10 款 AI 终端 CLI, 并标注已安装/未安装状态
#   3. 输入编号一键安装; 输入 u + 编号一键卸载; 支持批量与 all
#   4. 安装前自动检测依赖 (winget / node / npm / python / curl), 缺失自动补装
#   5. 彻底卸载: 删二进制 + 删专属目录 + npm/winget 兜底 + 清理用户 PATH + 询问清理配置
#
#  用法:
#   右键 "使用 PowerShell 运行", 或:
#   powershell -ExecutionPolicy Bypass -File install-ai-cli.ps1
#   双击 install-ai-cli.bat 亦可
# =============================================================================

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Script:NodeVersion = '22.12.0'
$Script:Toolbox = Join-Path $env:LOCALAPPDATA 'ai-cli-toolbox'
$Script:Lang = 'zh'

# ---------------------------- 多语言字符串表 ----------------------------
$Script:Text = @{
  'info'            = @{ zh='信息'; en='Info' }
  'done'            = @{ zh='完成'; en='Done' }
  'warn'            = @{ zh='警告'; en='Warn' }
  'error'           = @{ zh='错误'; en='Error' }
  'banner_title'    = @{ zh='AI 终端 CLI 一键安装 / 卸载工具 (Windows)'; en='AI CLI One-Click Installer / Uninstaller (Windows)' }
  'os_info'         = @{ zh='当前系统'; en='System' }
  'grp_foreign'     = @{ zh='国外 (International)'; en='International' }
  'grp_domestic'    = @{ zh='国内 (China)'; en='China (Domestic)' }
  'status_yes'      = @{ zh='[已安装]'; en='[installed]' }
  'status_no'       = @{ zh='[未安装]'; en='[not installed]' }
  'menu_hint'       = @{ zh='输入编号安装 (如: 1 3 8) | u+编号卸载 (如: u 2) | all 全装 | q 退出'; en='Enter number(s) to install (e.g. 1 3 8) | u+number to uninstall (e.g. u 2) | all | q to quit' }
  'prompt_action'   = @{ zh='请输入操作'; en='Enter an action' }
  'exited'          = @{ zh='已退出'; en='Exited' }
  'installing'      = @{ zh='正在安装'; en='Installing' }
  'install_done'    = @{ zh='安装完成'; en='installation complete' }
  'install_fail'    = @{ zh='安装失败'; en='installation failed' }
  'uninstalling'    = @{ zh='正在卸载'; en='Uninstalling' }
  'uninstall_done'  = @{ zh='卸载完成'; en='uninstall complete' }
  'uninstall_fail'  = @{ zh='卸载失败'; en='uninstall failed' }
  'not_installed'   = @{ zh='未安装, 无需卸载'; en='not installed, nothing to uninstall' }
  'invalid_id'      = @{ zh='无效编号'; en='Invalid number' }
  'no_curl'         = @{ zh='未检测到 curl (Win10 1803+ 应已内置), 请检查系统'; en='curl not found (should be bundled with Win10 1803+)' }
  'curl_fail'       = @{ zh='curl 不可用'; en='curl unavailable' }
  'step_node'       = @{ zh='安装 Node.js'; en='Installing Node.js' }
  'dl'              = @{ zh='下载'; en='Downloading' }
  'extract'         = @{ zh='解压部署...'; en='Extracting...' }
  'no_node_dir'     = @{ zh='解压后未找到 Node 目录'; en='Node directory not found after extraction' }
  'node_done'       = @{ zh='Node.js 安装完成'; en='Node.js installed' }
  'node_old'        = @{ zh='Node 版本过旧'; en='Node version too old' }
  'no_node'         = @{ zh='未检测到 Node.js'; en='Node.js not found' }
  'no_python'       = @{ zh='未检测到 Python/pip (Aider 需要), 尝试自动安装...'; en='Python/pip not found (required by Aider), attempting auto-install...' }
  'no_winget'       = @{ zh='未检测到 winget, 请从 python.org 手动安装 Python 并勾选 Add to PATH'; en='winget not found, please install Python from python.org (check "Add to PATH")' }
  'python_fail'     = @{ zh='Python 安装失败'; en='Python installation failed' }
  'python_retry'    = @{ zh='Python 安装失败, 请重开终端后重试'; en='Python install failed, reopen terminal and retry' }
  'python_done'     = @{ zh='Python 就绪'; en='Python ready' }
  'removed_bin'     = @{ zh='已删除二进制'; en='removed binary' }
  'removed_dir'     = @{ zh='已删除目录'; en='removed directory' }
  'not_found'       = @{ zh='未找到'; en='not found' }
  'ask_del_config'  = @{ zh='是否删除配置目录'; en='Delete config directory?' }
  'del_done'        = @{ zh='已删除'; en='deleted' }
  'kept'            = @{ zh='已保留'; en='kept' }
  'clean_path'      = @{ zh='已清理用户 PATH 中失效/空的目录条目'; en='cleaned stale/empty user PATH entries' }
  'clean_path_none' = @{ zh='用户 PATH 无失效条目, 无需清理'; en='no stale user PATH entries' }
  'kimi_git_warn'   = @{ zh='Kimi Code 依赖 Git for Windows 作为其 shell 环境, 请先安装 Git'; en='Kimi Code requires Git for Windows as its shell environment' }
  'final_done'      = @{ zh='流程结束'; en='Finished' }
  'final_hint'      = @{ zh='提示: 安装后请重新打开终端使 PATH 生效; 各工具首次运行需自行登录/配置 API Key。'; en='Tip: reopen the terminal after install; each tool needs its own login/API key on first run.' }
}

function T ([string]$k) {
  return $Script:Text[$k][$Script:Lang]
}

function Info ($m)  { Write-Host ("[{0}] {1}" -f (T 'info'), $m) -ForegroundColor Cyan }
function Ok   ($m)  { Write-Host ("[{0}] {1}" -f (T 'done'), $m) -ForegroundColor Green }
function Warn ($m)  { Write-Host ("[{0}] {1}" -f (T 'warn'), $m) -ForegroundColor Yellow }
function Err  ($m)  { Write-Host ("[{0}] {1}" -f (T 'error'), $m) -ForegroundColor Red }
function Step ($m)  { Write-Host ("`n▶ {0}" -f $m) -ForegroundColor White }

function Test-Cmd ([string]$name) {
    return $null -ne (Get-Command $name -ErrorAction SilentlyContinue)
}

# ---------------------------- 语言选择 ----------------------------
function Choose-Language {
    Write-Host ''
    Write-Host '  请选择语言 / Choose language:' -ForegroundColor White
    Write-Host '    1. 中文 (Chinese)'
    Write-Host '    2. English'
    Write-Host ''
    $c = Read-Host '  输入 / Enter (1/2, 默认中文 / default 1)'
    if ($c.Trim() -eq '2') { $Script:Lang = 'en' } else { $Script:Lang = 'zh' }
}

# ============================ 依赖检测与安装 ============================
function Ensure-Curl {
    if (Test-Cmd curl) { return }
    Warn (T 'no_curl')
    throw (T 'curl_fail')
}

function Install-Node {
    Step ("{0} v{1}" -f (T 'step_node'), $Script:NodeVersion)
    Ensure-Curl
    $arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' }
    $pkg = "node-v$Script:NodeVersion-win-$arch.zip"
    $url = "https://nodejs.org/dist/v$Script:NodeVersion/$pkg"
    $tmp = Join-Path $Script:Toolbox '.tmp-node'
    $nodeHome = Join-Path $Script:Toolbox 'node'

    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    Info ("{0} {1}" -f (T 'dl'), $url)
    curl.exe -fsSL $url -o (Join-Path $tmp $pkg)
    Info (T 'extract')
    Expand-Archive -Path (Join-Path $tmp $pkg) -DestinationPath $tmp -Force
    $top = Get-ChildItem $tmp -Directory | Where-Object { $_.Name -like 'node-v*' } | Select-Object -First 1
    if (-not $top) { throw (T 'no_node_dir') }
    if (Test-Path $nodeHome) { Remove-Item $nodeHome -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $Script:Toolbox | Out-Null
    Move-Item $top.FullName $nodeHome
    Remove-Item $tmp -Recurse -Force

    Add-ToUserPath $nodeHome
    $env:Path = "$nodeHome;$env:Path"
    Ok ("{0}: {1}" -f (T 'node_done'), (node --version))
}

function Add-ToUserPath ([string]$dir) {
    $cur = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($cur -split ';' -notcontains $dir) {
        [Environment]::SetEnvironmentVariable('Path', "$cur;$dir".TrimStart(';'), 'User')
    }
}

function Ensure-Node {
    if (Test-Cmd node) {
        $v = (node --version) -replace 'v',''
        if ([int]($v.Split('.')[0]) -ge 18) { return }
        Warn ("{0} (v{1})" -f (T 'node_old'), $v)
    } else {
        Warn (T 'no_node')
    }
    Install-Node
}

function Ensure-Python {
    if ((Test-Cmd python) -and (Test-Cmd pip)) { return }
    if ((Test-Cmd python3) -and (Test-Cmd pip3)) { return }
    Warn (T 'no_python')
    if (Test-Cmd winget) {
        winget install -e --id Python.Python.3.12 --silent --accept-package-agreements --accept-source-agreements
    } else {
        Warn (T 'no_winget')
        throw (T 'python_fail')
    }
    if (-not (Test-Cmd python)) { throw (T 'python_retry') }
    Ok (T 'python_done')
}

# ============================ 通用卸载辅助 ============================
# 删除命令对应的可执行文件(含 shim 变体)
function Remove-Binary ([string]$cmdName) {
    $removed = $false
    $g = Get-Command $cmdName -ErrorAction SilentlyContinue
    if ($g) {
        $src = $g.Source
        $base = [System.IO.Path]::GetFileNameWithoutExtension($src)
        $dir = Split-Path $src
        foreach ($ext in @('', '.exe', '.cmd', '.ps1', '.bat')) {
            $p = Join-Path $dir ($base + $ext)
            if (Test-Path $p) { Remove-Item $p -Force -ErrorAction SilentlyContinue; $removed = $true }
        }
    }
    return $removed
}

# 删除整个目录(若存在), 返回是否删除成功
function Remove-Tree ([string]$dir) {
    $full = [Environment]::ExpandEnvironmentVariables($dir)
    if (Test-Path $full) {
        Remove-Item $full -Recurse -Force -ErrorAction SilentlyContinue
        if (-not (Test-Path $full)) { Ok ("{0}: {1}" -f (T 'removed_dir'), $full); return $true }
    }
    return $false
}

# 清理用户 PATH 中已失效(不存在)或已清空的目录条目
function Clean-Path {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if (-not $userPath) { Info (T 'clean_path_none'); return }
    $entries = @($userPath -split ';' | Where-Object { $_.Trim() -ne '' })
    $valid = @(); $changed = $false
    foreach ($e in $entries) {
        $trimmed = $e.Trim()
        $expanded = [Environment]::ExpandEnvironmentVariables($trimmed)
        if (-not $expanded -or -not (Test-Path -LiteralPath $expanded)) { $changed = $true; continue }
        $any = Get-ChildItem -LiteralPath $expanded -Force -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $any) { $changed = $true; continue }   # 空目录同样移除
        $valid += $trimmed
    }
    if ($changed) {
        $newPath = ($valid -join ';')
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        Ok (T 'clean_path')
    } else {
        Info (T 'clean_path_none')
    }
}

# 询问是否清理配置目录
function Clean-Config ([string[]]$dirs) {
    foreach ($d in $dirs) {
        $full = [Environment]::ExpandEnvironmentVariables($d)
        if (Test-Path $full) {
            $ans = Read-Host ("  {0} {1} ? (y/N)" -f (T 'ask_del_config'), $full)
            if ($ans -match '^(y|Y)$') { Remove-Item $full -Recurse -Force; Ok ("{0} {1}" -f (T 'del_done'), $full) }
            else { Info ("{0}: {1}" -f (T 'kept'), $full) }
        }
    }
}

# ============================ 工具定义 ============================
# Name/Vendor 为中文, NameEn/VendorEn 为英文
$Tools = @(
    [PSCustomObject]@{
        Id=1; Name='Claude Code'; NameEn='Claude Code'; Vendor='Anthropic'; VendorEn='Anthropic'; Group='foreign'; Cmd='claude'
        Install={ Step ("{0} Claude Code (Anthropic)" -f (T 'installing')); Ensure-Curl; Invoke-Expression (Invoke-RestMethod https://claude.ai/install.ps1) }
        Uninstall={
            Step ("{0} Claude Code" -f (T 'uninstalling'))
            Remove-Binary 'claude' | Out-Null
            Remove-Item "$env:USERPROFILE\.local\bin\claude*" -Force -ErrorAction SilentlyContinue
            Remove-Tree '$env:USERPROFILE\.local\share\claude'
            if (Test-Cmd npm) { npm uninstall -g @anthropic-ai/claude-code 2>$null }
            if (Test-Cmd winget) { winget uninstall Anthropic.ClaudeCode -e --silent 2>$null }
            Clean-Path
            Clean-Config @('$env:USERPROFILE\.claude', '$env:USERPROFILE\.claude.json')
        }
    }
    [PSCustomObject]@{
        Id=2; Name='Codex CLI'; NameEn='Codex CLI'; Vendor='OpenAI'; VendorEn='OpenAI'; Group='foreign'; Cmd='codex'
        Install={ Step ("{0} Codex CLI (OpenAI)" -f (T 'installing')); Ensure-Curl; Invoke-Expression (Invoke-RestMethod https://chatgpt.com/codex/install.ps1) }
        Uninstall={
            Step ("{0} Codex CLI" -f (T 'uninstalling'))
            Remove-Binary 'codex' | Out-Null
            Remove-Item "$env:USERPROFILE\.local\bin\codex*" -Force -ErrorAction SilentlyContinue
            if (Test-Cmd npm) { npm uninstall -g @openai/codex 2>$null }
            Clean-Path
            Clean-Config @('$env:USERPROFILE\.codex')
        }
    }
    [PSCustomObject]@{
        Id=3; Name='Gemini CLI'; NameEn='Gemini CLI'; Vendor='Google'; VendorEn='Google'; Group='foreign'; Cmd='gemini'
        Install={ Step ("{0} Gemini CLI (Google)" -f (T 'installing')); Ensure-Node; npm install -g @google/gemini-cli }
        Uninstall={
            Step ("{0} Gemini CLI" -f (T 'uninstalling'))
            if (Test-Cmd npm) {
                npm uninstall -g @google/gemini-cli 2>$null
                $prefix = npm config get prefix 2>$null
                if ($prefix) { Remove-Item (Join-Path $prefix 'gemini*') -Force -ErrorAction SilentlyContinue }
            }
            Remove-Binary 'gemini' | Out-Null
            Clean-Path
        }
    }
    [PSCustomObject]@{
        Id=4; Name='OpenCode'; NameEn='OpenCode'; Vendor='开源社区'; VendorEn='Open Source'; Group='foreign'; Cmd='opencode'
        Install={ Step ("{0} OpenCode" -f (T 'installing')); Ensure-Node; npm install -g opencode-ai@latest }
        Uninstall={
            Step ("{0} OpenCode" -f (T 'uninstalling'))
            if (Test-Cmd npm) {
                npm uninstall -g opencode-ai 2>$null
                $prefix = npm config get prefix 2>$null
                if ($prefix) { Remove-Item (Join-Path $prefix 'opencode*') -Force -ErrorAction SilentlyContinue }
            }
            Remove-Binary 'opencode' | Out-Null
            Clean-Path
        }
    }
    [PSCustomObject]@{
        Id=5; Name='Aider'; NameEn='Aider'; Vendor='开源社区'; VendorEn='Open Source'; Group='foreign'; Cmd='aider'
        Install={ Step ("{0} Aider" -f (T 'installing')); Ensure-Python; python -m pip install --user --upgrade aider-install; python -m pip install --user --upgrade aider-chat }
        Uninstall={
            Step ("{0} Aider" -f (T 'uninstalling'))
            python -m pip uninstall -y aider-chat aider-install 2>$null
            Remove-Binary 'aider' | Out-Null
            Clean-Path
            Clean-Config @('$env:USERPROFILE\.aider')
        }
    }
    [PSCustomObject]@{
        Id=6; Name='Goose'; NameEn='Goose'; Vendor='Block(开源)'; VendorEn='Block (open source)'; Group='foreign'; Cmd='goose'
        Install={ Step ("{0} Goose" -f (T 'installing')); Ensure-Curl; Invoke-Expression (Invoke-RestMethod https://github.com/block/goose/releases/latest/download/install.ps1) }
        Uninstall={
            Step ("{0} Goose" -f (T 'uninstalling'))
            Remove-Binary 'goose' | Out-Null
            Remove-Tree '$env:USERPROFILE\.config\goose'
            if (Test-Cmd npm) { npm uninstall -g @block/goose 2>$null }
            Clean-Path
        }
    }
    [PSCustomObject]@{
        Id=7; Name='Cline CLI'; NameEn='Cline CLI'; Vendor='Cline(开源)'; VendorEn='Cline (open source)'; Group='foreign'; Cmd='cline'
        Install={ Step ("{0} Cline CLI" -f (T 'installing')); Ensure-Node; npm install -g cline }
        Uninstall={
            Step ("{0} Cline CLI" -f (T 'uninstalling'))
            if (Test-Cmd npm) {
                npm uninstall -g cline 2>$null
                $prefix = npm config get prefix 2>$null
                if ($prefix) { Remove-Item (Join-Path $prefix 'cline*') -Force -ErrorAction SilentlyContinue }
            }
            Remove-Binary 'cline' | Out-Null
            Clean-Path
        }
    }
    [PSCustomObject]@{
        Id=8; Name='CodeBuddy Code'; NameEn='CodeBuddy Code'; Vendor='腾讯'; VendorEn='Tencent'; Group='domestic'; Cmd='codebuddy'
        Install={ Step ("{0} CodeBuddy Code" -f (T 'installing')); Ensure-Curl; Invoke-Expression (Invoke-RestMethod https://copilot.tencent.com/cli/install.ps1) }
        Uninstall={
            Step ("{0} CodeBuddy Code" -f (T 'uninstalling'))
            Remove-Binary 'codebuddy' | Out-Null
            Remove-Tree '$env:LOCALAPPDATA\codebuddy'
            Remove-Item "$env:USERPROFILE\.local\bin\codebuddy*" -Force -ErrorAction SilentlyContinue
            if (Test-Cmd npm) { npm uninstall -g @tencent-ai/codebuddy-code 2>$null }
            Clean-Path
            Clean-Config @('$env:USERPROFILE\.codebuddy')
        }
    }
    [PSCustomObject]@{
        Id=9; Name='Qoder CN 通义灵码'; NameEn='Qoder CN (Tongyi Lingma)'; Vendor='阿里云'; VendorEn='Alibaba Cloud'; Group='domestic'; Cmd='qoder'
        Install={ Step ("{0} Qoder CN" -f (T 'installing')); Ensure-Node; npm install -g qoder-cli }
        Uninstall={
            Step ("{0} Qoder CN" -f (T 'uninstalling'))
            if (Test-Cmd npm) {
                npm uninstall -g qoder-cli 2>$null
                $prefix = npm config get prefix 2>$null
                if ($prefix) { Remove-Item (Join-Path $prefix 'qoder*') -Force -ErrorAction SilentlyContinue }
            }
            Remove-Binary 'qoder' | Out-Null
            Clean-Path
        }
    }
    [PSCustomObject]@{
        Id=10; Name='Kimi Code'; NameEn='Kimi Code'; Vendor='月之暗面'; VendorEn='Moonshot AI'; Group='domestic'; Cmd='kimi'
        Install={ Step ("{0} Kimi Code" -f (T 'installing')); Ensure-Curl; if (-not (Test-Cmd git)) { Warn (T 'kimi_git_warn') }; Invoke-Expression (Invoke-RestMethod https://code.kimi.com/kimi-code/install.ps1) }
        Uninstall={
            Step ("{0} Kimi Code" -f (T 'uninstalling'))
            Remove-Binary 'kimi' | Out-Null
            Remove-Item "$env:USERPROFILE\.local\bin\kimi*" -Force -ErrorAction SilentlyContinue
            if (Test-Cmd npm) { npm uninstall -g @moonshot-ai/kimi-code 2>$null }
            Clean-Path
            Clean-Config @('$env:USERPROFILE\.kimi-code')
        }
    }
)

# ============================ 菜单与主流程 ============================
function Show-Banner {
    Write-Host ''
    Write-Host '======================================================' -ForegroundColor Cyan
    Write-Host ("  {0}" -f (T 'banner_title')) -ForegroundColor Cyan
    Write-Host '======================================================' -ForegroundColor Cyan
    $arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'ARM64' } else { 'x64' }
    Write-Host ("{0}: Windows ({1})" -f (T 'os_info'), $arch)
    Write-Host ''
}

function Get-StatusMark ([string]$cmd) {
    if (Test-Cmd $cmd) { return (T 'status_yes') } else { return (T 'status_no') }
}

function Show-Menu {
    Write-Host ("—— {0} ——" -f (T 'grp_foreign')) -ForegroundColor Cyan
    foreach ($t in $Tools) {
        if ($t.Group -eq 'foreign') {
            $mark = Get-StatusMark $t.Cmd
            $name = if ($Script:Lang -eq 'zh') { $t.Name } else { $t.NameEn }
            $vendor = if ($Script:Lang -eq 'zh') { $t.Vendor } else { $t.VendorEn }
            $color = if ($mark -eq (T 'status_yes')) { 'Green' } else { 'DarkGray' }
            Write-Host ("  {0,2}. {1,-24} ({2}) {3}" -f $t.Id, $name, $vendor, $mark) -ForegroundColor $color
        }
    }
    Write-Host ''
    Write-Host ("—— {0} ——" -f (T 'grp_domestic')) -ForegroundColor Cyan
    foreach ($t in $Tools) {
        if ($t.Group -eq 'domestic') {
            $mark = Get-StatusMark $t.Cmd
            $name = if ($Script:Lang -eq 'zh') { $t.Name } else { $t.NameEn }
            $vendor = if ($Script:Lang -eq 'zh') { $t.Vendor } else { $t.VendorEn }
            $color = if ($mark -eq (T 'status_yes')) { 'Green' } else { 'DarkGray' }
            Write-Host ("  {0,2}. {1,-24} ({2}) {3}" -f $t.Id, $name, $vendor, $mark) -ForegroundColor $color
        }
    }
    Write-Host ''
    Write-Host ("  {0}" -f (T 'menu_hint')) -ForegroundColor DarkGray
}

function Run-Install ([int]$id) {
    $t = $Tools | Where-Object { $_.Id -eq $id }
    if (-not $t) { Warn ("{0}: {1}" -f (T 'invalid_id'), $id); return }
    Write-Host ''
    Write-Host ("════════ {0} ════════" -f $t.Name) -ForegroundColor White
    try {
        & $t.Install
        Ok ("{0} {1}" -f $t.Name, (T 'install_done'))
    } catch {
        Err ("{0} {1}: {2}" -f $t.Name, (T 'install_fail'), $_.Exception.Message)
    }
}

function Run-Uninstall ([int]$id) {
    $t = $Tools | Where-Object { $_.Id -eq $id }
    if (-not $t) { Warn ("{0}: {1}" -f (T 'invalid_id'), $id); return }
    if (-not (Test-Cmd $t.Cmd)) { Warn ("{0} {1}" -f $t.Name, (T 'not_installed')); return }
    Write-Host ''
    Write-Host ("════════ {0} ════════" -f $t.Name) -ForegroundColor White
    try {
        & $t.Uninstall
        Ok ("{0} {1}" -f $t.Name, (T 'uninstall_done'))
    } catch {
        Err ("{0} {1}: {2}" -f $t.Name, (T 'uninstall_fail'), $_.Exception.Message)
    }
}

function Main {
    Choose-Language
    Show-Banner
    Ensure-Curl

    while ($true) {
        Show-Menu
        Write-Host ''
        $input = Read-Host (T 'prompt_action')
        if (-not $input) { continue }
        $input = $input.Trim()
        if ($input -eq 'q') { Info (T 'exited'); break }

        if ($input -eq 'all') {
            foreach ($t in $Tools) { Run-Install $t.Id }
            continue
        }

        if ($input -match '^u\s+(.+)$') {
            $ids = ($Matches[1] -split '\s+') | Where-Object { $_ -ne '' }
            foreach ($i in $ids) { Run-Uninstall ([int]$i) }
            continue
        }

        $ids = ($input -split '\s+') | Where-Object { $_ -ne '' }
        foreach ($i in $ids) { Run-Install ([int]$i) }
    }

    Write-Host ''
    Write-Host ("════════ {0} ════════" -f (T 'final_done')) -ForegroundColor Green
    Write-Host (T 'final_hint') -ForegroundColor DarkGray
}

Main
