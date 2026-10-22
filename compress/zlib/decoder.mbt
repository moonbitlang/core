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
const DECODER_INPUT_LIMIT : Int32 = 65536

///|
priv enum DecMode {
  ZHeader
  ZBody
  ZTrailer
  ZFinished
}

///|
/// Streaming zlib decompressor
struct Decoder {
  inf : @flate.Inflater
  adler : @checksum.Adler32 // of the decompressed output
  mut pending : BytesView
  mut pending_pos : Int32
  mut borrowed_input : Bool
  mut unused : Bytes // cached read-ahead suffix after successful completion
  mut ending : Bool // Final input stays latched across output suspension
  mut mode : DecMode
  dict : BytesView? // preset dictionary, if the caller has one
  mut failure_kind : ZlibErrorKind? // stable first terminal error
  mut failure_message : String
  mut step_consumed : Int32
  mut step_produced : Int32
}

///|
/// Create a fresh zlib decompressor. Supply `dictionary` when the stream was
/// compressed with a preset dictionary : the header's DICTID
/// is verified against it before use.
pub fn Decoder::Decoder(dictionary? : BytesView) -> Decoder {
  {
    inf: Inflater(),
    adler: Adler32(),
    pending: b"",
    pending_pos: 0,
    borrowed_input: false,
    unused: b"",
    ending: false,
    mode: ZHeader,
    dict: dictionary,
    failure_kind: None,
    failure_message: "",
    step_consumed: 0,
    step_produced: 0,
  }
}

///|
/// Whether the whole zlib stream has been decoded and its trailer verified.
pub fn Decoder::is_finished(self : Decoder) -> Bool {
  self.mode is ZFinished
}

///|
/// Number of input bytes accepted by the most recent successful `step` call.
/// It is reset to zero when a call raises `ZlibError`.
pub fn Decoder::last_consumed(self : Decoder) -> Int32 {
  self.step_consumed
}

///|
/// Number of output bytes written by the most recent successful `step` call.
/// It is reset to zero when a call raises `ZlibError`.
pub fn Decoder::last_produced(self : Decoder) -> Int32 {
  self.step_produced
}

///|
/// Bytes accepted by `step` beyond the end of the completed zlib stream.
///
/// A buffered sync reader or async transport commonly delivers the zlib
/// trailer and bytes from the next protocol frame in one read. After `Done`,
/// this method returns the accepted read-ahead suffix. Any unaccepted suffix
/// remains with the caller, as reported by `last_consumed()`. It is empty before completion and when no suffix was buffered.
pub fn Decoder::unused_input(self : Decoder) -> Bytes {
  guard self.mode is ZFinished else { return b"" }
  self.unused
}

///|
/// Number of bytes not yet consumed from `pending`.
fn Decoder::pending_length(self : Decoder) -> Int32 {
  self.pending.length() - self.pending_pos
}

///|
/// Enter the successful terminal state while retaining only transport
/// read-ahead after the Adler-32 trailer has been verified.
fn Decoder::finish_stream(self : Decoder) -> Unit {
  self.unused = copy_input(self.pending[self.pending_pos:])
  self.pending = b""
  self.pending_pos = 0
  self.borrowed_input = false
  self.mode = ZFinished
}

///|
// Borrow only when no older input must be joined. Residual input is owned
// before the public step returns, so a small suffix never retains a caller's
// arbitrarily large backing allocation between calls.
fn Decoder::buffer_input(self : Decoder, input : BytesView) -> Unit {
  guard input.length() != 0 else { return }
  if self.pending_length() == 0 {
    self.pending = input
    self.pending_pos = 0
    self.borrowed_input = true
  } else {
    self.pending = Bytes::from_iter(self.pending.iter().concat(input.iter()))
    self.borrowed_input = false
  }
}

///|
fn Decoder::detach_input(self : Decoder) -> Unit {
  guard self.borrowed_input else { return }
  self.pending = copy_input(self.pending[self.pending_pos:])
  self.pending_pos = 0
  self.borrowed_input = false
}

///|
fn Decoder::compact_for_input(self : Decoder) -> Unit {
  guard self.pending_pos != 0 else { return }
  self.pending = self.pending[self.pending_pos:]
  self.pending_pos = 0
}

