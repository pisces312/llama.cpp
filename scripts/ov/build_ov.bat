@echo off
setlocal

set "VCVARS=C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
set "OV_SETUP=D:\dev\openvino_toolkit_windows_2026.1.1.21373.3687ccc8dab_x86_64\setupvars.bat"
set "CMAKE_EXE=C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
set "NINJA_EXE=C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe"
set "LLAMA_DIR=D:\dev\llama.cpp"
set "OPENCL_INCLUDE=D:\dev\opencl-sdk\include"
set "OPENCL_LIB=D:\dev\opencl-sdk\lib\OpenCL.lib"

echo === [1/4] Init MSVC ===
call "%VCVARS%"
if errorlevel 1 (echo [ERROR] MSVC init failed & exit /b 1)
echo [OK] cl.exe: & where cl.exe

echo.
echo === [2/4] Init OpenVINO ===
call "%OV_SETUP%"
if errorlevel 1 (echo [ERROR] OpenVINO init failed & exit /b 1)
echo [OK] OpenVINO_DIR: %OpenVINO_DIR%

echo.
echo === [3/4] CMake Configure ===
cd /d "%LLAMA_DIR%"
if exist build\ReleaseOV rmdir /s /q build\ReleaseOV
"%CMAKE_EXE%" -B build\ReleaseOV -G Ninja -DCMAKE_BUILD_TYPE=Release -DGGML_OPENVINO=ON -DLLAMA_CURL=OFF -DOPENCL_INCLUDE_DIR="%OPENCL_INCLUDE%" -DOPENCL_LIBRARY="%OPENCL_LIB%" -DCMAKE_MAKE_PROGRAM="%NINJA_EXE%"
if errorlevel 1 (echo [ERROR] CMake configure failed & exit /b 1)

echo.
echo === [4/4] CMake Build ===
"%CMAKE_EXE%" --build build\ReleaseOV --parallel
if errorlevel 1 (echo [ERROR] Build failed & exit /b 1)

echo.
echo === BUILD SUCCESS ===
dir build\ReleaseOV\bin\*.exe
