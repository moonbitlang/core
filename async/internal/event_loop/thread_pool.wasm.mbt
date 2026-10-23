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
priv struct Worker(UInt64)

///|
#unsafe_skip_stub_check
fn init_thread_pool_ffi(bus : EventBus) -> @fd_util.Fd = "moonbitlang/async" "thread_pool/init_thread_pool"

///|
#unsafe_skip_stub_check
fn destroy_thread_pool() -> Unit = "moonbitlang/async" "thread_pool/destroy_thread_pool"

///|
#unsafe_skip_stub_check
fn Worker::spawn_ffi(init_job_id : Int32, init_job : JobHandle) -> Worker = "moonbitlang/async" "thread_pool/spawn_worker"

///|
fn Worker::spawn(init_job_id : Int32, init_job : Job) -> Worker {
  Worker::spawn_ffi(init_job_id, init_job.handle)
}

///|
#unsafe_skip_stub_check
fn Worker::free(worker : Worker) -> Unit = "moonbitlang/async" "thread_pool/free_worker"

///|
#unsafe_skip_stub_check
fn Worker::wake_ffi(worker : Worker, job_id : Int32, job : JobHandle) -> Unit = "moonbitlang/async" "thread_pool/wake_worker"

///|
fn Worker::wake(worker : Worker, job_id : Int32, job : Job) -> Unit {
  worker.wake_ffi(job_id, job.handle)
}

///|
#unsafe_skip_stub_check
fn Worker::enter_idle(worker : Worker) -> Unit = "moonbitlang/async" "thread_pool/worker_enter_idle"

///|
// 0: retry later; 1: keep waiting; 2: the job result is ready.
#unsafe_skip_stub_check
fn Worker::cancel_ffi(worker : Worker) -> Int32 = "moonbitlang/async" "thread_pool/cancel_worker_with_retry"

///|
fn Worker::cancel(
  worker : Worker,
  context~ : String,
) -> CancellationStatus raise {
  match worker.cancel_ffi() {
    0 => RetryLater
    // Retire the worker through its completion notification even if its job
    // has already finished, as the native cancellation path does.
    1 | 2 => NeedWait
    _ => {
      @os_error.check_errno(context)
      NoWait
    }
  }
}

///|
fn Worker::check_cancellation_retry(worker : Worker) -> Bool {
  // Use the same host call for initial cancellation and completion checks.
  // Native also keeps waiting if a cancellation attempt reports an error.
  worker.cancel_ffi() != 2
}

///|
#unsafe_skip_stub_check
#borrow(output)
fn fetch_completion_ffi(
  notify_recv : @fd_util.Fd,
  output : FixedArray[Int32],
  len~ : Int32 = output.length(),
) -> Int32 = "moonbitlang/async" "thread_pool/fetch_completion/unix"

///|
/// The actual job object submitted to the thread pool in runtime
priv struct JobHandle(UInt64)

///|
/// In WASM backend, letting the thread pool occupy reference to
/// (mapped) physical address of WASM memory is unsafe,
/// because `memory.grow` may change the base address of WASM memory.
/// Hence for all output buffer passed to the thread pool,
/// we need to allocate a temporary buffer in the runtime instead,
/// and copy output data to the MoonBit buffer only after job completion.
/// To align with native API, this copy phase is implemented as a callback.
#valtype
priv struct Job {
  handle : JobHandle
  copy_output : ((JobHandle) -> Unit)?
}

///|
fn Job::Job(handle : JobHandle, copy_output? : (JobHandle) -> Unit) -> Job {
  { handle, copy_output, }
}

///|
#unsafe_skip_stub_check
fn JobHandle::free(self : JobHandle) -> Unit = "moonbitlang/async" "thread_pool/free_job"

///|
fn Job::free(self : Job) -> Unit {
  self.handle.free()
}

///|
#unsafe_skip_stub_check
fn JobHandle::ret(self : JobHandle) -> Int32 = "moonbitlang/async" "thread_pool/job_get_ret"

