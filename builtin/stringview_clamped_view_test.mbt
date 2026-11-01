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
test "StringView clamped bounds agree with enumerated UTF-16 boundaries" {
  let source = "x😀a😁y"
  // Include empty slices and raw slices that start/end inside a surrogate pair.
  for base in 0..<=source.length() {
    for limit in base..<=source.length() {
      let view = source.unsafe_view(start=base, end=limit)
      let len = view.length()
      let boundaries = [0]
      let mut pos = 0
      while pos < len {
        let unit = view.code_unit_at(pos)
        pos += if unit.is_leading_surrogate() &&
          pos + 1 < len &&
          view.code_unit_at(pos + 1).is_trailing_surrogate() {
          2
        } else {
          1
        }
        boundaries.push(pos)
      }
      let offsets = [@int.MIN_VALUE, @int.MAX_VALUE]
      for i in -1..<=(len + 1) {
        offsets.push(i)
      }
      let ends = [None]
      for offset in offsets {
        ends.push(Some(offset))
      }
      for start in offsets {
        let lo = for boundary in boundaries {
          if boundary >= start {
            break boundary
          }
        } nobreak {
          len
        }
        for end in ends {
          let requested_end = end.unwrap_or(len)
          let hi = for boundary in boundaries.rev_iter() {
            if boundary <= requested_end {
              break boundary
            }
          } nobreak {
            0
          }
          let expected_length = if hi > lo { hi - lo } else { 0 }
          let result = view.clamped_view(start~, end?)
          assert_eq(result.start_offset(), base + lo)
          assert_eq(result.length(), expected_length)
          for i in 0..<expected_length {
            assert_eq(
              result.code_unit_at(i),
              source.code_unit_at(base + lo + i),
            )
          }
        }
      }
    }
  }
}
