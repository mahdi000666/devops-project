@echo off
setlocal enabledelayedexpansion

set URL=%1
if "%URL%"=="" set URL=http://localhost:8080

set MAX_RETRIES=15
set RETRY=0

echo ===================================
echo SMOKE TEST STARTING
echo Target: %URL%
echo ===================================

:RETRY_LOOP
if !RETRY! GEQ %MAX_RETRIES% goto FAILED

echo [Attempt !RETRY!/!MAX_RETRIES!] Testing %URL% ...
curl -sf %URL% >nul 2>&1
if !ERRORLEVEL! EQU 0 goto PASSED

set /A RETRY+=1
ping 127.0.0.1 -n 3 >nul
goto RETRY_LOOP

:PASSED
echo.
echo ===================================
echo ✓ SMOKE TEST PASSED
echo ===================================
echo PASSED > smoke.log
exit /b 0

:FAILED
echo.
echo ===================================
echo ✗ SMOKE TEST FAILED
echo ===================================
echo FAILED > smoke.log
exit /b 1