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
test "fixed streaming output views match offset array views across history wraps" {
  let source = Bytes::from_array(Array::makei(140000, i => (i % 257).to_byte()))
  for level in [0, 6] {
    let compressed = @flate.deflate_all(source, level~)
    for capacity in [1, 257, 32768, 65536] {
      let fixed = @flate.Inflater()
      let viewed = @flate.Inflater()
      let output = FixedArray::make(capacity, b'\x00')
      let padded = Array::make(capacity + 6, b'\xA5')
      let collected : Array[Byte] = []
      let mut position = 0
      for ;; {
        let end = (position + 97).min(compressed.length())
        let input = compressed[position:end]
        let status_result = fixed.step(input, output.mut_view())
        let status = status_result.status
        assert_false(status is NeedMoreInput && end == compressed.length())
        let other_result = viewed.step(
          input,
          padded.mut_view(start=3, end=3 + capacity),
        )
        @test.assert_eq(status, other_result.status)
        @test.assert_eq(status_result.consumed, other_result.consumed)
        @test.assert_eq(status_result.produced, other_result.produced)
        let count = status_result.produced
        @test.assert_eq(
          Bytes::from_array(output[:count]),
          Bytes::from_array(padded[3:3 + count]),
        )
        @test.assert_eq(padded[2], b'\xA5')
        @test.assert_eq(padded[capacity + 3], b'\xA5')
        collected.append(output[:count])
        position = position + status_result.consumed
        if status is Done {
          break
        }
      }
      @test.assert_eq(Bytes::from_array(collected), source)
      fixed.reset()
      let empty = FixedArray::make(0, b'\x00')
      let result = fixed.step(compressed, empty.mut_view())
      @test.assert_eq(result.status, NeedMoreOutput)
      @test.assert_eq(result.produced, 0)
    }
  }
}
