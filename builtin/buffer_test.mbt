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

test "expect method with matching content" {
  let buf = Buffer::new(size_hint=100)
  buf.write_string("Test")
  buf.expect!(content="Test")
}

test "expect method with non-matching content" {
  let buf = Buffer::new(size_hint=100)
  buf.write_string("Test")
  buf.expect!(content="Test")
}

test "grow_if_necessary method" {
  let buf = Buffer::new(size_hint=10)
  buf.write_string(
    "This is a test string that is longer than the initial capacity",
  )
  @test.is_true!(buf.to_bytes().length() >= 60)
}

test "write_sub_string method" {
  let buf = Buffer::new(size_hint=10)
  buf.write_sub_string("Hello, World!", 7, 5)
  buf.expect!(content="World")
}

test "write_byte method" {
  let buf = Buffer::new(size_hint=10)
  buf.write_byte(b'A')
  buf.write_byte(b'\x00')
  buf.expect!(content="A")
}

test "to_bytes method" {
  let buf = Buffer::new(size_hint=10)
  buf.write_string("Test")
  let bytes = buf.to_bytes()
  @test.eq!(bytes.length(), 8) // Each character in "Test" is 2 bytes
}

test "expect method with non-matching content" {
  let buf = Buffer::new(size_hint=100)
  buf.write_string("Test")
  buf.expect!(content="Test")
}

test "grow_if_necessary method" {
  let buf = Buffer::new(size_hint=10)
  buf.write_string(
    "This is a test string that is longer than the initial capacity",
  )
  @test.is_true!(buf.to_bytes().length() >= 60)
}

test "write_sub_string method" {
  let buf = Buffer::new(size_hint=10)
  buf.write_sub_string("Hello, World!", 7, 5)
  buf.expect!(content="World")
}

test "write_byte method" {
  let buf = Buffer::new(size_hint=10)
  buf.write_byte(b'A')
  buf.write_byte(b'\x00')
  buf.expect!(content="A")
}

test "to_bytes method" {
  let buf = Buffer::new(size_hint=10)
  buf.write_string("Test")
  let bytes = buf.to_bytes()
  @test.eq!(bytes.length(), 8) // Each character in "Test" is 2 bytes
}

test "expect method with matching content" {
  let buf = Buffer::new(size_hint=100)
  buf.write_string("Test")
  buf.expect!(content="Test")
}

test "expect method with non-matching content" {
  let buf = Buffer::new(size_hint=100)
  buf.write_string("Test")
  buf.expect!(content="Test")
}

test "grow_if_necessary method" {
  let buf = Buffer::new(size_hint=10)
  buf.write_string(
    "This is a test string that is longer than the initial capacity",
  )
  @test.is_true!(buf.to_bytes().length() >= 60)
}

test "write_sub_string method" {
  let buf = Buffer::new(size_hint=10)
  buf.write_sub_string("Hello, World!", 7, 5)
  buf.expect!(content="World")
}

test "write_byte method" {
  let buf = Buffer::new(size_hint=10)
  buf.write_byte(b'A')
  buf.write_byte(b'\x00')
  buf.expect!(content="A")
}

test "to_bytes method" {
  let buf = Buffer::new(size_hint=10)
  buf.write_string("Test")
  let bytes = buf.to_bytes()
  @test.eq!(bytes.length(), 8) // Each character in "Test" is 2 bytes
}

test "write_bytes" {
  let buf = Buffer::new(size_hint=4)
  buf.write_bytes(b"1\x002\x003\x004\x00")
  buf.write_bytes(b"5\x006\x007\x008\x00")
  buf.expect!(content="12345678")
}

test "write_buffer" {
  let buf = Buffer::new()
  let other = Buffer::new()
  let empty = Buffer::new(size_hint=100)
  other.write_bytes(b"1\x002\x003\x00")
  buf.write_buffer(other)
  buf.write_buffer(other)
  buf.write_buffer(empty)
  buf.expect!(content="123123")
  @test.eq!(buf.to_bytes().length(), 12)
}

test "iter" {
  let buf = Buffer::new(size_hint=100)
  buf.write_bytes(b"0123456789")
  let array = buf.iter().collect()
  for i = 0; i < array.length(); i = i + 1 {
    @test.eq!(array[i], (0x30 + i).to_byte())
  }
}
