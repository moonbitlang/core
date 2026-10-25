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
/// The unique identity of a file on the system.
/// Consist of the ID of its device and its unique ID within that device.
#valtype
pub(all) struct FileIdentity {
  dev_id : UInt64
  file_id : UInt64
} derive(Eq, Hash)

///|
/// Open a new handle to the file at `path`.
/// `access` is the desired access of the new handle.
/// `create` describe new file creation and truncation behavior.
/// `append=true` will open the file in append mode.
/// `sync` describes data synchronization behavior when writing to the file handle.
/// `mode` is the Unix permission of created new file, if any.
pub async fn open(
  path : StringView,
  // 0 => read only, 1 => write only, 2 => read write, 3 => directory listing
  access : Int32,
  // See `@fs.CreateMode` for more details
  create~ : Int32,
  append~ : Bool,
  // 0 => no sync, 1 => data sync, 2 => full sync
  sync~ : Int32,
  // permission for file when new file is created
  mode~ : Int32,
  context~ : String,
) -> (IoHandle, FileIdentity) {
  let path_bytes = @os_string.from_string(path)
  let stat_buf = FixedArray::make(32, b'\x00')
  let job = Job::open(
    path_bytes,
    access,
    create~,
    append~,
    sync~,
    mode~,
    stat_request=STAT_FILE_KIND | STAT_DEVICE_ID | STAT_FILE_ID,
    stat_buf~,
    stat_buf_len=stat_buf.length(),
  )
  defer job.0.free()
  try perform_job_in_worker(job.0, context~, cancellable=true) catch {
    @os_error.OsError(_) as err =>
      raise err.wrap_context(context => "\{context}: \{path.escape()}")
    err => raise err
  } noraise {
    _ => {
      let fd = job.fd()
      guard! stat_buf
        is [u32le(_), u32le(mask), i64le(kind), u64le(dev_id), u64le(file_id)]
      guard (mask & STAT_FILE_KIND) > 0 else {
        // we need at least the file kind
        raise @os_error.from_errno(
          @errno_util.not_directory,
          context="\{context}: \{path.escape()}",
        )
      }
      let kind = @fd_util.FileKind::from_int(kind.to_int())
      let io = IoHandle::from_fd(
        fd,
        kind~,
        is_async=access is 3 || (!(platform is Windows) && kind.can_poll()),
        read_only=access is 0,
      )
      if append {
        // For append mode file descriptor, let the OS do the work.
        // Reading is unaffected by `append`.
        io.write_offset = -1
      }
      (io, { dev_id, file_id, })
    }
  }
}

///|
/// A generic `stat`-like operation that retrieve various different information
/// of an existing file descriptor using as few system call as possible.
/// `request` is a bit mask specifying which information should be retrieved.
/// It should be a bitwise `or` of `STAT_*` constants.
/// The requested information will be written to `buf`, whose length is `buf_len`.
/// The layout of data written to `buf` is as follows:
///
/// - the first 32bits is an unsigned integer containing the length of result, in bytes,
///   including the length field itself
///
/// - the next 32bits is an `uint32_t` obtained by OR-ing `STAT_*` constants
///   of successfully returned properties.
///   Some requested properties may be unsupported on certain file systems,
///   in this case they will be missing from the returned bitmask.
///
///   Note that an unsupported property will still occupy space in the output buffer,
///   but the value at the position would be meaningless,
///   so callers should always check the returned bitmask.
///   As a consequence, the layout of the output buffer is fixed for any given input `request`.
///
/// - the rest of the output buffer contain a list of values for each requested property.
///   Each property is 8-byte aligned.
///   The order of supported properties and the content of their value is as follows:
///
///   - `STAT_FILE_KIND`: a `int64_t`, zero extended from `enum FileKind`,
///     holding the kind of the file
///
///   - `STAT_FILE_SIZE`: a `int64_t` holding the size of the file
///
///   - `STAT_DEVICE_ID`: a `uint64_t` holding the ID of the device containing the file.
///     Correspond to `st_dev` from `stat` on Unix-like systems,
///     or the volume serial number on Windows
///
///   - `STAT_FILE_ID`: the unique `uint64_t` id of the file in its file system.
///     Correspond to `st_ino` from `stat` on Unix-like systems,
///     or file id returned by `GetFileInformationByHandle` on Windows.
///
///   - `STAT_ACCESS_TIME`/`STAT_MODIFY_TIME`/`STAT_CHANGE_TIME`/`STAT_CREATE_TIME`:
///     two `int64_t` containing the last access/last data change/last metdata change/creation time
///     of the target file.
///     The first `int64_t` contain the second part, the second `int64_t` contain the nanosecond part
pub async fn fstatx(
  fd : @fd_util.Fd,
  request : UInt32,
  buf : FixedArray[Byte],
  buf_len : Int32,
  context~ : String,
) -> Unit {
  let job = Job::fstatx(fd, request, buf, buf_len)
  defer job.free()
  ignore <| perform_job_in_worker(job, context~)
}

