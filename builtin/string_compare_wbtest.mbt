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
/// Builds `shift` zero units followed by the fill pattern, with `first` at
/// `off + pos`, `later` right after it (when still inside the range), and
/// `past` at `off + len`, just past the range. `pos < 0` plants nothing.
/// Built with `makei` rather than by storing into a copied array.
#cfg(any(target="native", target="wasm"))
fn simd_cmp_string(
  shift~ : Int,
  off~ : Int,
  len~ : Int,
  pos~ : Int,
  first~ : UInt16,
  later~ : UInt16,
  past~ : UInt16,
) -> String {
  let units : Array[UInt16] = Array::makei(shift + off + len + 3, j => {
    let i = j - shift
    if i < 0 {
      0
    } else if pos >= 0 && i == off + pos {
      first
    } else if pos >= 0 && i == off + pos + 1 && pos + 1 < len {
      later
    } else if i == off + len {
      past
    } else {
      match i % 5 {
        0 => 0x41
        1 => 0x8001
        2 => 0xD83D
        3 => 0xDE00
        _ => (0x61 + i % 26).to_uint16()
      }
    }
  })
  String::from_array(units.map(u => u.to_int().unsafe_to_char()))
}

///|
#cfg(any(target="native", target="wasm"))
test "code_unit_range_compare_simd direct" {
  // Calls the vector search directly, so a dispatch change that bypasses it
  // cannot hide a bug in it. Covers every length from one block up to five,
  // hence every mix of 16-unit iterations, 8-unit blocks and final
  // overlapping block, and every mismatch position, with the two ranges at
  // different start offsets.
  let pairs : Array[(UInt16, UInt16)] = [
    (0x61, 0x62),
    (0x7FFF, 0x8000),
    (0x0000, 0xFFFF),
    (0xD83D, 0xE000),
  ]
  let off = 3
  for len in 8..<=40 {
    // Equal ranges followed by units that differ just past the range, which
    // must be ignored.
    let sx = simd_cmp_string(
      shift=0,
      off~,
      len~,
      pos=-1,
      first=0,
      later=0,
      past=0xFFFF,
    )
    let sy = simd_cmp_string(
      shift=1,
      off~,
      len~,
      pos=-1,
      first=0,
      later=0,
      past=0x0000,
    )
    assert_true(code_unit_range_compare_simd(sx, off, sx, off, len) == 0)
    assert_true(code_unit_range_compare_simd(sx, off, sy, off + 1, len) == 0)
    assert_true(code_unit_range_compare_simd(sy, off + 1, sx, off, len) == 0)
    for pos in 0..<len {
      for pair in pairs {
        let (lo, hi) = pair
        // A later difference in the opposite direction must not win.
        let sx = simd_cmp_string(
          shift=0,
          off~,
          len~,
          pos~,
          first=lo,
          later=0xFFFF,
          past=0xFFFF,
        )
        let sy = simd_cmp_string(
          shift=1,
          off~,
          len~,
          pos~,
          first=hi,
          later=0x0000,
          past=0x0000,
        )
        assert_true(
          code_unit_range_compare_simd(sx, off, sy, off + 1, len) == -1,
        )
        assert_true(
          code_unit_range_compare_simd(sy, off + 1, sx, off, len) == 1,
        )
      }
    }
  }
}
