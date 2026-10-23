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
/// Which bounded resource was exceeded during a bounded read or write. The
/// payload-related kinds guard decoded allocations; `DirectoryBytes` bounds
/// metadata-only directory input; `OutputBytes` bounds serialization size.
pub(all) enum LimitKind {
  PackageBytes
  Entries
  EntryUncompressedBytes
  TotalUncompressedBytes
  DirectoryBytes
  OutputBytes
} derive(Eq, @debug.Debug)

///|
/// Machine-readable category for a ZIP container failure. The accompanying
/// `ZipError` message is intended for diagnostics rather than branching.
pub(all) enum ZipErrorKind {
  /// The input ended before a complete record, header, payload, or trailer.
  Truncated
  /// A fixed signature (local, central, end-of-central, zip64) was wrong.
  InvalidSignature
  /// No end-of-central-directory record could be located.
  MissingEndOfCentral
  /// The entry uses a compression method this package cannot decode. Carries
  /// the method code from the central directory.
  UnsupportedCompression(Int32)
  /// An entry or archive name is not valid UTF-8.
  InvalidUtf8
  /// The archive uses a ZIP feature this package does not support (encryption,
  /// multi-disk, ambiguous or inconsistent records, ...).
  UnsupportedFeature
  /// The entry contains malformed DEFLATE data.
  InvalidDeflate
  /// A range reader response did not match its requested byte count,
  /// or nonempty input was supplied without an active range request.
  InvalidRead
  /// The requested directory entry index is out of bounds.
  InvalidEntryIndex(Int32)
  /// Entry size declarations or decoded sizes are inconsistent, or a `Writer`
  /// entry received more or fewer bytes than its declared size.
  SizeMismatch
  /// The entry payload does not match its stored CRC-32.
  ChecksumMismatch
  /// A caller-supplied resource limit was exceeded.
  /// The actual value is observed usage when processing stopped, not necessarily
  /// the complete decoded size of an entry that exceeded its output limit.
  LimitExceeded(LimitKind, UInt64, UInt64)
  /// The caller's cancellation callback returned `true` during a bounded read.
  Cancelled
  /// A caller-supplied argument is out of range, such as a negative limit.
  InvalidArgument
  /// A `Writer` call is not valid in its current state: no open entry, an
  /// entry already open, a reentrant sink call, or use after finish/failure.
  InvalidState
} derive(Eq, @debug.Debug)

///|
/// Structured ZIP failure: a stable category plus a human-readable diagnostic.
pub suberror ZipError {
  ZipError(ZipErrorKind, String)
}

///|
fn check_cancelled(cancelled : () -> Bool) -> Unit raise ZipError {
  if cancelled() {
    raise ZipError(Cancelled, "zip: cancelled")
  }
}

///|
/// Map a raw DEFLATE failure without losing cooperative cancellation.
fn wrap_inflate_error(err : @flate.InflateError) -> ZipError {
  let InflateError(kind, message) = err
  match kind {
    Cancelled => ZipError(Cancelled, message)
    Truncated => ZipError(Truncated, message)
    _ => ZipError(InvalidDeflate, message)
  }
}
