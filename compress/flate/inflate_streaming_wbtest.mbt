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
test "Inflater owns only a bounded atomic tail between non-overlapping chunks" {
  let bytes : Array[Byte] = []
  for i in 0..<4096 {
    bytes.push(((i * 29 + i / 7) & 0x0F).to_byte())
  }
  let source = Bytes::from_array(bytes)
  let compressed = deflate_all(source)
  let inflater = Inflater()
  let output = FixedArray::make(1, b'\x00')
  let decoded = @buffer.Buffer()
  let mut pos = 0
  for ;; {
    let endi = if pos < compressed.length() { pos + 1 } else { pos }
    let status_result = inflater.step(compressed[pos:endi], output.mut_view())
    let status = status_result.status
    assert_false(status is NeedMoreInput && endi == compressed.length())
    let consumed = status_result.consumed
    let produced = status_result.produced
    pos = pos + consumed
    if produced == 1 {
      decoded.write_byte(output[0])
    }
    // A full dynamic header is the largest atomic input unit and is well below
    // this defensive test bound. Call-owned views must already be released.
    assert_true(inflater.staged_input.length() <= 512)
    @test.assert_eq(inflater.view.length(), 0)
    @test.assert_eq(inflater.out.length(), 0)
    if status is Done {
      break
    }
  }
  @test.assert_eq(pos, compressed.length())
  @test.assert_eq(decoded.to_bytes(), source)
}

///|
/// One suspended match drained into `room` bytes of output at a time, from a
/// window whose cursor is `wpos`: the window and the output must hold the
/// forward byte-by-byte expansion, nothing may be written behind the room of
/// a step, and the cursor must advance by the match.
fn assert_drained_match(
  wpos : Int32,
  distance : Int32,
  length : Int32,
  room : Int32,
  fixed : Bool,
) -> Unit raise {
  let inflater = Inflater()
  for i in 0..<WINDOW_SIZE {
    inflater.window[i] = (i * 151 + i / 13).to_byte()
  }
  inflater.wpos = wpos
  inflater.filled = true
  let expected = FixedArray::makei(WINDOW_SIZE, i => inflater.window[i])
  for i in 0..<length {
    expected[(wpos + i) & (WINDOW_SIZE - 1)] = expected[(wpos + i - distance) &
      (WINDOW_SIZE - 1)]
  }
  inflater.copy_remaining = length
  inflater.copy_dist = distance
  let produced = @buffer.Buffer()
  while inflater.copy_remaining > 0 {
    let output = if fixed {
      FixedArray::make(room + 3, b'\xA5').mut_view()
    } else {
      Array::make(room + 3, b'\xA5').mut_view()
    }
    inflater.out = output.mut_view(end=room)
    inflater.out_pos = 0
    inflater.out_end = room
    let before = inflater.copy_remaining
    inflater.drain_match()
    @test.assert_eq(inflater.out_pos, before.min(room))
    @test.assert_eq(inflater.copy_remaining, before - inflater.out_pos)
    for i in 0..<inflater.out_pos {
      produced.write_byte(output[i])
    }
    for i in inflater.out_pos..<output.length() {
      @test.assert_eq(output[i], b'\xA5')
    }
  }
  @test.assert_eq(inflater.wpos, wpos + length)
  @test.assert_eq(inflater.window, expected)
  let bytes = produced.to_bytes()
  @test.assert_eq(bytes.length(), length)
  for i in 0..<length {
    @test.assert_eq(bytes[i], expected[(wpos + i) & (WINDOW_SIZE - 1)])
  }
}

///|
test "streaming matches expand forward across wraps, lengths and output splits" {
  let lengths = [
    3, 4, 7, 8, 15, 16, 17, 31, 32, 47, 48, 49, 50, 64, 100, 257, 258,
  ]
  for
    distance in [
      1, 2, 3, 4, 5, 7, 8, 9, 15, 16, 17, 23, 24, 25, 47, 48, 49, 257, 258, 259,
      32767, 32768,
    ] {
    for length in lengths {
      // Neither range wraps, the target wraps inside the match, the source
      // wraps inside the match, and each ends exactly at the window's end.
      for
        wpos in [
          WINDOW_SIZE,
          2 * WINDOW_SIZE - 1,
          2 * WINDOW_SIZE - length / 2,
          2 * WINDOW_SIZE - length,
          WINDOW_SIZE + distance - 1,
          WINDOW_SIZE + distance + length / 2,
          WINDOW_SIZE + distance - length,
        ] {
        for fixed in [true, false] {
          for room in [1, 5, 48, 49, 300] {
            assert_drained_match(wpos, distance, length, room, fixed)
          }
        }
      }
    }
  }
}
