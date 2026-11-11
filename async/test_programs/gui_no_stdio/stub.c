// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <moonbit.h>

#ifdef _WIN32
#include <windows.h>

// Clear handles before MoonBit globals and event-loop hooks initialize. CI
// normally supplies pipes even to GUI programs, so the subsystem alone is not
// enough to reproduce launching a GUI application without standard handles.
static void clear_standard_handles(void) {
  SetStdHandle(STD_INPUT_HANDLE, NULL);
  SetStdHandle(STD_OUTPUT_HANDLE, NULL);
  SetStdHandle(STD_ERROR_HANDLE, NULL);
  SetLastError(ERROR_SUCCESS);
}

#ifdef _MSC_VER
#pragma comment(linker, "/SUBSYSTEM:WINDOWS")
#pragma comment(linker, "/ENTRY:mainCRTStartup")
#pragma section(".CRT$XCU", read)
__declspec(allocate(".CRT$XCU"))
static void (*const initialize_standard_handles)(void) = clear_standard_handles;
#else
__attribute__((constructor)) static void initialize_standard_handles(void) {
  clear_standard_handles();
}
#endif

MOONBIT_FFI_EXPORT int32_t standard_handles_are_null(void) {
  return GetStdHandle(STD_INPUT_HANDLE) == NULL &&
         GetStdHandle(STD_OUTPUT_HANDLE) == NULL &&
         GetStdHandle(STD_ERROR_HANDLE) == NULL;
}
#else
MOONBIT_FFI_EXPORT int32_t standard_handles_are_null(void) { return 0; }
#endif
