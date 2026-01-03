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
test "extract bit" {
  let bs1 = b"\x89\xab\xcd\xef"
  let bs2 : Array[Byte] = bs1.to_array()
  for i in 0..=(bs1.length() * 8 - 1) {
    assert_eq(bs1.unsafe_extract_bit(i, 1), bs2.unsafe_extract_bit(i, 1))
  }
}

///|
test "BytesView::unsafe_extract_bit_signed" {
  let view = b"\x80"[:]
  inspect(view.unsafe_extract_bit_signed(0, 1), content="-1")
}

///|
test "panic ArrayView::unsafe_extract_uint_le invalid len" {
  let arr : Array[Byte] = [b'\x01', b'\x02', b'\x03', b'\x04']
  let view = arr[:]
  view.unsafe_extract_uint_le(0, 40) |> ignore
}

///|
test "panic ArrayView::unsafe_extract_uint_be invalid len" {
  let arr : Array[Byte] = [b'\x01', b'\x02', b'\x03', b'\x04']
  let view = arr[:]
  view.unsafe_extract_uint_be(0, 40) |> ignore
}

///|
test "panic ArrayView::unsafe_extract_uint64_le invalid len" {
  let arr : Array[Byte] = [b'\x01', b'\x02', b'\x03', b'\x04']
  let view = arr[:]
  view.unsafe_extract_uint64_le(0, 80) |> ignore
}

///|
test "panic ArrayView::unsafe_extract_uint64_be invalid len" {
  let arr : Array[Byte] = [b'\x01', b'\x02', b'\x03', b'\x04']
  let view = arr[:]
  view.unsafe_extract_uint64_be(0, 80) |> ignore
}

///|
test "panic BytesView::unsafe_extract_uint_le invalid len" {
  let view = b"\x01\x02\x03\x04"[:]
  view.unsafe_extract_uint_le(0, 40) |> ignore
}

///|
test "panic BytesView::unsafe_extract_uint_be invalid len" {
  let view = b"\x01\x02\x03\x04"[:]
  view.unsafe_extract_uint_be(0, 40) |> ignore
}

///|
test "panic BytesView::unsafe_extract_uint64_le invalid len" {
  let view = b"\x01\x02\x03\x04"[:]
  view.unsafe_extract_uint64_le(0, 80) |> ignore
}

