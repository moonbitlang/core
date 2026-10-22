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
test "match copies preserve overlap and exact output boundaries" {
  for
    distance in [
      1, 2, 3, 4, 7, 8, 15, 16, 17, 31, 32, 255, 256, 257, 258, 32768,
    ] {
    let history = Bytes::makei(distance, i => (i * 73 + i / 19).to_byte())
    // Include the 1- and 2-byte fragments created at cancellation boundaries.
    for length in 1..<=258 {
      for extra in [0, 7] {
        let storage = FixedArray::make(distance + length + extra, b'\xA5')
        storage.blit_from_bytes(0, history, 0, distance)
        let out = DecodeOutput::into(storage)
        out.length = distance
        out.append_repeated_suffix(distance, length)
        @test.assert_eq(out.length, distance + length)
        for i in 0..<length {
          @test.assert_eq(storage[distance + i], history[i % distance])
        }
        for i in (distance + length)..<storage.length() {
          @test.assert_eq(storage[i], b'\xA5')
        }
      }
    }
  }
}

///|
test "optimized matches stop exactly at cancellation boundaries" {
  for pattern in [b"R", b"abc", b"a longer repeated pattern"] {
    let source = Bytes::makei(9000, i => pattern[i % pattern.length()])
    let mut calls = 0
    let decoder = MemDecoder(deflate_all(source), () => {
      calls += 1
      calls == 2
    })
    let err = @test.expect_error(() => decoder.run())
    guard err is InflateError(kind, _)
    @test.assert_eq(kind, Cancelled)
    @test.assert_eq(calls, 2)
    @test.assert_eq(decoder.out.length, 4096)
    @test.assert_eq(decoder.out.to_bytes(), source[:4096].to_owned())
  }
}

///|
test "decoded matches preserve exact capacity overlap and cancellation cadence" {
  for code in 257..<286 {
    let info = length_code_info_table[code - 257]
    let extra_bits = info & 7
    for extra in [0, (1 << extra_bits) - 1] {
      let length = (info >> 3) + extra
      for pair in [(1, 0), (2, 16), (3, 8), (4, 24)] {
        let (distance, distance_bits) = pair
        for cancel_after in [1, length, length + 1] {
          for spare in [0, 7] {
            let storage = FixedArray::make(4 + length + spare, b'\xA5')
            storage.blit_from_bytes(0, b"abcd", 0, 4)
            let mut calls = 0
            let d = MemDecoder(b"", () => {
              calls += 1
              false
            })
            d.out = DecodeOutput::into(storage)
            d.out.length = 4
            d.next_cancel = 4 + cancel_after
            d.bitbuf = (extra | (distance_bits << extra_bits)).reinterpret_as_uint()
            d.bit_count = extra_bits + 5
            d.decode_match(code, None)
            @test.assert_eq(d.out.length, 4 + length)
            @test.assert_eq(calls, if cancel_after <= length { 1 } else { 0 })
            for i in 0..<length {
              @test.assert_eq(
                storage[4 + i],
                b"abcd"[4 - distance + i % distance],
              )
            }
            for i in (4 + length)..<storage.length() {
              @test.assert_eq(storage[i], b'\xA5')
            }
          }
        }
      }
    }
  }
}

///|
test "decoded short matches reject insufficient capacity before copying" {
  for length in 3..<=10 {
    let storage = FixedArray::make(length, b'x')
    let d = MemDecoder(b"", () => false)
    d.out = DecodeOutput::into(storage)
    d.out.length = 1
    d.next_cancel = 4096
    d.bit_count = 5 // fixed distance symbol 0: distance 1
    let err = @test.expect_error(() => d.decode_match(length + 254, None))
    guard err is InflateError(kind, _)
    @test.assert_eq(kind, OutputLimitExceeded)
    @test.assert_eq(d.out.length, 1)
    for byte in storage {
      @test.assert_eq(byte, b'x')
    }
  }
}
