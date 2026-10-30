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
// Counts and offsets are UTF-16 code units, copied back with
// `thread_pool/get_read_console_result`. The job waits for console input
// records and owns the event that cancels the wait.
#unsafe_skip_stub_check
fn JobHandle::tty_read_console_input(
  input : @fd_util.Fd,
  len : Int32,
) -> JobHandle = "moonbitlang/async" "thread_pool/make_tty_read_console_input_job"

///|
fn TtyReadConsoleInputJob::new(
  input : @fd_util.Fd,
  buf : FixedArray[UInt16],
  offset : Int32,
  len : Int32,
) -> TtyReadConsoleInputJob {
  TtyReadConsoleInputJob(
    Job(JobHandle::tty_read_console_input(input, len), copy_output=job => {
      job.get_read_console_result(buf, offset, len)
    }),
  )
}

///|
#unsafe_skip_stub_check
fn JobHandle::tty_read_console_input_resized(self : JobHandle) -> Bool = "moonbitlang/async" "thread_pool/tty_read_console_input_job_get_resized"

///|
/// Whether a resize was read along with the returned input
fn TtyReadConsoleInputJob::resized(self : TtyReadConsoleInputJob) -> Bool {
  self.0.handle.tty_read_console_input_resized()
}
