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
#cfg(any(target="native", target="wasm"))
const CHECKSUM_BUFFER_SIZE : Int32 = 4096

///|
#cfg(not(any(target="native", target="wasm")))
const CHECKSUM_BUFFER_SIZE : Int32 = 0

// Streaming gzip (RFC 1952) decompressor: a push-based, suspendable state
// machine wrapping the `@flate.IncrementalDecoder`. The variable-length header is parsed
// with one state per field: FEXTRA, FNAME and FCOMMENT bytes are discarded
// as they are consumed,
// so header-phase memory is O(1) even against an adversarial unterminated
// FNAME. It then drives the inflater over the DEFLATE body (folding
// decompressed output into a running CRC-32 and length) and verifies the
// 8-byte trailer. The one-shot `decompress` remains for in-memory use.

///|
priv enum DecMode {
  GzHeader // the fixed 10-byte header (magic, method, FLG, MTIME, XFL, OS)
  GzExtraLen // the 2-byte XLEN of FEXTRA
  GzExtra(Int32) // discarding the FEXTRA payload; bytes still to skip
  GzName // discarding the NUL-terminated FNAME
  GzComment // discarding the NUL-terminated FCOMMENT
  GzHcrc // verify the low sixteen bits of the header CRC-32
  GzBody // inflating the DEFLATE stream
  GzTrailer // reading + verifying the CRC-32 / ISIZE trailer
  GzFinished
}

///|
/// Streaming gzip decompressor (RFC 1952). Feed compressed input and drain
/// plaintext with `step`; it verifies the CRC-32 and length trailer. Binds no
/// I/O trait.
struct Decoder {
  inf : @flate.IncrementalDecoder
  mut crc : @checksum.Crc32 // of the current member's decompressed output
  checksum_buffer : FixedArray[Byte] // owned batch storage; empty on direct-view backends
  mut checksum_pending : Int32
  mut header_crc : @checksum.Crc32
  mut osize : UInt32 // current member's decompressed length, mod 2^32
  mut pending : BytesView // incomplete fixed-size field, at most 10 bytes
  mut borrowed_input : Bool // only borrowed during the active step
  mut flg : Int32 // header FLG byte, gates the optional-field states
  mut ending : Bool // Final input stays latched across output suspension
  mut mode : DecMode
  mut failure_kind : GzipErrorKind? // stable first terminal error
  mut failure_message : String
}

///|
/// Create a fresh single-member gzip decompressor. `step` never consumes bytes
/// beyond that member's trailer. Decode an RFC 1952 multi-member stream by
/// calling `reset` only when another member is available, then re-presenting
/// the unconsumed suffix. If `Done` leaves no suffix, read first: EOF completes
/// the sequence without a reset; non-empty input can begin the next member.
pub fn Decoder::Decoder() -> Decoder {
  {
    inf: IncrementalDecoder(),
    crc: Crc32(),
    checksum_buffer: FixedArray::make(CHECKSUM_BUFFER_SIZE, b'\x00'),
    checksum_pending: 0,
    header_crc: Crc32(),
    osize: 0,
    pending: b"",
    borrowed_input: false,
    flg: 0,
    ending: false,
    mode: GzHeader,
    failure_kind: None,
    failure_message: "",
  }
}

///|
/// Start a fresh gzip member while preserving and reusing internal allocations,
/// including the inflater's history window and Huffman tables. This also clears
/// a completed, incomplete, or failed state.
pub fn Decoder::reset(self : Decoder) -> Unit {
  self.inf.reset()
  self.crc = Crc32()
  self.checksum_pending = 0
  self.header_crc = Crc32()
  self.osize = 0
  self.pending = b""
  self.borrowed_input = false
  self.flg = 0
  self.ending = false
  self.mode = GzHeader
  self.failure_kind = None
  self.failure_message = ""
}

///|
/// Whether the current gzip member has been decoded and its trailer verified.
pub fn Decoder::is_finished(self : Decoder) -> Bool {
  self.mode is GzFinished
}

///|
/// Number of unread buffered bytes.
fn Decoder::available(self : Decoder) -> Int32 {
  self.pending.length()
}

