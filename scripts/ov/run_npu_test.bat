@echo off
set "GGML_OPENVINO_DEVICE=NPU"
call "D:\dev\openvino_toolkit_windows_2026.1.1.21373.3687ccc8dab_x86_64\setupvars.bat"
cd /d D:\dev\llama.cpp-ov
echo === NPU Chat Test (Qwen2.5-1.5B) ===
llama-cli.exe -m "D:\dev\ai-models\gguf\qwen2.5-1.5b-instruct-q4_k_m.gguf" -c 512 -n 80 --no-display-prompt -p "用一句话介绍 Intel NPU"
