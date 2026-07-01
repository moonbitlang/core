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

///|
test "bench V128 load8x8_u n=10000" (it : @bench.T) {
  let bytes = make_v128_bench_bytes()
  it.bench(fn() {
    let mut acc = @v128.i64x2_const(0UL, 0UL)
    for i = 0; i < v128_bench_size; i = i + 1 {
      acc = @v128.i64x2_add(acc, @v128.v128_load8x8_u(bytes, i & 63))
    }
    it.keep(acc)
  })
}

///|
test "bench V128 load8x8_s n=10000" (it : @bench.T) {
  let bytes = make_v128_bench_bytes()
  it.bench(fn() {
    let mut acc = @v128.i64x2_const(0UL, 0UL)
    for i = 0; i < v128_bench_size; i = i + 1 {
      acc = @v128.i64x2_add(acc, @v128.v128_load8x8_s(bytes, i & 63))
    }
    it.keep(acc)
  })
}

///|
test "bench V128 load16x4_u n=10000" (it : @bench.T) {
  let bytes = make_v128_bench_bytes()
  it.bench(fn() {
    let mut acc = @v128.i64x2_const(0UL, 0UL)
    for i = 0; i < v128_bench_size; i = i + 1 {
      acc = @v128.i64x2_add(acc, @v128.v128_load16x4_u(bytes, i & 63))
    }
    it.keep(acc)
  })
}

///|
test "bench V128 load16x4_s n=10000" (it : @bench.T) {
  let bytes = make_v128_bench_bytes()
  it.bench(fn() {
    let mut acc = @v128.i64x2_const(0UL, 0UL)
    for i = 0; i < v128_bench_size; i = i + 1 {
      acc = @v128.i64x2_add(acc, @v128.v128_load16x4_s(bytes, i & 63))
    }
    it.keep(acc)
  })
}

///|
test "bench V128 load32x2_u n=10000" (it : @bench.T) {
  let bytes = make_v128_bench_bytes()
  it.bench(fn() {
    let mut acc = @v128.i64x2_const(0UL, 0UL)
    for i = 0; i < v128_bench_size; i = i + 1 {
      acc = @v128.i64x2_add(acc, @v128.v128_load32x2_u(bytes, i & 63))
    }
    it.keep(acc)
  })
}

///|
test "bench V128 load32x2_s n=10000" (it : @bench.T) {
  let bytes = make_v128_bench_bytes()
  it.bench(fn() {
    let mut acc = @v128.i64x2_const(0UL, 0UL)
    for i = 0; i < v128_bench_size; i = i + 1 {
      acc = @v128.i64x2_add(acc, @v128.v128_load32x2_s(bytes, i & 63))
    }
    it.keep(acc)
  })
}

///|
test "bench V128 load_splat n=10000" (it : @bench.T) {
  let bytes = make_v128_bench_bytes()
  it.bench(fn() {
    let mut acc = @v128.i64x2_const(0UL, 0UL)
    for i = 0; i < v128_bench_size; i = i + 1 {
      let offset = i & 63
      acc = @v128.i64x2_add(acc, @v128.v128_load8_splat(bytes, offset))
      acc = @v128.i64x2_add(acc, @v128.v128_load16_splat(bytes, offset))
      acc = @v128.i64x2_add(acc, @v128.v128_load32_splat(bytes, offset))
      acc = @v128.i64x2_add(acc, @v128.v128_load64_splat(bytes, offset))
    }
    it.keep(acc)
  })
}

///|
test "bench V128 load8_lane n=10000" (it : @bench.T) {
  let bytes = make_v128_bench_bytes()
  it.bench(fn() {
    let mut acc = @v128.i64x2_const(0UL, 0UL)
    for i = 0; i < v128_bench_size; i = i + 1 {
      acc = @v128.v128_load8_lane(bytes, i & 63, acc, i & 15)
    }
    it.keep(acc)
  })
}

///|
test "bench V128 load16_lane n=10000" (it : @bench.T) {
  let bytes = make_v128_bench_bytes()
  it.bench(fn() {
    let mut acc = @v128.i64x2_const(0UL, 0UL)
    for i = 0; i < v128_bench_size; i = i + 1 {
      acc = @v128.v128_load16_lane(bytes, i & 63, acc, i & 7)
    }
    it.keep(acc)
  })
}

///|
test "bench V128 load32_lane n=10000" (it : @bench.T) {
  let bytes = make_v128_bench_bytes()
  it.bench(fn() {
    let mut acc = @v128.i64x2_const(0UL, 0UL)
    for i = 0; i < v128_bench_size; i = i + 1 {
      acc = @v128.v128_load32_lane(bytes, i & 63, acc, i & 3)
    }
    it.keep(acc)
  })
}