///|
fn Job::ret(self : Job) -> Int32 {
  self.handle.ret()
}

///|
#unsafe_skip_stub_check
fn JobHandle::err(self : JobHandle) -> Int32 = "moonbitlang/async" "thread_pool/job_get_err"

///|
fn Job::err(self : Job) -> Int32 {
  self.handle.err()
}

///|
fn Job::copy_output(self : Job) -> Unit {
  if self.copy_output is Some(copy_output) {
    copy_output(self.handle)
  }
}

///|
#unsafe_skip_stub_check
fn JobHandle::read(
  fd : @fd_util.Fd,
  len : Int32,
  position~ : Int64,
) -> JobHandle = "moonbitlang/async" "thread_pool/make_read_job"

///|
#unsafe_skip_stub_check
#borrow(buf)
fn JobHandle::get_read_result(
  self : JobHandle,
  buf : FixedArray[Byte],
  offset : Int32,
  len : Int32,
) -> Unit = "moonbitlang/async" "thread_pool/get_read_result"

///|
fn Job::read(
  fd : @fd_util.Fd,
  buf : FixedArray[Byte],
  offset : Int32,
  len : Int32,
  // `-1` indicates no offset
  position~ : Int64,
) -> Job {
  Job(JobHandle::read(fd, len, position~), copy_output=job => {
    job.get_read_result(buf, offset, len)
  })
}

///|
#unsafe_skip_stub_check
#borrow(buf)
fn JobHandle::write(
  fd : @fd_util.Fd,
  buf : Bytes,
  offset : Int32,
  len : Int32,
  // `-1` indicates no offset
  position~ : Int64,
) -> JobHandle = "moonbitlang/async" "thread_pool/make_write_job"

///|
fn Job::write(
  fd : @fd_util.Fd,
  buf : Bytes,
  offset : Int32,
  len : Int32,
  // `-1` indicates no offset
  position~ : Int64,
) -> Job {
  Job(JobHandle::write(fd, buf, offset, len, position~))
}

///|
// Counts and offsets at this boundary are UTF-16 code units. The host owns the
// buffer while a worker is running; the completion callback copies it back.
#unsafe_skip_stub_check
fn JobHandle::read_console(fd : @fd_util.Fd, len : Int32) -> JobHandle = "moonbitlang/async" "thread_pool/make_read_console_job"

///|
#unsafe_skip_stub_check
#borrow(buf)
fn JobHandle::get_read_console_result(
  self : JobHandle,
  buf : FixedArray[UInt16],
  offset : Int32,
  len : Int32,
) -> Unit = "moonbitlang/async" "thread_pool/get_read_console_result"

///|
fn Job::read_console(
  fd : @fd_util.Fd,
  buf : FixedArray[UInt16],
  offset : Int32,
  len : Int32,
) -> Job {
  Job(JobHandle::read_console(fd, len), copy_output=job => {
    job.get_read_console_result(buf, offset, len)
  })
}

///|
#unsafe_skip_stub_check
#borrow(buf)
fn JobHandle::write_console(
  fd : @fd_util.Fd,
  buf : FixedArray[UInt16],
  offset : Int32,
  len : Int32,
) -> JobHandle = "moonbitlang/async" "thread_pool/make_write_console_job"

///|
fn Job::write_console(
  fd : @fd_util.Fd,
  buf : FixedArray[UInt16],
  offset : Int32,
  len : Int32,
) -> Job {
  Job(JobHandle::write_console(fd, buf, offset, len))
}

///|
#unsafe_skip_stub_check
#borrow(filename)
fn JobHandle::open(
  filename : @os_string.OsString,
  filename_len~ : Int32 = filename.to_string().length(),
  // 0 => read only, 1 => write only, 2 => read write
  access : Int32,
  // See `@fs.CreateMode` for more details
  create~ : Int32,
  append~ : Bool,
  // 0 => no sync, 1 => data sync, 2 => full sync
  sync~ : Int32,
  // permission for file when new file is created
  mode~ : Int32,
  stat_request~ : UInt32,
  stat_buf_len~ : Int32,
) -> JobHandle = "moonbitlang/async" "thread_pool/make_open_stat_job"