///|
/// Enter the successful terminal state. Precise consumption leaves transport
/// bytes beyond the gzip boundary with the caller.
fn Decoder::finish_stream(self : Decoder) -> Unit {
  guard! self.available() == 0
  self.pending = b""
  self.borrowed_input = false
  self.mode = GzFinished
}

///|
/// Read an unread buffered byte at a relative offset.
fn Decoder::pending_at(self : Decoder, off : Int32) -> Byte {
  self.pending[off]
}

///|
// Borrow only when no older input must be joined. Residual input is owned
// before the public step returns, so a small suffix never retains a caller's
// arbitrarily large backing allocation between calls.
fn Decoder::buffer_input(self : Decoder, input : BytesView) -> Unit {
  guard input.length() != 0 else { return }
  if self.available() == 0 {
    self.pending = input
    self.borrowed_input = true
  } else {
    self.pending = Bytes::from_iter(self.pending.iter().concat(input.iter()))
    self.borrowed_input = false
  }
}

///|
/// Admit at most enough caller input to make `required` bytes pending.
/// Returns the exact number admitted from `input[start:end]`.
fn Decoder::fill_pending(
  self : Decoder,
  input : BytesView,
  start : Int32,
  end : Int32,
  required : Int32,
) -> Int32 {
  let take = (required - self.available()).min(end - start)
  guard take > 0 else { return 0 }
  self.buffer_input(input[start:start + take])
  take
}

///|
fn Decoder::detach_input(self : Decoder) -> Unit {
  guard self.borrowed_input else { return }
  self.pending = copy_input(self.pending)
  self.borrowed_input = false
}

///|
fn Decoder::advance(self : Decoder, k : Int32) -> Unit {
  guard k > 0 else { return }
  guard! k == self.pending.length()
  self.pending = b""
  self.borrowed_input = false
}

///|
/// The header state that follows field group `done` (0 = fixed header,
/// 1 = FEXTRA, 2 = FNAME, 3 = FCOMMENT), gated by the FLG bits.
fn Decoder::next_header_mode(self : Decoder, done : Int32) -> DecMode {
  if done < 1 && (self.flg & 4) != 0 {
    GzExtraLen
  } else if done < 2 && (self.flg & 8) != 0 {
    GzName
  } else if done < 3 && (self.flg & 16) != 0 {
    GzComment
  } else if done < 4 && (self.flg & 2) != 0 {
    GzHcrc
  } else {
    GzBody
  }
}

///|
/// Parse a complete fixed 10-byte header.
fn Decoder::finish_gzheader(self : Decoder) -> Unit raise GzipError {
  guard! self.available() >= 10
  guard self.pending_at(0).to_int() == 0x1F &&
    self.pending_at(1).to_int() == 0x8B else {
    raise GzipError(InvalidHeader, "gzip: bad magic")
  }
  guard self.pending_at(2).to_int() == 0x08 else {
    raise GzipError(InvalidHeader, "gzip: unsupported compression method")
  }
  self.flg = self.pending_at(3).to_int()
  guard (self.flg & 0xE0) == 0 else {
    raise GzipError(InvalidHeader, "gzip: reserved flags are set")
  }
  self.advance_header(10)
  self.mode = self.next_header_mode(0)
}

///|
/// React to the inner inflater's status after one `GzBody` step.
/// Return `None` to continue or the status to suspend with.
fn Decoder::after_body_step(
  self : Decoder,
  st : @flate.Status,
) -> @flate.Status? raise GzipError {
  match st {
    Done => {
      self.mode = GzTrailer
      None
    }
    NeedMoreInput => {
      guard !self.ending else { raise GzipError(Truncated, "gzip: truncated") }
      Some(NeedMoreInput)
    }
    NeedMoreOutput => Some(NeedMoreOutput)
  }
}

///|
/// Verify a complete CRC-32/ISIZE trailer and finish the member.
fn Decoder::finish_member_trailer(self : Decoder) -> Unit raise GzipError {
  guard! self.available() >= 8
  self.flush_output_checksum()
  guard self.crc.finish() == self.u32_le(0) else {
    raise GzipError(ChecksumMismatch, "gzip: CRC-32 mismatch")
  }
  guard self.osize == self.u32_le(4) else {
    raise GzipError(LengthMismatch, "gzip: length mismatch")
  }
  self.advance(8)
  self.finish_stream()
}

