@echo off
call "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
call "D:\dev\openvino_toolkit_windows_2026.1.1.21373.3687ccc8dab_x86_64\setupvars.bat"
cd /d D:\dev\llama.cpp
"C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" --build build\ReleaseOV --parallel
