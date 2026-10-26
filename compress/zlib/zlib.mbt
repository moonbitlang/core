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
pub using @flate {
  type Strategy,
  type Status,
  type StepResult,
  type DeflateAction,
}

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
fn zlib_frame(
  input : BytesView,
  deflated : Bytes,
  dictionary : BytesView?,
) -> Bytes {
  let out = @buffer.Buffer()
  for byte in zlib_header(dictionary) {
    out.write_byte(byte)
  }
  out.write_bytes(deflated)
  let adler = @checksum.adler32(input)
  out.write_uint_be(adler)
  out.to_bytes()
}

///|
/// Compress a complete zlib stream with the selected DEFLATE strategy.
/// `dictionary` seeds the history; its full Adler-32 is stored as DICTID.
/// `fast_store` may bypass the strategy for sampled inputs, trading ratio for speed.
pub fn compress(
  input : BytesView,
  strategy~ : @flate.Strategy = Standard(level=6),
  dictionary? : BytesView,
  fast_store~ : Bool = false,
) -> Bytes {
  zlib_frame(
    input,
    @flate.deflate_all(input, strategy~, dictionary?, fast_store~),
    dictionary,
  )
}

///|
/// Decode zlib data and verify its Adler-32 trailer. `max_output` caps decoded
/// bytes (default: `Bytes` capacity); exceeding it raises `OutputLimitExceeded`,
/// a negative value `InvalidArgument`. Supply `dictionary` for an FDICT stream.
/// `cancelled` is polled at entry, every
/// 8 KiB decoded and every 4 KiB checksummed; true raises `Cancelled`.
pub fn decompress(
  input : BytesView,
  dictionary? : BytesView,
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
  let dict = if (flg & 0x20) != 0 {
    guard dictionary is Some(dict) else {
      raise ZlibError(DictionaryRequired, "zlib: preset dictionary required")
    }
    guard n >= 10 else {
      raise ZlibError(Truncated, "zlib: truncated dictionary ID")
    }
    guard adler32_cancellable(dict, cancelled) == u32_be(input, 2) else {
      raise ZlibError(DictionaryMismatch, "zlib: dictionary ID mismatch")
    }
    Some(dict)
  } else {
    None
  }
  let out = match dict {
    None =>
      @flate.inflate_exact(input[2:n - 4], max_output?, cancelled?) catch {
        error => raise wrap_inflate_error(error)
      }
    Some(dictionary) =>
      inflate_dictionary(input[6:n - 4], dictionary, max_output, cancelled)
  }
  guard adler32_cancellable(out, cancelled) == u32_be(input, n - 4) else {
    raise ZlibError(ChecksumMismatch, "zlib: Adler-32 mismatch")
  }
  out
}

///|
/// The dictionary path uses the incremental engine's seeded history.
fn inflate_dictionary(
  input : BytesView,
  dictionary : BytesView,
  max_output : Int32?,
  cancelled : (() -> Bool)?,
) -> Bytes raise ZlibError {
  let decoder = @flate.IncrementalDecoder(dictionary~)
  let scratch = FixedArray::make(8192, b'\x00')
  let output = @buffer.Buffer()
  let limit = max_output.unwrap_or(0x7fff_ffff)
  let mut pos = 0
  for ;; {
    if cancelled is Some(callback) && callback() {
      raise ZlibError(Cancelled, "zlib: cancelled by caller")
    }
    let result = decoder.step(input[pos:], scratch.mut_view()) catch {
      error => raise wrap_inflate_error(error)
    }
    pos += result.consumed
    guard result.produced <= limit - output.length() else {
      raise ZlibError(
        OutputLimitExceeded(
          limit=limit.to_uint64(),
          observed=output.length().to_uint64() + result.produced.to_uint64(),
        ),
        "zlib: decoded output exceeds its byte limit",
      )
    }
    output.write_bytes(Bytes::from_array(scratch[:result.produced]))
    match result.status {
      Done => {
        guard pos == input.length() else {
          raise ZlibError(TrailingData, "zlib: trailing DEFLATE data")
        }
        return output.to_bytes()
      }
      NeedMoreOutput => ()
      NeedMoreInput =>
        raise ZlibError(Truncated, "zlib: truncated DEFLATE data")
    }
  }
}

///|
fn wrap_inflate_error(error : @flate.InflateError) -> ZlibError {
  let InflateError(kind, message) = error
  match kind {
    Truncated => ZlibError(Truncated, "zlib: truncated DEFLATE stream")
    TrailingData =>
      ZlibError(TrailingData, "zlib: data between DEFLATE stream and trailer")
    OutputLimitExceeded(limit~, observed~) =>
      ZlibError(OutputLimitExceeded(limit~, observed~), message)
    Cancelled => ZlibError(Cancelled, message)
    InvalidArgument => ZlibError(InvalidArgument, message)
    _ => ZlibError(InvalidDeflate, message)
  }
}