///|
priv struct OpenJob(Job)

///|
fn Job::open(
  filename : @os_string.OsString,
  // 0 => read only, 1 => write only, 2 => read write
  access : Int32,
  // See `@fs.CreateMode` for more details
  create~ : Int32,
  append~ : Bool,
  // 0 => no sync, 1 => data sync, 2 => full sync
  sync~ : Int32,
  // permission for file when new file is created
  mode~ : Int32,
  stat_request~ : UInt32,
  stat_buf~ : FixedArray[Byte],
  stat_buf_len~ : Int32,
) -> OpenJob {
  Job(
    JobHandle::open(
      filename,
      access,
      create~,
      append~,
      sync~,
      mode~,
      stat_request~,
      stat_buf_len~,
    ),
    copy_output=job => job.get_stat_result(stat_buf, stat_buf_len),
  )
}

///|
#unsafe_skip_stub_check
fn OpenJob::fd_ffi(job : JobHandle) -> @fd_util.Fd = "moonbitlang/async" "thread_pool/open_job_get_fd"

///|
fn OpenJob::fd(job : OpenJob) -> @fd_util.Fd {
  OpenJob::fd_ffi(job.0.handle)
}

///|
#unsafe_skip_stub_check
#borrow(buf)
fn JobHandle::get_stat_result(
  self : JobHandle,
  buf : FixedArray[Byte],
  buf_len : Int32,
) -> Unit = "moonbitlang/async" "thread_pool/get_stat_result"

///|
/// Constant used as input of `statx` for retrieving the kind of a file
pub const STAT_FILE_KIND : UInt32 = 0x0001

///|
/// Constant used as input of `statx` for retrieving the size of a file
pub const STAT_FILE_SIZE : UInt32 = 0x0002

///|
/// Constant used as input of `statx` for retrieving the drive ID of a regular file
pub const STAT_DEVICE_ID : UInt32 = 0x0004

///|
/// Constant used as input of `statx` for retrieving the inode number of a regular file
pub const STAT_FILE_ID : UInt32 = 0x0008

///|
/// Constant used as input of `statx` for retrieving the last access time of a file
pub const STAT_ACCESS_TIME : UInt32 = 0x0010

///|
/// Constant used as input of `statx` for retrieving the last modify time of a file
pub const STAT_MODIFY_TIME : UInt32 = 0x0020

///|
/// Constant used as input of `statx` for retrieving the last metdata change time of a file
pub const STAT_CHANGE_TIME : UInt32 = 0x0040

///|
/// Constant used as input of `statx` for retrieving the creation time of a file
pub const STAT_CREATE_TIME : UInt32 = 0x0080

///|
#unsafe_skip_stub_check
fn JobHandle::fstatx(
  fd : @fd_util.Fd,
  request : UInt32,
  buf_len : Int32,
) -> JobHandle = "moonbitlang/async" "thread_pool/make_fstatx_job"

///|
fn Job::fstatx(
  fd : @fd_util.Fd,
  request : UInt32,
  buf : FixedArray[Byte],
  buf_len : Int32,
) -> Job {
  Job(JobHandle::fstatx(fd, request, buf_len), copy_output=job => {
    job.get_stat_result(buf, buf_len)
  })
}

///|
#unsafe_skip_stub_check
#borrow(path)
fn JobHandle::statx(
  path : @os_string.OsString,
  path_len~ : Int32 = path.to_string().length(),
  request : UInt32,
  buf_len : Int32,
  parent~ : @fd_util.Fd,
  follow_symlink~ : Bool,
) -> JobHandle = "moonbitlang/async" "thread_pool/make_statx_job"

///|
fn Job::statx(
  path : @os_string.OsString,
  request : UInt32,
  buf : FixedArray[Byte],
  buf_len : Int32,
  parent~ : @fd_util.Fd,
  follow_symlink~ : Bool,
) -> Job {
  Job(JobHandle::statx(path, request, buf_len, parent~, follow_symlink~), copy_output=job => {
    job.get_stat_result(buf, buf_len)
  })
}

