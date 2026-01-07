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
test "basic1" {
  let bs = b"\x00\x01\x02\x03\x04\x05"
  let bv1 = bs[1:4]
  let bv2 = bs[:]
  let bv3 = bs[1:]
  let bv4 = bs[:4]
  inspect(bv1, content="b\"\\x01\\x02\\x03\"")
  inspect(bv2, content="b\"\\x00\\x01\\x02\\x03\\x04\\x05\"")
  inspect(bv3, content="b\"\\x01\\x02\\x03\\x04\\x05\"")
  inspect(bv4, content="b\"\\x00\\x01\\x02\\x03\"")
  @json.inspect(bv1, content="\\x01\\x02\\x03")
  @json.inspect(b"abc"[:], content="abc")
}

///|
test "basic2" {
  let bs = b"\x00\x01\x02\x03\x04\x05\x06\x07"
  let bv = bs[1:7]
  let bv1 = bv[1:4]
  let bv2 = bv[:4]
  let bv3 = bv[1:]
  let bv4 = bv[:]
  inspect(bv, content="b\"\\x01\\x02\\x03\\x04\\x05\\x06\"")
  inspect(bv1, content="b\"\\x02\\x03\\x04\"")
  inspect(bv2, content="b\"\\x01\\x02\\x03\\x04\"")
  inspect(bv3, content="b\"\\x02\\x03\\x04\\x05\\x06\"")
  inspect(bv4, content="b\"\\x01\\x02\\x03\\x04\\x05\\x06\"")
}

///|
test "basic3" {
  let bs = b"\x00"
  let bv = bs[0:0]
  inspect(bv, content="b\"\"")
}

///|
test "panic invalid index1" {
  let bs = b"\x00\x01\x02\x03\x04\x05"
  let _ = bs[-7:]

}

///|
test "panic invalid index2" {
  let bs = b"\x00\x01\x02\x03\x04\x05"
  let _ = bs[:7]

}

///|
test "panic invalid index3" {
  let bs = b"\x00\x01\x02\x03\x04\x05"
  let _ = bs[3:2]

}

///|
test "panic invalid index4" {
  let bs = b"\x00\x01\x02\x03\x04\x05"[:]
  let _ = bs[:-7]

}

///|
test "panic invalid index5" {
  let bs = b"\x00\x01\x02\x03\x04\x05"[:]
  let _ = bs[7:]

}

///|
test "panic invalid index6" {
  let bs = b"\x00\x01\x02\x03\x04\x05"[:1]
  let _ = bs[:2]

}

///|
test "iter" {
  let bs = b"\x00\x01\x02\x03\x04\x05"
  let bv = bs[:]
  inspect(
    bv.iter().to_array(),
    content="[b'\\x00', b'\\x01', b'\\x02', b'\\x03', b'\\x04', b'\\x05']",
  )
}

///|
test "iter2" {
  let bs = b"\x00\x01\x02\x03\x04\x05"
  let bv = bs[1:5]
  inspect(
    bv.iter2(),
    content="[(0, b'\\x01'), (1, b'\\x02'), (2, b'\\x03'), (3, b'\\x04')]",
  )
}

///|
test "negative index1" {
  let bs = b"\x01\x02\x03"
  let bv = bs[-1:]
  inspect(
    bv,
    content=(
      #|b"\x03"
    ),
  )
  let bv = bs[-2:]
  inspect(
    bv,
    content=(
      #|b"\x02\x03"
    ),
  )
  let bv = bs[-3:]
  inspect(
    bv,
    content=(
      #|b"\x01\x02\x03"
    ),
  )
  let bv = bs[:-1]
  inspect(
    bv,
    content=(
      #|b"\x01\x02"
    ),
  )
  let bv = bs[:-2]
  inspect(
    bv,
    content=(
      #|b"\x01"
    ),
  )
  let bv = bs[:-3]
  inspect(
    bv,
    content=(
      #|b""
    ),
  )
  let bv = bs[-3:-3]
  inspect(
    bv,
    content=(
      #|b""
    ),
  )
  let bv = bs[-3:-2]
  inspect(
    bv,
    content=(
      #|b"\x01"
    ),
  )
  let bv = bs[-3:-1]
  inspect(
    bv,
    content=(
      #|b"\x01\x02"
    ),
  )
  let bv = bs[-3:0]
  inspect(
    bv,
    content=(
      #|b""
    ),
  )
  let bv = bs[-3:1]
  inspect(
    bv,
    content=(
      #|b"\x01"
    ),
  )
  let bv = bs[-3:2]
  inspect(
    bv,
    content=(
      #|b"\x01\x02"
    ),
  )
  let bv = bs[-3:3]
  inspect(
    bv,
    content=(
      #|b"\x01\x02\x03"
    ),
  )
}

