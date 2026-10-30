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
/// Handle to an opened file
pub struct File {
  /// `text` is a builtin UTF-8 view of the file's content.
  /// It can be used for direct UTF-8 based text IO over the file.
  text : @io.Utf8TextView
  priv io : @event_loop.IoHandle
  priv reader_ctrl : @io.BinaryReaderController
  priv writer_ctrl : @io.BinaryWriterController
}

///|
/// Get the underlying file descriptor/Windows HANDLE of a file
pub fn File::fd(self : File) -> @fd_util.Fd {
  self.io.fd()
}

///|
/// Close an opened file handle, release associated resource
pub fn File::close(self : File) -> Unit {
  self.text.close()
  self.io.close()
}

///|
/// Access to request for when opening a file
pub(all) enum Mode {
  ReadOnly = 0
  WriteOnly
  ReadWrite
}

///|
/// Determine how data is synchronized after writing:
///
/// - `NoSync` means no synchronization is performed.
///
/// - `Data` means the data part and relevant metadata such as file size
///   will be synchronized immediately after a `write` call,
///   but other metadata, such as last access time, will not.
///   See man page of `fdatasync(2)` for more details.
///
/// - `Full` means all data and metdata will be synchronized
///   immediately after writing.
///   See man page of `fsync(2)` for more details.
pub(all) enum SyncMode {
  NoSync
  Data
  Full
}

///|
/// Specify how to handle file creation in `@fs.open()`.
///
/// - `OpenExisting`: open an existing file, fail if the file does not exist
/// - `TruncateExisting`: open an existing file and truncate it, fail if the file does not exist
/// - `OpenOrCreate`: if the file exists, open it without truncation. Otherwise create a new file
/// - `CreateOrTruncate`: if the file exists, open it and truncate it. Otherwise create a new file
/// - `CreateNew`: create a new file, fail if the file already exists
pub(all) enum CreateMode {
  /// open an existing file, fail if the file does not exist
  OpenExisting = 0
  /// open an existing file and truncate it, fail if the file does not exist
  TruncateExisting = 1
  /// if the file exists, open it without truncation. Otherwise create a new file
  OpenOrCreate = 2
  /// if the file exists, open it and truncate it. Otherwise create a new file
  CreateOrTruncate = 3
  /// create a new file, fail if the file already exists
  CreateNew = 4
}

///|
fn CreateMode::to_int(self : CreateMode) -> Int32 = "%identity"

///|
/// Open a file. `filename` will be encoded using UTF8.
///
/// - `mode` determines what operations (read/write) are permitted for the file.
///
/// - `sync` determines how data will be synchronized to disk after writing,
///   see `SyncMode` for more details. The default is `NoSync`
///
/// - if `append` is `true` (`false` by default), the file will be opened in append mode.
///   Under append mode, sequential write (via the `@io.BinaryWriter` interface)
///   will always write to the end of the file, even if the file is modified externally.
///   The semantic of reading from the file is unaffected by `append`.
///   Random access write (`write_at`) is forbidden for file opened in append mode.
///
/// - `create_mode` specify how to handle file creation, truncation, etc.
///   See the type `CreateMode` for more details.
///   The default value is `OpenExisting`.
///
/// - `permission` specifies the user permission of the new file,
///   if a new file is created by `@fs.open`.
///   The permission is represented as an integer in UNIX permission style.
///   For example, `0o640` means:
///
///   - the owner of the file can read and write the file (`6`)
///   - users in the owner group of the file can read the file (`4`)
///   - other users can do nothing to the file
///
///   The default value is `0o644` (anyone can read, only owner can write, not executable).
///   `permission` is currently ignored on Windows.
pub async fn open(
  filename : StringView,
  mode~ : Mode,
  sync~ : SyncMode = NoSync,
  append~ : Bool = false,
  create_mode~ : CreateMode = OpenExisting,
  permission~ : Int32 = 0o644,
) -> File {
  let access = match mode {
    ReadOnly => 0
    WriteOnly => 1
    ReadWrite => 2
  }
  let sync = match sync {
    NoSync => 0
    Data => 1
    Full => 2
  }
  let (io, _) = @event_loop.open(
    filename,
    access,
    create=create_mode.to_int(),
    append~,
    sync~,
    mode=permission,
    context="@fs.open()",
  )
  let file = {
    text: @io.Utf8TextView::new_uninitialized(),
    io,
    reader_ctrl: BinaryReaderController(),
    writer_ctrl: BinaryWriterController(),
  }
  file.text.set_inner(file)
  file
}

