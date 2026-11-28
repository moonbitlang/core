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
priv struct Handle(Int32)

///|
#external
priv type FileResult

///|
extern "js" fn FileResult::value(self : FileResult) -> Int32 = "r => r.value"

///|
extern "js" fn FileResult::error(self : FileResult) -> String = "r => r.error"

///|
extern "js" fn FileResult::missing(self : FileResult) -> Bool = "r => r.missing === true"

///|
#module("node:fs")
extern "js" fn open_sync(path : String, flags : String) -> Int32 = "openSync"

///|
#module("node:fs")
extern "js" fn read_sync(
  fd : Int32,
  buffer : FixedArray[Byte],
  offset : Int32,
  len : Int32,
  position : Int64,
) -> Int32 = "readSync"

///|
#module("node:fs")
extern "js" fn close_sync(fd : Int32) -> Unit = "closeSync"

///|
extern "js" fn open_result(
  open : (String, String) -> Int32,
  path : String,
) -> FileResult =
  #| (open, path) => {
  #|   try { return { value: open(path, "r"), error: "" }; }
  #|   catch (e) { return { value: -1, error: String(e), missing: e.code === "ENOENT" }; }
  #| }

///|
extern "js" fn read_result(
  read : (Int32, FixedArray[Byte], Int32, Int32, Int64) -> Int32,
  fd : Int32,
  buffer : FixedArray[Byte],
  offset : Int32,
  len : Int32,
  position : Int64,
) -> FileResult =
  #| (read, fd, buffer, offset, len, position) => {
  #|   try { return { value: read(fd, buffer, offset, len, position), error: "" }; }
  #|   catch (e) { return { value: -1, error: String(e) }; }
  #| }

///|
extern "js" fn close_result(close : (Int32) -> Unit, fd : Int32) -> FileResult =
  #| (close, fd) => {
  #|   try { close(fd); return { value: 0, error: "" }; }
  #|   catch (e) { return { value: -1, error: String(e) }; }
  #| }

///|
// Called only during snapshot comparison, never while loading the package.
extern "js" fn file_host_is_unix() -> Bool = "() => process.platform !== 'win32'"

///|
fn open(path : String) -> Handle? raise {
  let result = open_result(open_sync, path)
  if result.missing() {
    return None
  }
  guard result.value() >= 0 else { fail(result.error()) }
  Some(Handle(result.value()))
}

///|
fn Handle::read(
  self : Handle,
  buffer : FixedArray[Byte],
  offset : Int32,
  len : Int32,
  position : Int64,
) -> Int32 raise {
  let result = read_result(read_sync, self.0, buffer, offset, len, position)
  guard result.value() >= 0 else { fail(result.error()) }
  result.value()
}

///|
fn Handle::close(self : Handle) -> Unit raise {
  let result = close_result(close_sync, self.0)
  guard result.value() == 0 else { fail(result.error()) }
}
