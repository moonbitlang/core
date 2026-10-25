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

#ifdef __MACH__

#include <pthread.h>
#include <mach/mach.h>
#include <mach/mach_time.h>

_Noreturn void moonbit_panic();

#endif

#include "moonbit.h"

MOONBIT_FFI_EXPORT
void increase_current_thread_priority() {
#ifdef __MACH__
  static int32_t already_processsed = 0;
  if (already_processsed)
    return;

  already_processsed = 1;

  // https://developer.apple.com/library/archive/documentation/Darwin/Conceptual/KernelProgramming/scheduler/scheduler.html#//apple_ref/doc/uid/TP30000905-CH211-BABCHEEB

  mach_timebase_info_data_t timebase_info;
  mach_timebase_info(&timebase_info);

  const uint64_t NANOS_PER_MSEC = 1000000ULL;
  double clock2abs = ((double)timebase_info.denom / (double)timebase_info.numer) * NANOS_PER_MSEC;


  thread_time_constraint_policy_data_t policy;
  policy.period      = 0;
  policy.computation = (uint32_t)(5 * clock2abs); // 5 ms of work
  policy.constraint  = (uint32_t)(10 * clock2abs);
  policy.preemptible = FALSE;

  int kr = thread_policy_set(
    pthread_mach_thread_np(pthread_self()),
    THREAD_TIME_CONSTRAINT_POLICY,
    (thread_policy_t)&policy,
    THREAD_TIME_CONSTRAINT_POLICY_COUNT
  );
  if (kr != KERN_SUCCESS) {
    mach_error("thread_policy_set:", kr);
    moonbit_panic();
  }
#endif
}
