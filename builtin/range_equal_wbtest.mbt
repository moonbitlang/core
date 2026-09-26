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

// Tests for `String::unsafe_range_equal` and `Bytes::unsafe_range_equal`.
// On wasm their bodies run a vector loop (`string_range_equal_simd`,
// `bytes_range_equal_simd`); native lowers them to `memcmp`; js and wasm-gc
// run the scalar body. The same checks run on every backend.

///|
/// Builds a string from raw UTF-16 code units (little-endian storage).
fn range_equal_units_to_string(units : Array[Int]) -> String {
  let bytes = FixedArray::make(units.length() * 2, b'\x00')
  for i, u in units {
    bytes[2 * i] = (u & 0xFF).to_byte()
    bytes[2 * i + 1] = ((u >> 8) & 0xFF).to_byte()
  }
  unsafe_to_bytes(bytes).to_unchecked_string()
}

///|
/// Body units for the string boundary tests. The period (7) is coprime with
/// the vector width, so every unit kind lands on every lane. It contains
/// ASCII, a BMP CJK unit, a surrogate pair, and units whose low or high byte
/// is zero. XOR-ing any of them with 0x1 or 0x100 yields a unit of the same
/// kind, so a planted mismatch keeps surrogate pairs well-formed.
let range_equal_unit_pattern : Array[Int] = [
  0x61, 0x4E2D, 0xD83D, 0xDE00, 0xFF, 0x100, 0x7A,
]

///|
/// Builds `prefix ++ body ++ suffix` where the body is `len` pattern units.
/// `pad` chooses the filler so the two sides of a comparison differ outside
/// the compared ranges.
fn range_equal_make_units(
  prefix : Int,
  len : Int,
  suffix : Int,
  pad : Int,
) -> Array[Int] {
  let units = []
  for i in 0..<prefix {
    units.push(pad + i)
  }
  for i in 0..<len {
    units.push(range_equal_unit_pattern[i % range_equal_unit_pattern.length()])
  }
  for i in 0..<suffix {
    units.push(pad + 0x10 + i)
  }
  units
}

///|
/// Offsets `(left, right)` for the boundary tests: aligned, unaligned on one
/// side, and unaligned on both sides.
let range_equal_offsets : Array[(Int, Int)] = [
  (0, 0),
  (1, 0),
  (0, 3),
  (5, 7),
  (9, 2),
  (17, 17),
]

///|
/// Plants a mismatch at every position of every length in `min_len..=max_len`
/// and checks `eq` against the expected answer. `suffix == 0` makes each
/// range end exactly at the end of its backing string.
fn check_string_range_equal(
  eq : (String, Int, String, Int, Int) -> Bool,
  min_len : Int,
  max_len : Int,
) -> Unit raise {
  for len in min_len..<=max_len {
    for offsets in range_equal_offsets {
      let (lo, ro) = offsets
      for suffix in [0, 3] {
        let left = range_equal_units_to_string(
          range_equal_make_units(lo, len, suffix, 0x30),
        )
        let right_units = range_equal_make_units(ro, len, suffix, 0x40)
        let right = range_equal_units_to_string(right_units)
        if !eq(left, lo, right, ro, len) {
          fail("len=\{len} lo=\{lo} ro=\{ro} suffix=\{suffix}: expected equal")
        }
        for pos in 0..<len {
          for flip in [0x1, 0x100] {
            let mutated = right_units.copy()
            mutated[ro + pos] = mutated[ro + pos] ^ flip
            let right = range_equal_units_to_string(mutated)
            if eq(left, lo, right, ro, len) {
              fail(
                "len=\{len} lo=\{lo} ro=\{ro} suffix=\{suffix} pos=\{pos} flip=\{flip}: expected unequal",
              )
            }
            // the mismatch on the left side must be found too
            if eq(right, ro, left, lo, len) {
              fail(
                "swapped len=\{len} lo=\{lo} ro=\{ro} suffix=\{suffix} pos=\{pos} flip=\{flip}: expected unequal",
              )
            }
          }
        }
      }
    }
  }
}

