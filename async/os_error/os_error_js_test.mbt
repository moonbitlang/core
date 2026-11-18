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
#external
priv type SystemErrorMap

///|
#module("node:util")
extern "js" fn get_system_error_map() -> SystemErrorMap = "getSystemErrorMap"

///|
extern "js" fn SystemErrorMap::code(
  self : SystemErrorMap,
  name : String,
) -> Int32 =
  #| (map, name) => {
  #|   for (const [code, [entryName]] of map) {
  #|     if (entryName === name) return code;
  #|   }
  #|   throw Error(`Missing required system error: ${name}`);
  #| }

///|
extern "js" fn SystemErrorMap::message(
  self : SystemErrorMap,
  code : Int32,
) -> String =
  #| (map, code) => map.get(code)[1]

///|
test "Node error classification and diagnostics" {
  let map = get_system_error_map()
  let cases : Array[(@os_error.Kind, String)] = [
    (NotFound, "ENOENT"),
    (AlreadyExists, "EEXIST"),
    (AccessDenied, "EACCES"),
    (NotDirectory, "ENOTDIR"),
    (ConnectionRefused, "ECONNREFUSED"),
    (OperationNotSupported, "ENOTSUP"),
    (NotEmpty, "ENOTEMPTY"),
    (Unknown, "EPERM"),
    (Unknown, "EBADF"),
    (Unknown, "EIO"),
  ]
  for (expected, name) in cases {
    let code = map.code(name)
    let error = @os_error.from_errno(code, context="operation")
    let OsError(kind, raw_code~, context~) = error
    assert_eq(kind, expected)
    assert_eq(raw_code, code)
    assert_eq(context, "operation")
    assert_eq(error.to_string(), "operation: \{map.message(code)}")
  }
}

///|
test "Unknown Node codes preserve the error contract" {
  for code in [-123456789, 0, 1, -2147483648, 2147483647] {
    let error = @os_error.OsError::from_errno(code, context="read")
    let OsError(kind, raw_code~, context~) = error
    assert_eq(kind, Unknown)
    assert_eq(raw_code, code)
    assert_eq(context, "read")
    assert_eq(error.to_string(), "read: Unknown system error \{code}")
  }
  let error = @os_error.from_errno(-123456789, context="read")
    .wrap_context(c => "file: \{c}")
    .wrap_context(c => "request: \{c}")
  try {
    raise error
  } catch {
    OsError(kind, raw_code~, context~) as caught => {
      debug_inspect(
        (kind, raw_code, context),
        content=(
          #|(Unknown, -123456789, "request: file: read")
        ),
      )
      inspect(
        caught.to_string(),
        content=(
          #|request: file: read: Unknown system error -123456789
        ),
      )
      debug_inspect(
        caught,
        content=(
          #|<@os_error.OsError:
          #|  "request: file: read: Unknown system error -123456789">
        ),
      )
      json_inspect(caught, content=[
        "OsError",
        "Unknown",
        { "raw_code": -123456789, "context": "request: file: read" },
      ])
    }
  }
}

///|
#module("node:os")
extern "js" fn tmpdir() -> String = "tmpdir"

///|
#module("node:fs")
extern "js" fn mkdtemp_sync(prefix : String) -> String = "mkdtempSync"

///|
#module("node:fs")
extern "js" fn rmdir_sync(path : String) -> Unit = "rmdirSync"

///|
#module("node:fs")
extern "js" fn unlink_sync(path : String) -> Unit = "unlinkSync"

///|
#module("node:fs")
extern "js" fn open_sync(path : String, flags : String) -> Int32 = "openSync"

///|
#module("node:fs")
extern "js" fn close_sync(fd : Int32) -> Unit = "closeSync"

///|
extern "js" fn open_errno(
  open : (String, String) -> Int32,
  close : (Int32) -> Unit,
  path : String,
  flags : String,
  expected : String,
) -> Int32 =
  #| (open, close, path, flags, expected) => {
  #|   try {
  #|     const fd = open(path, flags);
  #|     close(fd);
  #|   } catch (error) {
  #|     if (error.code !== expected || !Number.isInteger(error.errno)) throw error;
  #|     return error.errno;
  #|   }
  #|   throw Error(`Expected ${expected} from open`);
  #| }

///|
test "Real Node file errors convert to OsError" {
  let dir = mkdtemp_sync(tmpdir() + "/moon-os-error-")
  defer rmdir_sync(dir)
  let existing = dir + "/existing"
  let fd = open_sync(existing, "wx")
  defer unlink_sync(existing)
  close_sync(fd)
  let cases : Array[(String, String, String, @os_error.Kind)] = [
    (dir + "/missing", "r", "ENOENT", NotFound),
    (existing, "wx", "EEXIST", AlreadyExists),
  ]
  for (path, flags, name, expected) in cases {
    let code = open_errno(open_sync, close_sync, path, flags, name)
    let error = @os_error.from_errno(code, context="open \{path}")
    let OsError(kind, raw_code~, context~) = error
    assert_eq(kind, expected)
    assert_eq(raw_code, code)
    assert_eq(context, "open \{path}")
  }
}
