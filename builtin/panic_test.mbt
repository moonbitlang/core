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
test "panic array_split_at" {
  [1].split_at(3) |> ignore
}

///|
test "panic array_split_at" {
  [1].split_at(3) |> ignore
}

///|
test "panic array_swap" {
  [1, 2, 3].swap(1, 5)
}

///|
test "panic array_swap" {
  [1, 2, 3].swap(1, 5)
}

///|
test "panic array_op_get" {
  [1, 2, 3][5] |> ignore
}

///|
test "panic array_op_get" {
  [1, 2, 3][5] |> ignore
}

///|
test "panic array_set_out_of_bounds" {
  let arr = [1, 2, 3]
  arr[3] = 4 // This should panic
}

///|
test "panic array_drain_out_of_bounds" {
  let arr = [1, 2, 3, 4, 5]
  arr.drain(3, 6) |> ignore // This should panic
}

///|
test "panic array_remove_out_of_bounds" {
  let arr = [1, 2, 3]
  arr.remove(3) |> ignore // This should panic
}

///|
test "panic array_insert_out_of_bounds" {
  let arr = [1, 2, 3]
  arr.insert(4, 42) // This should panic
}

///|
test "panic array_resize_negative" {
  let arr = [1, 2, 3]
  arr.resize(-1, 42) // This should panic
}

///|
test "panic array_as_view_start_index_error" {
  [1, 2, 3][-1:0] |> ignore
}

///|
test "panic array_as_view_end_index_error" {
  [1, 2, 3][0:-4] |> ignore
}

///|
test "panic array_as_view_length_index_error" {
  [1, 2, 3][0:4] |> ignore
}

///|
test "panic view_as_view_start_index_error" {
  [1, 2, 3][:][-1:0] |> ignore
}

///|
test "panic view_as_view_end_index_error" {
  [1, 2, 3][:][0:-4] |> ignore
}

///|
test "panic view_as_view_length_index_error" {
  [1, 2, 3][:][0:4] |> ignore
}

///|
test "panic array_as_view_get_index_error" {
  [1, 2, 3][:][5] |> ignore
}

///|
test "panic op_div coverage for division by zero" {
  let a = BigInt::from_int(123456789)
  let b = BigInt::from_int(0)
  (a / b) |> ignore
}

///|
test "panic op_mod coverage for modulo by zero" {
  let a = BigInt::from_int(123456789)
  let b = BigInt::from_int(0)
  (a % b) |> ignore
}

///|
test "panic op_shl coverage for negative shift" {
  let a = BigInt::from_int(123456789)
  (a << -1) |> ignore
}

///|
test "panic op_shr coverage for negative shift" {
  let a = BigInt::from_int(123456789)
  (a >> -1) |> ignore
}

///|
test "panic from_string coverage for empty string" {
  BigInt::from_string("") |> ignore
}

///|
test "panic from_string coverage for invalid character" {
  BigInt::from_string("123a56789") |> ignore
}

///|
test "panic from_hex coverage for empty string" {
  BigInt::from_hex("") |> ignore
}

///|
test "panic from_hex coverage for invalid character" {
  BigInt::from_hex("123g56789") |> ignore
}

///|
test "panic op_div coverage for division by zero" {
  let a = BigInt::from_int(123456789)
  let b = BigInt::from_int(0)
  (a / b) |> ignore
}

///|
test "panic op_mod coverage for modulo by zero" {
  let a = BigInt::from_int(123456789)
  let b = BigInt::from_int(0)
  (a % b) |> ignore
}

///|
test "panic op_shl coverage for negative shift" {
  let a = BigInt::from_int(123456789)
  (a << -1) |> ignore
}

///|
test "panic op_shr coverage for negative shift" {
  let a = BigInt::from_int(123456789)
  (a >> -1) |> ignore
}

///|
test "panic from_string coverage for empty string" {
  BigInt::from_string("") |> ignore
}

///|
test "panic from_string coverage for invalid character" {
  BigInt::from_string("123a56789") |> ignore
}

///|
test "panic from_hex coverage for empty string" {
  BigInt::from_hex("") |> ignore
}

///|
test "panic from_hex coverage for invalid character" {
  BigInt::from_hex("123g56789") |> ignore
}

///|
test "panic pow coverage for negative exponent" {
  4N.pow(-13N, modulus=497N) |> ignore
}

///|
test "panic pow coverage for zero modulus" {
  4N.pow(13N, modulus=0N) |> ignore
}

///|
test "panic to_octets coverage for negative length" {
  123456789N.to_octets(length=-1) |> ignore
}

///|
test "panic to_octets coverage for zero length" {
  123456789N.to_octets(length=0) |> ignore
}

///|
test "panic to_octets coverage for negative number than required" {
  (-123456789N).to_octets() |> ignore
}

///|
test "panic from_octets coverage for empty octets" {
  BigInt::from_octets(b"") |> ignore
}

///|
test "panic sub_string with invalid byte_length" {
  let bytes = b"Hello, World!"
  bytes.to_unchecked_string(offset=0, length=-1) |> ignore
}

///|
test "panic sub_string with invalid byte_offset" {
  let bytes = b"Hello, World!"
  bytes.to_unchecked_string(offset=-1, length=5) |> ignore
}

///|
test "panic sub_string with invalid byte_offset + byte_length" {
  let bytes = b"Hello, World!"
  bytes.to_unchecked_string(offset=0, length=bytes.length() + 1) |> ignore
}

///|
test "panic blit_from_string with invalid length" {
  let bytes = FixedArray::make(10, Byte::default())
  let str = "Hello"
  bytes.blit_from_string(0, str, 0, -1) |> ignore
}

///|
test "panic blit_from_string with invalid bytes_offset" {
  let bytes = FixedArray::make(10, Byte::default())
  let str = "Hello"
  bytes.blit_from_string(-1, str, 0, str.length()) |> ignore
}

///|
test "panic blit_from_string with invalid str_offset" {
  let bytes = FixedArray::make(10, Byte::default())
  let str = "Hello"
  bytes.blit_from_string(0, str, -1, str.length()) |> ignore
}

///|
test "panic blit_from_string with invalid bytes_offset + length" {
  let bytes = FixedArray::make(10, Byte::default())
  let str = "Hello"
  bytes.blit_from_string(0, str, 0, bytes.length() + 1) |> ignore
}

///|
test "panic blit_from_string with invalid str_offset + length" {
  let bytes = FixedArray::make(10, Byte::default())
  let str = "Hello"
  bytes.blit_from_string(0, str, 0, str.length() + 1) |> ignore
}

///|
test "panic set_utf16le_char with invalid code point" {
  let arr = FixedArray::makei(10, _ => b'\x00')
  let char = (0x110000).unsafe_to_char()
  arr.set_utf16le_char(0, char) |> ignore
}

///|
test "panic set_utf16be_char with invalid code point" {
  let arr = FixedArray::makei(10, _ => b'\x00')
  let char = (0x110000).unsafe_to_char()
  arr.set_utf16le_char(0, char) |> ignore
}

///|
test "panic" {
  let _ : Int = Option::None.unwrap()

}