///|
/// Create a new file at `pathname`. `pathname` will be encoded using UTF8.
///
/// - If the file already exists and `allow_existing` is `true` (`true` by default),
///   the existing file will be truncated and opened.
///   If the file already exists and `allow_existing` is `fale`, this function will fail.
///
/// - User permission of the new file would be set to `permission`,
///   which is an integer in UNIX style. For example, `0o640` means:
///     - the owner of the file can read and write the file (`6`)
///     - users in the owner group of the file can read the file (`4`)
///     - other users can do nothing to the file
///   The default value is `0o644` (anyone can read, only owner can write, not executable).
///   `permission` is currently ignored on Windows.
///
/// - `sync` determines how data will be synchronized to disk after writing,
///   see `SyncMode` for more details. The default is `NoSync`
pub async fn create(
  filename : StringView,
  allow_existing~ : Bool = true,
  permission~ : Int32 = 0o644,
  sync~ : SyncMode = NoSync,
) -> File {
  let create_mode = if allow_existing { CreateOrTruncate } else { CreateNew }
  open(filename, mode=WriteOnly, sync~, create_mode~, permission~)
}

///|
/// When reading a file via the `@io.BinaryReader` interface,
/// the content of the file will be read as a byte stream.
/// The position of the read stream in the file is
/// independent of the write stream (via the `@io.BinaryWriter` interface)
pub impl @io.BinaryReader for File

///|
impl @io.BinaryReaderImpl for File with fn raw_read_impl(
  self,
  buf,
  offset~,
  max_len~,
) {
  self.io.read(
    buf,
    offset~,
    len=max_len,
    context="impl @io.BinaryReader for @fs.File",
  )
}

///|
impl @io.BinaryReaderImpl for File with fn get_controller(self) {
  self.reader_ctrl
}

///|
pub impl @io.BinaryReader for File with fn read_all(self) {
  guard self.io.kind() is Regular else { @io.read_all_binary(self) }
  let size = (self.size() - self.io.read_offset) catch {
    _ => return @io.read_all_binary(self)
  }
  guard size > 0 && size < @int.MAX_VALUE.to_int64() else {
    @io.read_all_binary(self)
  }
  let size_hint = size.to_int()
  let buf = FixedArray::make(size_hint, b'\x00')
  let n = self.read_into(buf, offset=0, max_len=size_hint)
  if n is 0 {
    return b""
  }
  // The only reliable way to detect EOF is `read` returning `0`,
  // even for regular files. So do a simple EOF probe here.
  let eof_probe = FixedArray::make(1, b'\x00')
  if self.read_into(eof_probe, offset=0, max_len=1) is 0 {
    // happy path, the file size is accurate
    return buf.unsafe_reinterpret_as_bytes()[:n].to_owned()
  }
  @io.read_all_binary(
    self,
    prefix_list=[
      buf.unsafe_reinterpret_as_bytes()[:n],
      eof_probe.unsafe_reinterpret_as_bytes(),
    ],
    chunk_size=1 << 16, // 64k
  )
}

///|
pub extend File with @io.BinaryReader::{
  read_into,
  read,
  read_at_least,
  peek,
  peek_at_least,
  read_exactly,
  drop_exactly,
  peek_exactly,
  read_all,
  drop_all,
  read_until,
  peek_until,
}

