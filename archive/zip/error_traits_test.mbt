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
fn zip_error(input : BytesView, limits? : @zip.ReadLimits) -> @zip.ZipError {
  try @zip.read_all(input, limits?) catch {
    e => e
  } noraise {
    _ => abort("expected a ZipError")
  }
}

///|
/// A valid empty archive: a bare end-of-central-directory record.
let empty_archive : Bytes = b"PK\x05\x06\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"

///|
test "ZipError Show prints kind and message" {
  let bad = zip_error(b"not a zip archive at all, no EOCD here")
  inspect(
    bad,
    content=(
      #|MissingEndOfCentral: zip: end of central directory not found
    ),
  )
  inspect(
    "\{bad}",
    content=(
      #|MissingEndOfCentral: zip: end of central directory not found
    ),
  )
  let limited = zip_error(empty_archive, limits=ReadLimits(max_package_bytes=1))
  inspect(
    limited,
    content=(
      #|LimitExceeded(kind=PackageBytes, limit=1, observed=22): zip: package exceeds the input size limit
    ),
  )
}

///|
test "ZipError Debug prints the constructor form" {
  @debug.debug_inspect(
    zip_error(b"not a zip archive at all, no EOCD here"),
    content=(
      #|ZipError(
      #|  MissingEndOfCentral,
      #|  "zip: end of central directory not found",
      #|)
    ),
  )
  @debug.debug_inspect(
    zip_error(empty_archive, limits=ReadLimits(max_package_bytes=1)),
    content=(
      #|ZipError(
      #|  LimitExceeded(kind=PackageBytes, limit=1, observed=22),
      #|  "zip: package exceeds the input size limit",
      #|)
    ),
  )
}

///|
test "ZipError Eq compares kind and message" {
  let a = zip_error(b"not a zip archive at all, no EOCD here")
  let b = zip_error(b"not a zip archive at all, no EOCD here")
  let c = zip_error(empty_archive, limits=ReadLimits(max_package_bytes=1))
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
  // Same kind (`InvalidSignature`), different message: not equal.
  let archive = @zip.Archive()
  archive.add("a", b"x", compression=Store)
  let bad_local = @zip.write(archive).to_fixedarray()
  bad_local[0] = 0
  let bad_central = @zip.write(archive).to_fixedarray()
  let eocd = bad_central.length() - 22
  bad_central[bad_central[eocd + 16].to_int() |
  (bad_central[eocd + 17].to_int() << 8)] = 0
  let d = zip_error(Bytes::from_array(bad_local))
  let e = zip_error(Bytes::from_array(bad_central))
  inspect(
    d,
    content=(
      #|InvalidSignature: zip: invalid local header signature
    ),
  )
  inspect(
    e,
    content=(
      #|InvalidSignature: zip: invalid central directory signature
    ),
  )
  inspect(
    d == e,
    content=(
      #|false
    ),
  )
}

///|
test "ZipError upcast to Error" {
  let err : Error = zip_error(b"not a zip archive at all, no EOCD here")
  inspect(
    err,
    content=(
      #|MissingEndOfCentral: zip: end of central directory not found
    ),
  )
  inspect(
    "\{err}",
    content=(
      #|MissingEndOfCentral: zip: end of central directory not found
    ),
  )
}

///|
test "ZipError Show keeps a wide LimitExceeded on one line" {
  let archive = @zip.Archive()
  archive.add("big", Bytes::make(100_001, 0))
  let err = zip_error(
    @zip.write(archive),
    limits=ReadLimits(max_entry_uncompressed_bytes=100_000),
  )
  inspect(
    err,
    content=(
      #|LimitExceeded(kind=EntryUncompressedBytes, limit=100000, observed=100001): zip: entry exceeds the per-entry uncompressed limit
    ),
  )
}

///|
test "ZipError::to_string is promoted" {
  let err = zip_error(b"not a zip archive at all, no EOCD here")
  inspect(
    err.to_string(),
    content=(
      #|MissingEndOfCentral: zip: end of central directory not found
    ),
  )
  assert_eq(err.to_string(), "\{err}")
}
