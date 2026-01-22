@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM End-to-end AQI Pipeline + Tableau Export (Windows, no Docker)
REM 1) Activate venv
REM 2) Run Python ingestion (data.gov.in -> MySQL raw table)
REM 3) Run dbt (stg + marts)
REM 4) Run dbt tests
REM 5) Export BI tables to CSVs for Tableau Public
REM ============================================================

REM --- Set project paths (edit ONLY if your folder is different)
set "PROJECT_DIR=C:\projects\aqi-india-realtime"

if not exist "%PROJECT_DIR%\logs" mkdir "%PROJECT_DIR%\logs"

for /f "tokens=1-3 delims=/- " %%a in ("%date%") do (
  set "D1=%%a"
  set "D2=%%b"
  set "D3=%%c"
)
for /f "tokens=1-3 delims=:." %%a in ("%time%") do (
  set "T1=%%a"
  set "T2=%%b"
  set "T3=%%c"
)
set "T1=%T1: =0%"
set "LOGFILE=%PROJECT_DIR%\logs\pipeline_%D3%%D2%%D1%_%T1%%T2%%T3%.log"

echo Log file: %LOGFILE%
echo ============================================>> "%LOGFILE%"
echo START %date% %time%>> "%LOGFILE%"
echo ============================================>> "%LOGFILE%"

set "VENV_ACTIVATE=%PROJECT_DIR%\.venv\Scripts\activate.bat"
set "PYTHON_EXE=%PROJECT_DIR%\.venv\Scripts\python.exe"

REM  ingestion script 
set "INGEST_SCRIPT=%PROJECT_DIR%\src\ingest\ingest_aqi.py"

REM dbt project directory
set "DBT_PROJECT_DIR=%PROJECT_DIR%\dbt\aqi_dbt"

REM Tableau export script
set "EXPORT_SCRIPT=%PROJECT_DIR%\src\bi\export_for_tableau.py"

echo.
echo ============================================================
echo   AQI Pipeline + Tableau Export starting...
echo   Project: %PROJECT_DIR%
echo ============================================================
echo.

REM --- Safety checks
if not exist "%PROJECT_DIR%" (
  echo [ERROR] PROJECT_DIR not found: %PROJECT_DIR%
  goto :fail
)

if not exist "%VENV_ACTIVATE%" (
  echo [ERROR] Virtualenv activate not found: %VENV_ACTIVATE%
  echo         Create venv: python -m venv .venv
  goto :fail
)

if not exist "%PYTHON_EXE%" (
  echo [ERROR] Python exe not found: %PYTHON_EXE%
  goto :fail
)

if not exist "%INGEST_SCRIPT%" (
  echo [ERROR] Ingestion script not found: %INGEST_SCRIPT%
  goto :fail
)

if not exist "%DBT_PROJECT_DIR%\dbt_project.yml" (
  echo [ERROR] dbt_project.yml not found in: %DBT_PROJECT_DIR%
  goto :fail
)

if not exist "%EXPORT_SCRIPT%" (
  echo [ERROR] Export script not found: %EXPORT_SCRIPT%
  goto :fail
)

REM --- Activate venv
call "%VENV_ACTIVATE%"
if errorlevel 1 (
  echo [ERROR] Failed to activate virtual environment.
  goto :fail
)

REM --- Ensure .env exists
if not exist "%PROJECT_DIR%\.env" (
  echo [ERROR] .env not found in: %PROJECT_DIR%
  goto :fail
)

REM --- Load .env into current CMD session (ignores comments)
for /f "usebackq tokens=1,* delims== eol=#" %%A in ("%PROJECT_DIR%\.env") do (
  if not "%%A"=="" set "%%A=%%B"
)


REM --- Move to project root
cd /d "%PROJECT_DIR%"

REM --- Step 1: Ingest
echo.
echo [1/4] Running ingestion...
echo ------------------------------------------------------------
"%PYTHON_EXE%" "%INGEST_SCRIPT%" >> "%LOGFILE%" 2>>&1
if errorlevel 1 (
  echo [ERROR] Ingestion failed.
  goto :fail
)

REM --- Step 2: dbt run
echo.
echo [2/4] Running dbt run...
echo ------------------------------------------------------------
cd /d "%DBT_PROJECT_DIR%"
dbt run >> "%LOGFILE%" 2>>&1
if errorlevel 1 (
  echo [ERROR] dbt run failed.
  goto :fail
)

REM --- Step 3: dbt test
echo.
echo [3/4] Running dbt test...
echo ------------------------------------------------------------
dbt run >> "%LOGFILE%" 2>>&1
if errorlevel 1 (
  echo [ERROR] dbt test failed.
  goto :fail
)

REM --- Step 4: Export CSVs for Tableau Public
echo.
echo [4/4] Exporting CSVs for Tableau Public...
echo ------------------------------------------------------------
cd /d "%PROJECT_DIR%"
"%PYTHON_EXE%" "%EXPORT_SCRIPT%" >> "%LOGFILE%" 2>>&1
if errorlevel 1 (
  echo [ERROR] Export step failed.
  goto :fail
)

echo.
echo ============================================================
echo   SUCCESS: Pipeline + Export completed end-to-end!
echo   CSVs are in: %PROJECT_DIR%\bi_exports
echo ============================================================
echo.

echo ============================================>> "%LOGFILE%"
echo SUCCESS %date% %time%>> "%LOGFILE%"
echo ============================================>> "%LOGFILE%"

pause
exit /b 0

:fail
echo.
echo ============================================================
echo   FAILED: Pipeline did not complete.
echo   Check the error above.
echo ============================================================
echo.

echo ============================================>> "%LOGFILE%"
echo FAILED %date% %time%>> "%LOGFILE%"
echo ============================================>> "%LOGFILE%"

pause
exit /b 1
