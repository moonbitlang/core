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
fn assert_bits(value : V128, lo : UInt64, hi : UInt64) -> Unit raise {
  assert_eq(@v128.lo(value), lo)
  assert_eq(@v128.hi(value), hi)
}

///|
fn make_by_index(index : Int) -> V128 {
  match index {
    0 => @v128.make(0x0000000000000000UL, 0x0000000000000001UL)
    1 => @v128.make(0x1111111111111111UL, 0x1111111111111112UL)
    2 => @v128.make(0x2222222222222222UL, 0x2222222222222223UL)
    3 => @v128.make(0x3333333333333333UL, 0x3333333333333334UL)
    4 => @v128.make(0x4444444444444444UL, 0x4444444444444445UL)
    _ => @v128.make(0xffffffffffffffffUL, 0xeeeeeeeeeeeeeeeeUL)
  }
}

///|
fn pass_through(value : V128) -> V128 {
  @v128.make(@v128.lo(value), @v128.hi(value))
}

///|
test "make and extract lanes" {
  let a = @v128.make(0x0123456789abcdefUL, 0xfedcba9876543210UL)
  let b = @v128.make(0x1111111122222222UL, 0x3333333344444444UL)
  let c = @v128.make(0xffffffffffffffffUL, 0x8000000000000000UL)
  assert_bits(@v128.make(0UL, 0UL), 0UL, 0UL)
  assert_bits(@v128.make(1UL, 2UL), 1UL, 2UL)
  assert_bits(a, 0x0123456789abcdefUL, 0xfedcba9876543210UL)
  assert_bits(c, 0xffffffffffffffffUL, 0x8000000000000000UL)
  assert_bits(pass_through(a), 0x0123456789abcdefUL, 0xfedcba9876543210UL)
  assert_bits(
    if true {
      a
    } else {
      b
    },
    0x0123456789abcdefUL,
    0xfedcba9876543210UL,
  )
  assert_bits(
    if false {
      a
    } else {
      b
    },
    0x1111111122222222UL,
    0x3333333344444444UL,
  )
}

///|
test "array storage" {
  let a = @v128.make(0x0123456789abcdefUL, 0xfedcba9876543210UL)
  let b = @v128.make(0x1111111122222222UL, 0x3333333344444444UL)
  let c = @v128.make(0xffffffffffffffffUL, 0x8000000000000000UL)
  let xs : Array[V128] = Array::make(5, a)
  inspect(xs.length(), content="5")
  assert_bits(xs.unsafe_get(0), 0x0123456789abcdefUL, 0xfedcba9876543210UL)
  assert_bits(xs.unsafe_get(2), 0x0123456789abcdefUL, 0xfedcba9876543210UL)
  assert_bits(xs.unsafe_get(4), 0x0123456789abcdefUL, 0xfedcba9876543210UL)
  xs.unsafe_set(1, b)
  xs.unsafe_set(3, c)
  assert_bits(xs.unsafe_get(0), 0x0123456789abcdefUL, 0xfedcba9876543210UL)
  assert_bits(xs.unsafe_get(1), 0x1111111122222222UL, 0x3333333344444444UL)
  assert_bits(xs.unsafe_get(2), 0x0123456789abcdefUL, 0xfedcba9876543210UL)
  assert_bits(xs.unsafe_get(3), 0xffffffffffffffffUL, 0x8000000000000000UL)
  assert_bits(xs.unsafe_get(4), 0x0123456789abcdefUL, 0xfedcba9876543210UL)
}

///|
test "array and fixedarray makei" {
  let ys : Array[V128] = Array::makei(6, make_by_index)
  inspect(ys.length(), content="6")
  assert_bits(ys.unsafe_get(0), 0x0000000000000000UL, 0x0000000000000001UL)
  assert_bits(ys.unsafe_get(3), 0x3333333333333333UL, 0x3333333333333334UL)
  assert_bits(ys.unsafe_get(5), 0xffffffffffffffffUL, 0xeeeeeeeeeeeeeeeeUL)

  let zs : FixedArray[V128] = FixedArray::makei(4, make_by_index)
  inspect(zs.length(), content="4")
  assert_bits(zs.unsafe_get(0), 0x0000000000000000UL, 0x0000000000000001UL)
  assert_bits(zs.unsafe_get(2), 0x2222222222222222UL, 0x2222222222222223UL)
  assert_bits(zs.unsafe_get(3), 0x3333333333333333UL, 0x3333333333333334UL)
}