///|
/// Read from a file at the offset given by `position`.
/// Only seekable files (e.g. regular files and block devices) support this operation,
/// calling `read_at` on unsupported file, such as pipe or socket, result in error.
///
/// This function does not change the cursor for reading/writing the file
/// as a stream (i.e. using `@io.BinaryReader` and `@io.BinaryWriter` APIs),
/// so it is safe to perform multiple `read_at` on the same file simutaneously.
///
/// Up to `len` bytes of data will be read into `buf[offset:]`.
/// The number of bytes actually read would be returned.
/// The number of read bytes will be smaller than `len` only when EOF is reached.
pub async fn File::read_at(
  self : File,
  buf : FixedArray[Byte],
  position~ : Int64,
  offset~ : Int32 = 0,
  len~ : Int32 = buf.length() - offset,
) -> Int32 {
  guard offset >= 0 &&
    offset <= buf.length() &&
    len >= 0 &&
    len <= buf.length() - offset else {
    raise Failure::Failure("`File::read_at()`: destination range out of bounds")
  }
  self.io.read_at(buf, offset~, len~, position~, context="@fs.File::read_at()")
}

///|
/// Read exactly `len` bytes from a file, starting at offset `position`,
/// and return requested content.
/// If there is no enough data before EOF, an error will be raised.
///
/// Only seekable files (e.g. regular files and block devices) support this operation,
/// calling `read_at_exactly` on unsupported file, such as pipe or socket, result in error.
///
/// This function does not change the cursor for reading/writing the file
/// as a stream (i.e. using `@io.BinaryReader` and `@io.BinaryWriter` APIs),
/// so it is safe to perform multiple `read_at` on the same file simutaneously.
pub async fn File::read_exactly_at(
  self : File,
  len : Int32,
  position~ : Int64,
) -> Bytes {
  let buf = FixedArray::make(len, b'\x00')
  let n = self.io.read_at(
    buf,
    offset=0,
    len~,
    position~,
    context="@fs.File::read_exactly_at()",
  )
  if n < len {
    raise @io.ReaderClosed
  }
  buf.unsafe_reinterpret_as_bytes()
}

///|
/// If the file is opened with `append=true`,
/// writing to the file via the `@io.BinaryWriter` interface
/// always append content at the end of the file.
///
/// If the file is opened with `append=false` (the default),
/// content written to the file via the `@io.BinaryWriter` interface
/// will be written as a byte stream, starting at offset 0.
/// The position of the write stream in the file is
/// independent of the read stream (via the `@io.BinaryReader` interface)
pub impl @io.BinaryWriter for File

///|
impl @io.BinaryWriterImpl for File with fn raw_write_impl(
  self,
  buf,
  offset~,
  len~,
) {
  self.io.write(
    buf,
    offset~,
    len~,
    context="impl @io.BinaryWriter for @fs.File",
  )
}

///|
impl @io.BinaryWriterImpl for File with fn get_controller(self) {
  self.writer_ctrl
}

///|
pub extend File with @io.BinaryWriter::{write, write_reader}

///|
/// Write to a file at the offset given by `position`.
/// Only seekable files (e.g. regular files and block devices) support this operation,
/// calling `write_at` on unsupported file, such as pipe or socket, result in error.
///
/// This function does not change the cursor for reading/writing the file
/// as a stream (i.e. using `@io.BinaryReader` and `@io.BinaryWriter` APIs),
/// so it is safe to perform multiple `write_at` on the same file simutaneously,
/// as long as the regions they write do not overlap.
///
/// `write_at` would only return after all data is written.
pub async fn File::write_at(
  self : File,
  buf : BytesView,
  position~ : Int64,
) -> Unit {
  self.io.write_at(
    buf.data(),
    offset=buf.start_offset(),
    len=buf.length(),
    position~,
    context="@fs.File::write_at()",
  )
}

///|
/// Flush all in-memory data of an opened file to disk.
/// If `only_data` is `true` (`false` by default),
/// some metadata such as timestamp may not be flushed.
/// Buf file content and important metadata such as file size are always flushed.
pub async fn File::sync(self : File, only_data~ : Bool = false) -> Unit {
  self.io.fsync(only_data~, context="@fs.File::sync()")
}

