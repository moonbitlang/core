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

///|
#owned(buf)
extern "C" fn Job::tty_read(
  input : @fd_util.Fd,
  wakeup : @fd_util.Fd,
  buf : FixedArray[Byte],
  offset : Int32,
  len : Int32,
) -> Job = "moonbit_rt_make_tty_read_job"

///|
#owned(buf)
extern "C" fn TtyReadConsoleInputJob::new(
  input : @fd_util.Fd,
  wakeup : @fd_util.Fd,
  buf : FixedArray[UInt16],
  offset : Int32,
  len : Int32,
) -> TtyReadConsoleInputJob = "moonbit_rt_make_tty_read_console_input_job"

///|
/// Whether a resize was read along with the returned input
extern "C" fn TtyReadConsoleInputJob::resized(
  job : TtyReadConsoleInputJob,
) -> Bool = "moonbit_rt_tty_read_console_input_job_get_resized"
