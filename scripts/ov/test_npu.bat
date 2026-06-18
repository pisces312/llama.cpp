@echo off
REM ============================================================
REM  路线A: NPU 推理测试 + 三设备性能对比
REM  前提: build_ov.bat 已成功执行
REM ============================================================
setlocal

set "LLAMA_BIN=D:\dev\llama.cpp\build\ReleaseOV\bin"
set "MODEL_SMALL=D:\dev\ai-models\gguf\qwen2.5-1.5b-instruct-q4_k_m.gguf"
set "MODEL_8B=D:\dev\ai-models\gguf\Qwen3-8B-Q4_K_M.gguf"

if not exist "%LLAMA_BIN%\llama-cli.exe" (
    echo [ERROR] llama.cpp 未编译，请先运行 build_ov.bat
    exit /b 1
)

echo ============================================================
echo  [1/2] NPU 聊天测试 (Qwen2.5-1.5B)
echo ============================================================
set "GGML_OPENVINO_DEVICE=NPU"
echo 设备: %GGML_OPENVINO_DEVICE%
echo 模型: %MODEL_SMALL%
echo.
"%LLAMA_BIN%\llama-cli.exe" -m "%MODEL_SMALL%" -c 512 -n 100 --color -i ^
    -p "你好，请用一句话介绍 Intel NPU"

echo.
echo ============================================================
echo  [2/2] 三设备性能对比 (llama-bench, Qwen2.5-1.5B)
echo ============================================================

echo.
echo --- NPU ---
set "GGML_OPENVINO_DEVICE=NPU"
"%LLAMA_BIN%\llama-bench.exe" -m "%MODEL_SMALL%" -fa 1

echo.
echo --- GPU (Arc 140T) ---
set "GGML_OPENVINO_DEVICE=GPU"
set "GGML_OPENVINO_STATEFUL_EXECUTION=1"
"%LLAMA_BIN%\llama-bench.exe" -m "%MODEL_SMALL%" -fa 1
set "GGML_OPENVINO_STATEFUL_EXECUTION="

echo.
echo --- CPU ---
set "GGML_OPENVINO_DEVICE=CPU"
"%LLAMA_BIN%\llama-bench.exe" -m "%MODEL_SMALL%" -fa 1

echo.
echo ============================================================
echo  完成! 对比上方的 tg128/pp128 数值 (token/s)
echo  tg128 = 生成 128 token 的速度
echo  pp128 = 处理 128 prompt token 的速度
echo ============================================================
