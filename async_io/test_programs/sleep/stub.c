/*
 * Copyright 2025 International Digital Economy Academy
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

#include <stdint.h>
#include <stdio.h>
#include <moonbit.h>

static int32_t swallow_cancel_signal = 0;

MOONBIT_FFI_EXPORT
void set_swallow_cancel_signal() {
  swallow_cancel_signal = 1;
}

#ifdef _WIN32

#include <windows.h>

BOOL WINAPI handler(DWORD ctrl_type) {
  switch (ctrl_type) {
    case CTRL_BREAK_EVENT:
      printf("received termination signal\n");
      fflush(stdout);
      if (!swallow_cancel_signal)
        ExitProcess(1);
      break;
    default:
      printf("received other signal\n");
      fflush(stdout);
      break;
  }
  return TRUE;
}

MOONBIT_FFI_EXPORT
void register_termination_handler() {
  SetConsoleCtrlHandler(&handler, TRUE);
}

#else

#include <signal.h>
#include <stdlib.h>

void handler(int s) {
  switch (s) {
    case SIGTERM:
      printf("received termination signal\n");
      fflush(stdout);
      if (!swallow_cancel_signal)
        exit(1);
      break;
    default:
      printf("received other signal\n");
      fflush(stdout);
      break;
  }
}

void register_termination_handler() {
  signal(SIGTERM, &handler);
  signal(SIGINT, &handler);
}

#endif
