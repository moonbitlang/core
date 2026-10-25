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

// Byte-aligned payloads of the bit writer.

///|
test "byte payloads append to the array sink from any view and offset" {
  let backing = Bytes::makei(70000, i => (i * 29 + i / 251).to_byte())
  for view_start in [0, 5] {
    let view = backing[view_start:]
    for offset in [0, 1, 300] {
      for length in [0, 1, 255, 65535, 65536] {
        let writer = BitWriter()
        writer.write_byte(b'\x7E')
        writer.write_bytes(view, offset, length)
        writer.write_byte(b'\x7F')
        @test.assert_eq(writer.out.length(), length + 2)
        @test.assert_eq(writer.out[0], b'\x7E')
        @test.assert_eq(writer.out[length + 1], b'\x7F')
        for i in 0..<length {
          guard writer.out[1 + i] == backing[view_start + offset + i] else {
            @test.fail("payload byte \{i} differs")
          }
        }
      }
    }
  }
}

///|
test "fixed bit writers cannot wrap an exhausted cursor" {
  let bytes = b"abcd"
  // Simulate the old cursor at the Int32 boundary without a huge allocation.
  let writer = BitWriter::into([])
  writer.direct_pos = 2147483647
  writer.overflowed = true
  writer.write_byte(b'x')
  writer.write_bytes(bytes, 0, bytes.length())
  assert_true(writer.direct_pos >= 0)
  @test.assert_eq(writer.overflowed, true)
  @test.assert_eq(bitwriter_output_length(2147483646, 1), 2147483647)
}

///|
#cfg(any(target="native", target="wasm"))
test "bulk bit writes cannot wrap an exhausted cursor" {
  let writer = BitWriter::into([])
  writer.direct_pos = 2147483647
  writer.overflowed = true
  writer.write_array([b'a', b'b'], 2)
  assert_true(writer.direct_pos >= 0)
  @test.assert_eq(writer.overflowed, true)
}

///|
test "panic growing bit writer output length overflow" {
  ignore(bitwriter_output_length(2147483646, 2))
}
