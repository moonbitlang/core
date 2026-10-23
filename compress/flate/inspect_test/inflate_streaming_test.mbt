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
// Standard vectors, including overlapping matches, with non-overlapping input
// chunks and an offset output view. Assert progress instead of hanging on a stall.
test "streaming standard vectors preserve bytes consumption and output boundaries" {
  for
    (compressed, plain) in [
      (hello_stored, b"hello"),
      (v_fixed_hello, b"hello"),
      (v_fixed_aaa, b"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"),
      (v_dynamic_text, dynamic_plain),
    ] {
    for (chunk, room) in [(1, 1), (5, 300)] {
      let inflater = @flate.Inflater()
      let output = FixedArray::make(room + 6, b'\xA5')
      let decoded = @buffer.Buffer()
      let mut pos = 0
      for ;; {
        let end = (pos + chunk).min(compressed.length())
        let status_result = inflater.step(
          compressed[pos:end],
          output.mut_view(start=3, end=3 + room),
        )
        let status = status_result.status
        assert_false(status is NeedMoreInput && end == compressed.length())
        let used = status_result.consumed
        let written = status_result.produced
        assert_true(used >= 0 && used <= end - pos)
        assert_true(written >= 0 && written <= room)
        @test.assert_eq(output[2], b'\xA5')
        @test.assert_eq(output[room + 3], b'\xA5')
        decoded.write_bytes(Bytes::from_array(output[3:3 + written]))
        pos += used
        if status is Done {
          break
        }
        assert_true(used > 0 || written > 0, msg="streaming decoder stalled")
      }
      @test.assert_eq(pos, compressed.length())
      @test.assert_eq(decoded.to_bytes(), plain)
    }
  }
}

///|
test "Inflater step resumes after empty input and drains into one byte" {
  let inflater = @flate.Inflater()
  let output = FixedArray::make(1, b'\x00')
  let first = inflater.step(hello_stored[:1], output.mut_view())
  @test.assert_eq(first.status, NeedMoreInput)
  @test.assert_eq(first.consumed, 1)
  @test.assert_eq(first.produced, 0)
  let empty = inflater.step(b"", output.mut_view())
  @test.assert_eq(empty.status, NeedMoreInput)
  @test.assert_eq(empty.consumed, 0)
  @test.assert_eq(empty.produced, 0)
  let decoded = @buffer.Buffer()
  let mut position = 1
  let mut suspensions = 0
  for ;; {
    let result = inflater.step(hello_stored[position:], output.mut_view())
    position += result.consumed
    decoded.write_bytes(Bytes::from_array(output[:result.produced]))
    match result.status {
      Done => break
      NeedMoreOutput => suspensions += 1
      NeedMoreInput => @test.fail("complete input was treated as truncated")
    }
  }
  assert_true(suspensions > 0)
  @test.assert_eq(position, hello_stored.length())
  @test.assert_eq(decoded.to_bytes(), b"hello")
  let done = inflater.step(b"later input", output.mut_view())
  @test.assert_eq(done.status, Done)
  @test.assert_eq(done.consumed, 0)
  @test.assert_eq(done.produced, 0)
}
