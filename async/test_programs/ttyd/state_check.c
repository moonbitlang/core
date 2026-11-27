/*
 * Copyright 2026 International Digital Economy Academy
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// Test-only observer: keep independent handles until after event loop cleanup.
#include <moonbit.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#ifdef _WIN32
#include <windows.h>
static HANDLE input, output;
static DWORD input_mode, output_mode;
static int32_t ttyd_save_state(void) {
  input = CreateFileW(L"CONIN$", GENERIC_READ | GENERIC_WRITE,
      FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL);
  output = CreateFileW(L"CONOUT$", GENERIC_READ | GENERIC_WRITE,
      FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL);
  return GetConsoleMode(input, &input_mode) && GetConsoleMode(output, &output_mode);
}
static int32_t ttyd_check_state(void) {
  DWORD current_input, current_output;
  int ok = GetConsoleMode(input, &current_input) && GetConsoleMode(output, &current_output)
      && current_input == input_mode && current_output == output_mode;
  CloseHandle(input);
  CloseHandle(output);
  return ok;
}
#else
#include <fcntl.h>
#include <termios.h>
#include <unistd.h>
static int terminal;
static struct termios saved;
static int32_t ttyd_save_state(void) {
  terminal = open("/dev/tty", O_RDWR | O_NOCTTY);
  return terminal >= 0 && tcgetattr(terminal, &saved) == 0;
}
static int32_t ttyd_check_state(void) {
  struct termios current;
  int ok = tcgetattr(terminal, &current) == 0;
  close(terminal);
  if (!ok) return 0;
  if (current.c_iflag != saved.c_iflag || current.c_oflag != saved.c_oflag ||
      current.c_cflag != saved.c_cflag || current.c_lflag != saved.c_lflag ||
      cfgetispeed(&current) != cfgetispeed(&saved) ||
      cfgetospeed(&current) != cfgetospeed(&saved)) return 0;
  for (int i = 0; i < NCCS; i++) {
    if (current.c_cc[i] != saved.c_cc[i]) return 0;
  }
  return 1;
}
#endif

static void verify_restored(void) {
  if (!ttyd_check_state()) {
    fputs("terminal state was not restored\n", stderr);
    // Distinguish restoration failure from the expected async failure exit (1).
    _Exit(99);
  }
}
MOONBIT_FFI_EXPORT int32_t ttyd_watch_state(void) {
  return ttyd_save_state() && atexit(verify_restored) == 0;
}
