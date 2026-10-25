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
/// Create a directory at `path`.
///
/// The Unix-style permission of the created directory can be set in `permission`,
/// the default value is `0o755` (anyone can read and traverse, only owner can write).
/// The `permission` parameter is currently ignored on Windows.
///
/// If `recursive=true` (`false` by default), non-existing parent directories
/// of `path` will be recursively created, too.
/// Parent directories are always created with `allow_exist=true`,
/// so concurrent tasks may create directories under a shared parent.
///
/// If `allow_exist=true` (`false` by default), it is not an error
/// if `path` is already a directory (like `mkdir -p`).
/// An existing non-directory at `path` is still an error.
pub async fn mkdir(
  path : StringView,
  permission~ : Int32 = 0o755,
  recursive~ : Bool = false,
  allow_exist~ : Bool = false,
) -> Unit {
  let context = "@fs.mkdir()"
  @event_loop.mkdir(path, mode=permission, context~) catch {
    @os_error.OsError(AlreadyExists, ..) as err if allow_exist => {
      let kind = kind(path) catch { _ => raise err }
      guard kind is Directory else { raise err }
    }
    @os_error.OsError(NotFound, ..) as err if recursive => {
      let last_path_sep_index = match path.rev_find("/") {
        Some(index) => index
        None if @event_loop.platform is Windows &&
          path.rev_find("\\") is Some(index) => index
        None => raise err
      }
      let parent = path[:last_path_sep_index].trim_end(chars="/")
      let parent = if @event_loop.platform is Windows {
        parent.trim_end(chars="\\")
      } else {
        parent
      }
      mkdir(parent, permission~, recursive=true, allow_exist=true)
      mkdir(path, permission~, allow_exist~)
    }
    err => raise err
  }
}

///|
/// Remove a directory at `path`,
/// If `recursive` is `true` (`false` by default),
/// files and directories in `path` will be removed recursively.
/// If `recursive` is `false`,
/// `path` must be an empty directory, otherwise `rmdir` will fail.
///
/// This function is not cancellable.
pub async fn rmdir(
  path : StringView,
  recursive~ : Bool = false,
) -> Unit nocancel {
  let context = "@fs.rmdir()"
  if recursive {
    let base = if @event_loop.platform is Windows {
      path.trim_end(chars="/\\")
    } else {
      path.trim_end(chars="/")
    }
    @async.protect_from_cancel <| () => {
      let dir = opendir_aux(path, context~)
      defer dir.close()
      while dir.next_aux(include_special=false, include_hidden=true, context~)
            is Some(ent) {
        let child_path = "\{base}/\{ent.name}"
        if ent.is_dir {
          rmdir(child_path, recursive=true)
        } else {
          @event_loop.remove(child_path, context~)
        }
      }
    }
  }
  @event_loop.rmdir(path, context~)
}

///|
priv enum DirectoryState {
  NoMoreEntry
  NeedMoreEntry
  HasBufferedEntry
}

///|
priv struct DirectoryBuffer(@c_buffer.Buffer)

///|
/// A directory in file system
struct Directory {
  io : @event_loop.IoHandle
  buf : DirectoryBuffer
  buf_len : Int32
  // The offset of the next entry in the buffer
  mut offset : Int32
  // The number of entries already consumed
  mut count : Int32
  // the return value of the corresponding job has different semantic of different platforms.
  // - Linux: number of bytes read
  // - MacOS: number on entries
  // - Windows: nonzero unless EOF
  mut job_ret : Int32
  mut state : DirectoryState
}

///|
/// Close a directory object, release associated resource
pub fn Directory::close(self : Directory) -> Unit {
  self.io.close()
  self.buf.0.free()
}

///|
#cfg(target="native")
extern "C" fn Directory::min_buffer_size() -> Int32 = "moonbit_rt_dir_buffer_min_size"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn Directory::min_buffer_size() -> Int32 = "moonbitlang/async" "fs/dir_buffer_min_size"

///|
/// Open the directory at `path`. `path` is encoded UTF8.
/// If `path` is not a directory, an error will be raised
pub async fn opendir(path : StringView) -> Directory {
  opendir_aux(path, context="@fs.opendir()")
}

///|
async fn opendir_aux(path : StringView, context~ : String) -> Directory {
  let (io, _) = @event_loop.open(
    path,
    0,
    create=0,
    append=false,
    sync=0,
    mode=0,
    context~,
  )
  if !(io.kind() is Directory) {
    io.close()
    raise @os_error.from_errno(
      @errno_util.not_directory,
      context="\{context}: \{path.escape()}",
    )
  }
  Directory::from_io_handle(io)
}

