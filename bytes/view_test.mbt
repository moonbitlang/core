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
test "basic1" {
  let bs = b"\x00\x01\x02\x03\x04\x05"
  let bv1 = bs[1:4]
  let bv2 = bs[:]
  let bv3 = bs[1:]
  let bv4 = bs[:4]
  inspect!(bv1, content="b\"\\x01\\x02\\x03\"")
  inspect!(bv2, content="b\"\\x00\\x01\\x02\\x03\\x04\\x05\"")
  inspect!(bv3, content="b\"\\x01\\x02\\x03\\x04\\x05\"")
  inspect!(bv4, content="b\"\\x00\\x01\\x02\\x03\"")
}

///|
test "basic2" {
  let bs = b"\x00\x01\x02\x03\x04\x05\x06\x07"
  let bv = bs[1:7]
  let bv1 = bv[1:4]
  let bv2 = bv[:4]
  let bv3 = bv[1:]
  let bv4 = bv[:]
  inspect!(bv, content="b\"\\x01\\x02\\x03\\x04\\x05\\x06\"")
  inspect!(bv1, content="b\"\\x02\\x03\\x04\"")
  inspect!(bv2, content="b\"\\x01\\x02\\x03\\x04\"")
  inspect!(bv3, content="b\"\\x02\\x03\\x04\\x05\\x06\"")
  inspect!(bv4, content="b\"\\x01\\x02\\x03\\x04\\x05\\x06\"")
}

///|
test "basic3" {
  let bs = b"\x00"
  let bv = bs[0:0]
  inspect!(bv, content="b\"\"")
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
  inspect!(
    bv.iter().to_array(),
    content="[b'\\x00', b'\\x01', b'\\x02', b'\\x03', b'\\x04', b'\\x05']",
  )
}

///|
test "negative index1" {
  let bs = b"\x01\x02\x03"
  let bv = bs[-1:]
  inspect!(
    bv,
    content=
      #|b"\x03"
    ,
  )
  let bv = bs[-2:]
  inspect!(
    bv,
    content=
      #|b"\x02\x03"
    ,
  )
  let bv = bs[-3:]
  inspect!(
    bv,
    content=
      #|b"\x01\x02\x03"
    ,
  )
  let bv = bs[:-1]
  inspect!(
    bv,
    content=
      #|b"\x01\x02"
    ,
  )
  let bv = bs[:-2]
  inspect!(
    bv,
    content=
      #|b"\x01"
    ,
  )
  let bv = bs[:-3]
  inspect!(
    bv,
    content=
      #|b""
    ,
  )
  let bv = bs[-3:-3]
  inspect!(
    bv,
    content=
      #|b""
    ,
  )
  let bv = bs[-3:-2]
  inspect!(
    bv,
    content=
      #|b"\x01"
    ,
  )
  let bv = bs[-3:-1]
  inspect!(
    bv,
    content=
      #|b"\x01\x02"
    ,
  )
  let bv = bs[-3:0]
  inspect!(
    bv,
    content=
      #|b""
    ,
  )
  let bv = bs[-3:1]
  inspect!(
    bv,
    content=
      #|b"\x01"
    ,
  )
  let bv = bs[-3:2]
  inspect!(
    bv,
    content=
      #|b"\x01\x02"
    ,
  )
  let bv = bs[-3:3]
  inspect!(
    bv,
    content=
      #|b"\x01\x02\x03"
    ,
  )
}

