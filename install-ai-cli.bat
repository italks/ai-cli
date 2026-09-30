@echo off
setlocal
REM ============================================================
REM  AI CLI 一键安装/卸载 - Windows 双击入口
REM  纯 PowerShell 原生实现, 不依赖 Git Bash
REM ============================================================
chcp 65001 >nul

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-ai-cli.ps1"

echo.
echo ============================================================
echo   Finished. Press any key to close...
echo ============================================================
pause >nul
