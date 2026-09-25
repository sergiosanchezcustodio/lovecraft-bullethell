@echo off
rem Lanza la partida (doble clic desde el Explorador).
set GODOT=C:\Tools\Godot\Godot_v4.4.1-stable_win64.exe
if not exist "%GODOT%" set GODOT=godot
start "" "%GODOT%" --path "%~dp0."
