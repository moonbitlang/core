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
test "bench byte splat and XOR n=10000" (it : @bench.T) {
  let values = Array::makei(10000, i => (i * 73 + (i >> 3)).to_byte())
  it.bench(fn() {
    let mut acc = @v128.i64x2_const(1UL, 2UL)
    for value in values {
      acc = @v128.v128_xor(acc, @v128.i8x16_splat(value))
    }
    it.keep(acc)
  })
}

///|
test "bench UInt16 splat and XOR n=10000" (it : @bench.T) {
  let values = Array::makei(10000, i => (i * 977 + (i >> 2)).to_uint16())
  it.bench(fn() {
    let mut acc = @v128.i64x2_const(1UL, 2UL)
    for value in values {
      acc = @v128.v128_xor(acc, @v128.i16x8_splat(value))
    }
    it.keep(acc)
  })
}
