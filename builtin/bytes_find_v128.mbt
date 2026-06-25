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
#coverage.skip
fn bytes_find_v128_make(lo : UInt64, hi : UInt64) -> V128 = "%v128.make"

///|
#coverage.skip
#intrinsic("%v128.i8x16_splat")
fn Byte::i8x16_splat(self : Byte) -> V128 = "%v128.i8x16_splat"

///|
#coverage.skip
#intrinsic("%v128.i8x16_eq")
fn V128::i8x16_eq(self : V128, other : V128) -> V128 = "%v128.i8x16_eq"

///|
#coverage.skip
#intrinsic("%v128.i8x16_bitmask")
fn V128::i8x16_bitmask(self : V128) -> Int = "%v128.i8x16_bitmask"

///|
#inline
#coverage.skip
fn bytes_find_match_range(
  target : BytesView,
  pattern : BytesView,
  candidate : Int,
  start : Int,
  end : Int,
) -> Bool {
  let mut index = start
  while index < end {
    if target.unsafe_get(candidate + index) != pattern.unsafe_get(index) {
      return false
    }
    index += 1
  }
  true
}
