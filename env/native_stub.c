#include <stdint.h>
#ifdef _WIN32
#include <windows.h>

// Adapted from https://stackoverflow.com/a/26085827.
uint64_t now_internal() {
  // Note: some broken versions only have 8 trailing zero's, the correct epoch
  // has 9 trailing zero's. This magic number is the number of 100 nanosecond
  // intervals since January 1, 1601 (UTC) until 00:00:00 January 1, 1970
  static const uint64_t EPOCH = ((uint64_t)116444736000000000ULL);

  SYSTEMTIME system_time;
  FILETIME file_time;

  GetSystemTime(&system_time);
  SystemTimeToFileTime(&system_time, &file_time);
  uint64_t time = ((uint64_t)file_time.dwHighDateTime << 32) +
                  (uint64_t)file_time.dwLowDateTime;

  return (uint64_t)((time - EPOCH) / 10000) +
         (uint64_t)(system_time.wMilliseconds);
}
#else
#include <stddef.h>
#include <sys/time.h>

uint64_t now_internal() {
  struct timeval res;
  gettimeofday(&res, NULL);
  return (uint64_t)res.tv_sec * 1000 + (uint64_t)res.tv_usec / 1000;
}
#endif
