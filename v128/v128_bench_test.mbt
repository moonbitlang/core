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
let v128_bench_size = 10_000

///|
fn make_v128_bench_values() -> Array[V128] {
  Array::makei(v128_bench_size, i => {
    let x = i.to_uint64()
    @v128.i64x2_const(x * 0x0000000000010001UL, x * 0x0000000100000001UL)
  })
}

///|
fn make_v128_bench_bytes() -> FixedArray[Byte] {
  FixedArray::makei(v128_bench_size + 80, i => (i & 0xff).to_byte())
}

///|
test "bench V128 i64x2_add n=10000" (it : @bench.T) {
  let values = make_v128_bench_values()
  it.bench(fn() {
    let mut acc = @v128.i64x2_const(1UL, 2UL)
    for i = 0; i < v128_bench_size; i = i + 1 {
      acc = @v128.i64x2_add(acc, values.unsafe_get(i))
    }
    it.keep(acc)
  })
}

///|
test "bench V128 i32x4_add n=10000" (it : @bench.T) {
  let values = make_v128_bench_values()
  it.bench(fn() {
    let mut acc = @v128.i32x4_const(1, 2, 3, 4)
    for i = 0; i < v128_bench_size; i = i + 1 {
      acc = @v128.i32x4_add(acc, values.unsafe_get(i))
    }
    it.keep(acc)
  })
}

///|
test "bench V128 i8x16_add n=10000" (it : @bench.T) {
  let values = make_v128_bench_values()
  it.bench(fn() {
    let mut acc = @v128.i8x16_splat(1)
    for i = 0; i < v128_bench_size; i = i + 1 {
      acc = @v128.i8x16_add(acc, values.unsafe_get(i))
    }
    it.keep(acc)
  })
}

///|
test "bench V128 i8x16_splat n=10000" (it : @bench.T) {
  it.bench(fn() {
    let mut acc = @v128.i8x16_splat(0)
    for i = 0; i < v128_bench_size; i = i + 1 {
      acc = @v128.i8x16_add(acc, @v128.i8x16_splat((i & 0xff).to_byte()))
    }
    it.keep(acc)
  })
}

///|
test "bench V128 i8x16_extract_lane_u n=10000" (it : @bench.T) {
  let value = @v128.i8x16_const(
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
  )
  it.bench(fn() {
    let mut sum = 0
    for i = 0; i < v128_bench_size; i = i + 1 {
      sum = sum + @v128.i8x16_extract_lane_u(value, i & 15).reinterpret_as_int()
    }
    it.keep(sum)
  })
}

///|
test "bench V128 i8x16_replace_lane n=10000" (it : @bench.T) {
  it.bench(fn() {
    let mut acc = @v128.i8x16_splat(0)
    for i = 0; i < v128_bench_size; i = i + 1 {
      acc = @v128.i8x16_replace_lane(
        acc,
        (i & 0xff).reinterpret_as_uint(),
        i & 15,
      )
    }
    it.keep(acc)
  })
}

///|
test "bench V128 i8x16_bitmask n=10000" (it : @bench.T) {
  let values = make_v128_bench_values()
  it.bench(fn() {
    let mut sum = 0
    for i = 0; i < v128_bench_size; i = i + 1 {
      sum = sum + @v128.i8x16_bitmask(values.unsafe_get(i))
    }
    it.keep(sum)
  })
}

///|
test "bench V128 load/store n=10000" (it : @bench.T) {
  let bytes = make_v128_bench_bytes()
  it.bench(fn() {
    let mut acc = @v128.i64x2_const(0UL, 0UL)
    for i = 0; i < v128_bench_size; i = i + 1 {
      let offset = i & 63
      let value = @v128.v128_load(bytes, offset)
      acc = @v128.i64x2_add(acc, value)
      @v128.v128_store(bytes, offset, acc)
    }
    it.keep(acc)
  })
}
