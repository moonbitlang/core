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
test "Bytes::unsafe_read_uint64_le basic functionality" {
  // Test with known byte pattern
  let data : Bytes = b"\x01\x02\x03\x04\x05\x06\x07\x08"
  let result = data.unsafe_read_uint64_le(0)
  inspect(result, content="578437695752307201") // 0x0807060504030201UL

  // Test with all zeros
  let zeros : Bytes = b"\x00\x00\x00\x00\x00\x00\x00\x00"
  let zero_result = zeros.unsafe_read_uint64_le(0)
  inspect(zero_result, content="0")

  // Test with all ones (255 in each byte)
  let ones : Bytes = b"\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF"
  let ones_result = ones.unsafe_read_uint64_le(0)
  inspect(ones_result, content="18446744073709551615") // 0xFFFFFFFFFFFFFFFFUL
}

///|
test "Bytes::unsafe_read_uint64_be basic functionality" {
  // Test with known byte pattern
  let data : Bytes = b"\x01\x02\x03\x04\x05\x06\x07\x08"
  let result = data.unsafe_read_uint64_be(0)
  inspect(result, content="72623859790382856") // 0x0102030405060708UL

  // Test with zeros
  let zeros : Bytes = b"\x00\x00\x00\x00\x00\x00\x00\x00"
  let zero_result = zeros.unsafe_read_uint64_be(0)
  inspect(zero_result, content="0")

  // Test with different pattern
  let data2 : Bytes = b"\xFF\x00\xFF\x00\xFF\x00\xFF\x00"
  let result2 = data2.unsafe_read_uint64_be(0)
  inspect(result2, content="18374966859414961920") // 0xFF00FF00FF00FF00UL
}

///|
test "Bytes::unsafe_read_uint32_le basic functionality" {
  // Test with known byte pattern
  let data : Bytes = b"\x01\x02\x03\x04"
  let result = data.unsafe_read_uint32_le(0)
  inspect(result, content="67305985") // 0x04030201U

  // Test with zeros
  let zeros : Bytes = b"\x00\x00\x00\x00"
  let zero_result = zeros.unsafe_read_uint32_le(0)
  inspect(zero_result, content="0")

  // Test with maximum value
  let max_bytes : Bytes = b"\xFF\xFF\xFF\xFF"
  let max_result = max_bytes.unsafe_read_uint32_le(0)
  inspect(max_result, content="4294967295") // 0xFFFFFFFFU
}

///|
test "Bytes::unsafe_read_uint32_be basic functionality" {
  // Test with known byte pattern
  let data : Bytes = b"\x01\x02\x03\x04"
  let result = data.unsafe_read_uint32_be(0)
  inspect(result, content="16909060") // 0x01020304U

  // Test with alternating pattern
  let alt_data : Bytes = b"\xFF\x00\xFF\x00"
  let alt_result = alt_data.unsafe_read_uint32_be(0)
  inspect(alt_result, content="4278255360") // 0xFF00FF00U
}

///|
test "Bytes::unsafe_read_uint16_le basic functionality" {
  // Test with known byte pattern
  let data : Bytes = b"\x01\x02"
  let result = data.unsafe_read_uint16_le(0)
  inspect(result, content="513") // 0x0201U16

  // Test with zeros
  let zeros : Bytes = b"\x00\x00"
  let zero_result = zeros.unsafe_read_uint16_le(0)
  inspect(zero_result, content="0")

  // Test with maximum value
  let max_bytes : Bytes = b"\xFF\xFF"
  let max_result = max_bytes.unsafe_read_uint16_le(0)
  inspect(max_result, content="65535") // 0xFFFFU16
}

///|
test "Bytes::unsafe_read_uint16_be basic functionality" {
  // Test with known byte pattern
  let data : Bytes = b"\x01\x02"
  let result = data.unsafe_read_uint16_be(0)
  inspect(result, content="258") // 0x0102U16

  // Test with alternating pattern
  let alt_data : Bytes = b"\xFF\x00"
  let alt_result = alt_data.unsafe_read_uint16_be(0)
  inspect(alt_result, content="65280") // 0xFF00U16
}

