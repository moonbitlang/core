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
/// Public gzip/deflate vectors in this file come from zlib's `test/infcover.c`
/// in the `madler/zlib` repository.

///|
fn add_metadata(deflate : Bytes, crc32 : UInt32, input_size : UInt32) -> Bytes {
  let trailer = FixedArray::make(8, b'\x00')
  trailer.unsafe_write_uint32_le(0, crc32)
  trailer.unsafe_write_uint32_le(4, input_size)
  b"\x1f\x8b\x08\x00\x00\x00\x00\x00\x00\xff" +
  deflate +
  trailer.unsafe_reinterpret_as_bytes()
}

///|
test "zlib infcover stored block" {
  let compressed = add_metadata(b"\x01\x01\x00\xfe\xff\x00", 3523407757U, 1U)
  let decoded = decode(compressed, expected_len=1)
  let decoded_min = decode(compressed, expected_len=1, input_step=Min)
  assert_eq(decoded, b"\x00")
  assert_eq(decoded_min, b"\x00")
  assert_eq(decode(encode(decoded), expected_len=1), decoded)
}

///|
test "zlib infcover fixed huffman block" {
  let compressed = add_metadata(b"\x03\x00", 0U, 0U)
  let decoded = decode(compressed, expected_len=0)
  let decoded_min = decode(compressed, expected_len=0, input_step=Min)
  assert_eq(decoded, b"")
  assert_eq(decoded_min, b"")
  assert_eq(decode(encode(decoded), expected_len=0), decoded)
}

///|
test "zlib infcover invalid stored block lengths" {
  let compressed = add_metadata(b"\x00\x00\x00\x00\x00", 0U, 0U)
  @test.assert_raise(() => decode(compressed, expected_len=0))
  @test.assert_raise(() => decode(compressed, expected_len=0, input_step=Min))
}

///|
test "zlib infcover invalid block type" {
  let compressed = add_metadata(b"\x06", 0U, 0U)
  @test.assert_raise(() => decode(compressed, expected_len=0))
  @test.assert_raise(() => decode(compressed, expected_len=0, input_step=Min))
}

///|
test "zlib infcover gzip optional header fields rejected" {
  let compressed = b"\x1f\x8b\x08\x02\x00\x00\x00\x00\x00\x00\x1d\x26\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00"
  @test.assert_raise(() => decode(compressed, expected_len=0))
  @test.assert_raise(() => decode(compressed, expected_len=0, input_step=Min))
}

///|
test "zlib infcover dynamic huffman length extra" {
  let compressed = add_metadata(
    b"\xed\xc0\x01\x01\x00\x00\x00\x40\x20\xff\x57\x1b\x42\x2c\x4f", 2893183767U,
    516U,
  )
  let decoded = decode(compressed, expected_len=516)
  let decoded_min = decode(compressed, expected_len=516, input_step=Min)
  inspect(decoded.length(), content="516")
  assert_eq(decoded_min.length(), 516)
  assert_eq(decoded_min, decoded)
  assert_eq(decode(encode(decoded), expected_len=516), decoded)
}

///|
test "zlib infcover dynamic huffman window end" {
  let compressed = add_metadata(
    b"\xed\xc0\x81\x00\x00\x00\x00\x80\xa0\xfd\xa9\x17\xa9\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x06",
    4130011695U, 33025U,
  )
  let decoded = decode(compressed, expected_len=33025)
  let decoded_min = decode(compressed, expected_len=33025, input_step=Min)
  inspect(decoded.length(), content="33025")
  assert_eq(decoded_min.length(), 33025)
  assert_eq(decoded_min, decoded)
  assert_eq(decode(encode(decoded), expected_len=33025), decoded)
}