///|
/// The permission to test for `acess()`
pub(all) enum Access {
  Exist = 0
  CanRead = 1
  CanWrite = 2
  CanExecute = 3
}

///|
#unsafe_skip_stub_check
#borrow(path)
fn JobHandle::access(
  path : @os_string.OsString,
  path_len~ : Int32 = path.to_string().length(),
  access : Access,
) -> JobHandle = "moonbitlang/async" "thread_pool/make_access_job"

///|
fn Job::access(path : @os_string.OsString, access : Access) -> Job {
  Job(JobHandle::access(path, access))
}

///|
#unsafe_skip_stub_check
#borrow(path)
fn JobHandle::chmod(
  path : @os_string.OsString,
  path_len~ : Int32 = path.to_string().length(),
  mode : Int32,
) -> JobHandle = "moonbitlang/async" "thread_pool/make_chmod_job"

///|
fn Job::chmod(path : @os_string.OsString, mode : Int32) -> Job {
  Job(JobHandle::chmod(path, mode))
}

///|
#unsafe_skip_stub_check
fn JobHandle::fsync(fd : @fd_util.Fd, only_data : Bool) -> JobHandle = "moonbitlang/async" "thread_pool/make_fsync_job"

///|
fn Job::fsync(fd : @fd_util.Fd, only_data : Bool) -> Job {
  Job(JobHandle::fsync(fd, only_data))
}

///|
#unsafe_skip_stub_check
fn JobHandle::flock(fd : @fd_util.Fd, exclusive : Bool) -> JobHandle = "moonbitlang/async" "thread_pool/make_flock_job"

///|
fn Job::flock(fd : @fd_util.Fd, exclusive : Bool) -> Job {
  Job(JobHandle::flock(fd, exclusive))
}

///|
#unsafe_skip_stub_check
#borrow(path)
fn JobHandle::remove(
  path : @os_string.OsString,
  path_len~ : Int32 = path.to_string().length(),
) -> JobHandle = "moonbitlang/async" "thread_pool/make_remove_job"

///|
fn Job::remove(path : @os_string.OsString) -> Job {
  Job(JobHandle::remove(path))
}

///|
#unsafe_skip_stub_check
#borrow(old_path, new_path)
fn JobHandle::rename(
  old_path : @os_string.OsString,
  old_path_len~ : Int32 = old_path.to_string().length(),
  new_path : @os_string.OsString,
  new_path_len~ : Int32 = new_path.to_string().length(),
  replace~ : Bool,
) -> JobHandle = "moonbitlang/async" "thread_pool/make_rename_job"

///|
fn Job::rename(
  old_path : @os_string.OsString,
  new_path : @os_string.OsString,
  replace~ : Bool,
) -> Job {
  Job(JobHandle::rename(old_path, new_path, replace~))
}

///|
#unsafe_skip_stub_check
#borrow(target, path)
fn JobHandle::symlink(
  target : @os_string.OsString,
  target_len~ : Int32 = target.to_string().length(),
  path : @os_string.OsString,
  path_len~ : Int32 = path.to_string().length(),
  force_symlink~ : Bool,
) -> JobHandle = "moonbitlang/async" "thread_pool/make_symlink_job"

///|
fn Job::symlink(
  target : @os_string.OsString,
  path : @os_string.OsString,
  force_symlink~ : Bool,
) -> Job {
  Job(JobHandle::symlink(target, path, force_symlink~))
}

///|
#unsafe_skip_stub_check
#borrow(path)
fn JobHandle::mkdir(
  path : @os_string.OsString,
  path_len~ : Int32 = path.to_string().length(),
  mode : Int32,
) -> JobHandle = "moonbitlang/async" "thread_pool/make_mkdir_job"

///|
fn Job::mkdir(path : @os_string.OsString, mode : Int32) -> Job {
  Job(JobHandle::mkdir(path, mode))
}