///|
async fn fstatx_single(
  fd : @fd_util.Fd,
  request : UInt32,
  length : Int32,
  context~ : String,
) -> ArrayView[Byte] {
  let buf = FixedArray::make(8 + (length << 3), b'\x00')
  fstatx(fd, request, buf, buf.length(), context~)
  guard! buf is [u32le(_), u32le(mask), .. payload]
  guard (mask & request) != 0 else {
    raise @os_error.from_errno(@errno_util.not_supported, context~)
  }
  payload
}

///|
/// A generic `stat`-like operation that retrieve various different information
/// of the file at `path` using as few system call as possible.
/// `request` is a bit mask specifying which information should be retrieved.
/// It should be a bitwise `or` of `STAT_*` constants.
/// The requested information will be written to `buf`, whose length is `buf_len`.
/// The layout of data written to `buf` is as follows:
///
/// - the first 32bits is an unsigned integer containing the length of result, in bytes,
///   including the length field itself
///
/// - the next 32bits is an `uint32_t` obtained by OR-ing `STAT_*` constants
///   of successfully returned properties.
///   Some requested properties may be unsupported on certain file systems,
///   in this case they will be missing from the returned bitmask.
///
///   Note that an unsupported property will still occupy space in the output buffer,
///   but the value at the position would be meaningless,
///   so callers should always check the returned bitmask.
///   As a consequence, the layout of the output buffer is fixed for any given input `request`.
///
/// - the rest of the output buffer contain a list of values for each requested property.
///   Each property is 8-byte aligned.
///   The order of supported properties and the content of their value is as follows:
///
///   - `STAT_FILE_KIND`: a `int64_t`, zero extended from `enum FileKind`,
///     holding the kind of the file
///
///   - `STAT_FILE_SIZE`: a `int64_t` holding the size of the file
///
///   - `STAT_DEVICE_ID`: a `uint64_t` holding the ID of the device containing the file.
///     Correspond to `st_dev` from `stat` on Unix-like systems,
///     or the volume serial number on Windows
///
///   - `STAT_FILE_ID`: the unique `uint64_t` id of the file in its file system.
///     Correspond to `st_ino` from `stat` on Unix-like systems,
///     or file id returned by `GetFileInformationByHandle` on Windows.
///
///   - `STAT_ACCESS_TIME`/`STAT_MODIFY_TIME`/`STAT_CHANGE_TIME`/`STAT_CREATE_TIME`:
///     two `int64_t` containing the last access/last data change/last metdata change/creation time
///     of the target file.
///     The first `int64_t` contain the second part, the second `int64_t` contain the nanosecond part
pub async fn statx(
  path : StringView,
  parent~ : @fd_util.Fd,
  follow_symlink~ : Bool,
  request : UInt32,
  buf : FixedArray[Byte],
  buf_len : Int32,
  context~ : String,
) -> Unit {
  let path_bytes = @os_string.from_string(path)
  let job = Job::statx(
    path_bytes,
    parent~,
    follow_symlink~,
    request,
    buf,
    buf_len,
  )
  defer job.free()
  try perform_job_in_worker(job, context~) catch {
    @os_error.OsError(_) as err =>
      raise err.wrap_context(context => "\{context}: \{path.escape()}")
    err => raise err
  } noraise {
    _ => ()
  }
}

