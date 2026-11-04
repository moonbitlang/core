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
fn JobHandle::read_console_input(input : @fd_util.Fd, len : Int32) -> JobHandle = "moonbitlang/async" "thread_pool/make_read_console_input_job"

///|
/// Like the native job, `buf[:len]` holds `len / INPUT_RECORD_UNITS` records.
/// The host reads the records itself and returns one code unit per record at
/// most, so it is given that many code units. `error` is never set.
fn ReadConsoleInputJob::new(
  input : @fd_util.Fd,
  buf : FixedArray[UInt16],
  len : Int32,
  error : @ref.Ref[Int32],
) -> ReadConsoleInputJob {
  ignore(error)
  let units = len / INPUT_RECORD_UNITS
  ReadConsoleInputJob(
    Job(JobHandle::read_console_input(input, units), copy_output=job => {
      job.get_read_console_result(buf, 0, units)
    }),
  )
}

///|
#unsafe_skip_stub_check
fn JobHandle::read_console_input_resized(self : JobHandle) -> Bool = "moonbitlang/async" "thread_pool/read_console_input_job_get_resized"

///|
/// Whether a resize was read along with the returned input
fn ReadConsoleInputJob::resized(self : ReadConsoleInputJob) -> Bool {
  self.0.handle.read_console_input_resized()
}
