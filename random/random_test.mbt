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
priv struct ArithmeticSource {
  mut value : UInt64
  step : UInt64
}

///|
impl @random.Source for ArithmeticSource with fn next(self) -> UInt64 {
  let value = self.value
  self.value += self.step
  value
}

///|
test "Rand::double and Rand::float accept interval bounds" {
  let double_source : ArithmeticSource = { value: 0, step: 0 }
  let double_rand = @random.Rand::new(
    generator=double_source as &@random.Source,
  )
  let float_source : ArithmeticSource = { value: 0, step: 0 }
  let float_rand = @random.Rand::new(generator=float_source as &@random.Source)
  inspect(double_rand.double(min=1.0, max=2.0), content="1.9999999999999998")
  inspect(float_rand.float(min=1.0F, max=2.0F), content="1.9999998807907104")
}

///|
test "explicit unit intervals preserve the original paths" {
  let seed = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ123456"
  let implicit = @random.Rand::chacha8(seed~)
  let explicit = @random.Rand::chacha8(seed~)
  @test.assert_eq(implicit.double(), explicit.double(min=0.0, max=1.0))
  @test.assert_eq(implicit.float(), explicit.float(min=0.0F, max=1.0F))
}

///|
fn histogram(
  sample : () -> UInt64,
  first_bits : UInt64,
  bins : Int,
  count : Int,
) -> Array[Int] raise {
  let histogram = Array::make(bins, 0)
  for _ in 0..<count {
    let bits = sample()
    guard bits >= first_bits && bits < first_bits + bins.to_uint64() else {
      fail("sample outside histogram")
    }
    let index = (bits - first_bits).to_int()
    histogram[index] += 1
  }
  histogram
}

///|
test "Rand::double samples every gamma section exactly once" {
  let source : ArithmeticSource = { value: 0, step: 1 }
  let rand = @random.Rand::new(generator=source as &@random.Source)
  let min = 0x3ff0000000000000UL.reinterpret_as_double()
  let max = 0x3ff0000000000004UL.reinterpret_as_double()
  let actual = [
    for _ in 0..<4 => rand.double(min~, max~).reinterpret_as_uint64()
  ]
  @test.assert_eq(actual, [
    0x3ff0000000000003UL, 0x3ff0000000000002UL, 0x3ff0000000000001UL, 0x3ff0000000000000UL,
  ])
}

///|
test "Rand::double includes the short boundary gap across an exponent" {
  let source : ArithmeticSource = { value: 0, step: 1 }
  let rand = @random.Rand::new(generator=source as &@random.Source)
  let min = 0x3fffffffffffffffUL.reinterpret_as_double()
  let max = 0x4000000000000001UL.reinterpret_as_double()
  let actual = [
    for _ in 0..<2 => rand.double(min~, max~).reinterpret_as_uint64()
  ]
  @test.assert_eq(actual, [0x4000000000000000UL, 0x3fffffffffffffffUL])
}

///|
test "Rand::double steps from the larger-magnitude lower bound" {
  let source : ArithmeticSource = { value: 0, step: 1 }
  let rand = @random.Rand::new(generator=source as &@random.Source)
  let min = 0xbff0000000000004UL.reinterpret_as_double()
  let max = 0xbff0000000000000UL.reinterpret_as_double()
  let actual = [
    for _ in 0..<4 => rand.double(min~, max~).reinterpret_as_uint64()
  ]
  @test.assert_eq(actual, [
    0xbff0000000000004UL, 0xbff0000000000003UL, 0xbff0000000000002UL, 0xbff0000000000001UL,
  ])
}

///|
test "Rand::double preserves k above 53 bits without overflow" {
  let source : ArithmeticSource = { value: 0x8000000000000401UL, step: 0 }
  let rand = @random.Rand::new(generator=source as &@random.Source)
  let min = 0xffefffffffffffffUL.reinterpret_as_double()
  let max = 0x7fefffffffffffffUL.reinterpret_as_double()
  let actual = rand.double(min~, max~).reinterpret_as_uint64()
  @test.assert_eq(actual, 0xfcb0000000000000UL)
}

