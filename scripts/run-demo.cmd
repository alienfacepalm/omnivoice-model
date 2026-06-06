@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-demo.ps1" %*
exit /b %ERRORLEVEL%
