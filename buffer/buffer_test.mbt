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

test "length method" {
  let buf = @buffer.new(size_hint=100)
  inspect!(buf.length(), content="0")
  buf.write_string("Test")
  inspect!(buf.length(), content="8")
}

test "is_empty method" {
  let buf = @buffer.new(size_hint=100)
  inspect!(buf.is_empty(), content="true")
  buf.write_string("Test")
  inspect!(buf.is_empty(), content="false")
}

test "expect method with matching content" {
  let buf = @buffer.new(size_hint=100)
  buf.write_string("Test")
  inspect!(buf, content="Test")
}

test "expect method with non-matching content" {
  let buf = @buffer.new(size_hint=100)
  buf.write_string("Test")
  inspect!(buf, content="Test")
}

test "grow_if_necessary method" {
  let buf = @buffer.new(size_hint=10)
  buf.write_string(
    "This is a test string that is longer than the initial capacity",
  )
  assert_true!(buf.to_bytes().length() >= 60)
}

test "write_substring method" {
  let buf = @buffer.new(size_hint=10)
  buf.write_substring("Hello, World!", 7, 5)
  inspect!(buf, content="World")
}

test "write_byte method" {
  let buf = @buffer.new(size_hint=10)
  buf.write_byte(b'A')
  buf.write_byte(b'\x00')
  inspect!(buf, content="A")
}

test "to_bytes method" {
  let buf = @buffer.new(size_hint=10)
  buf.write_string("Test")
  let bytes = buf.to_bytes()
  assert_eq!(bytes.length(), 8) // Each character in "Test" is 2 bytes
}

test "expect method with non-matching content" {
  let buf = @buffer.new(size_hint=100)
  buf.write_string("Test")
  inspect!(buf, content="Test")
}

test "grow_if_necessary method" {
  let buf = @buffer.new(size_hint=10)
  buf.write_string(
    "This is a test string that is longer than the initial capacity",
  )
  assert_true!(buf.to_bytes().length() >= 60)
}

test "write_substring method" {
  let buf = @buffer.new(size_hint=10)
  buf.write_substring("Hello, World!", 7, 5)
  inspect!(buf, content="World")
}

test "write_byte method" {
  let buf = @buffer.new(size_hint=10)
  buf.write_byte(b'A')
  buf.write_byte(b'\x00')
  inspect!(buf, content="A")
}

test "to_bytes method" {
  let buf = @buffer.new(size_hint=10)
  buf.write_string("Test")
  let bytes = buf.to_bytes()
  assert_eq!(bytes.length(), 8) // Each character in "Test" is 2 bytes
}

test "expect method with matching content" {
  let buf = @buffer.new(size_hint=100)
  buf.write_string("Test")
  inspect!(buf, content="Test")
}

test "expect method with non-matching content" {
  let buf = @buffer.new(size_hint=100)
  buf.write_string("Test")
  inspect!(buf, content="Test")
}

test "grow_if_necessary method" {
  let buf = @buffer.new(size_hint=10)
  buf.write_string(
    "This is a test string that is longer than the initial capacity",
  )
  assert_true!(buf.to_bytes().length() >= 60)
}

test "write_substring method" {
  let buf = @buffer.new(size_hint=10)
  buf.write_substring("Hello, World!", 7, 5)
  inspect!(buf, content="World")
}

test "write_byte method" {
  let buf = @buffer.new(size_hint=10)
  buf.write_byte(b'A')
  buf.write_byte(b'\x00')
  inspect!(buf, content="A")
}

test "to_bytes method" {
  let buf = @buffer.new(size_hint=10)
  buf.write_string("Test")
  let bytes = buf.to_bytes()
  assert_eq!(bytes.length(), 8) // Each character in "Test" is 2 bytes
}

test "write_bytes" {
  let buf = @buffer.new(size_hint=4)
  buf.write_bytes(b"1\x002\x003\x004\x00")
  buf.write_bytes(b"5\x006\x007\x008\x00")
  inspect!(buf, content="12345678")
}

test "write_uint64 method" {
  let buf = @buffer.new(size_hint=16)
  buf.write_uint64(114)
  buf.write_uint64(514)
  assert_eq!(
    buf.to_bytes(),
    b"\x72\x00\x00\x00\x00\x00\x00\x00\x02\x02\x00\x00\x00\x00\x00\x00",
  )
}

test "write_int64 method" {
  let buf = @buffer.new(size_hint=16)
  buf.write_int64(-114)
  buf.write_int64(514)
  assert_eq!(
    buf.to_bytes(),
    b"\x8e\xff\xff\xff\xff\xff\xff\xff\x02\x02\x00\x00\x00\x00\x00\x00",
  )
}

test "write_uint method" {
  let buf = @buffer.new(size_hint=8)
  buf.write_uint(114)
  buf.write_uint(514)
  assert_eq!(buf.to_bytes(), b"\x72\x00\x00\x00\x02\x02\x00\x00")
}