///|
async fn statx_single(
  path : StringView,
  parent~ : @fd_util.Fd,
  follow_symlink~ : Bool,
  request : UInt32,
  length : Int32,
  context~ : String,
) -> ArrayView[Byte] {
  let buf = FixedArray::make(8 + (length << 3), b'\x00')
  statx(path, parent~, follow_symlink~, request, buf, buf.length(), context~)
  guard! buf is [u32le(_), u32le(mask), .. payload]
  guard (mask & request) != 0 else {
    raise @os_error.from_errno(@errno_util.not_supported, context~)
  }
  payload
}

///|
/// Retrieve the kind of an existing file descriptor.
pub async fn kind_of_fd(
  fd : @fd_util.Fd,
  context~ : String,
) -> @fd_util.FileKind {
  guard! fstatx_single(fd, STAT_FILE_KIND, 1, context~) is [u64le(kind)]
  @fd_util.FileKind::from_int(kind.to_int())
}

///|
/// If `parent` is a valid fd and `path` is relative,
/// `path` will be interpreted relative to the directory pointed by `parent`,
/// see `fstatat` for more details.
/// `parent` is not supported on Windows.
pub async fn file_kind_by_path(
  path : StringView,
  parent~ : @fd_util.Fd,
  follow_symlink~ : Bool,
  context~ : String,
) -> @fd_util.FileKind {
  guard! statx_single(
      path,
      parent~,
      follow_symlink~,
      STAT_FILE_KIND,
      1,
      context~,
    )
    is [u64le(kind)]
  @fd_util.FileKind::from_int(kind.to_int())
}

///|
/// Return the size in bytes of an opened file
pub async fn file_size(fd : @fd_util.Fd, context~ : String) -> Int64 {
  guard! fstatx_single(fd, STAT_FILE_SIZE, 1, context~) is [i64le(size)]
  size
}

///|
/// Return the size in bytes of the file at `path`
pub async fn file_size_of_path(path : StringView, context~ : String) -> Int64 {
  guard! statx_single(
      path,
      parent=@fd_util.invalid_fd,
      follow_symlink=false,
      STAT_FILE_SIZE,
      1,
      context~,
    )
    is [i64le(size)]
  size
}

///|
/// Return the last modification time of an opened file
pub async fn mtime(fd : @fd_util.Fd, context~ : String) -> (Int64, Int32) {
  guard! fstatx_single(fd, STAT_MODIFY_TIME, 2, context~)
    is [i64le(sec), i64le(nsec)]
  (sec, nsec.to_int())
}

///|
/// Return the last access time of an opened file
pub async fn atime(fd : @fd_util.Fd, context~ : String) -> (Int64, Int32) {
  guard! fstatx_single(fd, STAT_ACCESS_TIME, 2, context~)
    is [i64le(sec), i64le(nsec)]
  (sec, nsec.to_int())
}

///|
/// Return the last metadata change time of an opened file
pub async fn ctime(fd : @fd_util.Fd, context~ : String) -> (Int64, Int32) {
  guard! fstatx_single(fd, STAT_CHANGE_TIME, 2, context~)
    is [i64le(sec), i64le(nsec)]
  (sec, nsec.to_int())
}

