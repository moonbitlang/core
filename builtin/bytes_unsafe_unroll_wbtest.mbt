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

// Equivalence tests for the unrolled `#intrinsic` fallback bodies in
// `bytes_unsafe.mbt`. Each `ref_*` function below is the loop form those
// bodies used to have, kept here as an independent oracle: the unrolled
// implementations must agree with it at every offset, for every sample value.
//
// These matter because the fallbacks are dead code on native (the intrinsics
// are lowered at the call site) but are the real implementation on wasm-gc and
// js, so a byte-order slip would only surface on two of three backends.

///|
/// `builtin` cannot depend on `@test`, so `assert_eq` is not available here;
/// `assert_true` is the only assertion in scope.
fn[T : Eq] check(actual : T, expected : T) -> Unit raise {
  assert_true(actual == expected)
}

///|
fn ref_read_u16_le(b : Bytes, index : Int) -> UInt16 {
  for i in 0..<=1; result = (0 : UInt16) {
    continue result | (b[i + index].to_uint16() << (8 * i))
  } nobreak {
    result
  }
}

///|
fn ref_read_u16_be(b : Bytes, index : Int) -> UInt16 {
  for i in 0..<=1; result = (0 : UInt16) {
    continue result | (b[i + index].to_uint16() << (8 * (1 - i)))
  } nobreak {
    result
  }
}

///|
fn ref_read_u32_le(b : Bytes, index : Int) -> UInt {
  for i in 0..<=3; result = (0 : UInt) {
    continue result | (b[i + index].to_uint() << (8 * i))
  } nobreak {
    result
  }
}

///|
fn ref_read_u32_be(b : Bytes, index : Int) -> UInt {
  for i in 0..<=3; result = (0 : UInt) {
    continue result | (b[i + index].to_uint() << (8 * (3 - i)))
  } nobreak {
    result
  }
}

///|
fn ref_read_u64_le(b : Bytes, index : Int) -> UInt64 {
  for i in 0..<=7; result = (0 : UInt64) {
    continue result | (b[i + index].to_uint64() << (8 * i))
  } nobreak {
    result
  }
}

///|
fn ref_read_u64_be(b : Bytes, index : Int) -> UInt64 {
  for i in 0..<=7; result = (0 : UInt64) {
    continue result | (b[i + index].to_uint64() << (8 * (7 - i)))
  } nobreak {
    result
  }
}

///|
/// A byte pattern with every bit position exercised, plus 0x00 and 0xFF runs so
/// sign-extension and zero-extension slips show up.
fn sample_bytes(len : Int) -> Bytes {
  Bytes::makei(len, i => {
    match i % 8 {
      0 => b'\x00'
      1 => b'\xFF'
      2 => b'\x80'
      3 => b'\x01'
      4 => b'\x7F'
      5 => b'\xAA'
      6 => b'\x55'
      _ => (i * 31 + 7).to_byte()
    }
  })
}

///|
test "unrolled Bytes reads agree with the loop form at every offset" {
  let len = 64
  let b = sample_bytes(len)
  for i in 0..<(len - 1) {
    check(b.unsafe_read_uint16_le(i), ref_read_u16_le(b, i))
    check(b.unsafe_read_uint16_be(i), ref_read_u16_be(b, i))
  }
  for i in 0..<(len - 3) {
    check(b.unsafe_read_uint32_le(i), ref_read_u32_le(b, i))
    check(b.unsafe_read_uint32_be(i), ref_read_u32_be(b, i))
  }
  for i in 0..<(len - 7) {
    check(b.unsafe_read_uint64_le(i), ref_read_u64_le(b, i))
    check(b.unsafe_read_uint64_be(i), ref_read_u64_be(b, i))
  }
}

