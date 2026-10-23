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
priv struct KqueueWatchedFile {
  identity : @event_loop.FileIdentity
  io : @event_loop.IoHandle
}

///|
#cfg(any(target="wasm", not(platform="windows")))
priv struct KqueueWatcher {
  kqueue : @event_loop.IoHandle
  watched : Map[@fd_util.Fd, KqueueWatchedFile]
  watcher : Watcher
  event_buffer : KqueueEventBuffer
  event_buffer_len : Int32
  debounce_timeout : Int32
  max_debounce_delay : Int32
}

///|
#cfg(all(target="native", not(platform="windows")))
extern "C" fn KqueueWatcher::new_ffi() -> @fd_util.Fd = "moonbit_rt_kqueue_watcher_create"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn KqueueWatcher::new_ffi() -> @fd_util.Fd = "moonbitlang/async" "fs/kqueue_watcher/create"

///|
#cfg(any(target="wasm", not(platform="windows")))
priv struct KqueueEventBuffer(@c_buffer.Buffer)

///|
#cfg(all(target="native", not(platform="windows")))
extern "C" fn KqueueEventBuffer::size() -> Int32 = "moonbit_rt_kqueue_watcher_buffer_size"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn KqueueEventBuffer::size() -> Int32 = "moonbitlang/async" "fs/kqueue_watcher/buffer_size"

///|
#cfg(any(target="wasm", not(platform="windows")))
fn KqueueWatcher::KqueueWatcher(
  watcher : Watcher,
  debounce_timeout~ : Int32,
  max_debounce_delay~ : Int32,
  context~ : String,
) -> KqueueWatcher raise {
  let kqueue = KqueueWatcher::new_ffi()
  if !@fd_util.fd_is_valid(kqueue) {
    @os_error.check_errno(context)
  }
  let event_buffer_len = KqueueEventBuffer::size()
  {
    kqueue: @event_loop.IoHandle::from_fd(
      kqueue,
      kind=Unknown,
      is_async=true,
      read_only=true,
    ),
    watched: Map([]),
    watcher,
    event_buffer: @c_buffer.new(event_buffer_len),
    event_buffer_len,
    debounce_timeout,
    max_debounce_delay,
  }
}

///|
#cfg(any(target="wasm", not(platform="windows")))
impl WatcherBackend for KqueueWatcher with fn close(self) {
  self.kqueue.close()
  for file in self.watched.values() {
    file.io.close()
  }
  self.watched.clear()
  self.event_buffer.0.free()
}

///|
#cfg(all(target="native", not(platform="windows")))
extern "C" fn KqueueWatcher::add_file_ffi(
  kqueue : @fd_util.Fd,
  fd : @fd_util.Fd,
  is_dir~ : Bool,
) -> Int32 = "moonbit_rt_kqueue_watcher_add_file"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn KqueueWatcher::add_file_ffi(
  kqueue : @fd_util.Fd,
  fd : @fd_util.Fd,
  is_dir~ : Bool,
) -> Int32 = "moonbitlang/async" "fs/kqueue_watcher/add_file"

///|
#cfg(any(target="wasm", not(platform="windows")))
impl WatcherBackend for KqueueWatcher with fn add_file(
  self,
  path,
  is_dir~,
  identity~,
  context~,
) {
  let (file, _) = @event_loop.open(
    path,
    0,
    create=0,
    append=false,
    sync=0,
    mode=0,
    context~,
  )
  let fd = file.fd()
  if KqueueWatcher::add_file_ffi(self.kqueue.fd(), fd, is_dir~) < 0 {
    file.close()
    @os_error.check_errno("\{context}: \{path.escape()}")
  }
  self.watched[fd] = { identity, io: file, }
  fd
}

///|
#cfg(any(target="wasm", not(platform="windows")))
impl WatcherBackend for KqueueWatcher with fn remove_file(self, fd, context~) {
  // closing the fd (which must be the last fd pointing to the file description)
  // automatically unregister the event for kqueue
  ignore(context)
  let file = self.watched[fd]
  file.io.close()
  self.watched.remove(fd)
}

///|
/// Return value:
/// - positive => number of bytes written
/// - zero => no more event available currently
/// - negative => error
#cfg(all(target="native", not(platform="windows")))
#borrow(buf)
extern "C" fn KqueueWatcher::fetch_os_event(
  watcher : @fd_util.Fd,
  buf : KqueueEventBuffer,
  len~ : Int32,
) -> Int32 = "moonbit_rt_kqueue_watcher_fetch_event"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(buf)
fn KqueueWatcher::fetch_os_event(
  watcher : @fd_util.Fd,
  buf : KqueueEventBuffer,
  len~ : Int32,
) -> Int32 = "moonbitlang/async" "fs/kqueue_watcher/fetch_event"

///|
#cfg(all(target="native", not(platform="windows")))
extern "C" fn KqueueEventBuffer::fd(self : Self, index : Int32) -> @fd_util.Fd = "moonbit_rt_kqueue_watcher_event_get_fd"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(self)
fn KqueueEventBuffer::fd(self : Self, index : Int32) -> @fd_util.Fd = "moonbitlang/async" "fs/kqueue_watcher/event_get_fd"

///|
#cfg(all(target="native", not(platform="windows")))
extern "C" fn KqueueEventBuffer::has_modify(self : Self, index : Int32) -> Bool = "moonbit_rt_kqueue_watcher_event_has_modify"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(self)
fn KqueueEventBuffer::has_modify(self : Self, index : Int32) -> Bool = "moonbitlang/async" "fs/kqueue_watcher/event_has_modify"

///|
#cfg(any(target="wasm", not(platform="windows")))
impl WatcherBackend for KqueueWatcher with fn wait(self) {
  let context = "@fs.Watcher::wait()"
  let root = self.watcher.watched[self.watcher.root_id]
  while root.is_clean() {
    self.process_events(timeout=None, context~)
  }
  let debounce_deadline = @event_loop.now() + self.max_debounce_delay.to_int64()
  for ;; {
    let t = @cmp.minimum(
      (debounce_deadline - @event_loop.now()).to_int(),
      self.debounce_timeout,
    )
    guard t > 0 else { break }
    self.process_events(timeout=Some(t), context~) catch {
      @async.TimeoutError => break
      err => raise err
    }
  }
}

///|
#cfg(any(target="wasm", not(platform="windows")))
async fn KqueueWatcher::process_events(
  self : KqueueWatcher,
  timeout~ : Int32?,
  context~ : String,
) -> Unit {
  let n = KqueueWatcher::fetch_os_event(
    self.kqueue.fd(),
    self.event_buffer,
    len=self.event_buffer_len,
  )
  if n < 0 {
    @os_error.check_errno(context)
  }
  if n is 0 {
    match timeout {
      None => self.kqueue.wait_read()
      Some(t) => @async.with_timeout(t, () => self.kqueue.wait_read())
    }
  }
  for i in 0..<n {
    let fd = self.event_buffer.fd(i)
    if self.event_buffer.has_modify(i) {
      let { identity, .. } = self.watched[fd]
      self.watcher.mark_as_modified(identity)
    }
  }
}