///|
fn Directory::from_io_handle(io : @event_loop.IoHandle) -> Directory {
  let buf_len = @cmp.maximum(1024, Directory::min_buffer_size())
  {
    io,
    buf: @c_buffer.new(buf_len),
    buf_len,
    offset: 0,
    count: 0,
    job_ret: 0,
    state: NeedMoreEntry,
  }
}

///|
#cfg(target="native")
extern "C" fn DirectoryBuffer::entry_length(
  self : Self,
  offset : Int32,
) -> Int32 = "moonbit_rt_dir_entry_length"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(self)
fn DirectoryBuffer::entry_length(self : Self, offset : Int32) -> Int32 = "moonbitlang/async" "fs/dir_entry_length"

///|
#cfg(target="native")
extern "C" fn DirectoryBuffer::entry_name_len(
  self : Self,
  offset : Int32,
) -> Int32 = "moonbit_rt_dir_entry_get_name_len"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(self)
fn DirectoryBuffer::entry_name_len(self : Self, offset : Int32) -> Int32 = "moonbitlang/async" "fs/dir_entry_get_name_len"

///|
#cfg(target="native")
extern "C" fn DirectoryBuffer::entry_name_offset(
  self : Self,
  offset : Int32,
) -> Int32 = "moonbit_rt_dir_entry_get_name_offset"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(self)
fn DirectoryBuffer::entry_name_offset(self : Self, offset : Int32) -> Int32 = "moonbitlang/async" "fs/dir_entry_get_name_offset"

///|
#cfg(target="native")
extern "C" fn DirectoryBuffer::entry_is_dir(
  self : Self,
  offset : Int32,
) -> Int32 = "moonbit_rt_dir_entry_is_dir"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(self)
fn DirectoryBuffer::entry_is_dir(self : Self, offset : Int32) -> Int32 = "moonbitlang/async" "fs/dir_entry_is_dir"

///|
#cfg(target="native")
extern "C" fn DirectoryBuffer::entry_is_hidden(
  self : Self,
  offset : Int32,
) -> Bool = "moonbit_rt_dir_entry_is_hidden"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(self)
fn DirectoryBuffer::entry_is_hidden(self : Self, offset : Int32) -> Bool = "moonbitlang/async" "fs/dir_entry_is_hidden"

///|
#cfg(target="native")
extern "C" fn DirectoryBuffer::entry_file_id(
  self : Self,
  offset : Int32,
) -> UInt64 = "moonbit_rt_dir_entry_get_file_id"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(self)
fn DirectoryBuffer::entry_file_id(self : Self, offset : Int32) -> UInt64 = "moonbitlang/async" "fs/dir_entry_get_file_id"

///|
/// An directory entry, containing name of the entry and other information
#valtype
pub struct DirectoryEntry {
  name : String
  /// Indicate whether the directory entry is another directory.
  /// Symbolic links are not treated as directories here.
  is_dir : Bool
  priv file_id : UInt64
}

///|
/// Fetch the next entry in the directory,
/// including its name and some extra information, see `DirectoryEntry`.
/// `None` indicates that the directory has no more files.
///
/// - If `include_special` is `true` (`false` by default),
///   `.` (current directory) and `..` (parent directory) will be included too
///
/// - If `include_hidden` is `true` (`true` by default),
///   hidden files (on Unix: file name starts with `.`, on Windows: has the hidden attribute)
///   will be included
///
/// The file name in the returned directory entry is interpreted as UTF8-encoded on Unix-like systems.
pub async fn Directory::next(
  dir : Directory,
  include_hidden~ : Bool = true,
  include_special~ : Bool = false,
) -> DirectoryEntry? {
  dir.next_aux(
    include_special~,
    include_hidden~,
    context="@fs.Directory::next()",
  )
}

///|
async fn Directory::next_aux(
  dir : Directory,
  include_hidden~ : Bool,
  include_special~ : Bool,
  restart~ : Bool = false,
  context~ : String,
) -> DirectoryEntry? {
  match dir.state {
    NoMoreEntry => return None
    HasBufferedEntry => ()
    NeedMoreEntry => {
      dir.offset = 0
      dir.count = 0
      dir.job_ret = dir.io.readdir(dir.buf.0, dir.buf_len, restart~, context~)
      if dir.job_ret is 0 {
        dir.state = NoMoreEntry
        return None
      } else {
        dir.state = HasBufferedEntry
      }
    }
  }
  let entry_len = dir.buf.entry_length(dir.offset)
  let offset = dir.offset
  dir.offset += entry_len
  dir.count += 1
  let need_more_entry = match @event_loop.platform {
    Linux => dir.offset >= dir.job_ret
    MacOS => dir.count >= dir.job_ret
    Windows => entry_len is 0
  }
  if need_more_entry {
    dir.state = NeedMoreEntry
  }
  if !include_hidden && dir.buf.entry_is_hidden(offset) {
    return dir.next_aux(include_special~, include_hidden~, context~)
  }
  let name = dir.buf.0.decode_as_os_string(
    offset=offset + dir.buf.entry_name_offset(offset),
    len=dir.buf.entry_name_len(offset),
  )
  if !include_special && name is ("." | "..") {
    return dir.next_aux(include_special~, include_hidden~, context~)
  }
  let is_dir = match dir.buf.entry_is_dir(offset) {
    0 => false
    1..<_ => true
    _..<0 => {
      let kind = @event_loop.file_kind_by_path(
        name,
        parent=dir.io.fd(),
        follow_symlink=false,
        context~,
      )
      kind is Directory
    }
  }
  let file_id = dir.buf.entry_file_id(offset)
  let entry = { name, is_dir, file_id, }
  // Native file watching consumes this private field. Wasm keeps the same
  // entry shape even though watch support is not compiled there yet.
  ignore(entry.file_id)
  Some(entry)
}

