@echo off
set "NODE_PATH=C:\Program Files\nodejs"
if exist "%NODE_PATH%\node.exe" (
  set "PATH=%NODE_PATH%;%PATH%"
)

echo PATH patched for this terminal session.
where node
where npm
echo.
echo Use this shell command pattern in Cursor terminal:
echo   call scripts\cursor-env.cmd ^&^& cd backend ^&^& npm install ^&^& npm run build
