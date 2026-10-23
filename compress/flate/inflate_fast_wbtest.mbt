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

// The streaming inflater decodes whole units with local state while a step
// has eight bytes of input and 258 bytes of output room in hand (native).
// With less room every unit takes the careful path. Both must give the same
// bytes, the same consumption (bytes behind the stream stay unread) and the
// same verdict on damaged streams.

///|
fn fast_stream_run(
  input : Bytes,
  chunk : Int32,
  room : Int32,
  fixed : Bool,
) -> Result[(Bytes, Int32), InflateErrorKind] {
  let inflater = Inflater()
  let output = if fixed {
    FixedArray::make(room, b'\x00').mut_view()
  } else {
    Array::make(room, b'\x00').mut_view()
  }
  let decoded = @buffer.Buffer()
  let mut position = 0
  for ;; {
    let end = (position + chunk).min(input.length())
    let status_result = inflater.step(input[position:end], output) catch {
      InflateError(kind, _) => return Err(kind)
    }
    let status = status_result.status
    if status is NeedMoreInput && end == input.length() {
      return Err(Truncated)
    }
    position += status_result.consumed
    decoded.write_bytes(Bytes::from_array(output[:status_result.produced]))
    if status is Done {
      return Ok((decoded.to_bytes(), position))
    }
  }
}

///|
#cfg(target="native")
fn fast_stream_sources() -> Array[Bytes] {
  let words : ReadOnlyArray[Bytes] = [
    b"the ", b"window ", b"of ", b"a ", b"stream ", b"literal ", b"match ", b"0123456789 ",
    b"BT /F1 12 Tf ", b"<0A1B2C> ", b"\n",
  ]
  let rng = InflateDifferentialRng(0xFA57D0C5U)
  let text = @buffer.Buffer()
  while text.length() < 100000 {
    text.write_bytes(words[rng.size(words.length()) - 1])
    if rng.size(40) == 1 {
      // a long match far back, and a run of distance one
      text.write_bytes(text.to_bytes()[:rng.size(300)].to_owned())
      text.write_bytes(Bytes::make(rng.size(400), b'='))
    }
  }
  let mixed = @buffer.Buffer()
  mixed.write_bytes(inflate_differential_random_bytes(0xFA57D0C6U, 20000, 256))
  mixed.write_bytes(inflate_differential_pattern(b"moonbit-flate-", 30000))
  mixed.write_bytes(inflate_differential_random_bytes(0xFA57D0C7U, 20000, 7))
  [
    text.to_bytes(),
    mixed.to_bytes(),
    Bytes::make(70000, b'a'),
    // Short inputs are fixed-Huffman blocks.
    b"fixed blocks carry no trees: fixed blocks carry no trees, fixed blocks.",
    inflate_differential_pattern(b"abcdefgh", 300),
    ..inflate_differential_sources(),
  ]
}

///|
/// Run one schedule on two decoders and compare what every call reports. The
/// first takes each call as it is. The second is given the same input view
/// but its output room in pieces of at most 257 bytes, a room in which no
/// call can hold a whole longest match: it decodes every unit through
/// `decode_unit`. Its pieces, put together, are what one careful call does,
/// so status, consumed and produced counts, the bytes and the error kind of
/// every call must be the same.
#cfg(target="native")
fn assert_calls_agree(
  input : Bytes,
  chunk : Int32,
  room : Int32,
  fixed : Bool,
) -> Result[(Bytes, Int32), InflateErrorKind] raise {
  let whole = Inflater()
  let pieces = Inflater()
  let output = if fixed {
    FixedArray::make(room, b'\x00').mut_view()
  } else {
    Array::make(room, b'\x00').mut_view()
  }
  let reference = FixedArray::make(room, b'\x00')
  let mut position = 0
  let decoded = @buffer.Buffer()
  for ;; {
    let end = (position + chunk).min(input.length())
    let view = input[position:end]
    let mut verdict : InflateErrorKind? = None
    let mut whole_result : StepResult = {
      status: Done,
      consumed: 0,
      produced: 0,
    }
    try {
      whole_result = whole.step(view, output)
    } catch {
      InflateError(kind, _) => verdict = Some(kind)
    }
    let mut consumed = 0
    let mut produced = 0
    let mut expected_verdict : InflateErrorKind? = None
    let mut expected : Status = NeedMoreOutput
    for ;; {
      let piece = (room - produced).min(257)
      let step_result = pieces.step(
        view[consumed:],
        reference.mut_view(start=produced, end=produced + piece),
      ) catch {
        InflateError(kind, _) => {
          expected_verdict = Some(kind)
          break
        }
      }
      let step = step_result.status
      consumed = consumed + step_result.consumed
      produced = produced + step_result.produced
      expected = step
      guard step is NeedMoreOutput && produced < room else { break }
    }
    @test.assert_eq(verdict, expected_verdict)
    if verdict is Some(kind) {
      return Err(kind)
    }
    let status = whole_result.status
    @test.assert_eq(status, expected)
    @test.assert_eq(whole_result.consumed, consumed)
    @test.assert_eq(whole_result.produced, produced)
    for i in 0..<produced {
      guard output[i] == reference[i] else {
        @test.fail("byte \{i} of a call differs")
      }
    }
    decoded.write_bytes(Bytes::from_array(output[:produced]))
    position += consumed
    if status is Done {
      return Ok((decoded.to_bytes(), position))
    }
    if status is NeedMoreInput && end == input.length() {
      return Err(Truncated)
    }
    assert_true(consumed > 0 || produced > 0, msg="streaming decoder stalled")
  }
}