///|
/// Read all entries in a directory.
///
/// - If `include_special` is `true` (`false` by default),
///   `.` (current directory) and `..` (parent directory) will be included too
///
/// - If `include_hidden` is `true` (`true` by default),
///   hidden files (on Unix: file name starts with `.`, on Windows: has the hidden attribute)
///   will be included
///
/// The returned file names are interpreted as UTF8-encoded on Unix-like systems.
pub async fn Directory::read_all(
  dir : Directory,
  include_hidden~ : Bool = true,
  include_special~ : Bool = false,
) -> Array[String] {
  let result = []
  let context = "@fs.Directory::read_all()"
  while dir.next_aux(include_hidden~, include_special~, context~) is Some(entry) {
    result.push(entry.name)
  }
  result
}

///|
/// Read all entries in the directory located at `path`.
///
/// - If `include_special` is `true` (`false` by default),
///   `.` (current directory) and `..` (parent directory) will be included too
///
/// - If `include_hidden` is `true` (`true` by default),
///   hidden files (on Unix: file name starts with `.`, on Windows: has the hidden attribute)
///   will be included
///
/// - If `sort` is `true` (`false` by default),
///   the result will be sorted using `Array::sort`.
///
/// The returned file names are interpreted as UTF8-encoded on Unix-like systems.
pub async fn readdir(
  path : StringView,
  include_hidden~ : Bool = true,
  include_special~ : Bool = false,
  sort~ : Bool = false,
) -> Array[String] {
  let context = "@fs.readdir()"
  let dir : Directory = opendir_aux(path, context~)
  defer dir.close()
  let list = []
  while dir.next_aux(include_hidden~, include_special~, context~) is Some(entry) {
    list.push(entry.name)
  }
  if sort {
    list.sort()
  }
  list
}

///|
/// `walk(path, f, ..)` recursively walk the directory `path`,
/// and call `f` on every sub-directory in `path`, including `path` itself.
///
/// If `exclude` is present, it will be invoked with the path of every directory
/// before traversing them. If `exclude` returns `true`,
/// the directory and all its children will be skipped.
/// The path passed to `exclude` has the following format:
/// - always start with `path`
/// - does not contain trailing directory separator
///
/// The directories are walked in parallel.
/// Use `max_concurrency` to limit the number of workers spawned in parallel.
/// For example, setting `max_concurrency=1` result in sequential walking.
/// By default `max_concurrency` is set to a large value.
///
/// If `allow_failure` is `true` (`false` by default),
/// error raised by `f` will be silently ignored.
/// Otherwise, failure in `f` will stop the whole `walk`,
/// cancelling the handling of other sub-directories.
pub async fn walk(
  path : StringView,
  f : async (String, Array[String]) -> Unit,
  exclude~ : (String) -> Bool = _ => false,
  max_concurrency~ : Int32 = 1000,
  allow_failure~ : Bool = false,
) -> Unit {
  let context = "@fs.walk()"
  guard! max_concurrency > 0
  let sem = @async.Semaphore(max_concurrency)
  @async.with_task_group() <| fn(group) {
    fn handle_path(path : String) {
      guard !exclude(path) else {  }
      group.spawn_bg(allow_failure~) <| () => {
        sem.acquire()
        defer sem.release()
        let dir = opendir_aux(path, context~)
        defer dir.close()
        let sub_dirs = []
        let files = []
        while dir.next_aux(include_hidden=true, include_special=false, context~)
              is Some(ent) {
          if ent.is_dir {
            let file_path = if path is [.., '/'] {
              path + ent.name
            } else {
              "\{path}/\{ent.name}"
            }
            sub_dirs.push(file_path)
          }
          files.push(ent.name)
        }
        for path in sub_dirs {
          handle_path(path)
        }
        f(path, files)
      }
    }

    handle_path(path.to_owned())
  }
}