///|
/// Read a little-endian u32 from `pending` at `off`.
fn Decoder::u32_le(self : Decoder, off : Int32) -> UInt32 {
  self.pending_at(off).to_uint() |
  (self.pending_at(off + 1).to_uint() << 8) |
  (self.pending_at(off + 2).to_uint() << 16) |
  (self.pending_at(off + 3).to_uint() << 24)
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
    decoder.crc.update_array(data)
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
  decoder.crc.update(
    decoder.checksum_buffer.unsafe_reinterpret_as_bytes()[:decoder.checksum_pending],
  )
  decoder.checksum_pending = 0
}

///|
/// Run one decompression step. Decodes plaintext into `output` and returns the
/// exact caller-input prefix committed to gzip parsing. Drop only
/// `input[:result.consumed]` and re-present the suffix. Output backpressure and
/// the member boundary may leave input unconsumed.
/// Small incomplete fixed fields are copied; DEFLATE input is consumed directly.
/// There is no fixed per-call input budget: FNAME and FCOMMENT may scan the
/// complete supplied view for their terminator. Callers requiring bounded
/// per-call latency should pass bounded input slices.
/// If `step` has not returned `Done` once all source input is accepted, call
/// `check_end` to declare EOF. It requests output space or raises a truncation
/// error.
/// Drain pending output through `step` with empty input; EOF stays latched.
/// After EOF or `Done`, later input is not accepted. `Done` marks exactly one
/// gzip member; trailing bytes, including another member, remain in the
/// unconsumed input suffix. Call `reset` to decode that next member while
/// reusing allocations. On failure, the decoder locks the first `GzipError`
/// kind/message and rethrows it on every later call until `reset`. A failing
/// call returns no result; its output buffer may already contain partial output.
pub fn Decoder::step(
  self : Decoder,
  input : BytesView,
  output : MutArrayView[Byte],
) -> @flate.StepResult raise GzipError {
  self.step_impl(input, output, end_of_input=false)
}

///|
/// Declare EOF before the current member has completed. `NeedMoreOutput`
/// requires draining with `step`; incomplete input raises `Truncated`.
pub fn Decoder::check_end(self : Decoder) -> @flate.Status raise GzipError {
  self.step_impl(b"", [].mut_view(), end_of_input=true).status
}

///|
fn Decoder::step_impl(
  self : Decoder,
  input : BytesView,
  output : MutArrayView[Byte],
  end_of_input~ : Bool,
) -> @flate.StepResult raise GzipError {
  if self.failure_kind is Some(kind) {
    raise GzipError(kind, self.failure_message)
  }
  defer self.detach_input()
  self.step_active(input, output, end_of_input~) catch {
    GzipError(kind, message) => {
      self.failure_kind = Some(kind)
      self.failure_message = message
      raise GzipError(kind, message)
    }
  }
}