///|
test "Rand::double never returns the open upper bound after a negative residual" {
  let source : ArithmeticSource = { value: 0xfffffffffffffaabUL, step: 0 }
  let rand = @random.Rand::new(generator=source as &@random.Source)
  let min = 0xffefffffffffffffUL.reinterpret_as_double()
  let max = 0x7fe0000000000000UL.reinterpret_as_double()
  let actual = rand.double(min~, max~)
  @test.assert_eq(actual < max, true)
}

///|
test "Rand::double supports the underflow-guard boundary" {
  let source : ArithmeticSource = { value: 0, step: 0 }
  let rand = @random.Rand::new(generator=source as &@random.Source)
  let max = 4.0 * @double.min_positive
  let actual = rand.double(min=0.0, max~).reinterpret_as_uint64()
  @test.assert_eq(actual, 0x002fffffffffffffUL)
}

///|
test "Rand::float samples every gamma section exactly once" {
  let source : ArithmeticSource = { value: 0, step: 1 }
  let rand = @random.Rand::new(generator=source as &@random.Source)
  let min = Float::reinterpret_from_uint(0x3f800000U)
  let max = Float::reinterpret_from_uint(0x3f800004U)
  let actual = [
    for _ in 0..<4 => rand.float(min~, max~).reinterpret_as_uint()
  ]
  @test.assert_eq(actual, [0x3f800003U, 0x3f800002U, 0x3f800001U, 0x3f800000U])
}

///|
test "Rand::float includes the short boundary gap across an exponent" {
  let source : ArithmeticSource = { value: 0, step: 1 }
  let rand = @random.Rand::new(generator=source as &@random.Source)
  let min = Float::reinterpret_from_uint(0x3fffffffU)
  let max = Float::reinterpret_from_uint(0x40000001U)
  let actual = [
    for _ in 0..<2 => rand.float(min~, max~).reinterpret_as_uint()
  ]
  @test.assert_eq(actual, [0x40000000U, 0x3fffffffU])
}

///|
test "Rand::float steps from the larger-magnitude lower bound" {
  let source : ArithmeticSource = { value: 0, step: 1 }
  let rand = @random.Rand::new(generator=source as &@random.Source)
  let min = Float::reinterpret_from_uint(0xbf800004U)
  let max = Float::reinterpret_from_uint(0xbf800000U)
  let actual = [
    for _ in 0..<4 => rand.float(min~, max~).reinterpret_as_uint()
  ]
  @test.assert_eq(actual, [0xbf800004U, 0xbf800003U, 0xbf800002U, 0xbf800001U])
}

///|
test "Rand::float preserves k above 24 bits without overflow" {
  let source : ArithmeticSource = { value: 0x8000008000008001UL, step: 0 }
  let rand = @random.Rand::new(generator=source as &@random.Source)
  let min = Float::reinterpret_from_uint(0xff7fffffU)
  let max = Float::reinterpret_from_uint(0x7f7fffffU)
  let actual = rand.float(min~, max~).reinterpret_as_uint()
  @test.assert_eq(actual, 0xf4000000U)
}

///|
test "Rand::float supports the underflow-guard boundary" {
  let source : ArithmeticSource = { value: 0, step: 0 }
  let rand = @random.Rand::new(generator=source as &@random.Source)
  let max = 4.0F * @float.min_positive
  let actual = rand.float(min=0.0F, max~).reinterpret_as_uint()
  @test.assert_eq(actual, 0x017fffffU)
}

///|
test "gamma-section avoids naive Double bias and the open upper bound" {
  let min_bits = 0x3ff0000000000000UL
  let min = min_bits.reinterpret_as_double()
  let max = 0x3ff0000000000004UL.reinterpret_as_double()
  let naive_source : ArithmeticSource = { value: 0, step: 1UL << 49 }
  let naive_rand = @random.Rand::new(generator=naive_source as &@random.Source)
  let naive = histogram(
    () => (min + (max - min) * naive_rand.double()).reinterpret_as_uint64(),
    min_bits,
    5,
    16,
  )
  let gamma_source : ArithmeticSource = { value: 0, step: 1 }
  let gamma_rand = @random.Rand::new(generator=gamma_source as &@random.Source)
  let gamma = histogram(
    () => gamma_rand.double(min~, max~).reinterpret_as_uint64(),
    min_bits,
    5,
    16,
  )
  @debug.debug_inspect(
    (naive, gamma),
    content="([3, 3, 5, 3, 2], [4, 4, 4, 4, 0])",
  )
}

