@echo off
setlocal enabledelayedexpansion

set NASM_PATH=C:\MyPrograms\8088\comp\nasm-2.16.03-win32\nasm-2.16.03\nasm.exe
set SREC_CAT_PATH="C:\Program Files\srecord\bin\srec_cat.exe"
set PYTHON_PATH=python

echo Scanning for .asm files...

for %%f in (*.asm) do (
    set "ASM_FILE=%%f"
    set "BASE_NAME=%%~nf"
    set "LST_FILE=!BASE_NAME!.lst"
    set "BIN_FILE=!BASE_NAME!.bin"
    set "HEX_FILE=!BASE_NAME!.hex"

    echo Compiling !ASM_FILE!...
    %NASM_PATH% -l !LST_FILE! !ASM_FILE!
    if !errorlevel! neq 0 (
        echo Compilation failed for !ASM_FILE!.
        exit /b !errorlevel!
    )

    %NASM_PATH% -f bin -o !BIN_FILE! !ASM_FILE!
    if !errorlevel! neq 0 (
        echo Binary creation failed for !ASM_FILE!.
        exit /b !errorlevel!
    )

    %NASM_PATH% -f ith -o !HEX_FILE! !ASM_FILE!
    if !errorlevel! neq 0 (
        echo Hex file creation failed for !ASM_FILE!.
        exit /b !errorlevel!
    )

    echo !ASM_FILE! compiled successfully.
)

echo Cleaning up...
for %%f in (*) do (
    if "%%~xf"=="" (
        del /Q /F "%%f"
    )
)

for %%f in (*) do (
    if not "%%~xf"==".txt" if not "%%~xf"==".bat" if not "%%~xf"==".asm" if not "%%~xf"==".lst" if not "%%~xf"==".bin" if not "%%~xf"==".hex" (
        del /Q /F "%%f"
    )
)

echo All tasks completed successfully.
pause
