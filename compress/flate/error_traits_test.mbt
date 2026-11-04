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
fn inflate_error(input : BytesView, max_output? : Int32) -> @flate.InflateError {
  try @flate.inflate_exact(input, max_output?) catch {
    e => e
  } noraise {
    _ => abort("expected an InflateError")
  }
}

///|
test "InflateError Show prints kind and message" {
  let corrupt = inflate_error(b"\xff")
  inspect(
    corrupt,
    content=(
      #|Corrupt: corrupt: reserved block type
    ),
  )
  inspect(
    "\{corrupt}",
    content=(
      #|Corrupt: corrupt: reserved block type
    ),
  )
  let limited = inflate_error(@flate.deflate_all(b"hello, world"), max_output=4)
  inspect(
    limited,
    content=(
      #|OutputLimitExceeded(limit=4, observed=5): decoded output exceeds its byte limit
    ),
  )
}

///|
test "InflateError Debug prints the constructor form" {
  @debug.debug_inspect(
    inflate_error(b"\xff"),
    content=(
      #|InflateError(Corrupt, "corrupt: reserved block type")
    ),
  )
  @debug.debug_inspect(
    inflate_error(@flate.deflate_all(b"hello, world"), max_output=4),
    content=(
      #|InflateError(
      #|  OutputLimitExceeded(limit=4, observed=5),
      #|  "decoded output exceeds its byte limit",
      #|)
    ),
  )
}

///|
test "InflateError Eq compares kind and message" {
  let a = inflate_error(b"\xff")
  let b = inflate_error(b"\xff")
  let c = inflate_error(b"")
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
  // Same kind (`Corrupt`), different message: not equal.
  let d = inflate_error(b"\x01\x00\x00\x00\x00")
  inspect(
    d,
    content=(
      #|Corrupt: stored block length mismatch
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
test "InflateError upcast to Error" {
  let err : Error = inflate_error(b"\xff")
  inspect(
    err,
    content=(
      #|Corrupt: corrupt: reserved block type
    ),
  )
  inspect(
    "\{err}",
    content=(
      #|Corrupt: corrupt: reserved block type
    ),
  )
}

///|
test "InflateError::to_string is promoted" {
  let err = inflate_error(b"\xff")
  inspect(
    err.to_string(),
    content=(
      #|Corrupt: corrupt: reserved block type
    ),
  )
  assert_eq(err.to_string(), "\{err}")
}
