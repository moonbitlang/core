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
        let status = if end == compressed.length() {
          inflater.finish(
            compressed[pos:end],
            output.mut_view(start=3, end=3 + room),
          )
        } else {
          inflater.step(
            compressed[pos:end],
            output.mut_view(start=3, end=3 + room),
          )
        }
        let used = inflater.last_consumed()
        let written = inflater.last_produced()
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
