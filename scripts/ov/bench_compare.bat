@echo off
call "D:\dev\openvino_toolkit_windows_2026.1.1.21373.3687ccc8dab_x86_64\setupvars.bat"
cd /d D:\dev\llama.cpp-ov

echo ==========================================
echo  NPU Bench
echo ==========================================
set "GGML_OPENVINO_DEVICE=NPU"
llama-bench.exe -m "D:\dev\ai-models\gguf\qwen2.5-1.5b-instruct-q4_k_m.gguf" -fa 1

echo.
echo ==========================================
echo  GPU Bench (Arc 140T)
echo ==========================================
set "GGML_OPENVINO_DEVICE=GPU"
set "GGML_OPENVINO_STATEFUL_EXECUTION=1"
llama-bench.exe -m "D:\dev\ai-models\gguf\qwen2.5-1.5b-instruct-q4_k_m.gguf" -fa 1
set "GGML_OPENVINO_STATEFUL_EXECUTION="

echo.
echo ==========================================
echo  CPU Bench
echo ==========================================
set "GGML_OPENVINO_DEVICE=CPU"
llama-bench.exe -m "D:\dev\ai-models\gguf\qwen2.5-1.5b-instruct-q4_k_m.gguf" -fa 1
