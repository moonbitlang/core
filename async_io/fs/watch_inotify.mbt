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
#cfg(any(target="wasm", not(platform="windows")))
priv struct InotifyWatcher {
  inotify : @event_loop.IoHandle
  watched : Map[@fd_util.Fd, @event_loop.FileIdentity]
  watcher : Watcher
  mut event_processor : @coroutine.Coroutine?
  mut err : Error?
  mut waiter : @coroutine.Coroutine?
  debounce_timer : @async_io.Timer
  max_debounce_delay : Int32
}

///|
#cfg(all(target="native", not(platform="windows")))
extern "C" fn InotifyWatcher::new_ffi() -> @fd_util.Fd = "moonbit_rt_inotify_create"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn InotifyWatcher::new_ffi() -> @fd_util.Fd = "moonbitlang/async" "fs/inotify/create"

///|
#cfg(any(target="wasm", not(platform="windows")))
#warnings("-fragile_catch_all")
fn InotifyWatcher::InotifyWatcher(
  watcher : Watcher,
  debounce_timeout~ : Int32,
  max_debounce_delay~ : Int32,
  context~ : String,
) -> InotifyWatcher raise {
  let inotify_fd = InotifyWatcher::new_ffi()
  if !@fd_util.fd_is_valid(inotify_fd) {
    @os_error.check_errno(context)
  }
  let self = {
    inotify: @event_loop.IoHandle::from_fd(
      inotify_fd,
      kind=Unknown,
      is_async=true,
    ),
    watched: Map([]),
    watcher,
    event_processor: None,
    waiter: None,
    err: None,
    debounce_timer: Timer(debounce_timeout),
    max_debounce_delay,
  }
  self.event_processor = Some(
    @coroutine.spawn(() => {
      self.process_events() catch {
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
#cfg(any(target="wasm", not(platform="windows")))
impl WatcherBackend for InotifyWatcher with fn close(self) {
  self.inotify.close()
  if self.event_processor is Some(coro) {
    coro.cancel()
    self.event_processor = None
  }
  if self.waiter is Some(coro) {
    coro.wake()
  }
}

///|
#cfg(any(target="wasm", not(platform="windows")))
impl WatcherBackend for InotifyWatcher with fn wait(self) {
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
#cfg(any(target="wasm", not(platform="windows")))
impl WatcherBackend for InotifyWatcher with fn add_file(
  self,
  path,
  is_dir~,
  identity~,
  context~,
) {
  let wd = @event_loop.inotify_add_watch(
    self.inotify.fd(),
    path,
    is_dir~,
    context~,
  )
  self.watched[wd] = identity
  wd
}

///|
#cfg(all(target="native", not(platform="windows")))
extern "C" fn InotifyWatcher::remove_file_ffi(
  watcher : @fd_util.Fd,
  wd : @fd_util.Fd,
) -> Int32 = "moonbit_rt_inotify_remove_file"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn InotifyWatcher::remove_file_ffi(
  watcher : @fd_util.Fd,
  wd : @fd_util.Fd,
) -> Int32 = "moonbitlang/async" "fs/inotify/remove_file"

///|
#cfg(any(target="wasm", not(platform="windows")))
impl WatcherBackend for InotifyWatcher with fn remove_file(self, wd, context~) {
  guard self.watched.contains(wd) else {
    // `inotify` sometimes perform auto removal when file is deleted
    return
  }
  // We do not remove `wd` from `self.watched` here,
  // because when performing `inotify_rm`, it is possible that some events on te wd
  // has already been generated and queued.
  //
  // `inotify` generates a `IN_IGNORED` event for every removed file,
  // implicity or explicitly.
  // We rely on `IN_IGNORED` as the source of truth for the end of watching a file.
  let ret = InotifyWatcher::remove_file_ffi(self.inotify.fd(), wd)
  if ret < 0 {
    @os_error.check_errno(context)
  }
}

///|
#cfg(any(target="wasm", not(platform="windows")))
priv struct InotifyEventBuffer(@c_buffer.Buffer)

///|
#cfg(all(target="native", not(platform="windows")))
extern "C" fn InotifyEventBuffer::size() -> Int32 = "moonbit_rt_inotify_event_buffer_size"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn InotifyEventBuffer::size() -> Int32 = "moonbitlang/async" "fs/inotify/event_buffer_size"

///|
/// Return value:
/// - positive => number of bytes written
/// - zero => no more event available currently
/// - negative => error
#cfg(all(target="native", not(platform="windows")))
#borrow(buf)
extern "C" fn InotifyWatcher::fetch_os_event(
  watcher : @fd_util.Fd,
  buf : InotifyEventBuffer,
  len~ : Int32,
) -> Int32 = "moonbit_rt_inotify_fetch_event"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(buf)
fn InotifyWatcher::fetch_os_event(
  watcher : @fd_util.Fd,
  buf : InotifyEventBuffer,
  len~ : Int32,
) -> Int32 = "moonbitlang/async" "fs/inotify/fetch_event"

///|
#cfg(all(target="native", not(platform="windows")))
extern "C" fn InotifyEventBuffer::get_size(
  self : Self,
  offset : Int32,
) -> Int32 = "moonbit_rt_inotify_event_get_size"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(self)
fn InotifyEventBuffer::get_size(self : Self, offset : Int32) -> Int32 = "moonbitlang/async" "fs/inotify/event_get_size"

///|
#cfg(all(target="native", not(platform="windows")))
extern "C" fn InotifyEventBuffer::get_wd(
  self : Self,
  offset : Int32,
) -> @fd_util.Fd = "moonbit_rt_inotify_event_get_wd"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(self)
fn InotifyEventBuffer::get_wd(self : Self, offset : Int32) -> @fd_util.Fd = "moonbitlang/async" "fs/inotify/event_get_wd"

///|
#cfg(all(target="native", not(platform="windows")))
extern "C" fn InotifyEventBuffer::has_relevant_event(
  self : Self,
  offset : Int32,
) -> Bool = "moonbit_rt_inotify_event_has_relevant_event"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(self)
fn InotifyEventBuffer::has_relevant_event(self : Self, offset : Int32) -> Bool = "moonbitlang/async" "fs/inotify/event_has_relevant_event"

///|
#cfg(all(target="native", not(platform="windows")))
extern "C" fn InotifyEventBuffer::has_overflow(
  self : Self,
  offset : Int32,
) -> Bool = "moonbit_rt_inotify_event_has_overflow"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(self)
fn InotifyEventBuffer::has_overflow(self : Self, offset : Int32) -> Bool = "moonbitlang/async" "fs/inotify/event_has_overflow"

///|
#cfg(all(target="native", not(platform="windows")))
extern "C" fn InotifyEventBuffer::has_ignore(
  self : Self,
  offset : Int32,
) -> Bool = "moonbit_rt_inotify_event_has_ignore"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(self)
fn InotifyEventBuffer::has_ignore(self : Self, offset : Int32) -> Bool = "moonbitlang/async" "fs/inotify/event_has_ignore"

///|
#cfg(any(target="wasm", not(platform="windows")))
async fn InotifyWatcher::process_events(self : InotifyWatcher) -> Unit {
  let context = "@fs.Watcher::wait()"
  let buf_len = InotifyEventBuffer::size()
  let buf = InotifyEventBuffer(@c_buffer.new(buf_len))
  defer buf.0.free()
  for ;; {
    let n = InotifyWatcher::fetch_os_event(self.inotify.fd(), buf, len=buf_len)
    if n < 0 {
      @os_error.check_errno(context)
    }
    if n is 0 {
      if self.waiter is Some(coro) {
        coro.wake()
      }
      self.inotify.wait_read()
      continue
    }
    self.debounce_timer.refresh()
    for offset = 0; offset < n; offset = offset + buf.get_size(offset) {
      let wd = buf.get_wd(offset)
      if buf.has_ignore(offset) {
        self.watched.remove(wd)
        continue
      }

      if buf.has_overflow(offset) {
        self.watcher.overflow()
        continue
      }

      if buf.has_relevant_event(offset) {
        let id = self.watched[wd]
        self.watcher.mark_as_modified(id)
      }
    }
  }
}
