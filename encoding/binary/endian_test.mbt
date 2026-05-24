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
test "decode fixed-width unsigned integers" {
  inspect(try! @binary.Big.decode_uint16(b"\x12\x34"), content="4660")
  inspect(try! @binary.Little.decode_uint16(b"\x34\x12"), content="4660")
  inspect(
    try! @binary.Big.decode_uint32(b"\x12\x34\x56\x78"),
    content="305419896",
  )
  inspect(
    try! @binary.Little.decode_uint32(b"\x78\x56\x34\x12"),
    content="305419896",
  )
  inspect(
    try! @binary.Big.decode_uint64(b"\x01\x23\x45\x67\x89\xab\xcd\xef"),
    content="81985529216486895",
  )
  inspect(
    try! @binary.Little.decode_uint64(b"\xef\xcd\xab\x89\x67\x45\x23\x01"),
    content="81985529216486895",
  )
}

///|
test "decode from views with offsets" {
  inspect(try! @binary.Big.decode_uint16(b"\xff\x12\x34"[1:]), content="4660")
  inspect(
    try! @binary.Little.decode_uint32(b"\xff\x78\x56\x34\x12"[1:]),
    content="305419896",
  )
  inspect(
    try! @binary.Big.decode_uint64(b"\xff\x01\x23\x45\x67\x89\xab\xcd\xef"[1:]),
    content="81985529216486895",
  )
}

///|
test "encode fixed-width unsigned integers" {
  inspect(
    @binary.Big.encode_uint16((0x1234 : UInt16)),
    content=(
      #|b"\x124"
    ),
  )
  inspect(
    @binary.Little.encode_uint16((0x1234 : UInt16)),
    content=(
      #|b"4\x12"
    ),
  )
  inspect(
    @binary.Big.encode_uint32(0x12345678U),
    content=(
      #|b"\x124Vx"
    ),
  )
  inspect(
    @binary.Little.encode_uint32(0x12345678U),
    content=(
      #|b"xV4\x12"
    ),
  )
  inspect(
    @binary.Big.encode_uint64(0x0123456789abcdefUL),
    content=(
      #|b"\x01#Eg\x89\xab\xcd\xef"
    ),
  )
  inspect(
    @binary.Little.encode_uint64(0x0123456789abcdefUL),
    content=(
      #|b"\xef\xcd\xab\x89gE#\x01"
    ),
  )
}

///|
test "fixed-width round trips" {
  let u16_values = [
    (0 : UInt16),
    (1 : UInt16),
    (0x1234 : UInt16),
    (0xffff : UInt16),
  ]
  for value in u16_values {
    assert_eq(
      try! @binary.Big.decode_uint16(@binary.Big.encode_uint16(value)),
      value,
    )
    assert_eq(
      try! @binary.Little.decode_uint16(@binary.Little.encode_uint16(value)),
      value,
    )
  }
  let u32_values = [0U, 1U, 0x12345678U, 0xffffffffU]
  for value in u32_values {
    assert_eq(
      try! @binary.Big.decode_uint32(@binary.Big.encode_uint32(value)),
      value,
    )
    assert_eq(
      try! @binary.Little.decode_uint32(@binary.Little.encode_uint32(value)),
      value,
    )
  }
  let u64_values = [0UL, 1UL, 0x0123456789abcdefUL, 0xffffffffffffffffUL]
  for value in u64_values {
    assert_eq(
      try! @binary.Big.decode_uint64(@binary.Big.encode_uint64(value)),
      value,
    )
    assert_eq(
      try! @binary.Little.decode_uint64(@binary.Little.encode_uint64(value)),
      value,
    )
  }
}

///|
test "decode malformed fixed-width inputs" {
  try {
    let _ = @binary.Big.decode_uint16(b"\x01")
    panic()
  } catch {
    Malformed(_) => ()
  }
  try {
    let _ = @binary.Big.decode_uint32(b"\x01\x02\x03")
    panic()
  } catch {
    Malformed(_) => ()
  }
  try {
    let _ = @binary.Big.decode_uint64(b"\x01\x02\x03\x04")
    panic()
  } catch {
    Malformed(_) => ()
  }
}
