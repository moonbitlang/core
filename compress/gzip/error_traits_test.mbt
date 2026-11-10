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
fn gzip_error(input : BytesView, max_output_bytes? : Int32) -> @gzip.GzipError {
  try @gzip.decompress(input, max_output_bytes?) catch {
    e => e
  } noraise {
    _ => abort("expected a GzipError")
  }
}

///|
test "GzipError Show prints kind and message" {
  let bad = gzip_error(b"this is definitely not gzip data")
  inspect(
    bad,
    content=(
      #|InvalidHeader: gzip: bad magic
    ),
  )
  inspect(
    "\{bad}",
    content=(
      #|InvalidHeader: gzip: bad magic
    ),
  )
  inspect(
    gzip_error(@gzip.compress(b"hello, world"), max_output_bytes=4),
    content=(
      #|OutputLimitExceeded(limit=4, observed=5): decoded output exceeds its byte limit
    ),
  )
}

///|
test "GzipError Debug prints the constructor form" {
  @debug.debug_inspect(
    gzip_error(b"this is definitely not gzip data"),
    content=(
      #|GzipError(InvalidHeader, "gzip: bad magic")
    ),
  )
  @debug.debug_inspect(
    gzip_error(@gzip.compress(b"hello, world"), max_output_bytes=4),
    content=(
      #|GzipError(
      #|  OutputLimitExceeded(limit=4, observed=5),
      #|  "decoded output exceeds its byte limit",
      #|)
    ),
  )
}

///|
fn error_kind(err : @gzip.GzipError) -> @gzip.GzipErrorKind {
  match err {
    GzipError(kind, _) => kind
  }
}

///|
test "GzipError is matched by kind" {
  // The error doesn't implement `Eq`, because derived equality would compare the
  // message text too. Callers match on the kind, which does implement `Eq`.
  let a = gzip_error(b"this is definitely not gzip data")
  let c = gzip_error(@gzip.compress(b"hello, world"), max_output_bytes=4)
  let d = gzip_error(b"\x1f\x8b\x07this is definitely not gzip data")
  guard a is GzipError(InvalidHeader, _) && d is GzipError(InvalidHeader, _) else {
    fail("expected InvalidHeader, got \{a} and \{d}")
  }
  // Same kind, different message.
  inspect(error_kind(a) == error_kind(d), content="true")
  inspect("\{a}" == "\{d}", content="false")
  // Different kinds.
  inspect(error_kind(a) == error_kind(c), content="false")
}

///|
test "GzipError upcast to Error" {
  let err : Error = gzip_error(b"this is definitely not gzip data")
  inspect(
    err,
    content=(
      #|InvalidHeader: gzip: bad magic
    ),
  )
  inspect(
    "\{err}",
    content=(
      #|InvalidHeader: gzip: bad magic
    ),
  )
}

///|
test "GzipError::to_string is promoted" {
  let err = gzip_error(b"this is definitely not gzip data")
  inspect(
    err.to_string(),
    content=(
      #|InvalidHeader: gzip: bad magic
    ),
  )
  assert_eq(err.to_string(), "\{err}")
}
