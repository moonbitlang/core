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
/// A cross-platform enum describing common error kinds.
/// Useful for matching specific special error codes.
#non_exhaustive
pub(all) enum Kind {
  NotFound
  AlreadyExists
  AccessDenied
  NotDirectory
  ConnectionRefused
  OperationNotSupported
  // TODO: add private constructor support & make `Unknown` private
  Unknown
} derive(@debug.Debug, @json.ToJson, Eq)

///|
let errno_table : Map[Int32, Kind] = match @env_util.platform {
  Linux =>
    Map([
      (@errno.linux_ENOENT, NotFound),
      (@errno.linux_EEXIST, AlreadyExists),
      (@errno.linux_EACCES, AccessDenied),
      (@errno.linux_ENOTDIR, NotDirectory),
      (@errno.linux_ECONNREFUSED, ConnectionRefused),
      (@errno.linux_ENOTSUP, OperationNotSupported),
    ])
  MacOS =>
    Map([
      (@errno.macos_ENOENT, NotFound),
      (@errno.macos_EEXIST, AlreadyExists),
      (@errno.macos_EACCES, AccessDenied),
      (@errno.macos_ENOTDIR, NotDirectory),
      (@errno.macos_ECONNREFUSED, ConnectionRefused),
      (@errno.macos_ENOTSUP, OperationNotSupported),
    ])
  Windows =>
    Map([
      (@errno.windows_ERROR_FILE_NOT_FOUND, NotFound),
      (@errno.windows_ERROR_PATH_NOT_FOUND, NotFound),
      (@errno.windows_ERROR_FILE_EXISTS, AlreadyExists),
      (@errno.windows_ERROR_ALREADY_EXISTS, AlreadyExists),
      (@errno.windows_ERROR_ACCESS_DENIED, AccessDenied),
      (@errno.windows_ERROR_DIRECTORY, NotDirectory),
      (@errno.windows_ERROR_CONNECTION_REFUSED, ConnectionRefused),
      (@errno.windows_ERROR_NOT_SUPPORTED, OperationNotSupported),
    ])
}

///|
fn Kind::Kind(code : Int32) -> Kind {
  match errno_table.get(code) {
    None => Unknown
    Some(kind) => kind
  }
}
