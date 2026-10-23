@echo off
REM Chay ung dung web (ban build san trong build\web) tai http://localhost:5000
REM   run_server.bat          -> chay server (tu build neu chua co build\web)
REM   run_server.bat build    -> build lai roi chay server
setlocal
cd /d "%~dp0"
set PORT=5000

if /i "%~1"=="build" goto build
if exist "build\web\index.html" goto serve

:build
echo [1/2] Dang build Flutter web (mat khoang 1-2 phut)...
call flutter build web --release --no-tree-shake-icons --no-wasm-dry-run
if errorlevel 1 (
  echo Build that bai.
  pause
  exit /b 1
)

:serve
where python >nul 2>nul
if errorlevel 1 (
  echo Khong tim thay Python. Cai Python hoac dung: flutter run -d chrome --web-port %PORT%
  pause
  exit /b 1
)

echo.
echo ============================================================
echo  Ung dung dang chay tai: http://localhost:%PORT%
echo  (Dung "localhost", KHONG dung 127.0.0.1 - Firebase chi cho phep localhost)
echo  Dong cua so nay hoac nhan Ctrl+C de tat server.
echo ============================================================
echo.
start "" "http://localhost:%PORT%"
python -m http.server %PORT% --directory build\web
endlocal
