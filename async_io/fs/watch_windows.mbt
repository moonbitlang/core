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
#cfg(any(target="wasm", platform="windows"))
priv struct WindowsWatcher {
  root : @event_loop.IoHandle
  dev_id : UInt64
  watcher : Watcher
  mut event_processor : @coroutine.Coroutine?
  mut err : Error?
  mut waiter : @coroutine.Coroutine?
  debounce_timer : @async_io.Timer
  max_debounce_delay : Int32
}

///|
#cfg(any(target="wasm", platform="windows"))
#warnings("-fragile_catch_all")
fn WindowsWatcher::WindowsWatcher(
  watcher : Watcher,
  root : @event_loop.IoHandle,
  root_id~ : @event_loop.FileIdentity,
  debounce_timeout~ : Int32,
  max_debounce_delay~ : Int32,
) -> WindowsWatcher {
  let self = {
    root,
    dev_id: root_id.dev_id,
    watcher,
    err: None,
    waiter: None,
    event_processor: None,
    debounce_timer: Timer(debounce_timeout),
    max_debounce_delay,
  }
  self.event_processor = Some(
    @coroutine.spawn(() => {
      self.event_handler() catch {
        err => {
          self.err = Some(err)
          if self.waiter is Some(coro) {
            coro.wake()
          }
          raise err
        }
      }
    }),
  )
  self
}

///|
#cfg(any(target="wasm", platform="windows"))
impl WatcherBackend for WindowsWatcher with fn close(self) {
  if self.event_processor is Some(coro) {
    coro.cancel()
  }
}

///|
#cfg(any(target="wasm", platform="windows"))
impl WatcherBackend for WindowsWatcher with fn add_file(
  _self,
  _path,
  is_dir~,
  identity~,
  context~,
) {
  ignore(is_dir)
  ignore(identity)
  ignore(context)
  @fd_util.invalid_fd
}

///|
#cfg(any(target="wasm", platform="windows"))
impl WatcherBackend for WindowsWatcher with fn remove_file(_self, _fd, context~) {
  ignore(context)
}

///|
#cfg(any(target="wasm", platform="windows"))
impl WatcherBackend for WindowsWatcher with fn wait(self) {
  if self.err is Some(err) {
    raise err
  }
  guard! self.event_processor is Some(_)
  guard! self.waiter is None
  let root = self.watcher.watched[self.watcher.root_id]
  while root.is_clean() {
    self.waiter = Some(@coroutine.current_coroutine())
    defer {
      self.waiter = None
    }
    @coroutine.suspend()
    if self.err is Some(err) {
      raise err
    }
  }
  @async_io.with_timeout(self.max_debounce_delay, () => {
    self.debounce_timer.wait()
  }) catch {
    @async_io.TimeoutError => ()
    err => raise err
  }
}

///|
#cfg(platform="windows")
extern "C" fn WindowsWatcher::has_ReadDirectoryChangesExW() -> Bool = "moonbit_rt_has_ReadDirectoryChangesExW"

///|
#cfg(any(platform="windows", target="wasm"))
type WindowsWatcherBuf = @event_loop.WindowsWatcherBuf

///|
// According to https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-readdirectorychangesw,
// the initial buffer size on the first `ReadDirectoryChangesW` call on a directory handle
// will become the size for in-kernel event buffer of that directory handle.
// So larger buffer size reduce change of overflow.
// Meanwhile, the document also says that network file system does not support buffer larger than 64K,
// so use the largest possible value (64K) here.
#cfg(any(platform="windows", target="wasm"))
let watcher_buffer_size : Int32 = 1 << 16

///|
#cfg(platform="windows")
fn WindowsWatcherBuf::new() -> WindowsWatcherBuf {
  @c_buffer.new(watcher_buffer_size)
}

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn WindowsWatcherBuf::new() -> WindowsWatcherBuf = "moonbitlang/async" "fs/watcher/windows/buffer/new"

///|
#cfg(platform="windows")
fn WindowsWatcherBuf::free(self : WindowsWatcherBuf) -> Unit {
  self.0.free()
}

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn WindowsWatcherBuf::free(self : WindowsWatcherBuf) -> Unit = "moonbitlang/async" "fs/watcher/windows/buffer/free"

///|
#cfg(any(platform="windows", target="wasm"))
async fn WindowsWatcherBuf::read(
  self : WindowsWatcherBuf,
  root : @event_loop.IoHandle,
  context~ : String,
) -> Int32 {
  root.read_dir_changes(self.0, watcher_buffer_size, context~)
}

///|
#cfg(platform="windows")
extern "C" fn WindowsWatcherBuf::event_size(
  self : Self,
  offset : Int32,
) -> Int32 = "moonbit_rt_watcher_event_get_size"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(self)
fn WindowsWatcherBuf::event_size(self : Self, offset : Int32) -> Int32 = "moonbitlang/async" "fs/watcher/windows/event_get_size"