///|
#unsafe_skip_stub_check
#borrow(path)
fn JobHandle::rmdir(
  path : @os_string.OsString,
  path_len~ : Int32 = path.to_string().length(),
) -> JobHandle = "moonbitlang/async" "thread_pool/make_rmdir_job"

///|
fn Job::rmdir(path : @os_string.OsString) -> Job {
  Job(JobHandle::rmdir(path))
}

///|
#unsafe_skip_stub_check
#borrow(buf)
fn JobHandle::readdir(
  dir : @fd_util.Fd,
  buf : @c_buffer.Buffer,
  len : Int32,
  restart : Bool,
) -> JobHandle = "moonbitlang/async" "thread_pool/make_readdir_job"

///|
fn Job::readdir(
  dir : @fd_util.Fd,
  buf : @c_buffer.Buffer,
  len : Int32,
  restart : Bool,
) -> Job {
  Job(JobHandle::readdir(dir, buf, len, restart))
}

///|
#unsafe_skip_stub_check
#borrow(addr)
fn JobHandle::bind(
  socket : @fd_util.Fd,
  addr : Bytes,
  addr_len~ : Int32 = addr.length(),
) -> JobHandle = "moonbitlang/async" "thread_pool/make_bind_job"

///|
fn Job::bind(socket : @fd_util.Fd, addr : Bytes) -> Job {
  Job(JobHandle::bind(socket, addr))
}

///|
#unsafe_skip_stub_check
#borrow(host)
fn JobHandle::getaddrinfo(
  host : @os_string.OsString,
  host_len~ : Int32 = host.to_string().length(),
) -> JobHandle = "moonbitlang/async" "thread_pool/make_getaddrinfo_job"

///|
fn Job::getaddrinfo(host : @os_string.OsString) -> Job {
  Job(JobHandle::getaddrinfo(host))
}

///|
#unsafe_skip_stub_check
fn JobHandle::get_getaddrinfo_result(job : JobHandle) -> AddrInfo = "moonbitlang/async" "thread_pool/get_getaddrinfo_result"

///|
fn Job::get_getaddrinfo_result(job : Job) -> AddrInfo {
  job.handle.get_getaddrinfo_result()
}

///|
#unsafe_skip_stub_check
#borrow(path)
fn JobHandle::realpath(
  path : @os_string.OsString,
  path_len~ : Int32 = path.to_string().length(),
) -> JobHandle = "moonbitlang/async" "thread_pool/make_realpath_job"

///|
fn Job::realpath(path : @os_string.OsString) -> Job {
  Job(JobHandle::realpath(path))
}

///|
#unsafe_skip_stub_check
fn JobHandle::get_realpath_result(job : JobHandle) -> @c_buffer.Buffer = "moonbitlang/async" "thread_pool/get_realpath_result"

///|
fn Job::get_realpath_result(job : Job) -> @c_buffer.Buffer {
  job.handle.get_realpath_result()
}

///|
priv struct SpawnJob(Job)

///|
#unsafe_skip_stub_check
#borrow(path)
fn JobHandle::spawn_unix_ffi(
  path : @os_string.OsString,
  path_len~ : Int32 = path.to_string().length(),
  args : UInt64,
  env~ : UInt64,
  stdin~ : @fd_util.Fd,
  stdout~ : @fd_util.Fd,
  stderr~ : @fd_util.Fd,
) -> JobHandle = "moonbitlang/async" "thread_pool/spawn_job/unix"

///|
// Use JobHandle at the Wasm boundary so the private fields nested in Job are
// not lowered as additional import parameters.
#unsafe_skip_stub_check
#borrow(cwd)
fn JobHandle::spawn_job_set_cwd(
  job : JobHandle,
  cwd : @os_string.OsString,
  cwd_len~ : Int32 = cwd.to_string().length(),
) -> Unit = "moonbitlang/async" "thread_pool/spawn_job/set_cwd"

