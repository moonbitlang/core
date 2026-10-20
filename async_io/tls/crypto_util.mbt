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
#borrow(buf)
extern "C" fn rand_bytes_ffi(buf : FixedArray[Byte], num : Int32) -> Int32 = "moonbit_rt_tls_rand_bytes"

///|
/// Generate cryptographically secure random bytes using OpenSSL's RAND_bytes
/// Returns 1 on success, 0 on failure
#cfg(not(platform="windows"))
#internal(internal, "for internal use only")
pub fn rand_bytes(num : Int32) -> Bytes raise {
  // Reachable with no prior TLS connection (e.g. a plain `ws://` handshake).
  load_openssl()
  let result = FixedArray::make(num, b'\x00')
  if rand_bytes_ffi(result, num) != 1 {
    raise Failure::Failure(err_get_error())
  }
  result.unsafe_reinterpret_as_bytes()
}

///|
#cfg(platform="windows")
#borrow(buf)
extern "C" fn rand_bytes_ffi(buf : FixedArray[Byte], num : Int32) -> Int32 = "moonbit_rt_tls_rand_bytes"

///|
#cfg(platform="windows")
#internal(internal, "for internal use only")
pub fn rand_bytes(num : Int32) -> Bytes raise {
  let result = FixedArray::make(num, b'\x00')
  if rand_bytes_ffi(result, num) == 0 {
    @os_error.check_errno("@tls.rand_bytes()")
  }
  result.unsafe_reinterpret_as_bytes()
}

///|
#cfg(not(platform="windows"))
#borrow(src, dst)
extern "C" fn sha1_ffi(src : Bytes, len : Int32, dst : FixedArray[Byte]) = "moonbit_rt_tls_SHA1"

///|
#cfg(not(platform="windows"))
#internal(internal, "for internal use only")
pub fn sha1(src : Bytes) -> Bytes raise {
  // Reachable with no prior TLS connection (e.g. a plain `ws://` handshake).
  load_openssl()
  let result = FixedArray::make(20, b'\x00')
  sha1_ffi(src, src.length(), result)
  result.unsafe_reinterpret_as_bytes()
}

///|
#cfg(platform="windows")
#borrow(data, out)
extern "C" fn sha1_ffi(
  data : Bytes,
  len : Int32,
  out : FixedArray[Byte],
) -> Int32 = "moonbit_rt_tls_SHA1"

///|
#cfg(platform="windows")
#internal(internal, "for internal use only")
pub fn sha1(src : Bytes) -> Bytes raise {
  let result = FixedArray::make(20, b'\x00')
  if sha1_ffi(src, src.length(), result) == 0 {
    @os_error.check_errno("@tls.sha1()")
  }
  result.unsafe_reinterpret_as_bytes()
}
