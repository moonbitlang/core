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
/// Get the kind of a file at `path`.
/// If `path` is a symbolic link and `follow_symlink` is `true` (`true` by default),
/// the kind of the target of the link will be returned.
pub async fn kind(path : StringView, follow_symlink~ : Bool = true) -> FileKind {
  @event_loop.file_kind_by_path(
    path,
    parent=@fd_util.invalid_fd,
    follow_symlink~,
    context="@fs.kind()",
  )
  |> FileKind::from_fd_util_file_kind
}

///|
/// Get the last access time of a file at `path`.
///
/// If `follow_symlink` is `true` (`true` by default) and `path` is a symbolic link,
/// the timestamp of the target of `path` will be returned.
pub async fn atime(
  path : StringView,
  follow_symlink~ : Bool = true,
) -> Timestamp {
  let (sec, nsec) = @event_loop.atime_by_path(
    path,
    follow_symlink~,
    context="@fs.atime()",
  )
  { sec, nsec, }
}

///|
/// Get the last modification time of a file at `path`.
///
/// If `follow_symlink` is `true` (`true` by default) and `path` is a symbolic link,
/// the timestamp of the target of `path` will be returned.
pub async fn mtime(
  path : StringView,
  follow_symlink~ : Bool = true,
) -> Timestamp {
  let (sec, nsec) = @event_loop.mtime_by_path(
    path,
    follow_symlink~,
    context="@fs.mtime()",
  )
  { sec, nsec, }
}

///|
/// Get the last status change time of a file at `path`.
///
/// If `follow_symlink` is `true` (`true` by default) and `path` is a symbolic link,
/// the timestamp of the target of `path` will be returned.
pub async fn ctime(
  path : StringView,
  follow_symlink~ : Bool = true,
) -> Timestamp {
  let (sec, nsec) = @event_loop.ctime_by_path(
    path,
    follow_symlink~,
    context="@fs.ctime()",
  )
  { sec, nsec, }
}

///|
/// Check if the file at `path` exists
pub async fn exists(path : StringView) -> Bool {
  try @event_loop.access(path, Exist, context="@fs.exists()") catch {
    @os_error.OsError(NotFound, ..) => false
    err => raise err
  } noraise {
    _ => true
  }
}

///|
/// Check if current process is allowed to read the file at `path`
pub async fn can_read(path : StringView) -> Bool {
  try @event_loop.access(path, CanRead, context="@fs.can_read()") catch {
    @os_error.OsError(NotFound | AccessDenied, ..) => false
    err => raise err
  } noraise {
    _ => true
  }
}

///|
/// Check if current process is allowed to write the file at `path`
pub async fn can_write(path : StringView) -> Bool {
  try @event_loop.access(path, CanWrite, context="@fs.can_write()") catch {
    @os_error.OsError(NotFound | AccessDenied, ..) => false
    err => raise err
  } noraise {
    _ => true
  }
}

///|
/// Check if current process is allowed to execute the file at `path`
pub async fn can_execute(path : StringView) -> Bool {
  try @event_loop.access(path, CanExecute, context="@fs.can_execute()") catch {
    @os_error.OsError(NotFound | AccessDenied, ..) => false
    err => raise err
  } noraise {
    _ => true
  }
}

///|
/// Get the absolute real path of `path`,
/// removing all `..` and `.` in the `path`,
/// and unfold all symbolic links.
///
/// If the path contains cyclic symbolic link,
/// an error will be raised.
pub async fn realpath(path : StringView) -> String {
  @event_loop.realpath(path, context="@fs.realpath()")
}

///|
/// Create a symbolic link to `old_path` at `new_path`.
///
/// On Windows, creating true symbolic link requires admin privilege.
/// So `@fs.symlink()` will try to create NTFS junction when feasible,
/// which is similar to symlink in characteristics.
/// NTFS junction is not as flexible as symlink, it will only be created when:
///
/// 1. the target path is an existing directory
/// 2. the target path is onn the same local machine
/// 3. the link is created on a NTFS volume
///
/// To force creation of true symbolic link on Windows, pass `force_symlink=true`.
/// `force_symlink` has no effect on non-Windows platforms.
pub async fn symlink(
  target~ : StringView,
  path : StringView,
  force_symlink~ : Bool = false,
) -> Unit {
  @event_loop.symlink(target, path, force_symlink~, context="@fs.symlink()")
}

///|
/// Change the permission of a file.
/// Permission is represented as an integer in UNIX permission style.
/// For example, `0o640` means:
///
/// - the owner of the file can read and write the file (`6`)
/// - users in the owner group of the file can read the file (`4`)
/// - other users can do nothing to the file
///
/// On Windows, `@fs.chmod` is not supported, and will fail with error.
pub async fn chmod(path : StringView, mode : Int32) -> Unit {
  @event_loop.chmod(path, mode, context="@fs.chmod()")
}
