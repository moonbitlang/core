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
test "packed splats exhaust all byte and UInt16 values" {
  for code in 0..<256 {
    let b = code.to_byte()
    assert_eq(
      @v128.i8x16_splat(b),
      @v128.i8x16_const(b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b),
    )
  }
  for code in 0..<0x10000 {
    let u = code.to_uint16()
    assert_eq(@v128.i16x8_splat(u), @v128.i16x8_const(u, u, u, u, u, u, u, u))
  }
}