///|
fn Decoder::advance(self : Decoder, k : Int32) -> Unit {
  guard k > 0 else { return }
  self.pending_pos = self.pending_pos + k
  guard self.pending_pos < self.pending.length() else {
    self.pending = b""
    self.pending_pos = 0
    self.borrowed_input = false
    return
  }
  let worth_compacting = self.pending_pos >= 4096 &&
    self.pending_pos >= self.pending_length()
  guard worth_compacting else { return }
  self.compact_for_input()
}

///|
fn Decoder::pending_view(self : Decoder) -> BytesView {
  self.pending[self.pending_pos:]
}

///|
/// Read a big-endian u32 from `pending` at `off`.
fn Decoder::u32_be(self : Decoder, off : Int32) -> UInt32 {
  let pos = self.pending_pos + off
  (self.pending[pos].to_uint() << 24) |
  (self.pending[pos + 1].to_uint() << 16) |
  (self.pending[pos + 2].to_uint() << 8) |
  self.pending[pos + 3].to_uint()
}

///|
/// Parse the zlib header (CMF/FLG, FDICT verification) from `pending`,
/// advancing to `ZBody` when the two header bytes and any DICTID are complete.
/// Returns true when the step must suspend for more input.
fn Decoder::read_zheader(self : Decoder) -> Bool raise ZlibError {
  guard self.pending_length() >= 2 else {
    guard !self.ending else {
      raise ZlibError(Truncated, "zlib: truncated header")
    }
    return true
  }
  let cmf = self.pending[self.pending_pos].to_int()
  let flg = self.pending[self.pending_pos + 1].to_int()
  guard (cmf & 0x0F) == 8 else {
    raise ZlibError(InvalidHeader, "zlib: unsupported compression method")
  }
  guard cmf >> 4 <= 7 else {
    raise ZlibError(InvalidHeader, "zlib: invalid window size")
  }
  guard (cmf * 256 + flg) % 31 == 0 else {
    raise ZlibError(InvalidHeader, "zlib: bad header check")
  }
  // FDICT: a 4-byte DICTID follows; verify it against the supplied dictionary
  // and preload the inflater's window.
  guard (flg & 0x20) == 0 else {
    guard self.pending_length() >= 6 else {
      guard !self.ending else {
        raise ZlibError(Truncated, "zlib: truncated dictionary id")
      }
      return true
    }
    let dictid = self.u32_be(2)
    guard self.dict is Some(dict) else {
      raise ZlibError(DictionaryRequired, "zlib: preset dictionary required")
    }
    guard @checksum.adler32(dict) == dictid else {
      raise ZlibError(DictionaryMismatch, "zlib: dictionary id mismatch")
    }
    // Configure the raw inflater only after FDICT and DICTID have been
    // validated. Preloading it in `new` would incorrectly let a stream
    // without FDICT refer to caller-supplied history.
    self.inf.reset(dictionary=dict[:])
    self.advance(6)
    self.mode = ZBody
    return false
  }
  self.advance(2)
  self.mode = ZBody
  false
}

///|
/// React to the raw inflater's status after a body step.
fn Decoder::after_inflate_step(
  self : Decoder,
  st : @flate.Status,
) -> @flate.Status? raise ZlibError {
  match st {
    Done => {
      self.mode = ZTrailer
      None
    }
    NeedMoreInput => {
      guard !self.ending else {
        raise ZlibError(Truncated, "zlib: truncated DEFLATE stream")
      }
      Some(NeedMoreInput)
    }
    NeedMoreOutput => Some(NeedMoreOutput)
  }
}

///|
/// Verify the Adler-32 trailer and enter the terminal state. Returns true when
/// the step must suspend for more input.
fn Decoder::read_ztrailer(self : Decoder) -> Bool raise ZlibError {
  guard self.pending_length() >= 4 else {
    guard !self.ending else {
      raise ZlibError(Truncated, "zlib: truncated trailer")
    }
    return true
  }
  guard self.adler.finish() == self.u32_be(0) else {
    raise ZlibError(ChecksumMismatch, "zlib: Adler-32 mismatch")
  }
  self.advance(4)
  self.finish_stream()
  false
}

