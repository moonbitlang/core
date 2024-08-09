// Copyright 2024 International Digital Economy Academy
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

test "to_string" {
  let bytes = Bytes::of_string("Hello, World!")
  assert_eq!(bytes.to_string(), "Hello, World!")
}

test "of_string" {
  let str = "Hello, World!"
  let bytes = Bytes::of_string(str)
  assert_eq!(bytes.length(), str.length() * 2)
}

test "sub_string" {
  let bytes = Bytes::of_string("Hello, World!")
  assert_eq!(bytes.sub_string(0, 5 * 2), "Hello")
  // assert_eq(bytes.sub_string(10, 5 * 2), "World")?
}

test "blit_from_string" {
  let bytes = Bytes::new(10)
  let str = "Hello"
  bytes.blit_from_string(0, str, 0, str.length())
  assert_eq!(bytes.sub_string(0, str.length() * 2), str)
}

test "copy" {
  let bytes = Bytes::of_string("Hello, World!")
  let copy_bytes = bytes.copy()
  assert_eq!(copy_bytes.to_string(), bytes.to_string())
}

test "set_utf8_char" {
  let bytes = Bytes::new(10)
  let char = 'A'
  let len = bytes.set_utf8_char(0, char)
  assert_eq!(len, 1)
  // FIXME: inconsistency between wasm-gc & js
  bytes.sub_string(0, 1) |> ignore
  inspect!(bytes.sub_string(0, 2), content="A")
}

test "set_utf16_char" {
  let bytes = Bytes::new(10)
  let char = 'A'
  let len = bytes.set_utf16_char(0, char)
  assert_eq!(len, 2)
  assert_eq!(bytes.sub_string(0, 2), "A")
}

test "panic sub_string with invalid byte_length" {
  let bytes = Bytes::of_string("Hello, World!")
  bytes.sub_string(0, -1) |> ignore
}

test "panic sub_string with invalid byte_offset" {
  let bytes = Bytes::of_string("Hello, World!")
  bytes.sub_string(-1, 5) |> ignore
}

test "panic sub_string with invalid byte_offset + byte_length" {
  let bytes = Bytes::of_string("Hello, World!")
  bytes.sub_string(0, bytes.length() + 1) |> ignore
}

test "panic blit_from_string with invalid length" {
  let bytes = Bytes::new(10)
  let str = "Hello"
  bytes.blit_from_string(0, str, 0, -1) |> ignore
}

test "panic blit_from_string with invalid bytes_offset" {
  let bytes = Bytes::new(10)
  let str = "Hello"
  bytes.blit_from_string(-1, str, 0, str.length()) |> ignore
}

test "panic blit_from_string with invalid str_offset" {
  let bytes = Bytes::new(10)
  let str = "Hello"
  bytes.blit_from_string(0, str, -1, str.length()) |> ignore
}

test "panic blit_from_string with invalid bytes_offset + length" {
  let bytes = Bytes::new(10)
  let str = "Hello"
  bytes.blit_from_string(0, str, 0, bytes.length() + 1) |> ignore
}

test "panic blit_from_string with invalid str_offset + length" {
  let bytes = Bytes::new(10)
  let str = "Hello"
  bytes.blit_from_string(0, str, 0, str.length() + 1) |> ignore
}

test "panic set_utf8_char with invalid code point" {
  let bytes = Bytes::new(10)
  let char = Char::from_int(0x110000)
  bytes.set_utf8_char(0, char) |> ignore
}

test "panic set_utf16_char with invalid code point" {
  let bytes = Bytes::new(10)
  let char = Char::from_int(0x110000)
  bytes.set_utf16_char(0, char) |> ignore
}

test "op_equal" {
  let bytes = Bytes::of_string("Hello, World!")
  let copy_bytes = bytes.copy()
  assert_eq!(bytes, copy_bytes)
  assert_ne!(bytes, Bytes::new(10))
}
