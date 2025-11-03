@echo off
REM TortoiseSVN Neovim Merge Wrapper
REM Arguments: %base %theirs %mine %merged

SET MERGED=%1
SET THEIRS=%2
SET MINE=%3
SET BASE=%4

REM Remove quotes
SET MERGED=%MERGED:"=%
SET THEIRS=%THEIRS:"=%
SET MINE=%MINE:"=%
SET BASE=%BASE:"=%

REM Launch nvim with diff mode
"C:\Program Files\Neovim\bin\nvim.exe" -d "%MERGED%" "%THEIRS%" "%MINE%" -c "wincmd J" -c "norm ]c"
REM "C:\Program Files\Neovim\bin\nvim.exe" -d "%MERGED%" "%THEIRS%" "%MINE%" "%BASE%" -c "wincmd J" -c "norm ]c"

REM nvim should save to the MERGED file location
REM If MERGED file doesn't exist, copy MINE as a fallback
IF NOT EXIST "%MERGED%" (
    COPY "%MINE%" "%MERGED%" > NUL
)

EXIT /B 0
