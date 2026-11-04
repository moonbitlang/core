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
fn zlib_error(input : BytesView, max_output? : Int32) -> @zlib.ZlibError {
  try @zlib.decompress(input, max_output?) catch {
    e => e
  } noraise {
    _ => abort("expected a ZlibError")
  }
}

///|
test "ZlibError Show prints kind and message" {
  let bad = zlib_error(b"\x78\x9c\xff\x00\x00\x00\x00\x00\x00\x00")
  inspect(
    bad,
    content=(
      #|InvalidDeflate: corrupt: reserved block type
    ),
  )
  inspect(
    "\{bad}",
    content=(
      #|InvalidDeflate: corrupt: reserved block type
    ),
  )
  inspect(
    zlib_error(@zlib.compress(b"hello, world"), max_output=4),
    content=(
      #|OutputLimitExceeded(limit=4, observed=5): decoded output exceeds its byte limit
    ),
  )
}

///|
test "ZlibError Debug prints the constructor form" {
  @debug.debug_inspect(
    zlib_error(b"\x78\x9c\xff\x00\x00\x00\x00\x00\x00\x00"),
    content=(
      #|ZlibError(InvalidDeflate, "corrupt: reserved block type")
    ),
  )
  @debug.debug_inspect(
    zlib_error(@zlib.compress(b"hello, world"), max_output=4),
    content=(
      #|ZlibError(
      #|  OutputLimitExceeded(limit=4, observed=5),
      #|  "decoded output exceeds its byte limit",
      #|)
    ),
  )
}

///|
test "ZlibError Eq compares kind and message" {
  let a = zlib_error(b"\x78\x9c\xff\x00\x00\x00\x00\x00\x00\x00")
  let b = zlib_error(b"\x78\x9c\xff\x00\x00\x00\x00\x00\x00\x00")
  let c = zlib_error(@zlib.compress(b"hello, world"), max_output=4)
  inspect(
    a == b,
    content=(
      #|true
    ),
  )
  inspect(
    a.equal(b),
    content=(
      #|true
    ),
  )
  inspect(
    a == c,
    content=(
      #|false
    ),
  )
  inspect(
    a != c,
    content=(
      #|true
    ),
  )
  // Same kind (`InvalidDeflate`), different message: not equal.
  let d = zlib_error(b"\x78\x9c\x01\x00\x00\x00\x00\x00\x00\x00\x00")
  inspect(
    d,
    content=(
      #|InvalidDeflate: stored block length mismatch
    ),
  )
  inspect(
    a == d,
    content=(
      #|false
    ),
  )
}

///|
test "ZlibError upcast to Error" {
  let err : Error = zlib_error(b"\x78\x9c\xff\x00\x00\x00\x00\x00\x00\x00")
  inspect(
    err,
    content=(
      #|InvalidDeflate: corrupt: reserved block type
    ),
  )
  inspect(
    "\{err}",
    content=(
      #|InvalidDeflate: corrupt: reserved block type
    ),
  )
}

///|
test "ZlibError::to_string is promoted" {
  let err = zlib_error(b"\x78\x9c\xff\x00\x00\x00\x00\x00\x00\x00")
  inspect(
    err.to_string(),
    content=(
      #|InvalidDeflate: corrupt: reserved block type
    ),
  )
  assert_eq(err.to_string(), "\{err}")
}
