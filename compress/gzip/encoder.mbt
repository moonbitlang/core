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

// Streaming gzip compressor: a push-based, suspendable state machine
// wrapping the `@flate.Deflater`. It emits the 10-byte header, then the raw
// DEFLATE stream block-by-block, then the 8-byte trailer (CRC-32 and ISIZE,
// little-endian), accumulating the checksum incrementally so it never holds the
// whole input. The one-shot `compress` remains for in-memory use.

///|
let gzip_header_bytes : FixedArray[Byte] = [
  0x1F, 0x8B, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF,
]

///|
priv enum EncMode {
  Header // draining the gzip header
  Body // draining DEFLATE blocks from the inner Deflater
  Trailer // draining the CRC-32 + ISIZE trailer
  Finished
}

///|
/// Streaming gzip compressor.
struct Encoder {
  def : @flate.Deflater
  crc : @checksum.Crc32
  mut isize : UInt32 // total input length, mod 2^32 (gzip ISIZE)
  mut mode : EncMode
  mut stage : FixedArray[Byte] // header or trailer bytes being drained
  mut stage_pos : Int32
  // The accepted control action remains sticky until the inner state machine
  // has drained it. A single enum makes finish and sync-flush mutually
  // exclusive by construction.
  mut pending_action : @flate.DeflateAction
}

///|
/// Create a fresh gzip compressor. `level` 0-9 (clamped) trades speed for
/// ratio; 0 = stored only, 6 = default.
/// Opt-in `fast_store` samples each block; it may increase output size.
/// The default is false.
pub fn Encoder::Encoder(
  level~ : Int32 = 6,
  fast_store~ : Bool = false,
) -> Encoder {
  {
    def: Deflater(level~, fast_store~),
    crc: Crc32(),
    isize: 0,
    mode: Header,
    stage: gzip_header_bytes,
    stage_pos: 0,
    pending_action: Continue,
  }
}

///|
/// Whether the complete gzip stream has been emitted.
pub fn Encoder::is_finished(self : Encoder) -> Bool {
  self.mode is Finished
}

///|
/// The 8-byte gzip trailer: CRC-32 then ISIZE, each little-endian.
fn Encoder::build_trailer(self : Encoder) -> FixedArray[Byte] {
  let crc = self.crc.finish()
  let isize = self.isize
  let t = FixedArray::make(8, b'\x00')
  // The 8-byte allocation above covers every fixed-offset write.
  t.unsafe_write_uint32_le(0, crc)
  t.unsafe_write_uint32_le(4, isize)
  t
}

///|
/// Run one compression step. Accepts a bounded prefix of `input` (folding only
/// that prefix into CRC-32 and ISIZE), then drains gzip output into `output`.
/// Returns `StepResult` with this call's status, consumed and produced byte
/// counts. Drop only `input[:result.consumed]`: output
/// backpressure may make a large input partially consumed. Re-present its
/// suffix with the same `action`; once the complete view is accepted,
/// `SyncFlush` or `Finish` remains sticky across header and body backpressure.
/// After finalization, later input is not accepted and `result.consumed` is
/// zero.
pub fn Encoder::step(
  self : Encoder,
  input : BytesView,
  output : MutArrayView[Byte],
  action~ : @flate.DeflateAction = Continue,
) -> @flate.StepResult {
  if self.mode is Finished {
    return { status: Done, consumed: 0, produced: 0, }
  }
  let mut consumed = 0
  // A pending Finish leaves later input unconsumed: feed only while the inner
  // deflater still accepts.
  if !(self.pending_action is Finish) {
    // Feed through the bounded inner state machine even while the wrapper
    // header is backpressured. Its zero-sized sink caps accepted input at one
    // block window and reports the exact prefix whose checksum we may commit.
    let scratch = FixedArray::make(0, b'\x00').mut_view()
    let accepted = self.def.step(input, scratch, action~).consumed
    consumed = accepted
    if accepted > 0 {
      self.crc.update(input[:accepted])
      self.isize = self.isize + accepted.reinterpret_as_uint()
    }
    if accepted == input.length() {
      guard action is Continue else { self.pending_action = action }
    }
  }
  let out_end = output.length()
  let mut op = 0
  for ;; {
    match self.mode {
      Header | Trailer => {
        while self.stage_pos < self.stage.length() && op < out_end {
          output.set(op, self.stage[self.stage_pos])
          op = op + 1
          self.stage_pos = self.stage_pos + 1
        }
        if self.stage_pos < self.stage.length() {
          return { status: NeedMoreOutput, consumed, produced: op, }
        }
        self.mode = if self.mode is Header { Body } else { Finished }
      }
      Body => {
        let st_result = self.def.step(
          b"",
          output.mut_view(start=op),
          action=self.pending_action,
        )
        let st = st_result.status
        let p = st_result.produced
        op = op + p
        if st is NeedMoreInput {
          // The inner deflater returns NeedMoreInput only after the sync-flush
          // marker (if requested) and all preceding compressed bytes drained.
          if self.pending_action is SyncFlush {
            self.pending_action = Continue
          }
          return { status: NeedMoreInput, consumed, produced: op, }
        }
        if st is NeedMoreOutput {
          return { status: NeedMoreOutput, consumed, produced: op, }
        }
        // The DEFLATE stream is complete; stage the trailer.
        self.stage = self.build_trailer()
        self.stage_pos = 0
        self.mode = Trailer
      }
      Finished => return { status: Done, consumed, produced: op, }
    }
  }
}