///|
fn Decoder::step_active(
  self : Decoder,
  input : BytesView,
  output : MutArrayView[Byte],
  end_of_input~ : Bool,
) -> @flate.StepResult raise GzipError {
  if self.mode is GzFinished {
    return { status: Done, consumed: 0, produced: 0, }
  }
  if end_of_input {
    self.ending = true
  }
  // Input offered after EOF is deliberately left unconsumed. `check_end`
  // itself always supplies an empty view.
  let input_end = if self.ending { 0 } else { input.length() }
  let mut consumed = 0
  let mut op = 0
  for ;; {
    match self.mode {
      GzHeader => {
        consumed += self.fill_pending(input, consumed, input_end, 10)
        guard self.available() >= 10 else {
          guard !self.ending else {
            raise GzipError(Truncated, "gzip: truncated")
          }
          return { status: NeedMoreInput, consumed, produced: op, }
        }
        self.finish_gzheader()
      }
      GzExtraLen => {
        consumed += self.fill_pending(input, consumed, input_end, 2)
        guard self.available() >= 2 else {
          guard !self.ending else {
            raise GzipError(Truncated, "gzip: truncated")
          }
          return { status: NeedMoreInput, consumed, produced: op, }
        }
        let xlen = self.pending_at(0).to_int() |
          (self.pending_at(1).to_int() << 8)
        self.advance_header(2)
        self.mode = GzExtra(xlen)
      }
      GzExtra(remaining) => {
        let take = remaining.min(input_end - consumed)
        if take > 0 {
          if (self.flg & 2) != 0 {
            self.header_crc.update(input[consumed:consumed + take])
          }
          consumed += take
        }
        guard take == remaining else {
          self.mode = GzExtra(remaining - take)
          guard !self.ending else {
            raise GzipError(Truncated, "gzip: truncated")
          }
          return { status: NeedMoreInput, consumed, produced: op, }
        }
        self.mode = self.next_header_mode(1)
      }
      GzName => {
        let remaining = input[consumed:input_end]
        match remaining.find(b"\x00") {
          Some(nul) => {
            let take = nul + 1
            if (self.flg & 2) != 0 {
              self.header_crc.update(remaining[:take])
            }
            consumed += take
            self.mode = self.next_header_mode(2)
          }
          None => {
            if remaining.length() > 0 && (self.flg & 2) != 0 {
              self.header_crc.update(remaining)
            }
            consumed = input_end
            guard !self.ending else {
              raise GzipError(Truncated, "gzip: truncated")
            }
            return { status: NeedMoreInput, consumed, produced: op, }
          }
        }
      }
      GzComment => {
        let remaining = input[consumed:input_end]
        match remaining.find(b"\x00") {
          Some(nul) => {
            let take = nul + 1
            if (self.flg & 2) != 0 {
              self.header_crc.update(remaining[:take])
            }
            consumed += take
            self.mode = self.next_header_mode(3)
          }
          None => {
            if remaining.length() > 0 && (self.flg & 2) != 0 {
              self.header_crc.update(remaining)
            }
            consumed = input_end
            guard !self.ending else {
              raise GzipError(Truncated, "gzip: truncated")
            }
            return { status: NeedMoreInput, consumed, produced: op, }
          }
        }
      }
      GzHcrc => {
        consumed += self.fill_pending(input, consumed, input_end, 2)
        guard self.available() >= 2 else {
          guard !self.ending else {
            raise GzipError(Truncated, "gzip: truncated")
          }
          return { status: NeedMoreInput, consumed, produced: op, }
        }
        let expected = self.pending_at(0).to_uint() |
          (self.pending_at(1).to_uint() << 8)
        guard (self.header_crc.finish() & 0xffff) == expected else {
          raise GzipError(ChecksumMismatch, "gzip: header CRC-16 mismatch")
        }
        self.advance(2)
        self.mode = GzBody
      }
      GzBody => {
        let op_before = op
        let st_result = self.inf.step(
          input[consumed:input_end],
          output.mut_view(start=op),
        ) catch {
          err => raise wrap_inflate_error(err)
        }
        let st = st_result.status
        let used = st_result.consumed
        let produced = st_result.produced
        if produced > 0 {
          self.update_output_checksum(output[op_before:op_before + produced])
          self.osize = self.osize + produced.reinterpret_as_uint()
        }
        op = op + produced
        consumed += used
        guard self.after_body_step(st) is Some(status) else { continue }
        return { status, consumed, produced: op, }
      }
      GzTrailer => {
        consumed += self.fill_pending(input, consumed, input_end, 8)
        guard self.available() >= 8 else {
          guard !self.ending else {
            raise GzipError(Truncated, "gzip: truncated")
          }
          return { status: NeedMoreInput, consumed, produced: op, }
        }
        self.finish_member_trailer()
      }
      GzFinished => return { status: Done, consumed, produced: op, }
    }
  }
}

///|
/// Consume header bytes while keeping FHCRC independent of the body checksum.
fn Decoder::advance_header(self : Decoder, count : Int32) -> Unit {
  if (self.flg & 2) != 0 {
    for i in 0..<count {
      self.header_crc.update_byte(self.pending_at(i))
    }
  }
  self.advance(count)
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
