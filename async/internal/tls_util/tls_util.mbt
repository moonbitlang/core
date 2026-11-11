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
#cfg(all(target="native", not(platform="windows")))
#borrow(buf)
extern "C" fn get_tls_error_ffi(buf : Bytes) -> Int32 = "moonbit_rt_tls_get_error"

///|
/// Get TLS library error, only available for OpenSSL backend
#cfg(all(target="native", not(platform="windows")))
pub fn get_tls_error() -> String {
  let buf = Bytes::make(256, 0)
  let len = get_tls_error_ffi(buf)
  @bytes_util.ascii_to_string(buf[:len])
}

///|
/// Get TLS library error, only available for OpenSSL backend
#cfg(any(target="wasm", platform="windows"))
pub fn get_tls_error() -> String {
  ignore(@bytes_util.ascii_to_string)
  panic()
}
