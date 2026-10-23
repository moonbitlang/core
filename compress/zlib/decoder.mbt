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
#cfg(any(target="native", target="wasm"))
const CHECKSUM_BUFFER_SIZE : Int32 = 4096

///|
#cfg(not(any(target="native", target="wasm")))
const CHECKSUM_BUFFER_SIZE : Int32 = 0

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
  checksum_buffer : FixedArray[Byte] // owned batch storage; empty on direct-view backends
  mut checksum_pending : Int32
  mut pending : BytesView
  mut pending_pos : Int32
  mut borrowed_input : Bool
  mut unused : Bytes // cached read-ahead suffix after successful completion
  mut ending : Bool // Final input stays latched across output suspension
  mut mode : DecMode
  dict : BytesView? // preset dictionary, if the caller has one
  mut failure_kind : ZlibErrorKind? // stable first terminal error
  mut failure_message : String
}

///|
/// Create a fresh zlib decompressor. Supply `dictionary` when the stream was
/// compressed with a preset dictionary : the header's DICTID
/// is verified against it before use.
pub fn Decoder::Decoder(dictionary? : BytesView) -> Decoder {
  {
    inf: Inflater(),
    adler: Adler32(),
    checksum_buffer: FixedArray::make(CHECKSUM_BUFFER_SIZE, b'\x00'),
    checksum_pending: 0,
    pending: b"",
    pending_pos: 0,
    borrowed_input: false,
    unused: b"",
    ending: false,
    mode: ZHeader,
    dict: dictionary,
    failure_kind: None,
    failure_message: "",
  }
}

///|
/// Whether the whole zlib stream has been decoded and its trailer verified.
pub fn Decoder::is_finished(self : Decoder) -> Bool {
  self.mode is ZFinished
}

///|
/// Bytes accepted by `step` beyond the end of the completed zlib stream.
///
/// A buffered sync reader or async transport commonly delivers the zlib
/// trailer and bytes from the next protocol frame in one read. After `Done`,
/// this method returns the accepted read-ahead suffix. Any unaccepted suffix
/// remains with the caller, as reported by `result.consumed`. It is empty before completion and when no suffix was buffered.
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
  self.flush_output_checksum()
  guard self.adler.finish() == self.u32_be(0) else {
    raise ZlibError(ChecksumMismatch, "zlib: Adler-32 mismatch")
  }
  self.advance(4)
  self.finish_stream()
  false
}

///|
/// Copy output into owned batches on native/linear Wasm. Other backends
/// checksum the view directly. No caller-owned view survives this call.
fn Decoder::update_output_checksum(
  decoder : Decoder,
  data : ArrayView[Byte],
) -> Unit {
  let capacity = decoder.checksum_buffer.length()
  guard capacity > 0 else {
    decoder.adler.update_array(data)
    return
  }
  let mut position = 0
  while position < data.length() {
    let count = (data.length() - position).min(
      capacity - decoder.checksum_pending,
    )
    decoder.checksum_buffer
    .mut_view()
    .blit_from_array(
      data[position:position + count],
      dst_offset=decoder.checksum_pending,
    )
    position += count
    decoder.checksum_pending += count
    if decoder.checksum_pending == capacity {
      decoder.flush_output_checksum()
    }
  }
}

///|
/// Fold the final partial batch before comparing a stream/member trailer.
fn Decoder::flush_output_checksum(decoder : Decoder) -> Unit {
  guard decoder.checksum_pending > 0 else { return }
  // The alias is read synchronously; only owned batch storage is exposed.
  decoder.adler.update(
    decoder.checksum_buffer.unsafe_reinterpret_as_bytes()[:decoder.checksum_pending],
  )
  decoder.checksum_pending = 0
}

///|
/// Run one decompression step. Buffers a bounded prefix of `input`, then decodes
/// plaintext into `output`. Returns `StepResult` with this call's status,
/// consumed and produced byte counts; drop only `input[:result.consumed]`. Pending body input is drained before accepting
/// more; output backpressure may leave a suffix unaccepted. Input is borrowed
/// only during this call, and any retained suffix is copied.
/// Use `finish` for the physical final input view. It turns incomplete
/// headers, DEFLATE bodies, and trailers into `ZlibError` instead of requesting
/// more input. If the final accepted view also contains bytes after
/// the zlib trailer, retrieve that read-ahead with `unused_input()`. On failure,
/// the decoder locks the first `ZlibError` kind/message and rethrows it on every
/// later call. A failing call returns no result; its output buffer may already
/// contain partial output.
pub fn Decoder::step(
  self : Decoder,
  input : BytesView,
  output : MutArrayView[Byte],
) -> @flate.StepResult raise ZlibError {
  self.step_output(input, output, end=false)
}

///|
/// Decode the final input chunk and declare the end of input. Pass an empty
/// input if the final chunk has already been supplied through `step`.
/// Returns `StepResult` with this call's status and consumed/produced counts.
/// If output backpressure leaves part of `input` unconsumed, call `finish`
/// again with that suffix and fresh output space. Once the final chunk has
/// been accepted, the end signal remains latched while output is drained.
/// An incomplete stream raises `ZlibError` instead of requesting more input.
/// Errors remain latched as with `step`; `Done` remains terminal.
pub fn Decoder::finish(
  self : Decoder,
  input : BytesView,
  output : MutArrayView[Byte],
) -> @flate.StepResult raise ZlibError {
  self.step_output(input, output, end=true)
}

///|
fn Decoder::step_output(
  self : Decoder,
  input : BytesView,
  output : MutArrayView[Byte],
  end~ : Bool,
) -> @flate.StepResult raise ZlibError {
  if self.failure_kind is Some(kind) {
    raise ZlibError(kind, self.failure_message)
  }
  let result = self.step_active(input, output, end~) catch {
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
fn Decoder::step_active(
  self : Decoder,
  input : BytesView,
  output : MutArrayView[Byte],
  end~ : Bool,
) -> @flate.StepResult raise ZlibError {
  // A terminal decoder must not claim input that it can no longer decode.
  if self.mode is ZFinished {
    return { status: Done, consumed: 0, produced: 0, }
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
          return { status: NeedMoreInput, consumed, produced: op, }
        }
      }
      ZBody => {
        let op_before = op
        let st_result = self.inf.step(
          self.pending_view(),
          output.mut_view(start=op),
        ) catch {
          InflateError(_, message) =>
            raise ZlibError(
              InvalidDeflate,
              "zlib: invalid DEFLATE stream: \{message}",
            )
        }
        let st = st_result.status
        let used = st_result.consumed
        let produced = st_result.produced
        if produced > 0 {
          self.update_output_checksum(output[op_before:op_before + produced])
        }
        op = op + produced
        self.advance(used)
        if st is NeedMoreInput && !admitted {
          continue
        }
        guard self.after_inflate_step(st) is Some(status) else { continue }
        return { status, consumed, produced: op, }
      }
      ZTrailer => {
        guard !self.read_ztrailer() else {
          return { status: NeedMoreInput, consumed, produced: op, }
        }
      }
      ZFinished => return { status: Done, consumed, produced: op, }
    }
  }
}

///|
// BytesView::to_owned can share a full backing buffer. Retained input must be
// independent even when the caller lends an entire reusable I/O buffer.
fn copy_input(input : BytesView) -> Bytes {
  guard input.length() != 0 else { return b"" }
  let copy = FixedArray::make(input.length(), b'\x00')
  copy.blit_from_bytes(0, input.data(), input.start_offset(), input.length())
  copy.unsafe_reinterpret_as_bytes()
}
