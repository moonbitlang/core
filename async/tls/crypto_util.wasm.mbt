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
#unsafe_skip_stub_check
#borrow(buf)
extern "wasm" fn rand_bytes_ffi(buf : FixedArray[Byte], num : Int32) -> Int32 = "moonbitlang/async" "random/fill"

///|
#internal(internal, "for internal use only")
pub fn rand_bytes(num : Int32) -> Bytes raise {
  let result = FixedArray::make(num, b'\x00')
  if rand_bytes_ffi(result, num) < 0 {
    @os_error.check_errno("@tls.rand_bytes()")
  }
  result.unsafe_reinterpret_as_bytes()
}

///|
fn sha1_rotate_left(x : Int32, n : Int32) -> Int32 {
  (x << n) | (x.reinterpret_as_uint() >> (32 - n)).reinterpret_as_int()
}

///|
/// Adapted from moonbitlang/x/crypto/sha1.mbt at commit
/// 96e498849ad8a9e6a7bfa35f7e9f4f6f2ab15e02.
#warnings("-unused_error_type")
#internal(internal, "for internal use only")
pub fn sha1(input : Bytes) -> Bytes raise {
  let old_length = input.length()
  let bits = old_length.to_uint64() * 8
  let mut new_length = (old_length / 64 + 1) * 64
  if new_length - old_length < 9 {
    new_length += 64
  }
  let bytes = FixedArray::make(new_length, b'\x00')
  bytes.blit_from_bytes(0, input, 0, old_length)
  bytes[old_length] = 0x80
  for i in (new_length - 8)..<new_length {
    bytes[i] = (bits >> (56 - (i - (new_length - 8)) * 8)).to_byte()
  }

  let h = [0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0]
  let bytes_per_chunk = 64
  let chunk_count = new_length / bytes_per_chunk
  for chunk in 0..<chunk_count {
    let words = FixedArray::make(80, 0)
    for i in 0..<16 {
      let start = chunk * bytes_per_chunk + i * 4
      words[i] = (bytes[start].to_int() << 24) |
        (bytes[start + 1].to_int() << 16) |
        (bytes[start + 2].to_int() << 8) |
        bytes[start + 3].to_int()
    }
    for i in 16..<80 {
      words[i] = sha1_rotate_left(
        words[i - 3] ^ words[i - 8] ^ words[i - 14] ^ words[i - 16],
        1,
      )
    }
    let v = h.copy()
    for i in 0..<80 {
      let (f, k) = if i < 20 {
        ((v[1] & v[2]) | (v[1].lnot() & v[3]), 0x5A827999)
      } else if i < 40 {
        (v[1] ^ v[2] ^ v[3], 0x6ED9EBA1)
      } else if i < 60 {
        ((v[1] & v[2]) | (v[1] & v[3]) | (v[2] & v[3]), 0x8F1BBCDC)
      } else {
        (v[1] ^ v[2] ^ v[3], 0xCA62C1D6)
      }
      let temp = sha1_rotate_left(v[0], 5) + f + v[4] + k + words[i]
      v[4] = v[3]
      v[3] = v[2]
      v[2] = sha1_rotate_left(v[1], 30)
      v[1] = v[0]
      v[0] = temp
    }
    for i in 0..<5 {
      h[i] += v[i]
    }
  }

  let result = FixedArray::make(20, b'\x00')
  for i in 0..<5 {
    result[i * 4] = (h[i].reinterpret_as_uint() >> 24).to_byte()
    result[i * 4 + 1] = (h[i].reinterpret_as_uint() >> 16).to_byte()
    result[i * 4 + 2] = (h[i].reinterpret_as_uint() >> 8).to_byte()
    result[i * 4 + 3] = h[i].to_byte()
  }
  result.unsafe_reinterpret_as_bytes()
}