///|
fn range_equal_make_bytes(
  prefix : Int,
  len : Int,
  suffix : Int,
  pad : Int,
) -> FixedArray[Byte] {
  let data = FixedArray::make(prefix + len + suffix, b'\x00')
  for i in 0..<prefix {
    data[i] = (pad + i).to_byte()
  }
  for i in 0..<len {
    // period 17 is coprime with the vector width; covers 0x00 and 0x80..0xFF
    data[prefix + i] = (i % 17 * 15).to_byte()
  }
  for i in 0..<suffix {
    data[prefix + len + i] = (pad + 0x10 + i).to_byte()
  }
  data
}

///|
fn check_bytes_range_equal(
  eq : (Bytes, Int, Bytes, Int, Int) -> Bool,
  min_len : Int,
  max_len : Int,
) -> Unit raise {
  for len in min_len..<=max_len {
    for offsets in range_equal_offsets {
      let (lo, ro) = offsets
      for suffix in [0, 5] {
        let left = unsafe_to_bytes(
          range_equal_make_bytes(lo, len, suffix, 0x30),
        )
        let right_data = range_equal_make_bytes(ro, len, suffix, 0x60)
        let right = unsafe_to_bytes(right_data.copy())
        if !eq(left, lo, right, ro, len) {
          fail("len=\{len} lo=\{lo} ro=\{ro} suffix=\{suffix}: expected equal")
        }
        for pos in 0..<len {
          for flip in [(0x01 : Byte), 0x80] {
            let mutated = right_data.copy()
            mutated[ro + pos] = mutated[ro + pos] ^ flip
            let right = unsafe_to_bytes(mutated)
            if eq(left, lo, right, ro, len) {
              fail(
                "len=\{len} lo=\{lo} ro=\{ro} suffix=\{suffix} pos=\{pos} flip=\{flip}: expected unequal",
              )
            }
            if eq(right, ro, left, lo, len) {
              fail(
                "swapped len=\{len} lo=\{lo} ro=\{ro} suffix=\{suffix} pos=\{pos} flip=\{flip}: expected unequal",
              )
            }
          }
        }
      }
    }
  }
}

///|
test "String::unsafe_range_equal plants a mismatch at every position" {
  check_string_range_equal(
    (l, lo, r, ro, len) => {
      l.unsafe_range_equal(self_off=lo, r, other_off=ro, len~)
    },
    0,
    41,
  )
}

///|
test "Bytes::unsafe_range_equal plants a mismatch at every position" {
  check_bytes_range_equal(
    (l, lo, r, ro, len) => {
      l.unsafe_range_equal(self_off=lo, r, other_off=ro, len~)
    },
    0,
    49,
  )
}

///|
test "unsafe_range_equal on empty and same-buffer ranges" {
  let s = "abcabcabcabcabcabcabcabc"
  assert_true(s.unsafe_range_equal(self_off=0, s, other_off=0, len=0))
  assert_true(s.unsafe_range_equal(self_off=24, "", other_off=0, len=0))
  assert_true(s.unsafe_range_equal(self_off=0, s, other_off=3, len=21))
  assert_false(s.unsafe_range_equal(self_off=0, s, other_off=1, len=20))
  let b = b"abcabcabcabcabcabcabcabcabcabcabcabc"
  assert_true(b.unsafe_range_equal(self_off=0, b, other_off=0, len=0))
  assert_true(b.unsafe_range_equal(self_off=36, b"", other_off=0, len=0))
  assert_true(b.unsafe_range_equal(self_off=0, b, other_off=3, len=33))
  assert_false(b.unsafe_range_equal(self_off=0, b, other_off=1, len=32))
}

///|
// Calls the vector bodies directly, so they are tested on wasm independently
// of the length threshold in the intrinsic bodies.
#cfg(target="wasm")
test "wasm: string_range_equal_simd plants a mismatch at every position" {
  check_string_range_equal(string_range_equal_simd, 8, 41)
}

///|
#cfg(target="wasm")
test "wasm: bytes_range_equal_simd plants a mismatch at every position" {
  check_bytes_range_equal(bytes_range_equal_simd, 16, 49)
}