///|
test "negative index2" {
  let bs = b"\x00\x01\x02\x03\x04"[1:4]
  let bv = bs[-1:]
  inspect!(
    bv,
    content=
      #|b"\x03"
    ,
  )
  let bv = bs[-2:]
  inspect!(
    bv,
    content=
      #|b"\x02\x03"
    ,
  )
  let bv = bs[-3:]
  inspect!(
    bv,
    content=
      #|b"\x01\x02\x03"
    ,
  )
  let bv = bs[:-1]
  inspect!(
    bv,
    content=
      #|b"\x01\x02"
    ,
  )
  let bv = bs[:-2]
  inspect!(
    bv,
    content=
      #|b"\x01"
    ,
  )
  let bv = bs[:-3]
  inspect!(
    bv,
    content=
      #|b""
    ,
  )
  let bv = bs[-3:-3]
  inspect!(
    bv,
    content=
      #|b""
    ,
  )
  let bv = bs[-3:-2]
  inspect!(
    bv,
    content=
      #|b"\x01"
    ,
  )
  let bv = bs[-3:-1]
  inspect!(
    bv,
    content=
      #|b"\x01\x02"
    ,
  )
  let bv = bs[-3:0]
  inspect!(
    bv,
    content=
      #|b""
    ,
  )
  let bv = bs[-3:1]
  inspect!(
    bv,
    content=
      #|b"\x01"
    ,
  )
  let bv = bs[-3:2]
  inspect!(
    bv,
    content=
      #|b"\x01\x02"
    ,
  )
  let bv = bs[-3:3]
  inspect!(
    bv,
    content=
      #|b"\x01\x02\x03"
    ,
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
  inspect!(result, content="b'\\x03'")
}

///|
test "View::get" {
  let bytes = b"\x01\x02\x03\x04\x05"
  let view = bytes[1:4]
  let result = view.get(1) // gets byte at index 1 (the second byte) of the view
  inspect!(result, content="Some(b'\\x03')")
}

///|
test "View::get out_of_bounds" {
  let bytes = b"\x01\x02\x03\x04\x05"
  let view = bytes[1:4]
  let result = view.get(5) // out of bounds
  inspect!(result, content="None")
}

///|
test "to_uint_be with b'\\xFF\\xFF\\xFF\\xFF'" {
  let bytes = b"\xFF\xFF\xFF\xFF"[:]
  inspect!(bytes.to_uint_be(), content="4294967295")
}

///|
test "View::to_uint_le with non-zero bytes" {
  let bytes = b"\x01\x02\x03\x04"
  let view = bytes[:]
  inspect!(view.to_uint_le(), content="67305985") // 67305985 = 0x04030201
}

///|
test "panic View::to_uint_le/out_of_bounds" {
  let bytes = b"\x01\x02\x03" // Only 3 bytes
  let view = bytes[:]
  ignore(view.to_uint_le()) // Should panic: index out of bounds
}

///|
test "View::to_uint64_be/first_byte_operation" {
  let bytes = b"\xFF\x00\x00\x00\x00\x00\x00\x00"[:] // First byte is all 1s
  let result = bytes.to_uint64_be()
  // First byte shifted left by 56 bits should give us: 0xFF00000000000000
  inspect!(result, content="18374686479671623680")
}

///|
test "test View::to_uint64_le with binary pattern" {
  let bytes = b"\x01\x00\x00\x00\x00\x00\x00\x00"[:]
  inspect!(bytes.to_uint64_le(), content="1")
  let bytes2 = b"\x00\x01\x00\x00\x00\x00\x00\x00"[:]
  inspect!(bytes2.to_uint64_le(), content="256")

  // Test all bytes set to non-zero values
  let bytes3 = b"\x01\x02\x03\x04\x05\x06\x07\x08"[:]
  inspect!(bytes3.to_uint64_le(), content="578437695752307201")
}

///|
test "test View::to_int_le with a non-zero 32-bit number" {
  let bytes = b"\x78\x56\x34\x12"[:]
  inspect!(bytes.to_int_le(), content="305419896")
}

///|
test "View::to_int64_be test cases" {
  // Test positive number
  let bytes = b"\x00\x00\x00\x00\x00\x00\x00\x01"
  inspect!(bytes[:].to_int64_be(), content="1")

  // Test negative number (most significant bit set)
  let bytes2 = b"\xF0\x00\x00\x00\x00\x00\x00\x00"
  inspect!(bytes2[:].to_int64_be(), content="-1152921504606846976")

  // Test large positive number
  let bytes3 = b"\x7F\xFF\xFF\xFF\xFF\xFF\xFF\xFF"
  inspect!(bytes3[:].to_int64_be(), content="9223372036854775807")
}

///|
test "View::to_int64_le with mixed bytes" {
  // Test with bytes containing both negative and positive values
  let bytes = b"\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF"
  let view = bytes[:]
  inspect!(view.to_int64_le(), content="-1")
}

///|
test "panic to_float_be/short_input" {
  // Test that trying to read from a view that's too short causes a panic
  let bytes = b"\x40\x49"
  let view = bytes[:]
  ignore(View::to_float_be(view)) // Should panic due to insufficient bytes
}

///|
test "View::to_float_le with different values" {
  // Test with value 0.0
  let bytes = b"\x00\x00\x00\x00"
  let f = bytes[:].to_float_le()
  inspect!(f.to_double(), content="0")

  // Test with value -1.0
  let bytes2 = b"\x00\x00\x80\xBF"
  let f2 = bytes2[:].to_float_le()
  inspect!(f2.to_double(), content="-1")
}

///|
test "View::to_double_be/zero" {
  let bytes = b"\x00\x00\x00\x00\x00\x00\x00\x00"
  let view = bytes[:]
  inspect!(view.to_double_be(), content="0")
}

///|
test "test to_double_le with normal float" {
  // 3.14 in little-endian IEEE 754 double format
  let bytes = b"\x1F\x85\xEB\x51\xB8\x1E\x09\x40"
  let view = bytes[:]
  inspect!(view.to_double_le(), content="3.14")
}

///|
test "iter break early" {
  let view = b"\x01\x02\x03"[:]
  let mut count = 0
  let mut total = 0
  view
  .iter()
  .take(2)
  .each(fn(x) {
    count = count + 1
    total = total + x.to_int()
  })
  inspect!(count, content="2")
  inspect!(total, content="3") // \x01 + \x02 = 3
}

///|
test "View::to_int_be with positive value" {
  let bytes = b"\x00\x00\x00\x01"[:] // Represents 1 in big-endian
  inspect!(bytes.to_int_be(), content="1")
}

///|
test "BytesView::compare" {
  let bytes = b"abcabc"
  inspect!(bytes[0:3].compare(bytes[3:6]), content="0") // abc = abc
  inspect!(bytes[0:3].compare(bytes[2:5]), content="-1") // abc < cab
  inspect!(bytes[1:4].compare(bytes[3:6]), content="1") // bca > abc
  inspect!(bytes[0:3].compare(bytes[0:4]), content="-1") // abc < abca
}

///|
test "BytesView::eq" {
  let bytes = b"abcabc"
  inspect!(bytes[0:3] == bytes[3:6], content="true")
  inspect!(bytes[0:3] == bytes[2:5], content="false")
  inspect!(bytes[0:4] == bytes[3:6], content="false")
}

///|
test "View::bytes" {
  let bytes = b"abcabc"
  let view = bytes[1:4]
  @test.same_object!(view.data(), bytes)
}

///|
test "View::start" {
  let bytes = b"abcabc"
  let view = bytes[1:4]
  inspect!(view.start_offset(), content="1")
}