///|
test "negative index2" {
  let bs = b"\x00\x01\x02\x03\x04"[1:4]
  let bv = bs[-1:]
  inspect(
    bv,
    content=(
      #|b"\x03"
    ),
  )
  let bv = bs[-2:]
  inspect(
    bv,
    content=(
      #|b"\x02\x03"
    ),
  )
  let bv = bs[-3:]
  inspect(
    bv,
    content=(
      #|b"\x01\x02\x03"
    ),
  )
  let bv = bs[:-1]
  inspect(
    bv,
    content=(
      #|b"\x01\x02"
    ),
  )
  let bv = bs[:-2]
  inspect(
    bv,
    content=(
      #|b"\x01"
    ),
  )
  let bv = bs[:-3]
  inspect(
    bv,
    content=(
      #|b""
    ),
  )
  let bv = bs[-3:-3]
  inspect(
    bv,
    content=(
      #|b""
    ),
  )
  let bv = bs[-3:-2]
  inspect(
    bv,
    content=(
      #|b"\x01"
    ),
  )
  let bv = bs[-3:-1]
  inspect(
    bv,
    content=(
      #|b"\x01\x02"
    ),
  )
  let bv = bs[-3:0]
  inspect(
    bv,
    content=(
      #|b""
    ),
  )
  let bv = bs[-3:1]
  inspect(
    bv,
    content=(
      #|b"\x01"
    ),
  )
  let bv = bs[-3:2]
  inspect(
    bv,
    content=(
      #|b"\x01\x02"
    ),
  )
  let bv = bs[-3:3]
  inspect(
    bv,
    content=(
      #|b"\x01\x02\x03"
    ),
  )
}

///|
test "panic negative index1" {
  let bs = b"\x01\x02\x03"
  let _ = bs[-1:-2]

}

///|
test "panic negative index2" {
  let bs = b"\x01\x02\x03"[:]
  let _ = bs[-1:-2]

}

///|
test "View::unsafe_get additional test" {
  let bytes = b"\x01\x02\x03\x04\x05"
  let view = bytes[1:4] // view contains [0x02, 0x03, 0x04]
  let result = view.unsafe_get(1) // gets byte at index 1 (the second byte) of the view
  inspect(result, content="b'\\x03'")
}

///|
test "View::get" {
  let bytes = b"\x01\x02\x03\x04\x05"
  let view = bytes[1:4]
  let result = view.get(1) // gets byte at index 1 (the second byte) of the view
  inspect(result, content="Some(b'\\x03')")
}

///|
test "View::get out_of_bounds" {
  let bytes = b"\x01\x02\x03\x04\x05"
  let view = bytes[1:4]
  let result = view.get(5) // out of bounds
  inspect(result, content="None")
}

///|
test "to_uint_be with b'\\xFF\\xFF\\xFF\\xFF'" {
  let bytes = b"\xFF\xFF\xFF\xFF"[:]
  guard bytes is [u32be(x), ..]
  inspect(x, content="4294967295")
}

///|
test "View::to_uint_le with non-zero bytes" {
  let bytes = b"\x01\x02\x03\x04"
  guard bytes is [u32le(x), ..]
  inspect(x, content="67305985") // 67305985 = 0x04030201
}

///|
test "panic View::to_uint_le/out_of_bounds" {
  let bytes = b"\x01\x02\x03" // Only 3 bytes
  match bytes {
    [u32le(_), ..] => ()
    _ => abort("Should not reach here")
  }
}

///|
test "View::to_uint64_be/first_byte_operation" {
  let bytes = b"\xFF\x00\x00\x00\x00\x00\x00\x00" // First byte is all 1s
  guard bytes is [u64be(result), ..]
  // First byte shifted left by 56 bits should give us: 0xFF00000000000000
  inspect(result, content="18374686479671623680")
}

///|
test "test View::to_uint64_le with binary pattern" {
  let bytes = b"\x01\x00\x00\x00\x00\x00\x00\x00"
  guard bytes is [u64le(x), ..]
  inspect(x, content="1")
  let bytes2 = b"\x00\x01\x00\x00\x00\x00\x00\x00"
  guard bytes2 is [u64le(x2), ..]
  inspect(x2, content="256")

  // Test all bytes set to non-zero values
  let bytes3 = b"\x01\x02\x03\x04\x05\x06\x07\x08"
  guard bytes3 is [u64le(x3), ..]
  inspect(x3, content="578437695752307201")
}

///|
test "test View::to_int_le with a non-zero 32-bit number" {
  let bytes = b"\x78\x56\x34\x12"
  guard bytes is [i32le(x), ..]
  inspect(x, content="305419896")
}

