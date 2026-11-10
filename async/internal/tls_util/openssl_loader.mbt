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
/// Initialize TLS library, load necessary imports
#cfg(any(target="wasm", platform="windows"))
#warnings("-unused_error_type")
pub fn setup_tls_library() -> Unit raise {
  ignore(@ref.Ref(0))
  ignore((_ : @lazy.Lazy[Result[Unit, String]]) => ())
}

///|
#cfg(all(target="native", not(platform="windows")))
#borrow(major, minor, fix)
extern "C" fn load_openssl_ffi(
  major : @ref.Ref[Int32],
  minor : @ref.Ref[Int32],
  fix : @ref.Ref[Int32],
) -> Int32 = "moonbit_rt_load_openssl"

///|
/// Lazily load OpenSSL on first use, so a program that never touches TLS pays
/// nothing. Every raw-symbol FFI wrapper calls this first; all other FFI runs on
/// handles those produce, so it is transitively covered. The outcome is cached →
/// success makes repeat calls free, failure re-raises the same error immediately.
#cfg(all(target="native", not(platform="windows")))
let load_openssl_result : @lazy.Lazy[Result[Unit, Error]] = Lazy(() => {
  let major = @ref.Ref(0)
  let minor = @ref.Ref(0)
  let fix = @ref.Ref(0)
  match load_openssl_ffi(major, minor, fix) {
    0 => Ok(())
    1 =>
      try @os_error.check_errno("load OpenSSL") catch {
        err => Err(err)
      } noraise {
        _ => Ok(())
      }
    2 => Err(Failure("failed to get OpenSSL version"))
    3 =>
      Err(
        Failure(
          "unsupported OpenSSL version \{major.val}.\{minor.val}.\{fix.val}",
        ),
      )
    4 => Err(Failure("failed to load some OpenSSL function"))
    _ => panic()
  }
})

///|
/// Initialize TLS library, load necessary imports
#cfg(all(target="native", not(platform="windows")))
pub fn setup_tls_library() -> Unit raise {
  load_openssl_result.force().unwrap_or_error()
}
