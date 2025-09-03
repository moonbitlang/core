// Copyright 2025 International Digital Economy Academy
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
test "extract bit" {
  let bs1 = b"\x89\xab\xcd\xef"
  let bs2 : Array[Byte] = bs1.to_array()
  for i in 0..=(bs1.length() * 8 - 1) {
    assert_eq(bs1.unsafe_extract_bit(i, 1), bs2.unsafe_extract_bit(i, 1))
  }
}

///|
test "extract byte" {
  let bs1 = b"\x89\xab\xcd\xef"
  let bs2 : Array[Byte] = bs1.to_array()
  for i in 0..=(bs1.length() * 8 - 8) {
    assert_eq(bs1.unsafe_extract_byte(i, 2), bs2.unsafe_extract_byte(i, 2))
    assert_eq(bs1.unsafe_extract_byte(i, 3), bs2.unsafe_extract_byte(i, 3))
    assert_eq(bs1.unsafe_extract_byte(i, 4), bs2.unsafe_extract_byte(i, 4))
    assert_eq(bs1.unsafe_extract_byte(i, 5), bs2.unsafe_extract_byte(i, 5))
    assert_eq(bs1.unsafe_extract_byte(i, 8), bs2.unsafe_extract_byte(i, 8))
  }
}

///|
test "extract int32" {
  let bs1 = b"\x89\xab\xcd\xef\x01\x23\x45\x67"
  let bs2 : Array[Byte] = bs1.to_array()
  for i in 0..=(bs1.length() * 8 - 32) {
    assert_eq(
      bs1.unsafe_extract_uint_be(i, 9),
      bs2.unsafe_extract_uint_be(i, 9),
    )
    assert_eq(
      bs1.unsafe_extract_uint_be(i, 12),
      bs2.unsafe_extract_uint_be(i, 12),
    )
    assert_eq(
      bs1.unsafe_extract_uint_be(i, 16),
      bs2.unsafe_extract_uint_be(i, 16),
    )
    assert_eq(
      bs1.unsafe_extract_uint_be(i, 23),
      bs2.unsafe_extract_uint_be(i, 23),
    )
    assert_eq(
      bs1.unsafe_extract_uint_be(i, 24),
      bs2.unsafe_extract_uint_be(i, 24),
    )
    assert_eq(
      bs1.unsafe_extract_uint_be(i, 32),
      bs2.unsafe_extract_uint_be(i, 32),
    )
    assert_eq(
      bs1.unsafe_extract_uint_le(i, 9),
      bs2.unsafe_extract_uint_le(i, 9),
    )
    assert_eq(
      bs1.unsafe_extract_uint_le(i, 12),
      bs2.unsafe_extract_uint_le(i, 12),
    )
    assert_eq(
      bs1.unsafe_extract_uint_le(i, 16),
      bs2.unsafe_extract_uint_le(i, 16),
    )
    assert_eq(
      bs1.unsafe_extract_uint_le(i, 23),
      bs2.unsafe_extract_uint_le(i, 23),
    )
    assert_eq(
      bs1.unsafe_extract_uint_le(i, 24),
      bs2.unsafe_extract_uint_le(i, 24),
    )
    assert_eq(
      bs1.unsafe_extract_uint_le(i, 32),
      bs2.unsafe_extract_uint_le(i, 32),
    )
  }
}

///|
test "extract int64" {
  let bs1 = b"\x89\xab\xcd\xef\x01\x23\x45\x67\x01\x23\x45\x67\x89\xab\xcd\xef"
  let bs2 : Array[Byte] = bs1.to_array()
  for i in 0..=(bs1.length() * 8 - 64) {
    assert_eq(
      bs1.unsafe_extract_uint64_be(i, 33),
      bs2.unsafe_extract_uint64_be(i, 33),
    )
    assert_eq(
      bs1.unsafe_extract_uint64_be(i, 40),
      bs2.unsafe_extract_uint64_be(i, 40),
    )
    assert_eq(
      bs1.unsafe_extract_uint64_be(i, 45),
      bs2.unsafe_extract_uint64_be(i, 45),
    )
    assert_eq(
      bs1.unsafe_extract_uint64_be(i, 48),
      bs2.unsafe_extract_uint64_be(i, 48),
    )
    assert_eq(
      bs1.unsafe_extract_uint64_be(i, 56),
      bs2.unsafe_extract_uint64_be(i, 56),
    )
    assert_eq(
      bs1.unsafe_extract_uint64_be(i, 64),
      bs2.unsafe_extract_uint64_be(i, 64),
    )
    assert_eq(
      bs1.unsafe_extract_uint64_le(i, 33),
      bs2.unsafe_extract_uint64_le(i, 33),
    )
    assert_eq(
      bs1.unsafe_extract_uint64_le(i, 40),
      bs2.unsafe_extract_uint64_le(i, 40),
    )
    assert_eq(
      bs1.unsafe_extract_uint64_le(i, 45),
      bs2.unsafe_extract_uint64_le(i, 45),
    )
    assert_eq(
      bs1.unsafe_extract_uint64_le(i, 48),
      bs2.unsafe_extract_uint64_le(i, 48),
    )
    assert_eq(
      bs1.unsafe_extract_uint64_le(i, 56),
      bs2.unsafe_extract_uint64_le(i, 56),
    )
    assert_eq(
      bs1.unsafe_extract_uint64_le(i, 64),
      bs2.unsafe_extract_uint64_le(i, 64),
    )
  }
}

///|
test "extract view" {
  let bs1 = b"\x89\xab\xcd\xef"
  let bs2 : Array[Byte] = bs1.to_array()
  fn equal(a : @bytes.View, b : ArrayView[Byte]) raise {
    assert_eq(a.length(), b.length())
    for i in 0..<a.length() {
      assert_eq(a[i], b[i])
    }
  }

  for i in 0..=bs1.length() {
    for j in 0..=(bs1.length() - i) {
      equal(
        bs1.unsafe_extract_bytesview(i * 8, j * 8),
        bs2.unsafe_extract_bytesview(i * 8, j * 8),
      )
    }
  }
}
