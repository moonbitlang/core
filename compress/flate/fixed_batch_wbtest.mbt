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

// A fixed block is decoded in memory with the fixed codes as tables, by the
// batch where there is room for it (native) and by the checked decoder at
// both ends. The encoder writes a fixed block only where it is the cheapest,
// so these are written by hand, of any size, and decoded against the
// streaming inflater, which reads the five bits of a distance directly.

///|
/// A final fixed block of `count` tokens from an LCG: literals, and matches of
/// every length at distances within what was produced.
fn fixed_batch_stream(count : Int32, seed : UInt32) -> Bytes {
  let mut state = seed
  let next = () => {
    state = state * 1103515245U + 12345U
    ((state >> 8) & 0xFFFFFFU).reinterpret_as_int()
  }
  let mut produced = 0
  let tokens = Array::makei(count, _ => {
    if produced == 0 || next() % 3 != 0 {
      produced += 1
      next() % 256
    } else {
      let length = 3 + next() % 256
      produced += length
      pack_match_token(length, 1 + next() % (produced - length).min(32768))
    }
  })
  let writer = BitWriter()
  writer.write_bit(1)
  writer.write_fixed_block(tokens)
  coverage_finish_bits(writer)
}

///|
/// The streaming inflater over all of `input`: bytes and consumed input, or
/// the error category.
fn fixed_batch_streaming(input : BytesView) -> (Bytes, Int32, String) {
  let inflater = Inflater()
  let output = FixedArray::make(700, b'\x00')
  let decoded = @buffer.Buffer()
  let mut used = 0
  for ;; {
    let status_result = inflater.step(input[used:], output.mut_view()) catch {
      InflateError(kind, _) => return (b"", 0, @debug.to_string(kind))
    }
    let status = status_result.status
    if status is NeedMoreInput {
      return (b"", 0, @debug.to_string(InflateErrorKind::Truncated))
    }
    used += status_result.consumed
    decoded.write_bytes(Bytes::from_array(output[:status_result.produced]))
    if status is Done {
      return (decoded.to_bytes(), used, "done")
    }
  }
}

///|
fn fixed_batch_in_memory(input : BytesView) -> (Bytes, Int32, String) {
  let decoder = MemDecoder(input, no_cancellation)
  decoder.set_cancellation(None)
  decoder.run() catch {
    InflateError(kind, _) => return (b"", 0, @debug.to_string(kind))
  }
  (decoder.out.to_bytes(), decoder.consumed(), "done")
}

///|
test "fixed blocks of every size decode in memory as they do in steps" {
  let behind = Bytes::makei(17, i => (i * 37 + 0x1F).to_byte())
  for count in [0, 1, 2, 3, 8, 30, 90, 400, 3000] {
    for seed in [1U, 2U, 3U] {
      let stream = fixed_batch_stream(count, seed * 7919)
      @test.assert_eq((stream[0].to_int() >> 1) & 3, 1)
      let (bytes, used, verdict) = fixed_batch_streaming(stream)
      @test.assert_eq(verdict, "done")
      @test.assert_eq(used, stream.length())
      // Whole, with bytes behind it, and cut: everywhere if it is short, at
      // both ends and at a spread otherwise.
      for extra in 0..<=17 {
        let longer = stream + behind[:extra].to_owned()
        guard fixed_batch_in_memory(longer) == (bytes, used, "done") else {
          fail("\{count} tokens, seed \{seed}, \{extra} bytes behind")
        }
      }
      for cut in 0..<stream.length() {
        guard stream.length() <= 400 ||
          cut < 20 ||
          cut >= stream.length() - 20 ||
          cut % 61 == 0 else {
          continue
        }
        let expected = fixed_batch_streaming(stream[:cut])
        guard fixed_batch_in_memory(stream[:cut]) == expected else {
          fail("\{count} tokens, seed \{seed}, cut at \{cut}: \{expected.2}")
        }
      }
    }
  }
}

///|
/// The batch stops a token's worth of output short of the next poll. A poll at
/// 0x7FFFF000 bytes sets the counter 4096 further, which wraps below zero and
/// used to read as no poll at all: the batch leaves that to the checked
/// decoder, which has polled a fixed block there all along.
#cfg(target="native")
test "the batch leaves a wrapped poll counter to the checked decoder" {
  let wrapped = MAX_DECODE_OUTPUT_SIZE - 4095 + CANCEL_GRANULARITY
  @test.assert_eq(wrapped, -2147483648)
  let (litlen, distance) = fixed_data_decoders
  let writer = BitWriter()
  for _ in 0..<1200 {
    writer.write_rcode(fixed_ll_val[65], fixed_ll_len[65])
  }
  writer.write_rcode(fixed_ll_val[256], fixed_ll_len[256])
  let input = coverage_finish_bits(writer) + Bytes::make(16, b'\x00')
  for
    case_ in [
      (wrapped, 0),
      (wrapped + 4095, 0),
      (0, 0),
      (258, 0),
      (259, 1),
      (1000, 742),
    ] {
    let (next_cancel, decoded) = case_
    let decoder = MemDecoder(input, () => false)
    decoder.out = DecodeOutput::into(FixedArray::make(2000, b'\xA5'))
    decoder.next_cancel = next_cancel
    @test.assert_eq(decoder.decode_batch(litlen, Some(distance)), false)
    @test.assert_eq(decoder.out.length, decoded)
  }
}