///|
test "bench V128 load64_lane n=10000" (it : @bench.T) {
  let bytes = make_v128_bench_bytes()
  it.bench(fn() {
    let mut acc = @v128.i64x2_const(0UL, 0UL)
    for i = 0; i < v128_bench_size; i = i + 1 {
      acc = @v128.v128_load64_lane(bytes, i & 63, acc, i & 1)
    }
    it.keep(acc)
  })
}

///|
test "bench V128 extend i8x16 to i16x8 n=10000" (it : @bench.T) {
  let values = make_v128_bench_values()
  it.bench(fn() {
    let mut acc = @v128.i64x2_const(0UL, 0UL)
    for i = 0; i < v128_bench_size; i = i + 1 {
      let value = values.unsafe_get(i)
      acc = @v128.i64x2_add(acc, @v128.i16x8_extend_low_i8x16_s(value))
      acc = @v128.i64x2_add(acc, @v128.i16x8_extend_high_i8x16_u(value))
    }
    it.keep(acc)
  })
}

///|
test "bench V128 extend i16x8 to i32x4 n=10000" (it : @bench.T) {
  let values = make_v128_bench_values()
  it.bench(fn() {
    let mut acc = @v128.i64x2_const(0UL, 0UL)
    for i = 0; i < v128_bench_size; i = i + 1 {
      let value = values.unsafe_get(i)
      acc = @v128.i64x2_add(acc, @v128.i32x4_extend_low_i16x8_s(value))
      acc = @v128.i64x2_add(acc, @v128.i32x4_extend_high_i16x8_u(value))
    }
    it.keep(acc)
  })
}

///|
test "bench V128 extend i32x4 to i64x2 n=10000" (it : @bench.T) {
  let values = make_v128_bench_values()
  it.bench(fn() {
    let mut acc = @v128.i64x2_const(0UL, 0UL)
    for i = 0; i < v128_bench_size; i = i + 1 {
      let value = values.unsafe_get(i)
      acc = @v128.i64x2_add(acc, @v128.i64x2_extend_low_i32x4_s(value))
      acc = @v128.i64x2_add(acc, @v128.i64x2_extend_high_i32x4_u(value))
    }
    it.keep(acc)
  })
}

///|
test "bench V128 all_true n=10000" (it : @bench.T) {
  let values = make_v128_bench_values()
  it.bench(fn() {
    let mut count = 0
    for i = 0; i < v128_bench_size; i = i + 1 {
      let value = values.unsafe_get(i)
      if @v128.i8x16_all_true(value) {
        count = count + 1
      }
      if @v128.i16x8_all_true(value) {
        count = count + 1
      }
      if @v128.i32x4_all_true(value) {
        count = count + 1
      }
      if @v128.i64x2_all_true(value) {
        count = count + 1
      }
    }
    it.keep(count)
  })
}

///|
test "bench V128 bitmask all widths n=10000" (it : @bench.T) {
  let values = make_v128_bench_values()
  it.bench(fn() {
    let mut sum = 0
    for i = 0; i < v128_bench_size; i = i + 1 {
      let value = values.unsafe_get(i)
      sum = sum + @v128.i8x16_bitmask(value)
      sum = sum + @v128.i16x8_bitmask(value)
      sum = sum + @v128.i32x4_bitmask(value)
      sum = sum + @v128.i64x2_bitmask(value)
    }
    it.keep(sum)
  })
}

///|
test "bench V128 swizzle n=10000" (it : @bench.T) {
  let values = make_v128_bench_values()
  let indices = @v128.i8x16_const(
    15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0,
  )
  it.bench(fn() {
    let mut acc = @v128.i64x2_const(0UL, 0UL)
    for i = 0; i < v128_bench_size; i = i + 1 {
      acc = @v128.i8x16_add(
        acc,
        @v128.i8x16_swizzle(values.unsafe_get(i), indices),
      )
    }
    it.keep(acc)
  })
}

///|
test "bench V128 shuffle n=10000" (it : @bench.T) {
  let values = make_v128_bench_values()
  it.bench(fn() {
    let mut acc = @v128.i64x2_const(0UL, 0UL)
    for i = 0; i < v128_bench_size; i = i + 1 {
      let value = values.unsafe_get(i)
      acc = @v128.i8x16_add(
        acc,
        @v128.i8x16_shuffle(
          value, acc, 0, 17, 2, 19, 4, 21, 6, 23, 8, 25, 10, 27, 12, 29, 14, 31,
        ),
      )
    }
    it.keep(acc)
  })
}
