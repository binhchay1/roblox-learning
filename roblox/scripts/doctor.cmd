@echo off
setlocal
echo === Roblox/Node Tooling Doctor ===
echo.
echo [1] Checking node and npm...
where node >nul 2>nul
if %errorlevel% neq 0 (
  echo node: MISSING in PATH
) else (
  for /f "delims=" %%i in ('where node') do echo node: %%i
  node -v
)
where npm >nul 2>nul
if %errorlevel% neq 0 (
  echo npm: MISSING in PATH
) else (
  for /f "delims=" %%i in ('where npm') do echo npm: %%i
  npm -v
)
echo.
echo [2] Checking rojo...
where rojo >nul 2>nul
if %errorlevel% neq 0 (
  echo rojo: MISSING in PATH
  echo Install options:
  echo   winget install Rojo.Rojo
  echo   OR cargo install rojo
) else (
  for /f "delims=" %%i in ('where rojo') do echo rojo: %%i
  rojo --version
)
echo.
echo [3] Current PATH:
echo %PATH%
echo.
echo Tip: After installing tools, close/reopen terminal (or reboot) to refresh PATH.
endlocal