///|
/// Run one decompression step. Buffers a bounded prefix of `input`, then decodes
/// plaintext into `output`. Read the accepted and produced counts with
/// `last_consumed()` and `last_produced()`; drop only
/// `input[:last_consumed()]`. Pending body input is drained before accepting
/// more; output backpressure may leave a suffix unaccepted. Input is borrowed
/// only during this call, and any retained suffix is copied.
/// Use `finish` for the physical final input view. It turns incomplete
/// headers, DEFLATE bodies, and trailers into `ZlibError` instead of requesting
/// more input. If the final accepted view also contains bytes after
/// the zlib trailer, retrieve that read-ahead with `unused_input()`. On failure,
/// the decoder locks the first `ZlibError` kind/message and rethrows it on every
/// later call; both progress counters remain zero.
pub fn Decoder::step(
  self : Decoder,
  input : BytesView,
  output : MutArrayView[Byte],
) -> @flate.Status raise ZlibError {
  self.step_output(input, output, None, end=false)
}

///|
/// Decode into a fixed output array, updating the Adler-32 checksum in batches.
/// Consumption, backpressure and EOF semantics match `step`. The output array
/// is borrowed only for this call.
pub fn Decoder::step_into(
  self : Decoder,
  input : BytesView,
  output : FixedArray[Byte],
) -> @flate.Status raise ZlibError {
  self.step_output(input, output.mut_view(), Some(output), end=false)
}

///|
/// Decode the final input chunk and declare the end of input. Pass an empty
/// input if the final chunk has already been supplied through `step`.
/// Read `last_consumed()` and `last_produced()` after each successful call.
/// If output backpressure leaves part of `input` unconsumed, call `finish`
/// again with that suffix and fresh output space. Once the final chunk has
/// been accepted, the end signal remains latched while output is drained.
/// An incomplete stream raises `ZlibError` instead of requesting more input.
/// Errors remain latched as with `step`; `Done` remains terminal.
pub fn Decoder::finish(
  self : Decoder,
  input : BytesView,
  output : MutArrayView[Byte],
) -> @flate.Status raise ZlibError {
  self.step_output(input, output, None, end=true)
}

///|
/// Finish decoding into a complete fixed output array. This has the same
/// final-input, backpressure and error semantics as `finish`, with the
/// fixed-array output path of `step_into`.
pub fn Decoder::finish_into(
  self : Decoder,
  input : BytesView,
  output : FixedArray[Byte],
) -> @flate.Status raise ZlibError {
  self.step_output(input, output.mut_view(), Some(output), end=true)
}

///|
fn Decoder::step_output(
  self : Decoder,
  input : BytesView,
  output : MutArrayView[Byte],
  fixed_output : FixedArray[Byte]?,
  end~ : Bool,
) -> @flate.Status raise ZlibError {
  self.step_consumed = 0
  self.step_produced = 0
  if self.failure_kind is Some(kind) {
    raise ZlibError(kind, self.failure_message)
  }
  let result = self.step_active(input, output, fixed_output, end~) catch {
    ZlibError(kind, message) => {
      self.detach_input()
      self.failure_kind = Some(kind)
      self.failure_message = message
      raise ZlibError(kind, message)
    }
  }
  self.detach_input()
  result
}

///|
fn Decoder::finish_step(
  self : Decoder,
  status : @flate.Status,
  consumed : Int32,
  produced : Int32,
) -> @flate.Status {
  self.step_consumed = consumed
  self.step_produced = produced
  status
}