///|
/// The per-call contract on intact and damaged streams: where a call
/// suspends, what it consumed and produced, and how it fails.
#cfg(target="native")
test "streaming calls report what careful calls report" {
  let rng = InflateDifferentialRng(0x7EACE5U)
  for source in fast_stream_sources() {
    for level in [0, 1, 6] {
      let compressed = deflate_all(source, level~)
      let framed = compressed +
        b"\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF"
      let schedules = [
        (1 << 20, 65536, true),
        (1 << 20, 258, false),
        (4096, 300, false),
        (263, 1000, true),
        (9, 258, true),
        (8, 4096, false),
      ]
      for schedule in schedules {
        let (chunk, room, fixed) = schedule
        guard chunk >= 263 || source.length() <= 2000 else { continue }
        @test.assert_eq(
          assert_calls_agree(framed, chunk, room, fixed),
          Ok((source, compressed.length())),
        )
      }
      for k in 0..<8 {
        let stream = if k % 2 == 0 {
          compressed[:rng.size(compressed.length()) - 1].to_owned()
        } else {
          inflate_differential_flip(
            compressed,
            rng.size(compressed.length()) - 1,
            1 << (rng.size(8) - 1),
          )
        }
        let expected = inflate_differential_one_shot(stream)
        for (chunk, room, fixed) in [(1 << 20, 65536, true), (263, 1000, false)] {
          let actual = match assert_calls_agree(stream, chunk, room, fixed) {
            Ok((bytes, _)) => InflateDifferentialOk(bytes)
            Err(kind) => InflateDifferentialErr(kind)
          }
          @test.assert_eq(actual, expected)
        }
      }
    }
  }
}

///|
/// A fixed-Huffman block of `literals` literals, then `unit` written by the
/// caller, then zero padding: enough input behind the unit that a decoder
/// with ample output room reaches it with a full reservoir.
fn fast_stream_malformed(literals : Int32, unit : (BitWriter) -> Unit) -> Bytes {
  let writer = BitWriter()
  writer.write_bit(1)
  writer.write_bits(1, 2)
  for i in 0..<literals {
    let symbol = 0x41 + i % 26
    writer.write_rcode(fixed_ll_val[symbol], fixed_ll_len[symbol])
  }
  unit(writer)
  writer.flush()
  for _ in 0..<16 {
    writer.write_byte(b'\x00')
  }
  Bytes::from_array(writer.out)
}

///|
/// Invalid units deep inside a block, reached with ample input and output:
/// the reserved length symbols 286 and 287, the reserved distance symbols 30
/// and 31, and a distance beyond the history. Every schedule and the one-shot
/// decoder must call them corrupt.
test "malformed units are corrupt for every output room" {
  let length3 = (writer : BitWriter) => {
    writer.write_rcode(fixed_ll_val[257], fixed_ll_len[257])
  }
  let units : Array[(BitWriter) -> Unit] = [
    writer => writer.write_rcode(fixed_ll_val[286], fixed_ll_len[286]),
    writer => writer.write_rcode(fixed_ll_val[287], fixed_ll_len[287]),
    writer => {
      length3(writer)
      writer.write_rcode(reverse_bits(30U, 5), 5)
    },
    writer => {
      length3(writer)
      writer.write_rcode(reverse_bits(31U, 5), 5)
    },
    // Distance 32768 behind fewer bytes than that.
    writer => {
      length3(writer)
      writer.write_rcode(fixed_dist_val[29], 5)
      writer.write_bits(8191, 13)
    },
  ]
  for literals in [20, 400, 5000] {
    for unit in units {
      let stream = fast_stream_malformed(literals, unit)
      for
        schedule in [
          (1 << 20, 257, true),
          (1 << 20, 258, true),
          (1 << 20, 65536, false),
          (64, 4096, true),
          (9, 300, false),
        ] {
        let (chunk, room, fixed) = schedule
        @test.assert_eq(
          fast_stream_run(stream, chunk, room, fixed),
          Err(Corrupt),
        )
      }
      @test.assert_eq(
        inflate_differential_one_shot(stream),
        InflateDifferentialErr(Corrupt),
      )
    }
  }
}

///|
/// The window cursor counts every byte ever written and wraps. A call that
/// writes a window's worth of literals must leave the window marked full
/// wherever the counter stands afterwards, or the next call rejects a match
/// that reaches back further than the wrapped counter's value. Getting there
/// takes a 2 GiB output array, so the cursor is set by hand: it stands for
/// the middle of such a call, a window short of wrapping past zero.
#cfg(target="native")
test "fast loop marks the window full by what a call wrote" {
  let stream = fast_stream_malformed(40000, writer => {
    // Length 3 at distance 20000 (symbol 28, base 16385), then end of block.
    writer.write_rcode(fixed_ll_val[257], fixed_ll_len[257])
    writer.write_rcode(fixed_dist_val[28], 5)
    writer.write_bits(20000 - 16385, 13)
    writer.write_rcode(fixed_ll_val[256], fixed_ll_len[256])
  })
  let inflater = Inflater()
  inflater.wpos = -30000
  let output = FixedArray::make(40000, b'\x00')
  let first_result = inflater.step(stream, output.mut_view())
  let first = first_result.status
  assert_true(first is NeedMoreOutput)
  @test.assert_eq(first_result.produced, 40000)
  @test.assert_eq(inflater.wpos, 10000)
  assert_true(inflater.filled)
  let rest = stream[first_result.consumed:]
  let second_result = inflater.step(rest, output.mut_view())
  let second = second_result.status
  assert_true(second is Done)
  @test.assert_eq(second_result.produced, 3)
  for i in 0..<3 {
    @test.assert_eq(output[i], (0x41 + (20000 + i) % 26).to_byte())
  }
}
