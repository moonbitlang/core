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

// zlib (RFC 1950): a header, optional dictionary ID, raw DEFLATE and an
// Adler-32 trailer. The streaming decoder supports preset dictionaries.

///|
/// Machine-readable category for a zlib decoding failure. The accompanying
/// `ZlibError` message remains intended for diagnostics rather than branching.
/// Output limits, cancellation and invalid limits apply to `decompress` only.
pub(all) enum ZlibErrorKind {
  /// The input ended before the header, body, DICTID, or trailer completed.
  Truncated
  /// CMF/FLG contains an unsupported method, window size, or bad header check.
  InvalidHeader
  /// The stream announces FDICT but the caller supplied no dictionary.
  DictionaryRequired
  /// The supplied dictionary does not match the stream's DICTID.
  DictionaryMismatch
  /// The wrapped raw DEFLATE payload is malformed.
  InvalidDeflate
  /// The Adler-32 trailer does not match the decompressed payload.
  ChecksumMismatch
  /// Bytes occur after the raw DEFLATE end and before the expected trailer.
  TrailingData
  /// The output ceiling and observed decoded size when processing stopped.
  /// The observed size need not be the complete stream's decoded size.
  OutputLimitExceeded(limit~ : UInt64, observed~ : UInt64)
  /// The caller's cancellation callback returned true.
  Cancelled
  /// A caller-supplied output ceiling is negative.
  InvalidArgument
} derive(Eq, @debug.Debug)

///|
/// Structured zlib decoding failure: a stable category plus a human-readable
/// diagnostic.
pub suberror ZlibError {
  ZlibError(ZlibErrorKind, String)
}

///|
fn u32_be(data : BytesView, off : Int32) -> UInt32 {
  (data[off].to_uint() << 24) |
  (data[off + 1].to_uint() << 16) |
  (data[off + 2].to_uint() << 8) |
  data[off + 3].to_uint()
}

///|
fn check_cancelled(cancelled : (() -> Bool)?) -> Unit raise ZlibError {
  if cancelled is Some(callback) && callback() {
    raise ZlibError(Cancelled, "zlib: cancelled by caller")
  }
}

///|
/// Keep the trailer checksum interruptible after decoding has completed.
fn adler32_cancellable(
  input : BytesView,
  cancelled : (() -> Bool)?,
) -> UInt32 raise ZlibError {
  guard cancelled is Some(_) else { return @checksum.adler32(input) }
  let adler = @checksum.Adler32()
  let mut start = 0
  while start < input.length() {
    check_cancelled(cancelled)
    let end = start + (input.length() - start).min(4096)
    adler.update(input[start:end])
    start = end
  }
  check_cancelled(cancelled)
  adler.finish()
}

///|
/// Wrap a raw DEFLATE stream `deflated` of `input` in the zlib header/trailer.
fn zlib_frame(input : BytesView, deflated : Bytes) -> Bytes {
  let out = @buffer.Buffer()
  // CMF=0x78 (CM=8 deflate, CINFO=7 -> 32K window); FLG=0x01 makes the
  // 16-bit header a multiple of 31 with FLEVEL=0 and no preset dictionary.
  out.write_byte(b'\x78')
  out.write_byte(b'\x01')
  out.write_bytes(deflated)
  let adler = @checksum.adler32(input)
  out.write_uint_be(adler)
  out.to_bytes()
}

///|
/// Compress `input` into the zlib format. `level` 0-9 (clamped) trades speed
/// for ratio; 0 = stored only, 6 = default.
/// Optional `fast_store` is off by default; sampled inputs may use stored
/// DEFLATE blocks, sacrificing compression ratio for speed.
pub fn compress(
  input : BytesView,
  level~ : Int32 = 6,
  fast_store~ : Bool = false,
) -> Bytes {
  zlib_frame(input, @flate.deflate_all(input, level~, fast_store~))
}

///|
/// Compress `input` into the zlib format with zopfli-style optimal parsing
/// over the complete input. `iterations` controls the parsing effort
/// per block and defaults to 15. Compression ratio depends on the input.
/// Optional `fast_store` is off by default; sampled inputs may use stored
/// DEFLATE blocks, sacrificing compression ratio for speed.
pub fn compress_optimal(
  input : BytesView,
  iterations~ : Int32 = 15,
  fast_store~ : Bool = false,
) -> Bytes {
  zlib_frame(input, @flate.deflate_all_optimal(input, iterations~, fast_store~))
}

///|
/// Decode zlib data and verify its Adler-32 trailer. `max_output` caps decoded
/// bytes (default: `Bytes` capacity); exceeding it raises `OutputLimitExceeded`,
/// a negative value `InvalidArgument`. `cancelled` is polled at entry, every
/// 8 KiB decoded and every 4 KiB checksummed; true raises `Cancelled`.
pub fn decompress(
  input : BytesView,
  max_output? : Int32,
  cancelled? : () -> Bool,
) -> Bytes raise ZlibError {
  if max_output is Some(limit) && limit < 0 {
    raise ZlibError(InvalidArgument, "max_output must be non-negative")
  }
  check_cancelled(cancelled)
  let n = input.length()
  guard n >= 6 else { raise ZlibError(Truncated, "zlib: input too short") }
  let cmf = input[0].to_int()
  let flg = input[1].to_int()
  guard (cmf & 0x0F) == 8 else {
    raise ZlibError(InvalidHeader, "zlib: unsupported compression method")
  }
  guard cmf >> 4 <= 7 else {
    raise ZlibError(InvalidHeader, "zlib: invalid window size")
  }
  guard (cmf * 256 + flg) % 31 == 0 else {
    raise ZlibError(InvalidHeader, "zlib: bad header check")
  }
  guard (flg & 0x20) == 0 else {
    raise ZlibError(
      DictionaryRequired,
      "zlib: preset dictionary required (use the streaming Decoder)",
    )
  }
  let out = @flate.inflate_exact(input[2:n - 4], max_output?, cancelled?) catch {
    InflateError(Truncated, _) =>
      raise ZlibError(Truncated, "zlib: truncated DEFLATE stream")
    InflateError(TrailingData, _) =>
      raise ZlibError(
        TrailingData,
        "zlib: data between DEFLATE stream and trailer",
      )
    InflateError(OutputLimitExceeded(limit~, observed~), message) =>
      raise ZlibError(OutputLimitExceeded(limit~, observed~), message)
    InflateError(Cancelled, message) => raise ZlibError(Cancelled, message)
    InflateError(InvalidArgument, message) =>
      raise ZlibError(InvalidArgument, message)
    InflateError(_, message) => raise ZlibError(InvalidDeflate, message)
  }
  guard adler32_cancellable(out, cancelled) == u32_be(input, n - 4) else {
    raise ZlibError(ChecksumMismatch, "zlib: Adler-32 mismatch")
  }
  out
}
