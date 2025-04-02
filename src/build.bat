@echo off

if  not exist "..\lib\windows" mkdir ..\lib\windows

cl -nologo -MT -TC -O2 -c pico_ecs.c
lib -nologo pico_ecs.obj -out:..\lib\windows\pico_ecs.lib

del *.obj
