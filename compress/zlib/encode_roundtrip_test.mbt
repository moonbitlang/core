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
fn roundtrip_input(size : Int32, seed : UInt32, alphabet : Int32) -> Bytes {
  let mut state = seed
  Bytes::makei(size, _ => {
    state = state * 1103515245U + 12345U
    let r = ((state >> 16) & 0x7FFFU).reinterpret_as_int()
    // Small alphabets compress; the full byte range exercises Adler-32 sums.
    if r % 7 == 0 {
      b' '
    } else {
      (0x41 + r % alphabet).to_byte()
    }
  })
}

///|
/// The PDF-writer driving pattern: one `Finish` step per call with a fixed
/// 32 KiB output window, re-presenting the unconsumed suffix.
fn roundtrip_zlib_stream(
  input : Bytes,
  level : Int32,
  out_chunk : Int32,
) -> Bytes {
  roundtrip_zlib_drive(Encoder(level~), input, out_chunk)
}

///|
fn roundtrip_zlib_drive(
  encoder : @zlib.Encoder,
  input : Bytes,
  out_chunk : Int32,
) -> Bytes {
  let out = FixedArray::make(out_chunk, b'\x00')
  let result = Buffer()
  for pos = 0 {
    let status_result = encoder.step(input[pos:], out.mut_view(), action=Finish)
    let status = status_result.status
    for i in 0..<status_result.produced {
      result.write_byte(out[i])
    }
    if status is Done {
      break result.to_bytes()
    }
    continue pos + status_result.consumed
  }
}

///|
test "zlib encoder round trips" {
  for
    data in [
      b"",
      b"\xff",
      roundtrip_input(70000, 1, 20),
      roundtrip_input(50000, 2, 190),
      roundtrip_input(200000, 3, 6),
    ] {
    for level in [0, 1, 6, 9] {
      assert_eq(@zlib.decompress(@zlib.compress(data, level~)), data)
      assert_eq(
        @zlib.decompress(roundtrip_zlib_stream(data, level, 32768)),
        data,
      )
    }
    assert_eq(@zlib.decompress(roundtrip_zlib_stream(data, 6, 17)), data)
  }
}

///|
test "zlib reset streams are identical to fresh encoders" {
  let first = roundtrip_input(90000, 4, 30)
  let second = roundtrip_input(70000, 5, 12)
  let dictionary = roundtrip_input(40000, 6, 12)
  for level in 0..<=9 {
    for dict in [None, Some(dictionary[:]), Some(dictionary[:100])] {
      let fresh = roundtrip_zlib_drive(
        Encoder(level~, dictionary?=dict),
        second,
        4096,
      )
      // Reuse after a finished stream, and after an abandoned partial one.
      let finished = @zlib.Encoder(level~)
      ignore(roundtrip_zlib_drive(finished, first, 32768))
      finished.reset(dictionary?=dict)
      assert_eq(roundtrip_zlib_drive(finished, second, 4096), fresh)
      let abandoned = @zlib.Encoder(level~, dictionary~)
      let out = FixedArray::make(100, b'\x00')
      ignore(abandoned.step(first[:50000], out.mut_view()))
      abandoned.reset(dictionary?=dict)
      assert_eq(roundtrip_zlib_drive(abandoned, second, 4096), fresh)
    }
  }
}
