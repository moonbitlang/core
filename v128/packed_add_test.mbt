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
test "packed byte addition handles every pair without carrying between lanes" {
  for a in 0..<256 {
    for b in 0..<256 {
      let left = @v128.i8x16_splat(a.to_byte())
      let right = @v128.i8x16_splat(b.to_byte())
      assert_eq(
        @v128.i8x16_add(left, right),
        @v128.i8x16_splat(((a + b) & 0xFF).to_byte()),
      )
      let neighbors = @v128.i8x16_const(
        0xff,
        0,
        a.to_byte(),
        0xff,
        0,
        0xff,
        0,
        a.to_byte(),
        a.to_byte(),
        0,
        0xff,
        0,
        0xff,
        a.to_byte(),
        0,
        0xff,
      )
      let increments = @v128.i8x16_const(
        1,
        0,
        b.to_byte(),
        1,
        0,
        1,
        0,
        b.to_byte(),
        b.to_byte(),
        0,
        1,
        0,
        1,
        b.to_byte(),
        0,
        1,
      )
      let result = @v128.i8x16_add(neighbors, increments)
      let sum = ((a + b) & 0xff).to_byte()
      assert_eq(
        result,
        @v128.i8x16_const(
          0, 0, sum, 0, 0, 0, 0, sum, sum, 0, 0, 0, 0, sum, 0, 0,
        ),
      )
    }
  }
}
