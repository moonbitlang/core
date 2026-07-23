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
test "varint length constants" {
  inspect(@binary.MAX_VARINT_LEN_16, content="3")
  inspect(@binary.MAX_VARINT_LEN_32, content="5")
  inspect(@binary.MAX_VARINT_LEN_64, content="10")
}

///|
test "encode uvarint" {
  assert_eq(@binary.encode_uvarint(0UL), b"\x00")
  assert_eq(@binary.encode_uvarint(1UL), b"\x01")
  assert_eq(@binary.encode_uvarint(127UL), b"\x7f")
  assert_eq(@binary.encode_uvarint(128UL), b"\x80\x01")
  assert_eq(@binary.encode_uvarint(255UL), b"\xff\x01")
  assert_eq(@binary.encode_uvarint(256UL), b"\x80\x02")
  assert_eq(@binary.encode_uvarint(300UL), b"\xac\x02")
  assert_eq(
    @binary.encode_uvarint(0xffffffffffffffffUL),
    b"\xff\xff\xff\xff\xff\xff\xff\xff\xff\x01",
  )
}

///|
test "decode uvarint" {
  let cases = [
    (b"\x00", 0UL, 1),
    (b"\x01", 1UL, 1),
    (b"\x7f", 127UL, 1),
    (b"\x80\x01", 128UL, 2),
    (b"\xff\x01", 255UL, 2),
    (b"\x80\x02", 256UL, 2),
    (b"\xac\x02rest", 300UL, 2),
    (
      b"\xff\xff\xff\xff\xff\xff\xff\xff\xff\x01tail", 18446744073709551615UL, 10,
    ),
  ]
  for case in cases {
    let (bytes, want, want_consumed) = case
    let (got, consumed) = try! @binary.uvarint(bytes)
    assert_eq(got, want)
    assert_eq(consumed, want_consumed)
  }
}

///|
test "uvarint round trips" {
  let values = [
    0UL, 1UL, 2UL, 127UL, 128UL, 255UL, 256UL, 300UL, 16384UL, 0xffffffffffffffffUL,
  ]
  for value in values {
    let encoded = @binary.encode_uvarint(value)
    let (decoded, consumed) = try! @binary.uvarint(encoded)
    assert_eq(decoded, value)
    assert_eq(consumed, encoded.length())
  }
}

///|
test "encode varint" {
  assert_eq(@binary.encode_varint(-65L), b"\x81\x01")
  assert_eq(@binary.encode_varint(-64L), b"\x7f")
  assert_eq(@binary.encode_varint(-2L), b"\x03")
  assert_eq(@binary.encode_varint(-1L), b"\x01")
  assert_eq(@binary.encode_varint(0L), b"\x00")
  assert_eq(@binary.encode_varint(1L), b"\x02")
  assert_eq(@binary.encode_varint(2L), b"\x04")
  assert_eq(@binary.encode_varint(63L), b"\x7e")
  assert_eq(@binary.encode_varint(64L), b"\x80\x01")
  assert_eq(@binary.encode_varint(300L), b"\xd8\x04")
  assert_eq(@binary.encode_varint(-300L), b"\xd7\x04")
}

///|
test "decode varint" {
  let cases = [
    (b"\x81\x01", -65L, 2),
    (b"\x7f", -64L, 1),
    (b"\x03", -2L, 1),
    (b"\x01", -1L, 1),
    (b"\x00", 0L, 1),
    (b"\x02", 1L, 1),
    (b"\x04", 2L, 1),
    (b"\x7e", 63L, 1),
    (b"\x80\x01", 64L, 2),
    (b"\xd8\x04tail", 300L, 2),
    (b"\xd7\x04tail", -300L, 2),
  ]
  for case in cases {
    let (bytes, want, want_consumed) = case
    let (got, consumed) = try! @binary.varint(bytes)
    assert_eq(got, want)
    assert_eq(consumed, want_consumed)
  }
}

///|
test "varint round trips" {
  let values = [
    -9223372036854775808L, -300L, -65L, -64L, -2L, -1L, 0L, 1L, 2L, 63L, 64L, 300L,
    9223372036854775807L,
  ]
  for value in values {
    let encoded = @binary.encode_varint(value)
    let (decoded, consumed) = try! @binary.varint(encoded)
    assert_eq(decoded, value)
    assert_eq(consumed, encoded.length())
  }
}

///|
test "malformed varints" {
  try {
    let _ = @binary.uvarint(b"")
    panic()
  } catch {
    Malformed(_) => ()
  }
  try {
    let _ = @binary.uvarint(b"\x80")
    panic()
  } catch {
    Malformed(_) => ()
  }
  try {
    let _ = @binary.uvarint(b"\x80\x80\x80\x80\x80\x80\x80\x80\x80\x02")
    panic()
  } catch {
    Malformed(_) => ()
  }
  try {
    let _ = @binary.uvarint(b"\x80\x80\x80\x80\x80\x80\x80\x80\x80\x80")
    panic()
  } catch {
    Malformed(_) => ()
  }
  try {
    let _ = @binary.varint(b"\x80")
    panic()
  } catch {
    Malformed(_) => ()
  }
}

///|
test "Debug for Malformed" {
  try {
    let _ = @binary.uvarint(b"\x80")
    panic()
  } catch {
    err => @debug.debug_inspect(err, content="Malformed(<BytesView: [0x80]>)")
  }
}