///|
/// The private `fixedarray_read_*` helpers carry their own copies of the same
/// unrolled bodies, so they need their own check.
test "unrolled FixedArray reads agree with the loop form at every offset" {
  let len = 64
  let b = sample_bytes(len)
  let fa = FixedArray::makei(len, i => b[i])
  for i in 0..<(len - 1) {
    check(fixedarray_read_uint16_le(fa, i), ref_read_u16_le(b, i))
    check(fixedarray_read_uint16_be(fa, i), ref_read_u16_be(b, i))
  }
  for i in 0..<(len - 3) {
    check(fixedarray_read_uint32_le(fa, i), ref_read_u32_le(b, i))
    check(fixedarray_read_uint32_be(fa, i), ref_read_u32_be(b, i))
  }
  for i in 0..<(len - 7) {
    check(fixedarray_read_uint64_le(fa, i), ref_read_u64_le(b, i))
    check(fixedarray_read_uint64_be(fa, i), ref_read_u64_be(b, i))
  }
}

///|
let u64_samples : Array[UInt64] = [
  0, 1, 0xFF, 0x100, 0x7FFF_FFFF, 0x8000_0000, 0xFFFF_FFFF, 0x1_0000_0000, 0x0123_4567_89AB_CDEF,
  0xFEDC_BA98_7654_3210, 0x7FFF_FFFF_FFFF_FFFF, 0x8000_0000_0000_0000, 0xFFFF_FFFF_FFFF_FFFF,
]

///|
/// Writes go through the unrolled `unsafe_write_*`; reading them back with the
/// independent `ref_read_*` oracle pins the byte order in both directions.
test "unrolled writes round-trip through the loop-form readers" {
  let len = 32
  for value in u64_samples {
    let v32 = value.to_uint()
    let v16 = value.to_uint16()
    for i in 0..<(len - 7) {
      let fa = FixedArray::make(len, b'\x00')
      fa.unsafe_write_uint64_le(i, value)
      check(ref_read_u64_le(unsafe_to_bytes(fa), i), value)
      let fa = FixedArray::make(len, b'\x00')
      fa.unsafe_write_uint64_be(i, value)
      check(ref_read_u64_be(unsafe_to_bytes(fa), i), value)
    }
    for i in 0..<(len - 3) {
      let fa = FixedArray::make(len, b'\x00')
      fa.unsafe_write_uint32_le(i, v32)
      check(ref_read_u32_le(unsafe_to_bytes(fa), i), v32)
      let fa = FixedArray::make(len, b'\x00')
      fa.unsafe_write_uint32_be(i, v32)
      check(ref_read_u32_be(unsafe_to_bytes(fa), i), v32)
    }
    for i in 0..<(len - 1) {
      let fa = FixedArray::make(len, b'\x00')
      fa.unsafe_write_uint16_le(i, v16)
      check(ref_read_u16_le(unsafe_to_bytes(fa), i), v16)
      let fa = FixedArray::make(len, b'\x00')
      fa.unsafe_write_uint16_be(i, v16)
      check(ref_read_u16_be(unsafe_to_bytes(fa), i), v16)
    }
  }
}

///|
/// A write must touch exactly its own bytes and leave the neighbours alone.
/// All six writers are covered, since each carries its own unrolled body.
test "unrolled writes do not disturb neighbouring bytes" {
  let len = 32
  let fill = b'\x3C'
  fn check_span(
    width : Int,
    write : (FixedArray[Byte], Int) -> Unit,
  ) -> Unit raise {
    for i in 0..<(len - width + 1) {
      let fa = FixedArray::make(len, fill)
      write(fa, i)
      for j in 0..<len {
        if j < i || j >= i + width {
          check(fa[j], fill)
        } else {
          check(fa[j], b'\xFF')
        }
      }
    }
  }

  check_span(8, (fa, i) => fa.unsafe_write_uint64_le(i, 0xFFFF_FFFF_FFFF_FFFF))
  check_span(8, (fa, i) => fa.unsafe_write_uint64_be(i, 0xFFFF_FFFF_FFFF_FFFF))
  check_span(4, (fa, i) => fa.unsafe_write_uint32_le(i, 0xFFFF_FFFF))
  check_span(4, (fa, i) => fa.unsafe_write_uint32_be(i, 0xFFFF_FFFF))
  check_span(2, (fa, i) => fa.unsafe_write_uint16_le(i, 0xFFFF))
  check_span(2, (fa, i) => fa.unsafe_write_uint16_be(i, 0xFFFF))
}