///|
/// Return the last modification time of the file at `path`
pub async fn mtime_by_path(
  path : StringView,
  follow_symlink~ : Bool,
  context~ : String,
) -> (Int64, Int32) {
  guard! statx_single(
      path,
      parent=@fd_util.invalid_fd,
      follow_symlink~,
      STAT_MODIFY_TIME,
      2,
      context~,
    )
    is [i64le(sec), i64le(nsec)]
  (sec, nsec.to_int())
}

///|
/// Return the last access time of the file at `path`
pub async fn atime_by_path(
  path : StringView,
  follow_symlink~ : Bool,
  context~ : String,
) -> (Int64, Int32) {
  guard! statx_single(
      path,
      parent=@fd_util.invalid_fd,
      follow_symlink~,
      STAT_ACCESS_TIME,
      2,
      context~,
    )
    is [i64le(sec), i64le(nsec)]
  (sec, nsec.to_int())
}

///|
/// Return the last metadata change time of the file at `path`
pub async fn ctime_by_path(
  path : StringView,
  follow_symlink~ : Bool,
  context~ : String,
) -> (Int64, Int32) {
  guard! statx_single(
      path,
      parent=@fd_util.invalid_fd,
      follow_symlink~,
      STAT_CHANGE_TIME,
      2,
      context~,
    )
    is [i64le(sec), i64le(nsec)]
  (sec, nsec.to_int())
}

///|
/// Check if the file at `path` can be accessed with permission specified by `acc` by current process.
pub async fn access(
  path : StringView,
  acc : Access,
  context~ : String,
) -> Int32 {
  let path_bytes = @os_string.from_string(path)
  let job = Job::access(path_bytes, acc)
  defer job.free()
  perform_job_in_worker(job, context~) catch {
    @os_error.OsError(_) as err =>
      raise err.wrap_context(context => "\{context}: \{path.escape()}")
    err => raise err
  }
}

///|
/// Change the Unix permission setting of a file to `mode`.
/// Not supported on Windows.
pub async fn chmod(path : StringView, mode : Int32, context~ : String) -> Unit {
  let path_bytes = @os_string.from_string(path)
  let job = Job::chmod(path_bytes, mode)
  defer job.free()
  try perform_job_in_worker(job, context~) catch {
    @os_error.OsError(_) as err =>
      raise err.wrap_context(context => "\{context}: \{path.escape()}")
    err => raise err
  } noraise {
    _ => ()
  }
}

///|
/// Flush buffered data on the file `handle` to physical storage.
/// If `only_data` is `true`, metadata will not be flushed.
/// The actual behavior of this API vary between systems.
pub async fn IoHandle::fsync(
  handle : IoHandle,
  only_data~ : Bool,
  context~ : String,
) -> Unit {
  let job = Job::fsync(handle.fd, only_data)
  defer job.free()
  perform_job_in_worker(job, context~) |> ignore
}

///|
/// Acquire an advisory lock on a file.
/// If the file is already locked, wait for the lock asynchronously.
/// If `exclusive` is `true`, an exclusive lock is acquired.
/// Otherwise, a shared lock is acquired.
/// See locking related API in `async/fs/file.mbt` for more details.
pub async fn IoHandle::lock(
  handle : IoHandle,
  exclusive~ : Bool,
  context~ : String,
) -> Unit {
  let job = Job::flock(handle.fd, exclusive)
  defer job.free()
  perform_job_in_worker(job, cancellable=true, context~) |> ignore
}

///|
/// Remove a regular file at `path`.
pub async fn remove(path : StringView, context~ : String) -> Unit nocancel {
  let path_bytes = @os_string.from_string(path)
  let job = Job::remove(path_bytes)
  defer job.free()
  @coroutine.protect_from_cancel <| () => {
    try perform_job_in_worker(job, context~) catch {
      @os_error.OsError(_) as err =>
        raise err.wrap_context(context => "\{context}: \{path.escape()}")
      err => raise err
    } noraise {
      _ => ()
    }
  }
}

