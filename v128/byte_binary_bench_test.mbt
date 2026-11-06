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
test "bench byte subtraction n=10000" (it : @bench.T) {
  let values = Array::makei(10000, i => {
    let x = i.to_uint64() + 1UL
    @v128.i64x2_const(x * 0x123456789abcdefUL, x * 0xfedcba987654321UL)
  })
  it.bench(fn() {
    let mut acc = @v128.i64x2_const(1UL, 2UL)
    for value in values {
      acc = @v128.i8x16_sub(acc, value)
    }
    it.keep(acc)
  })
}

///|
test "bench mixed byte operations n=10000" (it : @bench.T) {
  let values = Array::makei(10001, i => {
    let x = i.to_uint64() + 1UL
    @v128.i64x2_const(x * 0x123456789abcdefUL, x * 0xfedcba987654321UL)
  })
  it.bench(fn() {
    let mut acc = @v128.i64x2_const(1UL, 2UL)
    for i in 0..<10000 {
      let a = values.unsafe_get(i)
      let b = values.unsafe_get(i + 1)
      acc = @v128.i8x16_add(acc, a)
      acc = @v128.i8x16_sub(acc, b)
      let equal = @v128.i8x16_eq(acc, a)
      let less = @v128.i8x16_lt_u(acc, b)
      acc = @v128.v128_xor(acc, @v128.v128_xor(equal, less))
    }
    it.keep(acc)
  })
}