///|
test "Bytes unsafe read functions with different offsets" {
  // Create data with different values at each position
  let data : Bytes = b"\x10\x20\x30\x40\x50\x60\x70\x80\x90\xA0\xB0\xC0\xD0\xE0\xF0\x11"

  // Test UInt64 at different offsets
  let uint64_0 = data.unsafe_read_uint64_le(0)
  let uint64_1 = data.unsafe_read_uint64_le(1)
  let uint64_8 = data.unsafe_read_uint64_le(8)
  inspect(uint64_0, content="9255003132036915216") // 0x8070605040302010UL
  inspect(uint64_1, content="10412445897446141984") // 0x9080706050403020UL  
  inspect(uint64_8, content="1292780280245952656") // 0x11F0E0D0C0B0A090UL

  // Test UInt32 at different offsets
  let uint32_0 = data.unsafe_read_uint32_le(0)
  let uint32_4 = data.unsafe_read_uint32_le(4)
  let uint32_12 = data.unsafe_read_uint32_le(12)
  inspect(uint32_0, content="1076895760") // 0x40302010U
  inspect(uint32_4, content="2154848336") // 0x80706050U
  inspect(uint32_12, content="300998864") // 0x11F0E0D0U

  // Test UInt16 at different offsets
  let uint16_0 = data.unsafe_read_uint16_le(0)
  let uint16_2 = data.unsafe_read_uint16_le(2)
  let uint16_14 = data.unsafe_read_uint16_le(14)
  inspect(uint16_0, content="8208") // 0x2010U16
  inspect(uint16_2, content="16432") // 0x4030U16
  inspect(uint16_14, content="4592") // 0x11F0U16
}

///|
test "BytesView::unsafe_read_uint64_le basic functionality" {
  // Create a larger buffer and test reading from a view
  let data : Bytes = b"\x00\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0A"
  let view = data[2:10] // Skip first 2 bytes, take 8 bytes
  let result = view.unsafe_read_uint64_le(0)
  inspect(result, content="578437695752307201") // 0x0807060504030201UL

  // Test reading with offset within the view
  let view2 = data[0:12]
  let result2 = view2.unsafe_read_uint64_le(2) // Start from position 2 in the view
  inspect(result2, content="578437695752307201") // Same value as above
}

///|
test "BytesView::unsafe_read_uint64_be basic functionality" {
  let data : Bytes = b"\x00\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0A"
  let view = data[2:10]
  let result = view.unsafe_read_uint64_be(0)
  inspect(result, content="72623859790382856") // 0x0102030405060708UL
}

///|
test "BytesView::unsafe_read_uint32_le basic functionality" {
  let data : Bytes = b"\x00\x00\x01\x02\x03\x04\x05\x06"
  let view = data[2:6]
  let result = view.unsafe_read_uint32_le(0)
  inspect(result, content="67305985") // 0x04030201U
}

///|
test "BytesView::unsafe_read_uint32_be basic functionality" {
  let data : Bytes = b"\x00\x00\x01\x02\x03\x04\x05\x06"
  let view = data[2:6]
  let result = view.unsafe_read_uint32_be(0)
  inspect(result, content="16909060") // 0x01020304U
}

///|
test "BytesView::unsafe_read_uint16_le basic functionality" {
  let data : Bytes = b"\x00\x00\x01\x02\x03\x04"
  let view = data[2:4]
  let result = view.unsafe_read_uint16_le(0)
  inspect(result, content="513") // 0x0201U16
}

///|
test "BytesView::unsafe_read_uint16_be basic functionality" {
  let data : Bytes = b"\x00\x00\x01\x02\x03\x04"
  let view = data[2:4]
  let result = view.unsafe_read_uint16_be(0)
  inspect(result, content="258") // 0x0102U16
}

///|
test "Edge cases with single byte values" {
  // Test with single byte repeated
  let data_0x01 : Bytes = b"\x01\x01\x01\x01\x01\x01\x01\x01"
  let result_le = data_0x01.unsafe_read_uint64_le(0)
  let result_be = data_0x01.unsafe_read_uint64_be(0)
  inspect(result_le, content="72340172838076673") // 0x0101010101010101UL
  inspect(result_be, content="72340172838076673") // Same for both endianness when all bytes are the same

  // Test with 0x80 (high bit set)
  let data_0x80 : Bytes = b"\x80\x80\x80\x80"
  let result32_le = data_0x80.unsafe_read_uint32_le(0)
  let result32_be = data_0x80.unsafe_read_uint32_be(0)
  inspect(result32_le, content="2155905152") // 0x80808080U
  inspect(result32_be, content="2155905152") // Same value
}

///|
test "Mixed endianness comparison" {
  // Use a pattern where endianness makes a clear difference
  let data : Bytes = b"\x12\x34\x56\x78\x9A\xBC\xDE\xF0"
  let le_64 = data.unsafe_read_uint64_le(0)
  let be_64 = data.unsafe_read_uint64_be(0)
  inspect(le_64, content="17356517385562371090") // 0xF0DEBC9A78563412UL
  inspect(be_64, content="1311768467463790320") // 0x123456789ABCDEF0UL
  let le_32 = data.unsafe_read_uint32_le(0)
  let be_32 = data.unsafe_read_uint32_be(0)
  inspect(le_32, content="2018915346") // 0x78563412U
  inspect(be_32, content="305419896") // 0x12345678U
  let le_16 = data.unsafe_read_uint16_le(0)
  let be_16 = data.unsafe_read_uint16_be(0)
  inspect(le_16, content="13330") // 0x3412U16
  inspect(be_16, content="4660") // 0x1234U16
}
