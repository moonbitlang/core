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

// Streaming gzip (RFC 1952) decompressor: a push-based, suspendable state
// machine wrapping the `@flate.Inflater`. The variable-length header is parsed
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
  inf : @flate.Inflater
  mut crc : @checksum.Crc32 // of the current member's decompressed output
  checksum_buffer : FixedArray[Byte] // owned batch storage; empty on direct-view backends
  mut checksum_pending : Int32
  mut header_crc : @checksum.Crc32
  mut osize : UInt32 // current member's decompressed length, mod 2^32
  mut pending : BytesView // unconsumed compressed input
  mut pending_pos : Int32 // first unread byte in `pending`
  mut borrowed_input : Bool // only borrowed during the active step
  mut unused : Bytes // cached read-ahead suffix after successful completion
  mut flg : Int32 // header FLG byte, gates the optional-field states
  mut members : Int32 // fully verified members
  mut ending : Bool // Final input stays latched across output suspension
  multistream : Bool // decode RFC 1952 concatenated members when true
  mut mode : DecMode
  mut failure_kind : GzipErrorKind? // stable first terminal error
  mut failure_message : String
}

///|
/// Create a fresh gzip decompressor. With the default `multistream=true`,
/// adjacent RFC 1952 members are decoded as one logical stream. Set it to
/// false for a framed transport that must stop after the first member and
/// recover accepted read-ahead through `unused_input()`. Unaccepted bytes
/// remain with the caller, as reported by `result.consumed`.
pub fn Decoder::Decoder(multistream~ : Bool = true) -> Decoder {
  {
    inf: Inflater(),
    crc: Crc32(),
    checksum_buffer: FixedArray::make(CHECKSUM_BUFFER_SIZE, b'\x00'),
    checksum_pending: 0,
    header_crc: Crc32(),
    osize: 0,
    pending: b"",
    pending_pos: 0,
    borrowed_input: false,
    unused: b"",
    flg: 0,
    members: 0,
    ending: false,
    multistream,
    mode: GzHeader,
    failure_kind: None,
    failure_message: "",
  }
}

///|
/// Whether the whole gzip stream has been decoded and its trailer verified.
pub fn Decoder::is_finished(self : Decoder) -> Bool {
  self.mode is GzFinished
}

///|
/// Bytes accepted by `step` beyond the final completed gzip member.
///
/// A buffered sync reader or async transport can deliver a member trailer and
/// bytes from the next protocol frame in one read. Once `Done` is reached,
/// this method returns that read-ahead suffix. It is empty before completion
/// and when the gzip stream ended exactly at the input boundary.
pub fn Decoder::unused_input(self : Decoder) -> Bytes {
  guard self.mode is GzFinished else { return b"" }
  self.unused
}

///|
/// Number of unread buffered bytes.
fn Decoder::available(self : Decoder) -> Int32 {
  self.pending.length() - self.pending_pos
}

///|
/// Enter the successful terminal state, retaining only transport read-ahead.
fn Decoder::finish_stream(self : Decoder) -> Unit {
  self.unused = copy_input(self.pending[self.pending_pos:])
  self.pending = b""
  self.pending_pos = 0
  self.borrowed_input = false
  self.mode = GzFinished
}

///|
/// Read an unread buffered byte at a relative offset.
fn Decoder::pending_at(self : Decoder, off : Int32) -> Byte {
  self.pending[self.pending_pos + off]
}

