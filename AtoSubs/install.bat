@echo off
title AutoCaptions Installer
color 0A

echo.
echo  ╔═══════════════════════════════════════════════════════════╗
echo  ║              🎬 AutoCaptions Installer                    ║
echo  ║         Automatic Subtitles for DaVinci Resolve           ║
echo  ╚═══════════════════════════════════════════════════════════╝
echo.

:: Get current directory (where user extracted the zip)
set "INSTALL_DIR=%~dp0"
set "INSTALL_DIR=%INSTALL_DIR:~0,-1%"

echo  Install location: %INSTALL_DIR%
echo.

:: Check Python
echo  [1/4] Checking Python...
python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo  ❌ ERROR: Python is not installed!
    echo.
    echo     Please install Python 3.8+ from:
    echo       https://www.python.org/downloads/
    echo.
    echo     ⚠️  Make sure to check "Add Python to PATH" during installation!
    echo.
    pause
    exit /b 1
)

python --version
echo  ✓ Python found!
echo.

:: Install dependencies
echo  [2/4] Installing dependencies...
echo        This may take a few minutes...
echo.

pip install --upgrade pip >nul 2>&1
pip install openai-whisper customtkinter >nul 2>&1

if %errorLevel% neq 0 (
    echo  ⚠️  Warning: Some packages may have failed.
    echo     They will be installed on first run.
    echo.
) else (
    echo  ✓ Dependencies installed!
    echo.
)

:: Save install path for the Lua script to find
echo  [3/4] Saving configuration...

set "CONFIG_DIR=%APPDATA%\AutoCaptions"
if not exist "%CONFIG_DIR%" mkdir "%CONFIG_DIR%" 2>nul

echo %INSTALL_DIR%> "%CONFIG_DIR%\install_path.txt"
echo  ✓ Configuration saved!
echo.

:: Copy Lua script to DaVinci Resolve
echo  [4/4] Installing to DaVinci Resolve...

set "RESOLVE_SCRIPTS=C:\ProgramData\Blackmagic Design\DaVinci Resolve\Fusion\Scripts\Utility"

if not exist "%RESOLVE_SCRIPTS%" (
    mkdir "%RESOLVE_SCRIPTS%" 2>nul
)

copy /Y "%INSTALL_DIR%\AutoCaptions.lua" "%RESOLVE_SCRIPTS%\AutoCaptions.lua" >nul 2>&1

if %errorLevel% neq 0 (
    echo.
    echo  ⚠️  WARNING: Could not copy to Resolve scripts folder.
    echo     Try running this installer as Administrator.
    echo.
    echo     Or manually copy AutoCaptions.lua to:
    echo       %RESOLVE_SCRIPTS%
    echo.
) else (
    echo  ✓ Script installed to DaVinci Resolve!
)

echo.
echo  ╔═══════════════════════════════════════════════════════════╗
echo  ║              ✅ Installation Complete!                    ║
echo  ╚═══════════════════════════════════════════════════════════╝
echo.
echo   HOW TO USE:
echo.
echo   1. Open DaVinci Resolve
echo   2. Open a project with a timeline
echo   3. Go to: Workspace → Scripts → AutoCaptions
echo   4. Select your settings and click START
echo   5. Subtitles will be added automatically!
echo.
echo   ─────────────────────────────────────────────────────────────
echo.
echo   💡 TIP: For styled subtitles, create a Text+ with your
echo          desired style and drag it to the Media Pool.
echo          Then select it as the Template in AutoCaptions.
echo.
echo   📁 Keep this folder! Don't delete it after installing.
echo      Location: %INSTALL_DIR%
echo.
echo  ═════════════════════════════════════════════════════════════
echo.
pause