///|
#cfg(platform="windows")
extern "C" fn WindowsWatcherBuf::is_modify(self : Self, offset : Int32) -> Bool = "moonbit_rt_watcher_event_is_modify_event"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(self)
fn WindowsWatcherBuf::is_modify(self : Self, offset : Int32) -> Bool = "moonbitlang/async" "fs/watcher/windows/event_is_modify"

///|
#cfg(platform="windows")
extern "C" fn WindowsWatcherBuf::get_path_byte_len(
  self : Self,
  offset : Int32,
) -> Int32 = "moonbit_rt_watcher_event_get_path_len"

///|
#cfg(platform="windows")
extern "C" fn WindowsWatcherBuf::get_path_offset() -> Int32 = "moonbit_rt_watcher_event_get_path_offset"

///|
#cfg(platform="windows")
fn WindowsWatcherBuf::get_path(
  self : WindowsWatcherBuf,
  offset : Int32,
) -> String {
  self.0.decode_as_os_string(
    offset=offset + WindowsWatcherBuf::get_path_offset(),
    len=self.get_path_byte_len(offset),
  )
}

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(self)
fn WindowsWatcherBuf::get_path_unit_len(
  self : WindowsWatcherBuf,
  offset : Int32,
) -> Int32 = "moonbitlang/async" "fs/watcher/windows/event_path_len"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(self, path)
fn WindowsWatcherBuf::copy_path(
  self : WindowsWatcherBuf,
  offset : Int32,
  path : String,
  path_len : Int32,
) -> Unit = "moonbitlang/async" "fs/watcher/windows/event_path_copy"

///|
/// The host buffer already contains UTF-16 code units. Copy them directly so
/// the Wasm path has the same representation as the native `memcpy` path.
#cfg(target="wasm")
fn WindowsWatcherBuf::get_path(
  self : WindowsWatcherBuf,
  offset : Int32,
) -> String {
  let path_len = self.get_path_unit_len(offset)
  let path = String::make(path_len, '\u{0}')
  self.copy_path(offset, path, path_len)
  path
}

///|
#cfg(platform="windows")
extern "C" fn WindowsWatcherBuf::get_file_id(
  self : Self,
  offset : Int32,
) -> UInt64 = "moonbit_rt_watcher_event_get_file_id"

///|
#cfg(platform="windows")
extern "C" fn WindowsWatcherBuf::get_parent_file_id(
  self : Self,
  offset : Int32,
) -> UInt64 = "moonbit_rt_watcher_event_get_parent_file_id"

///|
#cfg(platform="windows")
fn WindowsWatcherBuf::has_file_ids(_self : WindowsWatcherBuf) -> Bool {
  WindowsWatcher::has_ReadDirectoryChangesExW()
}

///|
#cfg(platform="windows")
fn WindowsWatcherBuf::dirty_file_id(
  self : WindowsWatcherBuf,
  offset : Int32,
) -> UInt64 {
  if self.is_modify(offset) {
    self.get_file_id(offset)
  } else {
    self.get_parent_file_id(offset)
  }
}

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(self)
fn WindowsWatcherBuf::has_file_ids(self : WindowsWatcherBuf) -> Bool = "moonbitlang/async" "fs/watcher/windows/event_has_file_ids"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(self)
fn WindowsWatcherBuf::dirty_file_id(
  self : WindowsWatcherBuf,
  offset : Int32,
) -> UInt64 = "moonbitlang/async" "fs/watcher/windows/event_dirty_file_id"

///|
#cfg(any(target="wasm", platform="windows"))
async fn WindowsWatcher::event_handler(self : WindowsWatcher) -> Unit {
  defer self.root.close()
  let context = "@fs.Watcher::wait()"
  let buf = WindowsWatcherBuf::new()
  defer buf.free()
  for ;; {
    let n = buf.read(self.root, context~)
    self.debounce_timer.refresh()
    if n is 0 {
      // overflow
      self.watcher.overflow()
      continue
    }
    let mut offset = 0
    while offset < n {
      let size = buf.event_size(offset)
      let dirty_identity : @event_loop.FileIdentity = if buf.has_file_ids() {
        let file_id = buf.dirty_file_id(offset)
        { dev_id: self.dev_id, file_id, }
      } else {
        let path = buf.get_path(offset)
        let path = if buf.is_modify(offset) {
          path[:]
        } else {
          for i in path.length()>..0 {
            if path[i] is ('/' | '\\') {
              break path[:i]
            }
          } nobreak {
            ""
          }
        }
        // file change in the root directory
        let (file, file_id) = @event_loop.open(
          "\{self.watcher.base_path}\\\{path}",
          0,
          create=0,
          append=false,
          sync=0,
          mode=0,
          context~,
        )
        file.close()
        file_id
      }
      if self.watcher.watched.get(dirty_identity) is Some(file) {
        if !(buf.is_modify(offset) && file.is_dir) {
          self.watcher.mark_as_modified(dirty_identity)
        }
      }
      if size is 0 {
        offset = n
      } else {
        offset += size
      }
    }
    if self.waiter is Some(coro) {
      coro.wake()
    }
  }
}