///|
test "gamma-section avoids naive Float bias and the open upper bound" {
  let min_bits = 0x3f800000U
  let min = Float::reinterpret_from_uint(min_bits)
  let max = Float::reinterpret_from_uint(0x3f800004U)
  let naive_source : ArithmeticSource = { value: 0, step: 1UL << 20 }
  let naive_rand = @random.Rand::new(generator=naive_source as &@random.Source)
  let naive = histogram(
    () => {
      (min + (max - min) * naive_rand.float()).reinterpret_as_uint().to_uint64()
    },
    min_bits.to_uint64(),
    5,
    16,
  )
  let gamma_source : ArithmeticSource = { value: 0, step: 1 }
  let gamma_rand = @random.Rand::new(generator=gamma_source as &@random.Source)
  let gamma = histogram(
    () => gamma_rand.float(min~, max~).reinterpret_as_uint().to_uint64(),
    min_bits.to_uint64(),
    5,
    16,
  )
  @debug.debug_inspect(
    (naive, gamma),
    content="([3, 3, 5, 3, 2], [4, 4, 4, 4, 0])",
  )
}

///|
test "panic Rand::double rejects an empty interval" {
  let rand = @random.Rand::chacha8()
  ignore(rand.double(min=1.0, max=1.0))
}

///|
test "panic Rand::float rejects an empty interval" {
  let rand = @random.Rand::chacha8()
  ignore(rand.float(min=1.0F, max=1.0F))
}

///|
test "panic Rand::double rejects non-finite bounds" {
  let rand = @random.Rand::chacha8()
  ignore(rand.double(min=@double.not_a_number, max=1.0))
}

///|
test "panic Rand::float rejects non-finite bounds" {
  let rand = @random.Rand::chacha8()
  ignore(rand.float(min=@float.not_a_number, max=1.0F))
}

///|
test "panic Rand::double rejects bounds in the underflow region" {
  let rand = @random.Rand::chacha8()
  let two_min_subnormals = 2UL.reinterpret_as_double()
  ignore(rand.double(min=0.0, max=two_min_subnormals))
}

///|
test "panic Rand::float rejects bounds in the underflow region" {
  let rand = @random.Rand::chacha8()
  let two_min_subnormals = Float::reinterpret_from_uint(2U)
  ignore(rand.float(min=0.0F, max=two_min_subnormals))
}

///|
test "panic Rand::double rejects scaled-bound underflow" {
  let rand = @random.Rand::chacha8()
  let min = 0x8030000000000000UL.reinterpret_as_double()
  let max = 0x7fefffffffffffffUL.reinterpret_as_double()
  ignore(rand.double(min~, max~))
}

///|
let fixed_test_seed : Bytes = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ123456"

///|
test "prng" {
  let r = @random.Rand::chacha8(seed=fixed_test_seed)
  @test.assert_eq(r.uint(limit=10), 7)
  @test.assert_eq(r.uint(limit=10), 0)
  @test.assert_eq(r.uint(limit=10), 5)
  @test.assert_eq(r.int(), 1064320769)
  @test.assert_eq(r.double(), 0.3318940049218405)
  @test.assert_eq(r.int(limit=10), 0)
  @test.assert_eq(r.uint(), 311122750)
  let int64_val = r.int64()
  inspect(int64_val, content="2043189202271773519")
  assert_true(int64_val >= 0L)
  let limit : UInt64 = 1UL << 63
  assert_true(int64_val.reinterpret_as_uint64() < limit)
  @test.assert_eq(r.int64(limit=10), 8)
  @test.assert_eq(r.uint64(), 3951155890335085418)
  let a = [1, 2, 3, 4, 5]
  r.shuffle(a.length(), (i : Int, j : Int) => {
    let t = a[i]
    a[i] = a[j]
    a[j] = t
  })
  @test.assert_eq(a, [2, 1, 4, 3, 5])
}