///|
test "panic BytesView::unsafe_extract_uint64_be invalid len" {
  let view = b"\x01\x02\x03\x04"[:]
  view.unsafe_extract_uint64_be(0, 80) |> ignore
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
  fn equal(a : BytesView, b : ArrayView[Byte]) raise {
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

///|
test "FixedArray extract bit" {
  let bs1 = b"\x89\xab\xcd\xef"
  let bs2 : Array[Byte] = bs1.to_array()
  let bs3 : FixedArray[Byte] = FixedArray::from_array(bs2)
  for i in 0..=(bs1.length() * 8 - 1) {
    assert_eq(bs3.unsafe_extract_bit(i, 1), bs2.unsafe_extract_bit(i, 1))
    assert_eq(bs3.unsafe_extract_bit(i, 1), bs1.unsafe_extract_bit(i, 1))
  }
}

///|
test "FixedArray extract byte" {
  let bs1 = b"\x89\xab\xcd\xef"
  let bs2 : Array[Byte] = bs1.to_array()
  let bs3 : FixedArray[Byte] = FixedArray::from_array(bs2)
  for i in 0..=(bs1.length() * 8 - 8) {
    assert_eq(bs3.unsafe_extract_byte(i, 2), bs2.unsafe_extract_byte(i, 2))
    assert_eq(bs3.unsafe_extract_byte(i, 3), bs2.unsafe_extract_byte(i, 3))
    assert_eq(bs3.unsafe_extract_byte(i, 4), bs2.unsafe_extract_byte(i, 4))
    assert_eq(bs3.unsafe_extract_byte(i, 5), bs2.unsafe_extract_byte(i, 5))
    assert_eq(bs3.unsafe_extract_byte(i, 8), bs2.unsafe_extract_byte(i, 8))
    assert_eq(bs3.unsafe_extract_byte(i, 2), bs1.unsafe_extract_byte(i, 2))
    assert_eq(bs3.unsafe_extract_byte(i, 3), bs1.unsafe_extract_byte(i, 3))
    assert_eq(bs3.unsafe_extract_byte(i, 4), bs1.unsafe_extract_byte(i, 4))
    assert_eq(bs3.unsafe_extract_byte(i, 5), bs1.unsafe_extract_byte(i, 5))
    assert_eq(bs3.unsafe_extract_byte(i, 8), bs1.unsafe_extract_byte(i, 8))
  }
}

///|
test "FixedArray extract int32" {
  let bs1 = b"\x89\xab\xcd\xef\x01\x23\x45\x67"
  let bs2 : Array[Byte] = bs1.to_array()
  let bs3 : FixedArray[Byte] = FixedArray::from_array(bs2)
  for i in 0..=(bs1.length() * 8 - 32) {
    // Test big-endian extraction
    assert_eq(
      bs3.unsafe_extract_uint_be(i, 9),
      bs2.unsafe_extract_uint_be(i, 9),
    )
    assert_eq(
      bs3.unsafe_extract_uint_be(i, 12),
      bs2.unsafe_extract_uint_be(i, 12),
    )
    assert_eq(
      bs3.unsafe_extract_uint_be(i, 16),
      bs2.unsafe_extract_uint_be(i, 16),
    )
    assert_eq(
      bs3.unsafe_extract_uint_be(i, 23),
      bs2.unsafe_extract_uint_be(i, 23),
    )
    assert_eq(
      bs3.unsafe_extract_uint_be(i, 24),
      bs2.unsafe_extract_uint_be(i, 24),
    )
    assert_eq(
      bs3.unsafe_extract_uint_be(i, 32),
      bs2.unsafe_extract_uint_be(i, 32),
    )

    // Test little-endian extraction
    assert_eq(
      bs3.unsafe_extract_uint_le(i, 9),
      bs2.unsafe_extract_uint_le(i, 9),
    )
    assert_eq(
      bs3.unsafe_extract_uint_le(i, 12),
      bs2.unsafe_extract_uint_le(i, 12),
    )
    assert_eq(
      bs3.unsafe_extract_uint_le(i, 16),
      bs2.unsafe_extract_uint_le(i, 16),
    )
    assert_eq(
      bs3.unsafe_extract_uint_le(i, 23),
      bs2.unsafe_extract_uint_le(i, 23),
    )
    assert_eq(
      bs3.unsafe_extract_uint_le(i, 24),
      bs2.unsafe_extract_uint_le(i, 24),
    )
    assert_eq(
      bs3.unsafe_extract_uint_le(i, 32),
      bs2.unsafe_extract_uint_le(i, 32),
    )

    // Also test against BytesView
    assert_eq(
      bs3.unsafe_extract_uint_be(i, 9),
      bs1.unsafe_extract_uint_be(i, 9),
    )
    assert_eq(
      bs3.unsafe_extract_uint_be(i, 12),
      bs1.unsafe_extract_uint_be(i, 12),
    )
    assert_eq(
      bs3.unsafe_extract_uint_be(i, 16),
      bs1.unsafe_extract_uint_be(i, 16),
    )
    assert_eq(
      bs3.unsafe_extract_uint_be(i, 23),
      bs1.unsafe_extract_uint_be(i, 23),
    )
    assert_eq(
      bs3.unsafe_extract_uint_be(i, 24),
      bs1.unsafe_extract_uint_be(i, 24),
    )
    assert_eq(
      bs3.unsafe_extract_uint_be(i, 32),
      bs1.unsafe_extract_uint_be(i, 32),
    )
    assert_eq(
      bs3.unsafe_extract_uint_le(i, 9),
      bs1.unsafe_extract_uint_le(i, 9),
    )
    assert_eq(
      bs3.unsafe_extract_uint_le(i, 12),
      bs1.unsafe_extract_uint_le(i, 12),
    )
    assert_eq(
      bs3.unsafe_extract_uint_le(i, 16),
      bs1.unsafe_extract_uint_le(i, 16),
    )
    assert_eq(
      bs3.unsafe_extract_uint_le(i, 23),
      bs1.unsafe_extract_uint_le(i, 23),
    )
    assert_eq(
      bs3.unsafe_extract_uint_le(i, 24),
      bs1.unsafe_extract_uint_le(i, 24),
    )
    assert_eq(
      bs3.unsafe_extract_uint_le(i, 32),
      bs1.unsafe_extract_uint_le(i, 32),
    )
  }
}

///|
test "FixedArray extract int64" {
  let bs1 = b"\x89\xab\xcd\xef\x01\x23\x45\x67\x01\x23\x45\x67\x89\xab\xcd\xef"
  let bs2 : Array[Byte] = bs1.to_array()
  let bs3 : FixedArray[Byte] = FixedArray::from_array(bs2)
  for i in 0..=(bs1.length() * 8 - 64) {
    // Test big-endian extraction
    assert_eq(
      bs3.unsafe_extract_uint64_be(i, 33),
      bs2.unsafe_extract_uint64_be(i, 33),
    )
    assert_eq(
      bs3.unsafe_extract_uint64_be(i, 40),
      bs2.unsafe_extract_uint64_be(i, 40),
    )
    assert_eq(
      bs3.unsafe_extract_uint64_be(i, 45),
      bs2.unsafe_extract_uint64_be(i, 45),
    )
    assert_eq(
      bs3.unsafe_extract_uint64_be(i, 48),
      bs2.unsafe_extract_uint64_be(i, 48),
    )
    assert_eq(
      bs3.unsafe_extract_uint64_be(i, 56),
      bs2.unsafe_extract_uint64_be(i, 56),
    )
    assert_eq(
      bs3.unsafe_extract_uint64_be(i, 64),
      bs2.unsafe_extract_uint64_be(i, 64),
    )

    // Test little-endian extraction
    assert_eq(
      bs3.unsafe_extract_uint64_le(i, 33),
      bs2.unsafe_extract_uint64_le(i, 33),
    )
    assert_eq(
      bs3.unsafe_extract_uint64_le(i, 40),
      bs2.unsafe_extract_uint64_le(i, 40),
    )
    assert_eq(
      bs3.unsafe_extract_uint64_le(i, 45),
      bs2.unsafe_extract_uint64_le(i, 45),
    )
    assert_eq(
      bs3.unsafe_extract_uint64_le(i, 48),
      bs2.unsafe_extract_uint64_le(i, 48),
    )
    assert_eq(
      bs3.unsafe_extract_uint64_le(i, 56),
      bs2.unsafe_extract_uint64_le(i, 56),
    )
    assert_eq(
      bs3.unsafe_extract_uint64_le(i, 64),
      bs2.unsafe_extract_uint64_le(i, 64),
    )

    // Also test against BytesView
    assert_eq(
      bs3.unsafe_extract_uint64_be(i, 33),
      bs1.unsafe_extract_uint64_be(i, 33),
    )
    assert_eq(
      bs3.unsafe_extract_uint64_be(i, 40),
      bs1.unsafe_extract_uint64_be(i, 40),
    )
    assert_eq(
      bs3.unsafe_extract_uint64_be(i, 45),
      bs1.unsafe_extract_uint64_be(i, 45),
    )
    assert_eq(
      bs3.unsafe_extract_uint64_be(i, 48),
      bs1.unsafe_extract_uint64_be(i, 48),
    )
    assert_eq(
      bs3.unsafe_extract_uint64_be(i, 56),
      bs1.unsafe_extract_uint64_be(i, 56),
    )
    assert_eq(
      bs3.unsafe_extract_uint64_be(i, 64),
      bs1.unsafe_extract_uint64_be(i, 64),
    )
    assert_eq(
      bs3.unsafe_extract_uint64_le(i, 33),
      bs1.unsafe_extract_uint64_le(i, 33),
    )
    assert_eq(
      bs3.unsafe_extract_uint64_le(i, 40),
      bs1.unsafe_extract_uint64_le(i, 40),
    )
    assert_eq(
      bs3.unsafe_extract_uint64_le(i, 45),
      bs1.unsafe_extract_uint64_le(i, 45),
    )
    assert_eq(
      bs3.unsafe_extract_uint64_le(i, 48),
      bs1.unsafe_extract_uint64_le(i, 48),
    )
    assert_eq(
      bs3.unsafe_extract_uint64_le(i, 56),
      bs1.unsafe_extract_uint64_le(i, 56),
    )
    assert_eq(
      bs3.unsafe_extract_uint64_le(i, 64),
      bs1.unsafe_extract_uint64_le(i, 64),
    )
  }
}

///|
test "FixedArray extract view" {
  let bs1 = b"\x89\xab\xcd\xef"
  let bs2 : Array[Byte] = bs1.to_array()
  let bs3 : FixedArray[Byte] = FixedArray::from_array(bs2)
  fn equal(a : ArrayView[Byte], b : ArrayView[Byte]) raise {
    assert_eq(a.length(), b.length())
    for i in 0..<a.length() {
      assert_eq(a[i], b[i])
    }
  }

  fn equal_with_bytes(a : ArrayView[Byte], b : BytesView) raise {
    assert_eq(a.length(), b.length())
    for i in 0..<a.length() {
      assert_eq(a[i], b[i])
    }
  }

  for i in 0..=bs1.length() {
    for j in 0..=(bs1.length() - i) {
      // Test FixedArray vs Array
      equal(
        bs3.unsafe_extract_bytesview(i * 8, j * 8),
        bs2.unsafe_extract_bytesview(i * 8, j * 8),
      )

      // Test FixedArray vs BytesView
      equal_with_bytes(
        bs3.unsafe_extract_bytesview(i * 8, j * 8),
        bs1.unsafe_extract_bytesview(i * 8, j * 8),
      )
    }
  }
}

///|
test "extract bit signed" {
  let bytes : ArrayView[Byte] = [0xAA]
  let view = bytes[:]
  inspect(view.unsafe_extract_bit_signed(0, 1), content="-1")
  inspect(view.unsafe_extract_bit_signed(1, 1), content="0")
  inspect(view.unsafe_extract_bit_signed(2, 1), content="-1")
  inspect(view.unsafe_extract_bit_signed(3, 1), content="0")
  inspect(view.unsafe_extract_bit_signed(4, 1), content="-1")
  inspect(view.unsafe_extract_bit_signed(5, 1), content="0")
  inspect(view.unsafe_extract_bit_signed(6, 1), content="-1")
  inspect(view.unsafe_extract_bit_signed(7, 1), content="0")
}

///|
test "extract bit signed extremes" {
  let bytes : ArrayView[Byte] = [0x80, 0xFF, 0x00]
  let view = bytes[:]
  inspect(view.unsafe_extract_bit_signed(0, 1), content="-1")
  inspect(view.unsafe_extract_bit_signed(7, 1), content="0")
  inspect(view.unsafe_extract_bit_signed(8, 1), content="-1")
  inspect(view.unsafe_extract_bit_signed(15, 1), content="-1")
  inspect(view.unsafe_extract_bit_signed(16, 1), content="0")
}

///|
test "extract byte signed" {
  let bs1 : BytesView = b"\x7F\xFF\x80\x00\xAA\x55"
  let bs2 : ArrayView[Byte] = [0x7F, 0xFF, 0x80, 0x00, 0xAA, 0x55]
  for i in 0..=(bs1.length() * 8 - 8) {
    assert_eq(
      bs1.unsafe_extract_byte_signed(i, 2),
      bs2.unsafe_extract_byte_signed(i, 2),
    )
    assert_eq(
      bs1.unsafe_extract_byte_signed(i, 3),
      bs2.unsafe_extract_byte_signed(i, 3),
    )
    assert_eq(
      bs1.unsafe_extract_byte_signed(i, 4),
      bs2.unsafe_extract_byte_signed(i, 4),
    )
    assert_eq(
      bs1.unsafe_extract_byte_signed(i, 5),
      bs2.unsafe_extract_byte_signed(i, 5),
    )
    assert_eq(
      bs1.unsafe_extract_byte_signed(i, 8),
      bs2.unsafe_extract_byte_signed(i, 8),
    )
  }
}

///|
test "extract int signed" {
  let bs1 : BytesView = b"\xFF\xFF\xFF\xFF\x00\x00\x00\x80\x01\x00\x00\x00"
  let bs2 : ArrayView[Byte] = [
    0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x80, 0x01, 0x00, 0x00, 0x00,
  ]
  for i in 0..=(bs1.length() * 8 - 32) {
    // Test big-endian signed extraction
    assert_eq(bs1.unsafe_extract_int_be(i, 9), bs2.unsafe_extract_int_be(i, 9))
    assert_eq(
      bs1.unsafe_extract_int_be(i, 12),
      bs2.unsafe_extract_int_be(i, 12),
    )
    assert_eq(
      bs1.unsafe_extract_int_be(i, 16),
      bs2.unsafe_extract_int_be(i, 16),
    )
    assert_eq(
      bs1.unsafe_extract_int_be(i, 23),
      bs2.unsafe_extract_int_be(i, 23),
    )
    assert_eq(
      bs1.unsafe_extract_int_be(i, 24),
      bs2.unsafe_extract_int_be(i, 24),
    )
    assert_eq(
      bs1.unsafe_extract_int_be(i, 32),
      bs2.unsafe_extract_int_be(i, 32),
    )

    // Test little-endian signed extraction
    assert_eq(bs1.unsafe_extract_int_le(i, 9), bs2.unsafe_extract_int_le(i, 9))
    assert_eq(
      bs1.unsafe_extract_int_le(i, 12),
      bs2.unsafe_extract_int_le(i, 12),
    )
    assert_eq(
      bs1.unsafe_extract_int_le(i, 16),
      bs2.unsafe_extract_int_le(i, 16),
    )
    assert_eq(
      bs1.unsafe_extract_int_le(i, 23),
      bs2.unsafe_extract_int_le(i, 23),
    )
    assert_eq(
      bs1.unsafe_extract_int_le(i, 24),
      bs2.unsafe_extract_int_le(i, 24),
    )
    assert_eq(
      bs1.unsafe_extract_int_le(i, 32),
      bs2.unsafe_extract_int_le(i, 32),
    )
  }
}

///|
test "extract int64 signed" {
  let bs1 : BytesView = b"\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x00\x00\x00\x00\x00\x00\x00\x80\x01\x00\x00\x00\x00\x00\x00\x00"
  let bs2 : ArrayView[Byte] = [
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x80, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  ]
  for i in 0..=(bs1.length() * 8 - 64) {
    // Test big-endian signed extraction
    assert_eq(
      bs1.unsafe_extract_int64_be(i, 33),
      bs2.unsafe_extract_int64_be(i, 33),
    )
    assert_eq(
      bs1.unsafe_extract_int64_be(i, 40),
      bs2.unsafe_extract_int64_be(i, 40),
    )
    assert_eq(
      bs1.unsafe_extract_int64_be(i, 48),
      bs2.unsafe_extract_int64_be(i, 48),
    )
    assert_eq(
      bs1.unsafe_extract_int64_be(i, 56),
      bs2.unsafe_extract_int64_be(i, 56),
    )
    assert_eq(
      bs1.unsafe_extract_int64_be(i, 64),
      bs2.unsafe_extract_int64_be(i, 64),
    )

    // Test little-endian signed extraction
    assert_eq(
      bs1.unsafe_extract_int64_le(i, 33),
      bs2.unsafe_extract_int64_le(i, 33),
    )
    assert_eq(
      bs1.unsafe_extract_int64_le(i, 40),
      bs2.unsafe_extract_int64_le(i, 40),
    )
    assert_eq(
      bs1.unsafe_extract_int64_le(i, 48),
      bs2.unsafe_extract_int64_le(i, 48),
    )
    assert_eq(
      bs1.unsafe_extract_int64_le(i, 56),
      bs2.unsafe_extract_int64_le(i, 56),
    )
    assert_eq(
      bs1.unsafe_extract_int64_le(i, 64),
      bs2.unsafe_extract_int64_le(i, 64),
    )
  }
}
