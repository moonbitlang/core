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
/// Read console input records into `buf[:len]` and compact them in place
/// into UTF-16 code units. The job owns the event that cancels the wait;
/// `error` is set when that event cannot be created.
#cfg(platform="windows")
#owned(buf)
#borrow(error)
extern "C" fn ReadConsoleInputJob::new(
  input : @fd_util.Fd,
  buf : FixedArray[UInt16],
  len : Int32,
  error : @ref.Ref[Int32],
) -> ReadConsoleInputJob = "moonbit_rt_make_read_console_input_job"

///|
/// Whether a resize was read along with the returned input
#cfg(platform="windows")
extern "C" fn ReadConsoleInputJob::resized(job : ReadConsoleInputJob) -> Bool = "moonbit_rt_read_console_input_job_get_resized"