///|
fn SpawnJob::set_cwd(job : SpawnJob, cwd : @os_string.OsString) -> Unit {
  job.0.handle.spawn_job_set_cwd(cwd)
}

///|
fn Job::spawn_unix(
  path : @os_string.OsString,
  args : UInt64,
  env~ : UInt64,
  stdin~ : @fd_util.Fd,
  stdout~ : @fd_util.Fd,
  stderr~ : @fd_util.Fd,
  is_orphan~ : Bool,
  cwd~ : @os_string.OsString?,
) -> SpawnJob {
  // Match native Unix: hard-termination child cleanup is not supported, so
  // orphan status does not change the spawn job.
  ignore(is_orphan)
  let job = SpawnJob(
    Job(JobHandle::spawn_unix_ffi(path, args, env~, stdin~, stdout~, stderr~)),
  )
  if cwd is Some(cwd) {
    job.set_cwd(cwd)
  }
  job
}

///|
#unsafe_skip_stub_check
#borrow(command_line)
fn JobHandle::spawn_windows_ffi(
  command_line : @os_string.OsString,
  command_line_len~ : Int32 = command_line.to_string().length(),
  env~ : UInt64,
  stdin~ : @fd_util.Fd,
  stdout~ : @fd_util.Fd,
  stderr~ : @fd_util.Fd,
  is_orphan~ : Bool,
) -> JobHandle = "moonbitlang/async" "thread_pool/spawn_job/windows"

///|
// Keep the setter on JobHandle for the same aggregate-lowering reason as cwd.
#unsafe_skip_stub_check
fn JobHandle::spawn_job_set_no_console_window(job : JobHandle) -> Unit = "moonbitlang/async" "thread_pool/spawn_job/set_no_console_window"

///|
fn SpawnJob::set_no_console_window(job : SpawnJob) -> Unit {
  job.0.handle.spawn_job_set_no_console_window()
}

///|
fn Job::spawn_windows(
  command_line : @os_string.OsString,
  env~ : UInt64,
  stdin~ : @fd_util.Fd,
  stdout~ : @fd_util.Fd,
  stderr~ : @fd_util.Fd,
  cwd~ : @os_string.OsString?,
  no_console_window~ : Bool,
  is_orphan~ : Bool,
) -> SpawnJob {
  let job = SpawnJob(
    Job(
      JobHandle::spawn_windows_ffi(
        command_line,
        env~,
        stdin~,
        stdout~,
        stderr~,
        is_orphan~,
      ),
    ),
  )
  if cwd is Some(cwd) {
    job.set_cwd(cwd)
  }
  if no_console_window {
    job.set_no_console_window()
  }
  job
}

///|
#unsafe_skip_stub_check
fn JobHandle::spawn_job_result_handle(job : JobHandle) -> @fd_util.Fd = "moonbitlang/async" "thread_pool/spawn_job_get_result_handle"

///|
fn SpawnJob::result_handle(job : SpawnJob) -> @fd_util.Fd {
  job.0.handle.spawn_job_result_handle()
}

///|
#unsafe_skip_stub_check
fn JobHandle::wait_for_process(handle : @fd_util.Fd, pid~ : Int32) -> JobHandle = "moonbitlang/async" "thread_pool/make_wait_for_process_job"

///|
fn Job::wait_for_process(handle : @fd_util.Fd, pid~ : Int32) -> Job {
  Job(JobHandle::wait_for_process(handle, pid~))
}

///|
#unsafe_skip_stub_check
#borrow(path)
fn JobHandle::inotify_add_watch(
  inotify : @fd_util.Fd,
  path : @os_string.OsString,
  path_len~ : Int32 = path.to_string().length(),
  is_dir : Bool,
) -> JobHandle = "moonbitlang/async" "thread_pool/make_inotify_add_watch_job"

///|
fn Job::inotify_add_watch(
  inotify : @fd_util.Fd,
  path : @os_string.OsString,
  is_dir : Bool,
) -> Job {
  Job(JobHandle::inotify_add_watch(inotify, path, is_dir))
}
