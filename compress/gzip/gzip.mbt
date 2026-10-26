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

// gzip (RFC 1952): a fixed header with optional fields, raw DEFLATE and an
// 8-byte trailer (CRC-32 and ISIZE, both little-endian).

///|
pub using @flate {
  type Strategy,
  type Status,
  type StepResult,
  type DeflateAction,
}

///|
/// Machine-readable category for a gzip decoding failure. The accompanying
/// `GzipError` message remains intended for diagnostics rather than branching.
/// Output limits, cancellation and invalid limits apply to `decompress` only.
pub(all) enum GzipErrorKind {
  /// The input ended before a complete member, header field, body, or trailer.
  Truncated
  /// The fixed header, magic bytes, method, or reserved flags are invalid.
  InvalidHeader
  /// The member's raw DEFLATE payload is malformed.
  InvalidDeflate
  /// The trailer CRC-32 does not match the decompressed payload.
  ChecksumMismatch
  /// The trailer ISIZE does not match the decompressed payload length.
  LengthMismatch
  /// The cumulative output ceiling and observed decoded size when stopped.
  /// The observed size need not be the complete multi-member output size.
  OutputLimitExceeded(limit~ : UInt64, observed~ : UInt64)
  /// The caller's cancellation callback returned true.
  Cancelled
  /// A caller-supplied output ceiling is negative.
  InvalidArgument
} derive(Eq, @debug.Debug)

///|
/// Structured gzip decoding failure: a stable category plus a human-readable
/// diagnostic.
pub suberror GzipError {
  GzipError(GzipErrorKind, String)
}

///|
/// Preserve resource failures as well as the diagnostic of malformed DEFLATE.
fn wrap_inflate_error(err : @flate.InflateError) -> GzipError {
  let InflateError(kind, message) = err
  match kind {
    OutputLimitExceeded(limit~, observed~) =>
      GzipError(OutputLimitExceeded(limit~, observed~), message)
    Cancelled => GzipError(Cancelled, message)
    InvalidArgument => GzipError(InvalidArgument, message)
    _ => GzipError(InvalidDeflate, message)
  }
}

///|
fn check_cancelled(cancelled : (() -> Bool)?) -> Unit raise GzipError {
  if cancelled is Some(callback) && callback() {
    raise GzipError(Cancelled, "gzip: cancelled by caller")
  }
}

///|
/// Poll during checksums as well as during DEFLATE decoding.
fn crc32_cancellable(
  input : BytesView,
  cancelled : (() -> Bool)?,
) -> UInt32 raise GzipError {
  guard cancelled is Some(_) else { return @checksum.crc32(input) }
  let crc = @checksum.Crc32()
  let mut start = 0
  while start < input.length() {
    check_cancelled(cancelled)
    let end = start + (input.length() - start).min(4096)
    crc.update(input[start:end])
    start = end
  }
  check_cancelled(cancelled)
  crc.finish()
}

///|
fn u32_le(data : BytesView, off : Int32) -> UInt32 {
  data[off].to_uint() |
  (data[off + 1].to_uint() << 8) |
  (data[off + 2].to_uint() << 16) |
  (data[off + 3].to_uint() << 24)
}

///|
/// Wrap a raw DEFLATE stream `deflated` of `input` in the gzip header/trailer.
fn gzip_frame(input : BytesView, deflated : Bytes) -> Bytes {
  let out = @buffer.Buffer()
  // Header: magic, CM=8 (deflate), FLG=0, MTIME=0, XFL=0, OS=255 (unknown).
  out.write_bytes(b"\x1f\x8b\x08\x00\x00\x00\x00\x00\x00\xff")
  out.write_bytes(deflated)
  out.write_uint_le(@checksum.crc32(input))
  out.write_uint_le(input.length().reinterpret_as_uint())
  out.to_bytes()
}

///|
/// Compress a complete gzip stream with the selected DEFLATE strategy.
/// `fast_store` may bypass the strategy for sampled inputs, trading ratio for speed.
pub fn compress(
  input : BytesView,
  strategy~ : @flate.Strategy = Standard(level=6),
  fast_store~ : Bool = false,
) -> Bytes {
  gzip_frame(input, @flate.deflate_all(input, strategy~, fast_store~))
}

///|
/// Inflate the raw DEFLATE member starting at `input[q:]` with the in-memory
/// decoder, which ignores what follows the member's final block; afterwards
/// The consumed count locates the 8-byte trailer. The caller reuses one
/// decoder across members.
fn inflate_member(
  input : BytesView,
  q : Int32,
  decoder : @flate.Decompressor,
  max_output : Int32,
  cancelled : (() -> Bool)?,
) -> @flate.Decompressed raise GzipError {
  decoder.decompress(input[q:], max_output~, cancelled?) catch {
    // All remaining input was handed over, yet the stream did not end.
    InflateError(Truncated, _) => raise GzipError(Truncated, "gzip: truncated")
    err => raise wrap_inflate_error(err)
  }
}

///|
/// Whether the bytes at `p` begin a gzip member: the magic pair, with a
/// truncated second byte treated as a (still-to-be-validated) member start so
/// the caller reports `Truncated` rather than ending the stream.
fn gunzip_member_magic(input : BytesView, p : Int32, n : Int32) -> Bool {
  input[p].to_int() == 0x1F && (p + 1 >= n || input[p + 1].to_int() == 0x8B)
}

///|
/// Skip a NUL-terminated header field, returning the offset one past the NUL.
/// An unterminated field (bounded by the input end) still consumes its bytes;
/// the caller's truncated-input check rejects it.
fn gunzip_skip_nul_terminated(
  input : BytesView,
  q : Int32,
  cancelled : (() -> Bool)?,
) -> Int32 raise GzipError {
  let mut q = q
  while q < input.length() && input[q].to_int() != 0 {
    if (q & 4095) == 0 {
      check_cancelled(cancelled)
    }
    q = q + 1
  }
  q + 1
}

