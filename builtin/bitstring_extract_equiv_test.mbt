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

// Equivalence sweep for the generic bitstring integer extractors: every
// (offset, len) combination — aligned and unaligned, exact-width and
// partial — is checked against a byte-composition reference built from
// `unsafe_extract_byte`, so the aligned fast paths and the outlined slow
// paths must agree with the specified bit semantics everywhere.

///|
fn extract_ref_le(read : (Int, Int) -> UInt, offset : Int, len : Int) -> UInt64 {
  let n = (len + 7) / 8
  let mut acc : UInt64 = 0
  for k in 0..<n {
    let bits = if k == n - 1 { len - 8 * k } else { 8 }
    acc = acc | (read(offset + 8 * k, bits).to_uint64() << (8 * k))
  }
  acc
}

///|
fn extract_ref_be(read : (Int, Int) -> UInt, offset : Int, len : Int) -> UInt64 {
  let n = (len + 7) / 8
  let mut acc : UInt64 = 0
  for k in 0..<n {
    let bits = if k == n - 1 { len - 8 * k } else { 8 }
    acc = (acc << bits) | read(offset + 8 * k, bits).to_uint64()
  }
  acc
}

///|
test "generic uint extraction agrees with the byte-composition reference" {
  let bytes = Bytes::makei(32, i => ((i * 37 + 11) & 0xff).to_byte())
  let arr = Array::makei(32, i => ((i * 37 + 11) & 0xff).to_byte())
  // both zero-origin views and a nonzero-origin subview, so the aligned
  // helpers' start-offset handling is exercised too
  let bv = bytes[:]
  let av = arr[:]
  let bv2 = bytes[3:]
  let av2 = arr[3:]
  let bv_read = (o : Int, l : Int) => bv.unsafe_extract_byte(o, l)
  let av_read = (o : Int, l : Int) => av.unsafe_extract_byte(o, l)
  let bv2_read = (o : Int, l : Int) => bv2.unsafe_extract_byte(o, l)
  let av2_read = (o : Int, l : Int) => av2.unsafe_extract_byte(o, l)
  for offset in 0..<=16 {
    for len in 9..<=32 {
      assert_eq(
        bv.unsafe_extract_uint_le(offset, len).to_uint64(),
        extract_ref_le(bv_read, offset, len),
      )
      assert_eq(
        bv.unsafe_extract_uint_be(offset, len).to_uint64(),
        extract_ref_be(bv_read, offset, len),
      )
      assert_eq(
        av.unsafe_extract_uint_le(offset, len).to_uint64(),
        extract_ref_le(av_read, offset, len),
      )
      assert_eq(
        av.unsafe_extract_uint_be(offset, len).to_uint64(),
        extract_ref_be(av_read, offset, len),
      )
      assert_eq(
        bv2.unsafe_extract_uint_le(offset, len).to_uint64(),
        extract_ref_le(bv2_read, offset, len),
      )
      assert_eq(
        av2.unsafe_extract_uint_be(offset, len).to_uint64(),
        extract_ref_be(av2_read, offset, len),
      )
    }
    for len in 33..<=64 {
      assert_eq(
        bv.unsafe_extract_uint64_le(offset, len),
        extract_ref_le(bv_read, offset, len),
      )
      assert_eq(
        bv.unsafe_extract_uint64_be(offset, len),
        extract_ref_be(bv_read, offset, len),
      )
      assert_eq(
        av.unsafe_extract_uint64_le(offset, len),
        extract_ref_le(av_read, offset, len),
      )
      assert_eq(
        av.unsafe_extract_uint64_be(offset, len),
        extract_ref_be(av_read, offset, len),
      )
      assert_eq(
        bv2.unsafe_extract_uint64_le(offset, len),
        extract_ref_le(bv2_read, offset, len),
      )
      assert_eq(
        av2.unsafe_extract_uint64_be(offset, len),
        extract_ref_be(av2_read, offset, len),
      )
    }
  }
}
