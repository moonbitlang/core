#ifdef __cplusplus
extern "C" {
#endif

#include <errno.h>
#include <stdio.h>
#include <string.h>

#include "moonbit.h"

MOONBIT_FFI_EXPORT FILE *moonbitlang_core_diff_perf_fopen_ffi(
    moonbit_bytes_t path, moonbit_bytes_t mode) {
  return fopen((const char *)path, (const char *)mode);
}

MOONBIT_FFI_EXPORT int moonbitlang_core_diff_perf_is_null(void *ptr) {
  return ptr == NULL;
}

MOONBIT_FFI_EXPORT size_t moonbitlang_core_diff_perf_fread_ffi(
    moonbit_bytes_t ptr, int size, int nitems, FILE *stream) {
  return fread(ptr, size, nitems, stream);
}

MOONBIT_FFI_EXPORT int moonbitlang_core_diff_perf_fseek_ffi(FILE *stream,
                                                            long offset,
                                                            int whence) {
  return fseek(stream, offset, whence);
}

MOONBIT_FFI_EXPORT long moonbitlang_core_diff_perf_ftell_ffi(FILE *stream) {
  return ftell(stream);
}

MOONBIT_FFI_EXPORT int moonbitlang_core_diff_perf_fclose_ffi(FILE *stream) {
  return fclose(stream);
}

MOONBIT_FFI_EXPORT moonbit_bytes_t
moonbitlang_core_diff_perf_get_error_message(void) {
  const char *err = strerror(errno);
  size_t len = strlen(err);
  moonbit_bytes_t bytes = moonbit_make_bytes((int32_t)len, 0);
  memcpy(bytes, err, len);
  return bytes;
}

#ifdef __cplusplus
}
#endif