///|
test "Rand::new with generator" {
  let gen : ArithmeticSource = { value: 1, step: 1 }
  let rand = @random.Rand::new(generator=gen as &@random.Source)
  inspect(rand.int(limit=10) < 10, content="true")
}

///|
priv struct ScriptedSource {
  values : FixedArray[UInt64]
  mut index : Int
}

///|
impl @random.Source for ScriptedSource with fn next(self) -> UInt64 {
  let value = self.values[self.index]
  self.index += 1
  value
}

///|
test "Rand::uint64 applies Lemire rejection for limit 3" {
  let source : ScriptedSource = {
    // 3 * 0x5555555555555556 = 2^64 + 2, so the retry maps to 1.
    values: [0UL, 0x5555555555555556UL],
    index: 0,
  }
  let rand = @random.Rand::new(generator=source as &@random.Source)
  let result = rand.uint64(limit=3)
  @debug.debug_inspect((result, source.index), content="(1, 2)")
}

///|
test "Rand::uint64 applies Lemire rejection at the maximum limit" {
  let source : ScriptedSource = { values: [0UL, 2UL], index: 0 }
  let rand = @random.Rand::new(generator=source as &@random.Source)
  let result = rand.uint64(limit=0xffffffffffffffffUL)
  @debug.debug_inspect((result, source.index), content="(1, 2)")
}

///|
test {
  let random = @random.Rand::chacha8(seed=fixed_test_seed)
  inspect(random.float(), content="0.27378302812576294")
  inspect(random.float(), content="0.4169347286224365")
  inspect(random.float(), content="0.5513989925384521")
  inspect(random.float(), content="0.8607915639877319")
  inspect(random.float(), content="0.10972100496292114")
}

///|
test "panic random with invalid seed length" {
  let short_seed = b"short seed"
  let _ = @random.Rand::chacha8(seed=short_seed)
}

///|
test "panic negative limit in shuffle" {
  let r = @random.Rand::new()
  let arr : FixedArray[Int] = [1, 2, 3]
  r.shuffle(-1, (i : Int, j : Int) => {
    let t = arr[i]
    arr[i] = arr[j]
    arr[j] = t
  })
}

///|
test "panic negative limit in int" {
  let r = @random.Rand::new()
  ignore(r.int(limit=-1))
}

///|
test "panic negative limit in int64" {
  let r = @random.Rand::new()
  ignore(r.int64(limit=-1L))
}

///|
test "uint64 modulo bias handling with large limit" {
  let r = @random.Rand::new()
  let limit = 12345678901234567890UL // Large non-power-of-2 number
  let result = r.uint64(limit~)
  inspect(result < limit, content="true")
}

///|
test "bench random" (b : @bench.T) {
  let r = @random.Rand::new()
  b.bench(() => {
    for _ in 0..<1000000 {
      let _ = r.uint64(limit=10000000000000000000UL)
    }
  })
}

///|
test "boolean" {
  let result = @random.Rand::chacha8(seed=fixed_test_seed)
  inspect(result.boolean(), content="true")
}

///|
test "Rand::new uses entropy when available" {
  match @env.rand(0) {
    Some(_) => {
      let r1 = @random.Rand::new()
      let r2 = @random.Rand::new()
      @test.assert_not_eq(
        [r1.uint64(), r1.uint64(), r1.uint64(), r1.uint64()],
        [r2.uint64(), r2.uint64(), r2.uint64(), r2.uint64()],
      )
    }
    None => ()
  }
}

///|
#cfg(target="wasm-gc")
test "Rand::new fallback is deterministic without entropy" {
  let r1 = @random.Rand::new()
  let r2 = @random.Rand::new()
  @test.assert_eq([r1.uint64(), r1.uint64(), r1.uint64(), r1.uint64()], [
    r2.uint64(),
    r2.uint64(),
    r2.uint64(),
    r2.uint64(),
  ])
}