test "write_int method" {
  let buf = @buffer.new(size_hint=8)
  buf.write_int(-114)
  buf.write_int(514)
  assert_eq!(buf.to_bytes(), b"\x8e\xff\xff\xff\x02\x02\x00\x00")
}

test "write_double method" {
  let buf = @buffer.new(size_hint=16)
  buf.write_double(-114)
  buf.write_double(0.514)
  assert_eq!(
    buf.to_bytes(),
    b"\x00\x00\x00\x00\x00\x80\x5c\xc0\xa6\x9b\xc4\x20\xb0\x72\xe0\x3f",
  )
}

test "write_float method" {
  let buf = @buffer.new(size_hint=8)
  buf.write_float(-114)
  buf.write_float(0.514)
  assert_eq!(buf.to_bytes(), b"\x00\x00\xe4\xc2\x81\x95\x03\x3f")
}

test "test for uint64_byte_array and reverse" {
  let test_number : UInt64 = 1145141919810
  let tested : UInt64 = test_number
    |> @buffer.uint64_to_bytes
    |> @buffer.bytes_to_uint64
  if test_number != tested {
    fail!("Not equal after bytes conversion!")
  }
}

test "test for uint_byte_array and reverse" {
  let test_number : UInt = 114514
  let tested : UInt = test_number
    |> @buffer.uint_to_bytes
    |> @buffer.bytes_to_uint
  if test_number != tested {
    fail!("Not equal after bytes conversion!")
  }
}

test "test 1 for double_byte_array and reverse" {
  let test_number : Double = 1145141919810
  let tested : Double = test_number
    |> @buffer.double_to_bytes
    |> @buffer.bytes_to_double
  if test_number != tested {
    fail!("Not equal after bytes conversion!")
  }
}

test "test 2 for double_byte_array and reverse" {
  let test_number : Double = -1145141919810
  let tested : Double = test_number
    |> @buffer.double_to_bytes
    |> @buffer.bytes_to_double
  if test_number != tested {
    fail!("Not equal after bytes conversion!")
  }
}

test "test 3 for double_byte_array and reverse" {
  let test_number : Double = 114514.1919810
  let tested : Double = test_number
    |> @buffer.double_to_bytes
    |> @buffer.bytes_to_double
  if test_number != tested {
    fail!("Not equal after bytes conversion!")
  }
}

test "test 4 for double_byte_array and reverse" {
  let test_number : Double = -114514.1919810
  let tested : Double = test_number
    |> @buffer.double_to_bytes
    |> @buffer.bytes_to_double
  if test_number != tested {
    fail!("Not equal after bytes conversion!")
  }
}

test "test 1 for float_byte_array and reverse" {
  let test_number : Float = 1145141919810
  let tested : Float = test_number
    |> @buffer.float_to_bytes
    |> @buffer.bytes_to_float
  if test_number != tested {
    fail!("Not equal after bytes conversion!")
  }
}

test "test 2 for float_byte_array and reverse" {
  let test_number : Float = -1145141919810
  let tested : Float = test_number
    |> @buffer.float_to_bytes
    |> @buffer.bytes_to_float
  if test_number != tested {
    fail!("Not equal after bytes conversion!")
  }
}

test "test 3 for float_byte_array and reverse" {
  let test_number : Float = 114514.1919810
  let tested : Float = test_number
    |> @buffer.float_to_bytes
    |> @buffer.bytes_to_float
  if test_number != tested {
    fail!("Not equal after bytes conversion!")
  }
}

test "test 4 for float_byte_array and reverse" {
  let test_number : Float = -114514.1919810
  let tested : Float = test_number
    |> @buffer.float_to_bytes
    |> @buffer.bytes_to_float
  if test_number != tested {
    fail!("Not equal after bytes conversion!")
  }
}

test "test 1 for int_byte_array and reverse" {
  let test_number : Int64 = 1145141919810
  let tested : Int64 = test_number
    |> @buffer.int64_to_bytes
    |> @buffer.bytes_to_int64
  if test_number != tested {
    fail!("Not equal after bytes conversion!")
  }
}

test "test 2 for int64_byte_array and reverse" {
  let test_number : Int64 = -1145141919810
  let tested : Int64 = test_number
    |> @buffer.int64_to_bytes
    |> @buffer.bytes_to_int64
  if test_number != tested {
    fail!("Not equal after bytes conversion!")
  }
}

test "test 1 for int_byte_array and reverse" {
  let test_number : Int = 114514
  let tested : Int = test_number |> @buffer.int_to_bytes |> @buffer.bytes_to_int
  if test_number != tested {
    fail!("Not equal after bytes conversion!")
  }
}

test "test 2 for int_byte_array and reverse" {
  let test_number : Int = -114514
  let tested : Int = test_number |> @buffer.int_to_bytes |> @buffer.bytes_to_int
  if test_number != tested {
    fail!("Not equal after bytes conversion!")
  }
}
