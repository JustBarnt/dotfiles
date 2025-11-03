@echo off
REM TortoiseSVN Neovim Diff Wrapper
REM Arguments: %base %mine

SET BASE=%1
SET MINE=%2

REM Remove quotes
SET BASE=%BASE:"=%
SET MINE=%MINE:"=%

REM Launch nvim with diff mode
"C:\Program Files\Neovim\bin\nvim.exe" -d "%BASE%" "%MINE%" -c "wincmd J" -c "norm ]c"

EXIT /B 0

