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
#cfg(not(platform="windows"))
#borrow(major, minor, fix)
extern "C" fn load_openssl_ffi(
  major : @ref.Ref[Int32],
  minor : @ref.Ref[Int32],
  fix : @ref.Ref[Int32],
) -> Int32 = "moonbit_rt_load_openssl"

///|
#cfg(not(platform="windows"))
extern "C" fn init_bio_method(
  read : FuncRef[(BIO, @c_buffer.Buffer, Int32) -> Int32],
  write : FuncRef[(BIO, @c_buffer.Buffer, Int32) -> Int32],
) = "moonbit_rt_init_bio_method"

///|
/// Lazily load OpenSSL on first use, so a program that never touches TLS pays
/// nothing. Every raw-symbol FFI wrapper calls this first; all other FFI runs on
/// handles those produce, so it is transitively covered. The outcome is cached →
/// success makes repeat calls free, failure re-raises the same error immediately.
#cfg(not(platform="windows"))
let load_openssl_result : @lazy.Lazy[Result[Unit, Error]] = Lazy(() => {
  let major = @ref.Ref(0)
  let minor = @ref.Ref(0)
  let fix = @ref.Ref(0)
  match load_openssl_ffi(major, minor, fix) {
    0 => ()
    1 => return Err(TlsError("failed to load OpenSSL"))
    2 => return Err(TlsError("failed to get OpenSSL version"))
    3 =>
      return Err(
        TlsError(
          "unsupported OpenSSL version \{major.val}.\{minor.val}.\{fix.val}",
        ),
      )
    4 => return Err(TlsError("failed to load some OpenSSL function"))
    _ => panic()
  }
  init_bio_method((bio, dst, len) => bio.read(dst, len)) <| ((bio, src, len) => {
    bio.write(src, len)
  })
  Ok(())
})

///|
#cfg(not(platform="windows"))
fn load_openssl() -> Unit raise {
  load_openssl_result.force().unwrap_or_error()
}
