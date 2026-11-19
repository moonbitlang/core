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

// ABI declarations follow moonbitlang/async at 6c3c4c886f63318e15450d15a4cd5d3016f09449.
// "moonbitlang/async" is a host import module, not a MoonBit dependency.

///|
priv struct Handle(UInt64)

///|
priv struct FileJob(UInt64)

///|
/// runtime/get_platform uses the same tags as async's Platform.
priv enum FileHostPlatform {
  Linux = 0
  MacOS = 1
  Windows = 2
}

///|
#unsafe_skip_stub_check
fn file_host_platform() -> FileHostPlatform = "moonbitlang/async" "runtime/get_platform"

///|
fn file_host_is_unix() -> Bool {
  match file_host_platform() {
    Linux | MacOS => true
    Windows => false
  }
}

///|
/// EINTR is 4 on both Linux and macOS; Windows error 4 is not EINTR.
const UNIX_EINTR : Int32 = 4

///|
#unsafe_skip_stub_check
fn FileJob::run(self : FileJob) -> Unit = "moonbitlang/async" "thread_pool/run_job"

///|
#unsafe_skip_stub_check
fn FileJob::free(self : FileJob) -> Unit = "moonbitlang/async" "thread_pool/free_job"

///|
#unsafe_skip_stub_check
fn FileJob::err(self : FileJob) -> Int32 = "moonbitlang/async" "thread_pool/job_get_err"

///|
#unsafe_skip_stub_check
fn FileJob::ret(self : FileJob) -> Int32 = "moonbitlang/async" "thread_pool/job_get_ret"

///|
#unsafe_skip_stub_check
#borrow(path)
fn make_open_job(
  path : String,
  path_len~ : Int32,
  access~ : Int32,
  create~ : Int32,
  append~ : Bool,
  sync~ : Int32,
  permission~ : Int32,
  stat_request~ : UInt32,
  stat_buf_len~ : Int32,
) -> FileJob = "moonbitlang/async" "thread_pool/make_open_stat_job"

///|
#unsafe_skip_stub_check
fn FileJob::fd(self : FileJob) -> Handle = "moonbitlang/async" "thread_pool/open_job_get_fd"

///|
#unsafe_skip_stub_check
fn make_read_job(handle : Handle, len : Int32, position~ : Int64) -> FileJob = "moonbitlang/async" "thread_pool/make_read_job"

///|
#unsafe_skip_stub_check
#borrow(buffer)
fn FileJob::copy_read(
  self : FileJob,
  buffer : FixedArray[Byte],
  offset : Int32,
  len : Int32,
) -> Unit = "moonbitlang/async" "thread_pool/get_read_result"

///|
#unsafe_skip_stub_check
fn file_close_ffi(handle : Handle) -> Int32 = "moonbitlang/async" "fd_util/close_fd"

///|
#unsafe_skip_stub_check
fn file_errno() -> Int32 = "moonbitlang/async" "os_error/get_errno"

///|
fn Handle::read(
  self : Handle,
  buffer : FixedArray[Byte],
  offset : Int32,
  len : Int32,
  position : Int64,
) -> Int32 raise {
  for ;; {
    let job = make_read_job(self, len, position~)
    defer job.free()
    job.run()
    let error = job.err()
    if error == UNIX_EINTR && file_host_is_unix() {
      continue
    }
    guard error == 0 else { raise @os_error.from_errno(error, context="read") }
    let n = job.ret()
    job.copy_read(buffer, offset, n)
    break n
  }
}

///|
fn open(path : String) -> Handle? raise {
  let job = make_open_job(
    path,
    path_len=path.length(),
    access=0,
    create=0,
    append=false,
    sync=0,
    permission=0o600,
    stat_request=0U,
    stat_buf_len=8,
  )
  defer job.free()
  job.run()
  let error = job.err()
  if error == 0 {
    return Some(job.fd())
  }
  try {
    raise @os_error.from_errno(error, context="open \{path}")
  } catch {
    OsError(NotFound, ..) => None
    err => raise err
  }
}

///|
fn Handle::close(self : Handle) -> Unit raise {
  if file_close_ffi(self) < 0 {
    raise @os_error.from_errno(file_errno(), context="close")
  }
}
