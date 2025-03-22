@echo off
set CODE_DIR=..\code
set CC65_DIR=..\cc65
set SREC_CAT_PATH="C:\Program Files\srecord\bin\srec_cat.exe"

for %%f in (%CODE_DIR%\*.s) do (
    %CC65_DIR%\ca65.exe -g %%f -o %%~dpnf.o -l %%~dpnf.lst --list-bytes 0
    %CC65_DIR%\ld65.exe -o %%~dpnf.bin -Ln %%~dpnf.labels -m %%~dpnf.map -C %CODE_DIR%\system.cfg %%~dpnf.o
    %SREC_CAT_PATH% %%~dpnf.bin -binary -o %%~dpnf.c -C-Array %%~nf
)