///|
/// Rename the file at `old_path` to `new_path`.
/// If there is already an existing file at `new_path`,
/// that file will be atomically replaced if `replace` is `true`,
/// otherwise an error will be reported.
pub async fn rename(
  old_path : StringView,
  new_path : StringView,
  replace~ : Bool,
  context~ : String,
) -> Unit {
  let old_path_bytes = @os_string.from_string(old_path)
  let new_path_bytes = @os_string.from_string(new_path)
  let job = Job::rename(old_path_bytes, new_path_bytes, replace~)
  defer job.free()
  try perform_job_in_worker(job, context~) catch {
    @os_error.OsError(_) as err =>
      raise err.wrap_context(context => {
        "\{context}: \{old_path.escape()} => \{new_path.escape()}"
      })
    err => raise err
  } noraise {
    _ => ()
  }
}

///|
/// Create a new symbolic link pointing to `target` at `path`.
/// if `target` is relative, it will be interpreted relative to `path`.
///
/// On Windows, NTFS junction will be created whenever possible.
/// `force_symlink=true` disable NTFS junction creation and always create true symbolic link.
pub async fn symlink(
  target : StringView,
  path : StringView,
  force_symlink~ : Bool,
  context~ : String,
) -> Unit {
  let target_bytes = @os_string.from_string(target)
  let path_bytes = @os_string.from_string(path)
  let job = Job::symlink(target_bytes, path_bytes, force_symlink~)
  defer job.free()
  try perform_job_in_worker(job, context~) catch {
    @os_error.OsError(_) as err =>
      raise err.wrap_context(context => {
        "\{context}: \{target.escape()} => \{path.escape()}"
      })
    err => raise err
  } noraise {
    _ => ()
  }
}

///|
/// Create a new directory at `path`.
pub async fn mkdir(path : StringView, mode~ : Int32, context~ : String) -> Unit {
  let path_bytes = @os_string.from_string(path)
  let job = Job::mkdir(path_bytes, mode)
  defer job.free()
  try perform_job_in_worker(job, context~) catch {
    @os_error.OsError(_) as err =>
      raise err.wrap_context(context => "\{context}: \{path.escape()}")
    err => raise err
  } noraise {
    _ => ()
  }
}

///|
/// Remove an empty directory at `path`.
pub async fn rmdir(path : StringView, context~ : String) -> Unit nocancel {
  let path_bytes = @os_string.from_string(path)
  let job = Job::rmdir(path_bytes)
  defer job.free()
  @coroutine.protect_from_cancel <| () => {
    try perform_job_in_worker(job, context~) catch {
      @os_error.OsError(_) as err =>
        raise err.wrap_context(context => "\{context}: \{path.escape()}")
      err => raise err
    } noraise {
      _ => ()
    }
  }
}

///|
/// Read directory entries from `dir` into `buf`.
/// At most `len` bytes of directory entries will be written.
/// The layout of directory entry is platform dependent, see `async/fs/dir.mbt` for more details.
/// If `restart` is `true`, `readdir` will read directory entries from the start of the directory.
/// Otherwise, `readdir` will preserve previous progress and read for new entries.
pub async fn IoHandle::readdir(
  dir : IoHandle,
  buf : @c_buffer.Buffer,
  len : Int32,
  restart~ : Bool,
  context~ : String,
) -> Int32 {
  guard! dir.read is Idle
  dir.read = Submitted
  defer {
    dir.read = Idle
  }
  let job = Job::readdir(dir.fd, buf, len, restart)
  defer job.free()
  perform_job_in_worker(job, context~)
}

///|
/// Return the real path of a path, resolving all symbolic links.
#cfg(any(target="native", target="wasm"))
pub async fn realpath(path : StringView, context~ : String) -> String {
  let path_bytes = @os_string.from_string(path)
  let job = Job::realpath(path_bytes)
  defer job.free()
  let _ = perform_job_in_worker(job, context~) catch {
    @os_error.OsError(_) as err =>
      raise err.wrap_context(context => "\{context}: \{path.escape()}")
    err => raise err
  }
  let c_path = job.get_realpath_result()
  c_path.decode_as_os_string()
}

