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

// Tests for the public `deflate_all_split` entry point: round-trips, the
// never-worse-than-fixed arbitration guarantee, and edge cases (stored level,
// empty input, large multi-chunk inputs).

///|
fn bench_repetitive(size : Int32) -> Bytes {
  let unit = b"The quick brown fox jumps over the lazy dog. Pack my box. "
  Bytes::makei(size, i => unit[i % unit.length()])
}

///|
/// Effectively incompressible: bytes from a deterministic LCG.
fn bench_random(size : Int32) -> Bytes {
  let mut s = 0x12345678U
  Bytes::makei(size, _ => {
    s = s * 1103515245U + 12345U
    ((s >> 16) & 0xFF).reinterpret_as_int().to_byte()
  })
}

///|
fn bench_mixed(size : Int32) -> Bytes {
  bench_repetitive(size / 2) + bench_random(size - size / 2)
}

///|
fn split_prose(size : Int32) -> Bytes {
  let ps : ReadOnlyArray[_] = [
    b"The history of data compression is a history of finding structure in information that does not want to be found. Early codes worked letter by letter; the leap to phrase-based matching came only when programmers realized that a file is rarely a stream of independent symbols but a tapestry of repeated fragments.",
    b"Consider a text file. Common words appear over and over, at distances that vary with the sentence structure around them. A word like the or and may sit three characters from its twin in one sentence and three thousand in the next.",
    b"Matching is not the same as deciding. Finding a long match is cheap work for a hash table, but choosing whether to use it is a separate problem with its own economics.",
    b"The verification community has begun to look at compression with new eyes. If a decompressor and a compressor are proved to be mutual inverses, then the compressor becomes a safe place to be aggressive.",
    b"Corpus design is the quiet science behind every benchmark that matters. A single file proves nothing; a hand-picked set can flatter a codec into irrelevance.",
    b"Performance work in a garbage-collected runtime has its own texture. Allocation pressure hides in the most innocent loops, a boxed value appears where a register should be.",
    b"There is a recurring argument about whether a decoder should trust its input. The paranoid position holds that every stream is hostile until proven otherwise.",
    b"Writing about algorithms is a discipline of its own. The temptation is to describe what the code does rather than why it exists.",
  ]
  let arr : Array[Byte] = []
  let order = [
    0, 3, 1, 5, 2, 7, 4, 6, 1, 6, 0, 4, 7, 2, 5, 3, 5, 0, 3, 2, 6, 1, 7, 4,
  ]
  while arr.length() < size {
    for k in order {
      let unit = ps[k]
      for i in 0..<unit.length() {
        arr.push(unit[i])
      }
    }
  }
  Bytes::from_array(arr)
}

///|
fn split_code(size : Int32) -> Bytes {
  let src = b"pub fn Deflater::step(self : Deflater, input : BytesView, output : MutArrayView[Byte], action? : DeflateAction = Continue) -> Status { self.step_consumed = 0; self.step_produced = 0; if self.done { return self.finish_step(Done, 0, 0) }; let out_end = output.length(); let input_end = input.length(); let input_limit = DEFLATE_BLOCK_SIZE + MIN_LOOKAHEAD; let mut consumed = 0; for ;; { while self.out_pos < self.w.out.length() && write_pos < out_end { output.set(write_pos, self.w.out[self.out_pos]); write_pos = write_pos + 1 }; if consumed < input_end { let take = input_end - consumed; for i in consumed..<(consumed + take) { self.pending.push(input[i]) }; consumed = consumed + take; continue }; return self.finish_step(NeedMoreInput, consumed, write_pos) } };"
  let unit = src
  let arr : Array[Byte] = []
  while arr.length() < size {
    for i in 0..<unit.length() {
      arr.push(unit[i])
    }
  }
  Bytes::from_array(arr)
}

///|
fn split_drift(size : Int32) -> Bytes {
  // Statistics drift: compressible prose alternating with pseudo-random bytes,
  // the regime where a too-large adaptive block can lag a fixed cadence.
  let arr : Array[Byte] = []
  let unit = split_prose(65536)
  let mut p = 0
  while arr.length() < size {
    if arr.length() % 262144 < 131072 {
      arr.push(unit[p % unit.length()])
      p = p + 1
    } else {
      arr.push(((p * 31 + 7) & 0xFF).to_byte())
      p = p + 3
    }
  }
  Bytes::from_array(arr)
}

///|
fn split_midmix(size : Int32) -> Bytes {
  // Prose and pseudo-random bytes alternate every 32 KB, so the drift boundary
  // falls *inside* each 64 KB master chunk and forces a mid-chunk divergence
  // cut (non-empty `choose_splits` and the arbitration branch).
  let arr : Array[Byte] = []
  let unit = split_prose(32768)
  let mut p = 0
  while arr.length() < size {
    if arr.length() % 65536 < 32768 {
      arr.push(unit[p % unit.length()])
      p = p + 1
    } else {
      arr.push(((p * 17 + 3) & 0xFF).to_byte())
      p = p + 1
    }
  }
  Bytes::from_array(arr)
}

///|
/// The splitter must never be larger than the fixed-cadence `deflate_all` on
/// any input the arbitration can judge, and round-trips on large inputs that
/// cross master-chunk boundaries.
test "deflate_all_split never worse than fixed cadence" {
  for level in 1..<=9 {
    let inputs : FixedArray[(String, Bytes)] = [
      ("prose", split_prose(1048576)),
      ("code", split_code(1048576)),
      ("drift", split_drift(524288)),
      ("midmix", split_midmix(524288)),
      ("repetitive", bench_repetitive(262144)),
      ("mixed", bench_mixed(262144)),
    ]
    for t in inputs {
      let (name, data) = t
      let fixed = @flate.deflate_all(data, level~)
      let split = @flate.deflate_all_split(data, level~)
      assert_true(
        split.length() <= fixed.length(),
        msg="split larger than fixed on \{name} L\{level}: \{split.length()} > \{fixed.length()}",
      )
      @test.assert_eq(@flate.inflate_all(split), data)
    }
  }
}

///|
test "deflate_all_split clamps out-of-range levels" {
  let src = b"level clamping is deterministic across the splitter too"
  @test.assert_eq(
    @flate.deflate_all_split(src, level=-1),
    @flate.deflate_all_split(src, level=0),
  )
  @test.assert_eq(
    @flate.deflate_all_split(src, level=99),
    @flate.deflate_all_split(src, level=9),
  )
}