///|
// Borrow only when no older input must be joined. Residual input is owned
// before the public step returns, so a small suffix never retains a caller's
// arbitrarily large backing allocation between calls.
fn Decoder::buffer_input(self : Decoder, input : BytesView) -> Unit {
  guard input.length() != 0 else { return }
  if self.available() == 0 {
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
    self.pending_pos >= self.available()
  guard worth_compacting else { return }
  self.compact_for_input()
}

///|
fn Decoder::pending_view(self : Decoder) -> BytesView {
  self.pending[self.pending_pos:]
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
/// Parse the fixed 10-byte header (magic, method, FLG, reserved flags) — and,
/// for a concatenated stream, the member boundary before it. Returns true when
/// the step must suspend for more input.
fn Decoder::read_gzheader(self : Decoder) -> Bool raise GzipError {
  let available = self.available()
  if self.members > 0 {
    guard available != 0 else {
      guard !self.ending else {
        self.finish_stream()
        return false
      }
      return true
    }
    guard self.pending_at(0).to_int() == 0x1F else {
      // A non-member byte ends the concatenated gzip stream. Preserve it and
      // the rest of the transport read for the caller.
      self.finish_stream()
      return false
    }
    guard available >= 2 else {
      guard !self.ending else { raise GzipError(Truncated, "gzip: truncated") }
      return true
    }
    guard self.pending_at(1).to_int() == 0x8B else {
      self.finish_stream()
      return false
    }
  }
  guard available >= 10 else {
    guard !self.ending else { raise GzipError(Truncated, "gzip: truncated") }
    return true
  }
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
  false
}

///|
/// Discard the NUL-terminated field at the head of `pending`, advancing to the
/// next header mode on completion. Returns true when the step must suspend for
/// more input.
fn Decoder::skip_nul_field(
  self : Decoder,
  done : Int32,
) -> Bool raise GzipError {
  guard self.skip_nul_terminated() else {
    guard !self.ending else { raise GzipError(Truncated, "gzip: truncated") }
    return true
  }
  self.mode = self.next_header_mode(done)
  false
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
/// Verify the CRC-32/ISIZE trailer of a completed member and cross the member
/// boundary (reset per-member state, then next member or terminal state).
/// Returns true when the step must suspend for more input.
fn Decoder::finish_member_trailer(self : Decoder) -> Bool raise GzipError {
  guard self.available() >= 8 else {
    guard !self.ending else { raise GzipError(Truncated, "gzip: truncated") }
    return true
  }
  self.flush_output_checksum()
  guard self.crc.finish() == self.u32_le(0) else {
    raise GzipError(ChecksumMismatch, "gzip: CRC-32 mismatch")
  }
  guard self.osize == self.u32_le(4) else {
    raise GzipError(LengthMismatch, "gzip: length mismatch")
  }
  self.advance(8)
  // Member boundary. Reset the per-member state; the next member, if any,
  // starts fresh (RFC 1952 §2.2 — members are independent, no cross-member
  // back-references).
  self.inf.reset()
  self.crc = Crc32()
  self.osize = 0
  self.header_crc = Crc32()
  self.flg = 0
  self.members = self.members + 1
  guard self.multistream else {
    // A protocol-framed caller chose one-member mode. The trailer is the
    // exact boundary, even if the next frame itself begins with the gzip
    // magic bytes.
    self.finish_stream()
    return false
  }
  guard self.available() == 0 else {
    // Buffered bytes begin the next member; parse it now.
    self.mode = GzHeader
    return false
  }
  guard !self.ending else {
    // The caller has signalled end-of-input at a clean boundary: done.
    self.finish_stream()
    return false
  }
  // No more buffered, but the caller has not signalled end: another member
  // may still arrive. Wait in GzHeader for it (or for `end`).
  self.mode = GzHeader
  true
}

///|
/// Drop pending bytes up to and including the NUL that ends the current
/// header field, or discard everything seen so far (these fields have no
/// length bound, so they are never retained). Returns true when the field is
/// complete.
fn Decoder::skip_nul_terminated(self : Decoder) -> Bool {
  guard self.pending[self.pending_pos:].find(b"\x00") is Some(nul) else {
    self.advance_header(self.available())
    return false
  }
  self.advance_header(nul + 1)
  true
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
/// Run one decompression step. Accepts a bounded prefix of `input`, then decodes
/// plaintext into `output`. Returns `StepResult` with this call's status,
/// consumed and produced byte counts; drop only `input[:result.consumed]` and re-present a suffix that was held back by
/// output backpressure. Pending body input is drained before accepting more,
/// so a call can produce output without consuming new input.
/// Input is borrowed only for this call; any retained suffix is copied.
/// Use `finish` for the physical final input view. Once that complete view
/// has been accepted (or after `Done`), later input is not accepted and
/// `result.consumed` is zero. Keep draining until `Done`. gzip members are
/// self-delimiting but a multi-member stream needs `finish` to establish
/// that no further member will follow.
/// Concatenated multi-member streams (RFC 1952 §2.2) decode in full; their
/// payloads are joined. If the final accepted view also contains non-gzip
/// bytes, retrieve that read-ahead after `Done` with `unused_input()`. On
/// failure, the decoder locks the first `GzipError` kind/message and rethrows
/// it on every later call. A failing call returns no result; its output buffer
/// may already contain partial output.
pub fn Decoder::step(
  self : Decoder,
  input : BytesView,
  output : MutArrayView[Byte],
) -> @flate.StepResult raise GzipError {
  self.step_output(input, output, end=false)
}

///|
/// Decode the final input chunk and declare the end of input. Pass an empty
/// input if the final chunk has already been supplied through `step`.
/// Returns `StepResult` with this call's status and consumed/produced counts.
/// If output backpressure leaves part of `input` unconsumed, call `finish`
/// again with that suffix and fresh output space. Once the final chunk has
/// been accepted, the end signal remains latched while output is drained.
/// An incomplete stream raises `GzipError` instead of requesting more input.
/// Errors remain latched as with `step`; `Done` remains terminal.
pub fn Decoder::finish(
  self : Decoder,
  input : BytesView,
  output : MutArrayView[Byte],
) -> @flate.StepResult raise GzipError {
  self.step_output(input, output, end=true)
}

///|
fn Decoder::step_output(
  self : Decoder,
  input : BytesView,
  output : MutArrayView[Byte],
  end~ : Bool,
) -> @flate.StepResult raise GzipError {
  if self.failure_kind is Some(kind) {
    raise GzipError(kind, self.failure_message)
  }
  let result = self.step_active(input, output, end~) catch {
    GzipError(kind, message) => {
      self.detach_input()
      self.failure_kind = Some(kind)
      self.failure_message = message
      raise GzipError(kind, message)
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
) -> @flate.StepResult raise GzipError {
  if self.mode is GzFinished {
    return { status: Done, consumed: 0, produced: 0, }
  }
  let mut consumed = 0
  let mut admitted = false
  let mut op = 0
  for ;; {
    // Drain already accepted body input before admitting a fresh chunk. Once
    // it is exhausted, accept and process the offered chunk in this same call.
    if !admitted &&
      (!(self.mode is GzBody) || self.available() == 0 || input.length() == 0) {
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
      GzHeader => {
        guard !self.read_gzheader() else {
          return { status: NeedMoreInput, consumed, produced: op, }
        }
      }
      GzExtraLen => {
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
        let k = remaining.min(self.available())
        self.advance_header(k)
        guard k == remaining else {
          self.mode = GzExtra(remaining - k)
          guard !self.ending else {
            raise GzipError(Truncated, "gzip: truncated")
          }
          return { status: NeedMoreInput, consumed, produced: op, }
        }
        self.mode = self.next_header_mode(1)
      }
      GzName => {
        guard !self.skip_nul_field(2) else {
          return { status: NeedMoreInput, consumed, produced: op, }
        }
      }
      GzComment => {
        guard !self.skip_nul_field(3) else {
          return { status: NeedMoreInput, consumed, produced: op, }
        }
      }
      GzHcrc => {
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
          self.pending_view(),
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
        self.advance(used)
        // NeedMoreInput accepts the inflater's whole view, including atomic
        // tails. Admit the deferred external chunk instead of suspending.
        if st is NeedMoreInput && !admitted {
          continue
        }
        guard self.after_body_step(st) is Some(status) else { continue }
        return { status, consumed, produced: op, }
      }
      GzTrailer => {
        guard !self.finish_member_trailer() else {
          return { status: NeedMoreInput, consumed, produced: op, }
        }
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
