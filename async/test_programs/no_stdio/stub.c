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
#include <stdio.h>

#ifdef _WIN32
#include <windows.h>

// Write through a separate file handle: stdio is deliberately unavailable.
// Preserve LastError so the diagnostic does not change initialization behavior.
static int32_t record_handles(const char *stage) {
  DWORD saved_error = GetLastError();
  HANDLE input = GetStdHandle(STD_INPUT_HANDLE);
  HANDLE output = GetStdHandle(STD_OUTPUT_HANDLE);
  HANDLE error = GetStdHandle(STD_ERROR_HANDLE);
  int32_t all_null = input == NULL && output == NULL && error == NULL;
  wchar_t path[32768];
  DWORD length = GetEnvironmentVariableW(
      L"ASYNC_TEST_DIAGNOSTICS_FILE", path, 32768);
  if (length == 0 || length >= 32768) ExitProcess(80);
  HANDLE file = CreateFileW(path, FILE_APPEND_DATA, FILE_SHARE_READ, NULL,
                            OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
  if (file == INVALID_HANDLE_VALUE) ExitProcess(81);
  char line[256];
  int size = snprintf(line, sizeof(line),
                      "%s: all_null=%d stdin=%p stdout=%p stderr=%p\n",
                      stage, all_null, (void *)input, (void *)output, (void *)error);
  DWORD written = 0;
  if (size < 0 || size >= (int)sizeof(line) ||
      !WriteFile(file, line, (DWORD)size, &written, NULL) ||
      written != (DWORD)size) ExitProcess(82);
  CloseHandle(file);
  SetLastError(saved_error);
  return all_null;
}

// Establish and record the precondition before MoonBit globals and event-loop
// hooks initialize. Do not rely on the launcher's inherited standard handles.
static void clear_standard_handles(void) {
  SetStdHandle(STD_INPUT_HANDLE, NULL);
  SetStdHandle(STD_OUTPUT_HANDLE, NULL);
  SetStdHandle(STD_ERROR_HANDLE, NULL);
  SetLastError(ERROR_SUCCESS);
  if (!record_handles("setup")) ExitProcess(83);
}

#ifdef _MSC_VER
#pragma section(".CRT$XCU", read)
__declspec(allocate(".CRT$XCU"))
static void (*const initialize_standard_handles)(void) = clear_standard_handles;
#else
__attribute__((constructor)) static void initialize_standard_handles(void) {
  clear_standard_handles();
}
#endif

MOONBIT_FFI_EXPORT int32_t record_main_entry(void) {
  return record_handles("main");
}
#else
MOONBIT_FFI_EXPORT int32_t record_main_entry(void) { return 0; }
#endif
