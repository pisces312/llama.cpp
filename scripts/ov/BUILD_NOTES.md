# Building llama.cpp with OpenVINO Backend on Windows

Build notes from 2026-06-18, on an Intel Core Ultra 9 285H (Arrow Lake-H) machine
with VS 2026 Build Tools (v18.6) and OpenVINO Runtime 2026.1.1.

## Prerequisites

| Dependency | Path used | Notes |
|------------|-----------|-------|
| VS Build Tools (C++ workload) | `C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools` | VS 18, not 22. Ships its own CMake + Ninja. |
| OpenVINO Runtime 2026.1.1 | `D:\dev\openvino_toolkit_windows_2026.1.1.21373.3687ccc8dab_x86_64` | Downloaded from `storage.openvinotoolkit.org`. The GitHub release page only ships source tarballs. |
| OpenCL headers + import lib | `D:\dev\opencl-sdk` | Self-built (see below). |
| llama.cpp source | `D:\dev\llama.cpp` | Tag b9294 (commit `0f3cb3f`). |

## Build

```cmd
:: build_ov.bat chains these four steps together:
:: 1. call vcvars64.bat      (MSVC env)
:: 2. call setupvars.bat     (OpenVINO env)
:: 3. cmake -B build\ReleaseOV -G Ninja -DGGML_OPENVINO=ON ...
:: 4. cmake --build build\ReleaseOV --parallel
```

Run it from any cmd shell:

```cmd
D:\dev\llama.cpp\scripts\ov\build_ov.bat
```

## Problems hit and fixes

### 1. `cl2.hpp` not found

```
openvino/runtime/intel_gpu/ocl/ocl_wrapper.hpp(50): fatal error C1083:
  Cannot open include file: "CL/cl2.hpp": No such file or directory
```

`ggml-openvino` includes OpenVINO's `ocl_wrapper.hpp`, which pulls in
`CL/cl2.hpp`. That header is the C++ bindings shim from the OpenCL-CLHPP
repo and is NOT shipped with the Khronos `OpenCL-Headers` repo (which only
has C headers) nor with the CUDA toolkit's `CL/` folder.

**Fix**: create a one-line shim next to `cl.hpp`:

```cpp
// CL/cl2.hpp
#pragma once
#include "cl.hpp"
```

`cl.hpp` (the older C++ bindings) ships with CUDA's OpenCL headers and is
API-compatible enough for what `ocl_wrapper.hpp` uses. Drop the shim at
`D:\dev\cuda\include\CL\cl2.hpp`.

### 2. OpenCL SDK not installable via vcpkg

`vcpkg install opencl:x64-windows` failed because vcpkg's bootstrap tried to
download 7-Zip from GitHub and the network was flaky (`curl error 56`).
Cloning `KhronosGroup/OpenCL-ICD-Loader` also timed out.

**Fix**: skip vcpkg entirely. CMake's `find_package(OpenCL)` actually picked
up `D:\dev\cuda\lib\x64\OpenCL.lib` (from the CUDA toolkit) on its own, so
the manually-built import lib at `D:\dev\opencl-sdk\lib\OpenCL.lib` ended up
unused. The `OPENCL_INCLUDE_DIR` / `OPENCL_LIBRARY` cmake vars in
`build_ov.bat` are now redundant but left in for documentation; they can be
removed if a CUDA toolkit is present.

The self-built SDK (kept at `D:\dev\opencl-sdk`) was generated from the
system `C:\Windows\System32\OpenCL.dll` via `dumpbin /exports` + `lib /def`:

```cmd
dumpbin /exports C:\Windows\System32\OpenCL.dll > exports.txt
:: parse exports.txt -> opencl.def (123 functions)
lib /def:opencl.def /machine:x64 /out:OpenCL.lib
:: headers: copy CL/ from KhronosGroup/OpenCL-Headers
```

### 3. `.bat` files written by tools arrive as UTF-8 / LF

When the build scripts were generated via heredoc/Write tool, cmd.exe saw
garbled `setlocal` (rendered as `'nabledelayedexpansion'`) because the file
had LF line endings and cmd expects CRLF.

**Fix**: after writing any `.bat`, convert to CRLF:

```bash
sed -i 's/$/\r/' script.bat
```

Also avoid `setlocal enabledelayedexpansion` unless you actually need
`!var!` expansion; plain `setlocal` is safer for scripts that only use
`%var%`.

### 4. Calling `.bat` from PowerShell loses environment

`vcvars64.bat` and `setupvars.bat` set env vars in the current process.
Invoking them through `cmd /c` from PowerShell runs them in a child process,
so CMake cannot see `cl.exe` or `OpenVINO_DIR`.

**Fix**: invoke the whole build as a single `.bat` file via the call
operator `& "D:\dev\llama.cpp\scripts\ov\build_ov.bat"`. The `call` keyword
inside the bat keeps `vcvars`/`setupvars` env in the same cmd process, and
CMake inherits it.

### 5. `find_package(OpenVINO)` needs TBB

`ggml/src/ggml-openvino/CMakeLists.txt` does:

```cmake
include("${OpenVINO_DIR}/../3rdparty/tbb/lib/cmake/TBB/TBBConfig.cmake")
target_link_libraries(ggml-openvino PRIVATE openvino::runtime TBB::tbb OpenCL::OpenCL)
```

TBB ships inside the OpenVINO archive (`runtime/3rdparty/tbb`), so as long
as `setupvars.bat` ran, `OpenVINO_DIR` points at `runtime/cmake` and the
relative `../3rdparty/tbb` path resolves. No separate TBB install needed.

## Post-build: relocating the output

After a successful build the executables live at
`build\ReleaseOV\bin\`. We move just the `bin\` folder to a standalone
deployment directory and keep the rest of `build\ReleaseOV\` (CMakeCache,
`.obj`, `build.ninja`) so incremental rebuilds still work:

```cmd
move D:\dev\llama.cpp\build\ReleaseOV\bin D:\dev\llama.cpp-ov
```

Run/test scripts then point at `D:\dev\llama.cpp-ov` instead of
`build\ReleaseOV\bin`.

## Validated models (from `docs/backend/OPENVINO.md`)

| Model | CPU | GPU | NPU |
|-------|-----|-----|-----|
| Qwen2.5-1.5B-Instruct (Q4_K_M) | yes | yes | yes |
| Qwen3-8B-Instruct (Q4_K_M) | yes | bench-only | yes |

NPU primarily supports `Q4_0`; `Q4_K_M` works but its `Q6_K` tensors are
re-quantized to `Q4_0_128` at runtime (one-time cost on first run).
