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
// Independent bytewise reference: every intermediate sum stays reduced.
fn adler_reference(data : BytesView) -> UInt32 {
  let mut a = 1
  let mut b = 0
  for byte in data {
    a = (a + byte.to_int()) % 65521
    b = (b + a) % 65521
  }
  (b.reinterpret_as_uint() << 16) | a.reinterpret_as_uint()
}

///|
test "Adler block reduction agrees with bytewise reference at boundaries" {
  for size in [0, 1, 3799, 3800, 3801, 7599, 7600, 7601, 65536, 1048576] {
    for byte in [b'\x00', b'\xFF'] {
      let input = Bytes::make(size, byte)
      @test.assert_eq(@checksum.adler32(input), adler_reference(input))
    }
  }
}

///|
test "Adler mixed updates and finish preserve prefix state across blocks" {
  let input = Bytes::from_array(
    Array::makei(32000, i => (i * 73 + i / 19).to_byte()),
  )
  for chunk in [1, 3799, 3800, 3801, 7601] {
    let checksum = @checksum.Adler32()
    let mut position = 0
    while position < input.length() {
      let end = (position + chunk).min(input.length())
      checksum.update(input[position:end])
      checksum.update(b"")
      // finish is non-destructive, including before a subsequent update_byte.
      if chunk > 1 || end == input.length() {
        let expected = adler_reference(input[:end])
        @test.assert_eq(checksum.finish(), expected)
        @test.assert_eq(checksum.finish(), expected)
      }
      position = end
      if position < input.length() {
        checksum.update_byte(input[position])
        position = position + 1
      }
    }
    @test.assert_eq(checksum.finish(), adler_reference(input))
  }
}

///|
test "Adler eight-byte groups agree with bytewise reference for any view" {
  let mut state = 0x9E3779B9U
  let input = Bytes::makei(9000, _ => {
    state = state * 1103515245U + 12345U
    (state >> 24).reinterpret_as_int().to_byte()
  })
  for offset in 0..<9 {
    for length in [0, 1, 7, 8, 9, 15, 16, 17, 63, 3799, 3800, 3807, 3808, 8000] {
      let view = input[offset:offset + length]
      let checksum = @checksum.Adler32()
      checksum.update(view)
      @test.assert_eq(checksum.finish(), adler_reference(view))
    }
  }
}