///|
fn Decoder::step_active(
  self : Decoder,
  input : BytesView,
  output : MutArrayView[Byte],
  fixed_output : FixedArray[Byte]?,
  end~ : Bool,
) -> @flate.Status raise ZlibError {
  // A terminal decoder must not claim input that it can no longer decode.
  if self.mode is ZFinished {
    return self.finish_step(Done, 0, 0)
  }
  let mut consumed = 0
  let mut admitted = false
  let mut op = 0
  for ;; {
    // Drain already accepted body input before admitting a fresh chunk. Once
    // it is exhausted, accept and process the offered chunk in this same call.
    if !admitted &&
      (
        !(self.mode is ZBody) ||
        self.pending_length() == 0 ||
        input.length() == 0
      ) {
      if !self.ending && self.pending.length() >= DECODER_INPUT_LIMIT {
        self.compact_for_input()
      }
      let capacity = DECODER_INPUT_LIMIT - self.pending.length()
      consumed = if self.ending || capacity <= 0 {
        0
      } else {
        input.length().min(capacity)
      }
      if consumed > 0 {
        self.buffer_input(input[:consumed])
      }
      if end && consumed == input.length() {
        self.ending = true
      }
      admitted = true
    }
    match self.mode {
      ZHeader => {
        guard !self.read_zheader() else {
          return self.finish_step(NeedMoreInput, consumed, op)
        }
      }
      ZBody => {
        let op_before = op
        // A fixed array that is still empty goes to the inflater as it is,
        // for its bulk window copies; a view (or a later part of the array,
        // which `step_into` cannot address) takes the per-byte writes.
        let st = try {
          if fixed_output is Some(fixed) && op == 0 {
            self.inf.step_into(self.pending_view(), fixed)
          } else {
            self.inf.step(self.pending_view(), output.mut_view(start=op))
          }
        } catch {
          InflateError(_, message) =>
            raise ZlibError(
              InvalidDeflate,
              "zlib: invalid DEFLATE stream: \{message}",
            )
        }
        let used = self.inf.last_consumed()
        let produced = self.inf.last_produced()
        if produced > 0 {
          if fixed_output is Some(fixed) {
            let bytes = unsafe_bytes_of_array(fixed)
            self.adler.update(bytes[op_before:op_before + produced])
          } else {
            self.checksum_view(output, op_before, produced)
          }
        }
        op = op + produced
        self.advance(used)
        if st is NeedMoreInput && !admitted {
          continue
        }
        guard self.after_inflate_step(st) is Some(status) else { continue }
        return self.finish_step(status, consumed, op)
      }
      ZTrailer => {
        guard !self.read_ztrailer() else {
          return self.finish_step(NeedMoreInput, consumed, op)
        }
      }
      ZFinished => return self.finish_step(Done, consumed, op)
    }
  }
}

///|
/// Bytes of a mutable view that are checksummed per batch.
const CHECKSUM_VIEW_CHUNK : Int32 = 4096

///|
/// Fold `output[start:start + length)` into the Adler-32. Core has no bulk
/// read of a mutable view, so the bytes are gathered into a scratch chunk and
/// folded a chunk at a time instead of one `update_byte` (two divisions for
/// Adler-32, a table step for CRC-32) per byte.
fn Decoder::checksum_view(
  self : Decoder,
  output : MutArrayView[Byte],
  start : Int32,
  length : Int32,
) -> Unit {
  guard start >= 0 && length > 0 && length <= output.length() - start else {
    return
  }
  let chunk = FixedArray::make(length.min(CHECKSUM_VIEW_CHUNK), b'\x00')
  let bytes = unsafe_bytes_of_array(chunk)
  let mut done = 0
  while done < length {
    let count = (length - done).min(chunk.length())
    // SAFETY: `done + count <= length` and the guard above keeps
    // `start + length` within the view; `count <= chunk.length()`.
    for i in 0..<count {
      chunk.unsafe_set(i, output.unsafe_get(start + done + i))
    }
    self.adler.update(bytes[:count])
    done = done + count
  }
}

///|
// Callers either transfer a fresh array or borrow the alias synchronously for
// checksum calculation, before the output array can be written again.
fn unsafe_bytes_of_array(output : FixedArray[Byte]) -> Bytes = "%identity"

///|
// BytesView::to_owned can share a full backing buffer. Retained input must be
// independent even when the caller lends an entire reusable I/O buffer.
fn copy_input(input : BytesView) -> Bytes {
  guard input.length() != 0 else { return b"" }
  let copy = FixedArray::make(input.length(), b'\x00')
  copy.blit_from_bytes(0, input.data(), input.start_offset(), input.length())
  unsafe_bytes_of_array(copy)
}