///|
/// The kind of lock that can be acquired on a file.
/// `Exclusive` lock must be unique,
/// while multiple `Shared` lock can coexist.
/// `Exclusive` lock and `Shared` lock are mutually exclusive.
pub(all) enum Lock {
  Shared
  Exclusive
}

///|
/// Lock a file, block until the lock is successfully acquired.
///
/// The lock here is advisory, so normal read/write operations
/// on the file are not affected by the lock,
/// only another attempt to lock the same file may conflict with the lock here.
///
/// The underlying syscall used to implement the lock is undefined.
/// So the lock should only be used for synchronization between multiple process
/// written using `moonbitlang/async`.
pub async fn File::lock(self : File, lock : Lock) -> Unit {
  self.io.lock(exclusive=lock is Exclusive, context="@fs.File::lock()")
}

///|
#cfg(target="native")
extern "C" fn try_lock_ffi(fd : @fd_util.Fd, exclusive~ : Bool) -> Int32 = "moonbit_rt_try_lock_file"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn try_lock_ffi(fd : @fd_util.Fd, exclusive~ : Bool) -> Int32 = "moonbitlang/async" "fs/try_lock_file"

///|
/// Try to lock a file.
/// If the lock is successfully acquired, `true` is returned.
/// If the lock cannot be acquired immediately
/// (because an incompatible lock is held by another process),
/// `false` is returned immediately.
///
/// The lock here is advisory, so normal read/write operations
/// on the file are not affected by the lock,
/// only another attempt to lock the same file may conflict with the lock here.
///
/// The underlying syscall used to implement the lock is undefined.
/// So the lock should only be used for synchronization between multiple process
/// written using `moonbitlang/async`.
pub fn File::try_lock(self : File, lock : Lock) -> Bool raise {
  let ret = try_lock_ffi(self.fd(), exclusive=lock is Exclusive)
  if ret >= 0 {
    true
  } else if @errno_util.get_errno() == @errno_util.lock_violation {
    false
  } else {
    @os_error.check_errno("@fs.File::try_lock()")
    false
  }
}

///|
#cfg(target="native")
extern "C" fn unlock_ffi(fd : @fd_util.Fd) -> Int32 = "moonbit_rt_unlock_file"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn unlock_ffi(fd : @fd_util.Fd) -> Int32 = "moonbitlang/async" "fs/unlock_file"

///|
/// Unlock a file that was previously locked by this process.
pub fn File::unlock(self : File) -> Unit {
  if unlock_ffi(self.fd()) < 0 {
    // swallow the error so that we can use `unlock` in `defer`.
    // TODO: remove the `try!` after we support raising error in `defer`.
    try! @os_error.check_errno("@fs.File::unlock()")
  }
}

///|
/// Remove the file located at `path`.
/// This function is not cancellable.
pub async fn remove(path : StringView) -> Unit nocancel {
  @event_loop.remove(path, context="@fs.remove()")
}

///|
/// Rename (move) the file located at `old_path` to `new_path`.
///
/// If `replace` is `true` (`true` by default),
/// and a file already exist on `new_path`, that file will be replaced.
/// In this case, open handles to the existing file remain valid,
/// and still point to the old file.
pub async fn rename(
  old_path : StringView,
  new_path : StringView,
  replace~ : Bool = true,
) -> Unit {
  @event_loop.rename(old_path, new_path, replace~, context="@fs.rename()")
}

///|
/// Get the size of the file. This method will not change position in the file.
/// Can only be applied to a regular file.
pub async fn File::size(self : File) -> Int64 {
  @event_loop.file_size(self.io.fd(), context="@fs.File::size()")
}

///|
/// Get the size of the file at the specific path.
/// Can only be applied to a regular file.
pub async fn file_size(path : StringView) -> Int64 {
  @event_loop.file_size_of_path(path, context="@fs.file_size()")
}