///|
/// Perform `inotify_add_watch` on Linux.
/// Since this operation need to perform file system IO,
/// it is dispatched to the thread pool.
#cfg(all(target="native", not(platform="windows")))
pub async fn inotify_add_watch(
  inotify : @fd_util.Fd,
  path : StringView,
  is_dir~ : Bool,
  context~ : String,
) -> @fd_util.Fd {
  let path_bytes = @os_string.from_string(path)
  let job = Job::inotify_add_watch(inotify, path_bytes, is_dir)
  defer job.free()
  perform_job_in_worker(job, context~) catch {
    @os_error.OsError(_) as err =>
      raise err.wrap_context(context => "\{context}: \{path.escape()}")
    err => raise err
  }
}

///|
/// Perform `inotify_add_watch` on Linux.
/// Since this operation need to perform file system IO,
/// it is dispatched to the thread pool.
#cfg(target="wasm")
pub async fn inotify_add_watch(
  inotify : @fd_util.Fd,
  path : StringView,
  is_dir~ : Bool,
  context~ : String,
) -> @fd_util.Fd {
  let path_bytes = @os_string.from_string(path)
  let job = Job::inotify_add_watch(inotify, path_bytes, is_dir)
  defer job.free()
  let wd = perform_job_in_worker(job, context~) catch {
    @os_error.OsError(_) as err =>
      raise err.wrap_context(context => "\{context}: \{path.escape()}")
    err => raise err
  }
  wd.to_uint64()
}

///|
#cfg(platform="windows")
extern "C" fn read_dir_changes_ffi(
  fd : @fd_util.Fd,
  result : IoResult,
) -> Int32 = "moonbit_rt_async_read_dir_changes"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn IoResultHandle::read_dir_changes_ffi(
  fd : @fd_util.Fd,
  result : IoResultHandle,
) -> Int32 = "moonbitlang/async" "io/read_dir_changes/windows"

///|
#cfg(target="wasm")
fn read_dir_changes_ffi(fd : @fd_util.Fd, result : IoResult) -> Int32 {
  IoResultHandle::read_dir_changes_ffi(fd, result.handle)
}

///|
/// Buffer for storing file system events reported by `ReadDirectoryChangesW`
#cfg(platform="windows")
pub(all) struct WindowsWatcherBuf(@c_buffer.Buffer)

///|
/// Buffer for storing file system events reported by `ReadDirectoryChangesW`
#cfg(target="wasm")
pub(all) struct WindowsWatcherBuf(UInt64)

///|
/// zero return value indicates overflow
#cfg(any(platform="windows", target="wasm"))
pub async fn IoHandle::read_dir_changes(
  handle : IoHandle,
  buf : WindowsWatcherBuf,
  len : Int32,
  context~ : String,
) -> Int32 {
  @coroutine.check_cancellation()
  guard! handle.kind is Directory
  let result = IoResult::for_read_dir_changes(buf.0, len~)
  defer result.free()
  let n = read_dir_changes_ffi(handle.fd, result)
  if n >= 0 {
    // The `pause` here prevent a busy loop from exhausting the whole program,
    // and give chance for other tasks to execute.
    @coroutine.pause_nocancel()
    n
  } else if @errno_util.is_nonblocking_io_error() {
    handle.wait_read_result(result, context~)
    result.status(handle.fd, context~) catch {
      @os_error.OsError(_, raw_code~, ..) if raw_code ==
        @errno_util.windows_ERROR_NOTIFY_ENUM_DIR => 0
      err => raise err
    }
  } else {
    @os_error.check_errno(context)
    panic()
  }
}