///|
/// Offset one past the optional header fields (FEXTRA, FNAME, FCOMMENT, FHCRC)
/// gated by the FLG bits.
fn gunzip_optional_fields_end(
  input : BytesView,
  q : Int32,
  flg : Int32,
  cancelled : (() -> Bool)?,
) -> Int32 raise GzipError {
  let header_start = q - 10
  let mut q = q
  if (flg & 4) != 0 { // FEXTRA
    let xlen = input[q].to_int() | (input[q + 1].to_int() << 8)
    q = q + 2 + xlen
  }
  if (flg & 8) != 0 { // FNAME (NUL-terminated)
    q = gunzip_skip_nul_terminated(input, q, cancelled)
  }
  if (flg & 16) != 0 { // FCOMMENT (NUL-terminated)
    q = gunzip_skip_nul_terminated(input, q, cancelled)
  }
  if (flg & 2) != 0 { // FHCRC
    guard q <= input.length() - 2 else {
      raise GzipError(Truncated, "gzip: truncated header CRC")
    }
    let expected = input[q].to_uint() | (input[q + 1].to_uint() << 8)
    guard (crc32_cancellable(input[header_start:q], cancelled) & 0xffff) ==
      expected else {
      raise GzipError(ChecksumMismatch, "gzip: header CRC-16 mismatch")
    }
    q = q + 2
  }
  q
}

///|
/// Decode one member at `p`: fixed header, optional fields, DEFLATE payload,
/// and trailer verification. Returns the payload and the offset of the next
/// member (one past the trailer).
fn gunzip_decode_member(
  input : BytesView,
  p : Int32,
  n : Int32,
  decoder : @flate.Decompressor,
  max_output : Int32,
  cancelled : (() -> Bool)?,
) -> (Bytes, Int32) raise GzipError {
  guard n - p >= 18 else { raise GzipError(Truncated, "gzip: truncated") }
  guard input[p + 2].to_int() == 0x08 else {
    raise GzipError(InvalidHeader, "gzip: unsupported compression method")
  }
  let flg = input[p + 3].to_int()
  guard (flg & 0xE0) == 0 else {
    raise GzipError(InvalidHeader, "gzip: reserved flags are set")
  }
  let q = gunzip_optional_fields_end(input, p + 10, flg, cancelled)
  guard q <= n - 8 else { raise GzipError(Truncated, "gzip: truncated") }
  let result = inflate_member(input, q, decoder, max_output, cancelled)
  let payload = result.data
  let trailer = q + result.consumed
  guard trailer <= n - 8 else { raise GzipError(Truncated, "gzip: truncated") }
  guard crc32_cancellable(payload, cancelled) == u32_le(input, trailer) else {
    raise GzipError(ChecksumMismatch, "gzip: CRC-32 mismatch")
  }
  guard payload.length().reinterpret_as_uint() == u32_le(input, trailer + 4) else {
    raise GzipError(LengthMismatch, "gzip: length mismatch")
  }
  (payload, trailer + 8)
}

///|
/// Decode and join gzip members, verifying each CRC-32 and length trailer.
/// Trailing bytes that do not begin another member are ignored. `max_output`
/// caps cumulative output (default: `Bytes` capacity); exceeding it raises
/// `OutputLimitExceeded(limit~, observed~)`, a negative value `InvalidArgument`.
/// `cancelled` is polled at entry, between members and in 4 KiB intervals during
/// name/comment scanning, decoding, checksumming and joining; true raises `Cancelled`.
pub fn decompress(
  input : BytesView,
  max_output? : Int32,
  cancelled? : () -> Bool,
) -> Bytes raise GzipError {
  let limit = max_output.unwrap_or(0x7fff_ffff)
  guard limit >= 0 else {
    raise GzipError(InvalidArgument, "max_output must be non-negative")
  }
  check_cancelled(cancelled)
  let n = input.length()
  guard n >= 18 else { raise GzipError(Truncated, "gzip: input too short") }
  let out = @buffer.Buffer()
  let decoder = @flate.Decompressor()
  let mut p = 0
  let mut total = 0
  for ;; {
    // Stop once no further member begins: clean end or trailing garbage. A
    // complete magic prefix does begin another member, however, so it must be
    // decoded or reported as truncated rather than silently discarded.
    guard p < n else { break }
    guard gunzip_member_magic(input, p, n) else {
      guard p == 0 else { break }
      raise GzipError(InvalidHeader, "gzip: bad magic")
    }
    check_cancelled(cancelled)
    let (payload, next_p) = gunzip_decode_member(
      input,
      p,
      n,
      decoder,
      limit - total,
      cancelled,
    ) catch {
      GzipError(OutputLimitExceeded(limit=_, observed~), message) =>
        raise GzipError(
          OutputLimitExceeded(
            limit=limit.to_uint64(),
            observed=total.to_uint64() + observed,
          ),
          message,
        )
      error => raise error
    }
    total += payload.length()
    // The usual file is one member and nothing else: its payload is the
    // result, with no joining buffer to copy it through.
    if p == 0 && next_p == n {
      return payload
    }
    if cancelled is Some(_) {
      let mut start = 0
      while start < payload.length() {
        check_cancelled(cancelled)
        let end = start + (payload.length() - start).min(4096)
        out.write_bytes(payload[start:end])
        start = end
      }
    } else {
      out.write_bytes(payload)
    }
    p = next_p
  }
  check_cancelled(cancelled)
  out.to_bytes()
}