///|
/// Convert a file to directory.
/// If the file is not a directory, an error will be raised.
///
/// The ownership of the file will be transferred to `as_dir`.
/// The input file will be automatically closed when the
/// result directory object is closed.
/// If `as_dir` fails, the input file will be closed automatically.
pub fn File::as_dir(self : File) -> Directory raise {
  guard self.io.kind() is Directory else {
    self.close()
    raise @os_error.from_errno(
      @errno_util.not_directory,
      context="@fs.File::as_dir()",
    )
  }
  self.text.close()
  Directory::from_io_handle(self.io)
}

///|
/// Get the kind of a file
pub fn File::kind(self : File) -> FileKind {
  FileKind::from_fd_util_file_kind(self.io.kind())
}

///|
/// Get the last access time of a file.
pub async fn File::atime(self : File) -> Timestamp {
  let (sec, nsec) = @event_loop.atime(self.io.fd(), context="@fs.File::atime()")
  { sec, nsec, }
}

///|
/// Get the last modification time of a file.
pub async fn File::mtime(self : File) -> Timestamp {
  let (sec, nsec) = @event_loop.mtime(self.io.fd(), context="@fs.File::mtime()")
  { sec, nsec, }
}

///|
/// Get the last status change time of a file.
pub async fn File::ctime(self : File) -> Timestamp {
  let (sec, nsec) = @event_loop.ctime(self.io.fd(), context="@fs.File::ctime()")
  { sec, nsec, }
}

///|
/// Read the content of the file located at `path` in binary.
/// If `sync_timestamp` is `true` (`false` by default),
/// `read_binary` will block until timestamp change is written to the file system.
pub async fn read_binary(
  path : StringView,
  sync_timestamp~ : Bool = false,
) -> Bytes {
  let file = open(path, mode=ReadOnly)
  defer file.close()
  let result = file.read_all()
  if sync_timestamp {
    file.io.fsync(
      only_data=false,
      context="@fs.read_binary(sync_timestamp=true)",
    )
  }
  result
}

///|
/// Read the text content of the UTF-8 encoded file located at `path`.
/// If `sync_timestamp` is `true` (`false` by default),
/// `read_text` will block until timestamp change is written to the file system.
pub async fn read_text(
  path : StringView,
  sync_timestamp~ : Bool = false,
) -> String {
  let file = open(path, mode=ReadOnly)
  defer file.close()
  let result = file.text.read_all()
  if sync_timestamp {
    file.io.fsync(only_data=false, context="@fs.read_text(sync_timestamp=true)")
  }
  result
}

///|
/// Write binary data to a file located at `path`.
/// The meaning of `sync`, `append`, `create_mode` and `permission`,
/// is the same as `open`, except that `create_mode` is `TruncateExisting` by default.
/// See `open` for more details.
pub async fn write_binary(
  path : StringView,
  content : BytesView,
  create_mode~ : CreateMode = CreateOrTruncate,
  permission~ : Int32 = 0o644,
  sync~ : SyncMode = Data,
  append~ : Bool = false,
) -> Unit {
  let file = open(
    path,
    mode=WriteOnly,
    sync~,
    append~,
    create_mode~,
    permission~,
  )
  defer file.close()
  file.write(content)
}

///|
/// Write UTF-8 encoded text data to a file located at `path`.
/// The meaning of `sync`, `append`, `create_mode` and `permission`,
/// is the same as `open`, except that `create_mode` is `TruncateExisting` by default.
/// See `open` for more details.
pub async fn write_text(
  path : StringView,
  content : StringView,
  create_mode~ : CreateMode = CreateOrTruncate,
  permission~ : Int32 = 0o644,
  sync~ : SyncMode = Data,
  append~ : Bool = false,
) -> Unit {
  let file = open(
    path,
    mode=WriteOnly,
    sync~,
    append~,
    create_mode~,
    permission~,
  )
  defer file.close()
  file.text.write(content)
}
