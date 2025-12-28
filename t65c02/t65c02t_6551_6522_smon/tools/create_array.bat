@echo off
REM Create C array from SMON binary and update memorymap.h
REM This script uses srec_cat to convert binary to C array format

set SREC_CAT_PATH="C:\Program Files\srecord\bin\srec_cat.exe"

set BIN_FILE=firmware\SMON_E000\build\SMON_E000.bin
set C_FILE=firmware\SMON_E000\build\smon_array.c
set HEADER_FILE=memorymap.h

echo ================================================
echo SMON Binary to C Array Converter
echo ================================================

REM Check if build folder exists
if not exist "firmware\SMON_E000\build\" (
    echo Error: firmware\SMON_E000\build folder not found. Run 'make firmware' first.
    exit /b 1
)

REM Check if binary file exists
if not exist "%BIN_FILE%" (
    echo Error: %BIN_FILE% not found. Run 'make firmware' first.
    exit /b 1
)

REM Get file size
for %%A in ("%BIN_FILE%") do set SIZE=%%~zA
echo Binary file: %BIN_FILE%
echo Size: %SIZE% bytes

REM Convert binary to C array using Python script
echo Converting binary to C array...
python tools\bin2array.py %BIN_FILE% %C_FILE% rom_bin 0xE000
if %errorlevel% neq 0 (
    echo Error: Binary to C array conversion failed.
    exit /b %errorlevel%
)

REM Create memorymap.h header file
echo Creating memorymap.h...
(
    echo // ROM Size: %SIZE% bytes
    echo // ROM Start: 0xE000
    echo // ROM End: 0xFFFF
    echo // Memory map constants
    echo #define ROM_START 0xE000
    echo #define ROM_END   0xFFFF
    echo.
    echo // RAM configuration
    echo #define RAM_START 0x0000
    echo #define RAM_END   0x7FFF
    echo.
    echo // RAM array ^(32768 bytes: 0x0000-0x7FFF^)
    echo byte RAM[RAM_END - RAM_START + 1];
    type "%C_FILE%"
) > "%HEADER_FILE%"

if %errorlevel% neq 0 (
    echo Error: Failed to create memorymap.h
    exit /b %errorlevel%
)

echo.
echo ================================================
echo Success! Generated files:
echo   - %C_FILE%
echo   - %HEADER_FILE%
echo ================================================
pause
