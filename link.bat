@echo off

W:
IF EXIST W:\dev\ld49\bin\Luau.exe ( del W:\dev\ld49\bin\Luau.exe )
mklink /h W:\dev\ld49\bin\Luau.exe W:\dev\canvas\Luau\Debug\Luau.exe
