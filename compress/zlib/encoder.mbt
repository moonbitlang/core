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

// Streaming zlib (RFC 1950) compressor: a push-based, suspendable state machine
// wrapping the `@flate.Deflater`. It emits the 2-byte header, then the raw
// DEFLATE stream block-by-block, then the 4-byte big-endian Adler-32 trailer,
// accumulating the checksum incrementally. The one-shot `compress` remains
// for in-memory use.

///|
// CMF=0x78 (deflate, 32K window); FLG=0x01 makes the header a multiple of 31
// with FLEVEL=0 and no preset dictionary.
let zlib_header_bytes : FixedArray[Byte] = [0x78, 0x01]

///|
priv enum EncMode {
  Header
  Body
  Trailer
  Finished
}

///|
/// Streaming zlib compressor (RFC 1950). Feed input and drain compressed output
/// with `step`, finalize with `action=Finish`; binds no I/O trait.
struct Encoder {
  def : @flate.Deflater
  mut adler : @checksum.Adler32
  mut mode : EncMode
  mut stage : FixedArray[Byte]
  mut stage_pos : Int32
  // Accepted stream control, latched until the inner deflater drains it.
  // Finish and sync-flush cannot both be pending.
  mut pending_action : @flate.DeflateAction
}

///|
/// Create a fresh zlib compressor. `level` 0-9 (clamped) trades speed for
/// ratio; 0 = stored only, 6 = default. A preset `dictionary` (RFC 1950
/// FDICT) preloads the match window and is announced in the header via its
/// Adler-32; the decoder must supply the same dictionary.
/// Opt-in `fast_store` samples each block; it may increase output size.
/// The default is false.
pub fn Encoder::Encoder(
  level~ : Int32 = 6,
  dictionary? : BytesView,
  fast_store~ : Bool = false,
) -> Encoder {
  let def = if dictionary is Some(dict) {
    @flate.Deflater(level~, dictionary=dict, fast_store~)
  } else {
    Deflater(level~, fast_store~)
  }
  {
    def,
    adler: Adler32(),
    mode: Header,
    stage: zlib_header(dictionary),
    stage_pos: 0,
    pending_action: Continue,
  }
}

///|
/// The zlib header: CMF and FLG, followed by the DICTID of a preset dictionary.
fn zlib_header(dictionary : BytesView?) -> FixedArray[Byte] {
  guard dictionary is Some(dict) else { return zlib_header_bytes }
  let id = @checksum.adler32(dict)
  let h = FixedArray::make(6, b'\x00')
  // CMF=0x78; FLG=0x20 sets FDICT (0x7820 is a multiple of 31, FCHECK ok),
  // followed by the 4-byte big-endian DICTID.
  h[0] = b'\x78'
  h[1] = b'\x20'
  h[2] = ((id >> 24) & 0xFF).reinterpret_as_int().to_byte()
  h[3] = ((id >> 16) & 0xFF).reinterpret_as_int().to_byte()
  h[4] = ((id >> 8) & 0xFF).reinterpret_as_int().to_byte()
  h[5] = (id & 0xFF).reinterpret_as_int().to_byte()
  h
}

///|
/// Reset to the start of a fresh zlib stream, keeping the compression level
/// and `fast_store` policy and reusing the compressor's allocations. The next
/// stream's output is identical to that of a newly constructed `Encoder`
/// with the same options. A preset `dictionary` applies to the new stream
/// only, exactly as for the constructor.
pub fn Encoder::reset(self : Encoder, dictionary? : BytesView) -> Unit {
  match dictionary {
    Some(dict) => self.def.reset(dictionary=dict)
    None => self.def.reset()
  }
  self.adler = Adler32()
  self.mode = Header
  self.stage = zlib_header(dictionary)
  self.stage_pos = 0
  self.pending_action = Continue
}

///|
/// Whether the complete zlib stream has been emitted.
pub fn Encoder::is_finished(self : Encoder) -> Bool {
  self.mode is Finished
}

///|
/// The 4-byte zlib trailer: Adler-32, big-endian.
fn Encoder::build_trailer(self : Encoder) -> FixedArray[Byte] {
  let adler = self.adler.finish()
  let t = FixedArray::make(4, b'\x00')
  // The 4-byte allocation above covers every fixed-offset write.
  t.unsafe_write_uint32_be(0, adler)
  t
}

///|
/// Run one compression step. Accepts a bounded prefix of `input`, folds only
/// that prefix into Adler-32, then drains zlib output into `output`. Returns
/// `StepResult` with this call's status, consumed and produced byte counts.
/// Drop only `input[:result.consumed]`: a large view may be partially
/// consumed under output backpressure. Re-present its suffix with the same
/// `action`; once the complete view is accepted, `SyncFlush` or `Finish` remains
/// sticky. Later input is left unconsumed while the finished stream is drained.
pub fn Encoder::step(
  self : Encoder,
  input : BytesView,
  output : MutArrayView[Byte],
  action~ : @flate.DeflateAction = Continue,
) -> @flate.StepResult {
  // A terminal encoder must not claim or checksum input that cannot become
  // part of the already-finished stream.
  if self.mode is Finished {
    return { status: Done, consumed: 0, produced: 0, }
  }
  let mut consumed = 0
  // A pending Finish leaves later input unconsumed: feed only while the inner
  // deflater still accepts.
  if !(self.pending_action is Finish) {
    let scratch = FixedArray::make(0, b'\x00').mut_view()
    let accepted = self.def.step(input, scratch, action~).consumed
    consumed = accepted
    if accepted > 0 {
      self.adler.update(input[:accepted])
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
          // Deflater returns NeedMoreInput only after a requested sync flush
          // (including its marker) has been fully emitted.
          if self.pending_action is SyncFlush {
            self.pending_action = Continue
          }
          return { status: NeedMoreInput, consumed, produced: op, }
        }
        if st is NeedMoreOutput {
          return { status: NeedMoreOutput, consumed, produced: op, }
        }
        self.stage = self.build_trailer()
        self.stage_pos = 0
        self.mode = Trailer
      }
      Finished => return { status: Done, consumed, produced: op, }
    }
  }
}