///|
test "View::to_int64_(be|le) test cases" {
  // Test positive number
  let bytes = b"\x00\x00\x00\x00\x00\x00\x00\x01"
  let bytes2 = b"\xF0\x00\x00\x00\x00\x00\x00\x00"
  // Test large positive number
  let bytes3 = b"\x7F\xFF\xFF\xFF\xFF\xFF\xFF\xFF"
  let bytes4 = b"\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF"
  guard bytes is [i64be(a), ..] &&
    bytes2 is [i64be(b), ..] &&
    bytes3 is [i64be(c), ..] &&
    bytes4 is [i64le(d), ..] else {
    fail("Failed to match int64 big-endian pattern")
  }
  @json.inspect((a, b, c, d), content=[
    "1", "-1152921504606846976", "9223372036854775807", "-1",
  ])
}

///|
test "panic to_float_be/short_input" {
  // Test that trying to read from a view that's too short causes a panic
  let bytes = b"\x40\x49"
  match bytes {
    [u32be(_), ..] => ()
    _ => abort("Should not reach here")
  }
}

///|
test "View::to_float_le with different values" {
  // Test with value 0.0
  let bytes = b"\x00\x00\x00\x00"
  guard bytes is [u32le(bits), ..]
  let f = Float::reinterpret_from_uint(bits)
  inspect(f.to_double(), content="0")

  // Test with value -1.0
  let bytes2 = b"\x00\x00\x80\xBF"
  guard bytes2 is [u32le(bits2), ..]
  let f2 = Float::reinterpret_from_uint(bits2)
  inspect(f2.to_double(), content="-1")
}

///|
test "View::to_double_be/zero" {
  let bytes = b"\x00\x00\x00\x00\x00\x00\x00\x00"
  guard bytes is [u64be(bits), ..]
  inspect(bits.reinterpret_as_double(), content="0")
}

///|
test "test to_double_le with normal float" {
  // 3.14 in little-endian IEEE 754 double format
  let bytes = b"\x1F\x85\xEB\x51\xB8\x1E\x09\x40"
  guard bytes is [u64le(bits), ..]
  inspect(bits.reinterpret_as_double(), content="3.14")
}

///|
test "iter break early" {
  let view = b"\x01\x02\x03"[:]
  let mut count = 0
  let mut total = 0
  view
  .iter()
  .take(2)
  .each(x => {
    count = count + 1
    total = total + x.to_int()
  })
  inspect(count, content="2")
  inspect(total, content="3") // \x01 + \x02 = 3
}

///|
test "View::to_int_be with positive value" {
  let bytes = b"\x00\x00\x00\x01"[:] // Represents 1 in big-endian
  guard bytes is [i32be(x), ..]
  inspect(x, content="1")
}

///|
test "BytesView::compare" {
  let bytes = b"abcabc"
  inspect(bytes[0:3].compare(bytes[3:6]), content="0") // abc = abc
  inspect(bytes[0:3].compare(bytes[2:5]), content="-1") // abc < cab
  inspect(bytes[1:4].compare(bytes[3:6]), content="1") // bca > abc
  inspect(bytes[0:3].compare(bytes[0:4]), content="-1") // abc < abca
}

///|
test "BytesView::eq" {
  let bytes = b"abcabc"
  inspect(bytes[0:3] == bytes[3:6], content="true")
  inspect(bytes[0:3] == bytes[2:5], content="false")
  inspect(bytes[0:4] == bytes[3:6], content="false")
}

///|
test "View::bytes" {
  let bytes = b"abcabc"
  let view = bytes[1:4]
  @test.same_object(view.data(), bytes)
}

///|
test "View::start" {
  let bytes = b"abcabc"
  let view = bytes[1:4]
  inspect(view.start_offset(), content="1")
}

///|
test "View::to_bytes" {
  let bytes = b"abcabc"
  let view = bytes[1:4]
  inspect(
    view.to_bytes(),
    content=(
      #|b"bca"
    ),
  )
  let bytes = b"abcabc"
  let view = bytes[:]
  inspect(
    view.to_bytes(),
    content=(
      #|b"abcabc"
    ),
  )
  let bytes = b"abcabc"
  let view = bytes[0:0]
  inspect(
    view.to_bytes(),
    content=(
      #|b""
    ),
  )
}

///|
test "impl Hash for View" {
  let b0 : Bytes = "12345678"
  let b1 : Bytes = "56781234"
  assert_eq(b0[0:4].hash(), b1[4:8].hash())
  assert_eq(b0[4:8].hash(), b1[0:4].hash())
  assert_not_eq(b0[0:4].hash(), b1[0:4].hash())
  assert_not_eq(b0[4:8].hash(), b1[4:8].hash())
}

///|
/// This test checks the invariance that the hash of a bytes and its view are the same.
/// 
/// This is necessary because we may want to use a bytes view as a key in a hash map,
/// and we need to ensure that the hash remains consistent with the original bytes.
test "bytes view hash invariant" {
  let bytes : Array[Bytes] = @quickcheck.samples(20)
  for b in bytes {
    let view = b[:]
    assert_eq(view.hash(), b.hash())
  }
}
