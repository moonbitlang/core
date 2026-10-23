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

#include <moonbit.h>

#ifdef _WIN32

#include <windows.h>

LPWCH env_ptr = NULL;

MOONBIT_FFI_EXPORT
void init_env() {
  env_ptr = GetEnvironmentStringsW();
}

MOONBIT_FFI_EXPORT
moonbit_string_t next_entry(){
  if (!env_ptr)
    return moonbit_make_string_raw(0);

  int len = wcslen(env_ptr);
  if (len == 0)
    return moonbit_make_string_raw(0);

  moonbit_string_t result = moonbit_make_string_raw(len);
  memcpy(result, env_ptr, len * sizeof(WCHAR));
  env_ptr += len + 1;
  return result;
}

#else

#include <string.h>

extern char **environ;
char **cursor = 0;

void init_env() {
  cursor = environ;
}

moonbit_bytes_t next_entry() {
  if (cursor == 0 || *cursor == 0)
    return moonbit_make_bytes_raw(0);

  int len = strlen(*cursor);
  moonbit_bytes_t result = moonbit_make_bytes_raw(len);
  memcpy(result, *cursor, len);
  cursor += 1;
  return result;
}

#endif
