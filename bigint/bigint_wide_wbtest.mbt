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
priv struct MyBigInt(BigInt)

///|
impl Show for MyBigInt with fn output(self, logger) {
  let sign = match self.sign {
    Positive => "Positive"
    Negative => "Negative"
  }
  logger <+
    "{limbs : \{@debug.Repr(self.limbs)}, sign : \{sign}, len : \{self.len} }"
}

///|
test "debug_string" {
  let buf = StringBuilder()
  let v : Array[MyBigInt] = [0, 1, 2, 3, 4, -0, -1, -2, -3]
  (buf as &Logger).write_iter(v.iter(), sep="\n", prefix="", suffix="")
  // Logger::writer_iter()
  // trait logger has no method write_iter
  // precise:
  // (dyn Logger)::write_iter(buf,..)
  //  Logger::trait_method()
  inspect(
    buf,
    content=(
      #|{limbs : <FixedArray: [0, 0]>, sign : Positive, len : 1 }
      #|{limbs : <FixedArray: [1, 0]>, sign : Positive, len : 1 }
      #|{limbs : <FixedArray: [2, 0]>, sign : Positive, len : 1 }
      #|{limbs : <FixedArray: [3, 0]>, sign : Positive, len : 1 }
      #|{limbs : <FixedArray: [4, 0]>, sign : Positive, len : 1 }
      #|{limbs : <FixedArray: [0, 0]>, sign : Positive, len : 1 }
      #|{limbs : <FixedArray: [1, 0]>, sign : Negative, len : 1 }
      #|{limbs : <FixedArray: [2, 0]>, sign : Negative, len : 1 }
      #|{limbs : <FixedArray: [3, 0]>, sign : Negative, len : 1 }
    ),
  )
}

///|
fn check_invariant(a : BigInt) -> Unit raise {
  guard a.len > 0 else { fail("invariant len > 0 is broken: len = \{a.len}") }
  if a.limbs.iter().take(a.len).any(x => x > 0) {
    guard a.limbs[a.len - 1] > 0 else {
      fail(
        "invariant (exists 0 <= i < len. limbs[i] > 0) => limbs[len-1] > 0 is broken",
      )
    }
  } else {
    guard a.len == 1 && a.limbs[0] == 0 else {
      fail(
        "invariant (forall 0 <= i < len. limbs[i] == 0) => limbs[0] == 0 and len == 1 is broken: len = \{a.len}, limbs = \{@debug.Repr(a.limbs)}",
      )
    }
  }
  guard a.limbs.iter().drop(a.len).all(x => x == 0) else {
    fail(
      "invariant forall len <= i < limbs.length(). limbs[i] == 0 is broken: len = \{a.len}, limbs = \{@debug.Repr(a.limbs)}",
    )
  }
}

///|
test "shr" {
  let a = BigInt::from_int64(1234567890123456789L)
  let b = a >> 1
  check_invariant(b)
  inspect(b, content="617283945061728394")
  let c = a >> 64
  check_invariant(c)
  inspect(c, content="0")
  // 2^127 spans two UInt64 limbs; shifting by two complete limbs drops it.
  let a = 1N << 127
  let b = a >> (RADIX_BIT_LEN * 2)
  check_invariant(b)
  inspect(b, content="0")
}

///|
test "mul_single_limb boundaries" {
  // One-limb by one-limb with maximal carry-out: (2^64 - 1)^2.
  let max_limb = 18446744073709551615N
  let p = max_limb * max_limb
  check_invariant(p)
  @test.assert_eq(p, (1N << 128) - (1N << 65) + 1N)
  // Three all-max limbs times one max limb; carry grows len to n + 1.
  let a = (1N << 192) - 1N
  let expected = (1N << 256) - (1N << 192) - (1N << 64) + 1N
  let p = a * max_limb
  check_invariant(p)
  @test.assert_eq(p, expected)
  // commuted operand order takes the same fast path
  let p = max_limb * a
  check_invariant(p)
  @test.assert_eq(p, expected)
  // no carry-out: len stays at self.len, the spare limb beyond len stays zero
  let p = (1N << 128) * 2N
  check_invariant(p)
  @test.assert_eq(p, 1N << 129)
  // the dispatch applies the sign on top of the magnitude-only helper
  @test.assert_eq(a * -max_limb, -expected)
  @test.assert_eq(-a * max_limb, -expected)
  @test.assert_eq(-a * -max_limb, expected)
  // fast path agrees with the general routine on the same magnitudes
  let fast = a.mul_single_limb(0xffff_ffff_ffff_ffffUL)
  check_invariant(fast)
  @test.assert_eq(fast, a.grade_school_mul(max_limb))
}

///|
test "multiplication around the wide Karatsuba threshold" {
  let cases : Array[(Int, Int)] = [
    (63, 63), // schoolbook on both sides of the last pre-threshold case
    (63, 64), // asymmetric input still dispatches on the shorter operand
    (64, 64), // first exact Karatsuba case
    (64, 65), // Karatsuba with one high tail limb
    (65, 65),
  ]
  for case in cases {
    let (limbs_a, limbs_b) = case
    let bits_a = limbs_a * RADIX_BIT_LEN
    let bits_b = limbs_b * RADIX_BIT_LEN
    let a = (1N << bits_a) - 1N
    let b = (1N << bits_b) - 1N
    let expected = (1N << (bits_a + bits_b)) -
      (1N << bits_a) -
      (1N << bits_b) +
      1N
    @test.assert_eq(a.len, limbs_a)
    @test.assert_eq(b.len, limbs_b)
    let product = a * b
    check_invariant(product)
    @test.assert_eq(product, expected)
  }
}

///|
test "add coverage for max(self_len, other_len)" {
  let a = BigInt::from_int(123456789)
  let b = BigInt::from_int(987654321)
  let result = a + b
  inspect(a.len, content="1")
  inspect(b.len, content="1")
  inspect(result.len, content="1")
}

///|
test "sub coverage for max(self_len, other_len)" {
  let a = BigInt::from_int(987654321)
  let b = BigInt::from_int(123456789)
  let result = a - b
  inspect(a.len, content="1")
  inspect(b.len, content="1")
  inspect(result.len, content="1")
}

///|
test "BigInt::bit_length" {
  inspect(0N.bit_length(), content="0")
  inspect(1N.bit_length(), content="1")
  inspect((-1N).bit_length(), content="0")
  inspect(16N.bit_length(), content="5")
  inspect((-16N).bit_length(), content="4")
  inspect(42N.bit_length(), content="6")
  inspect((-42N).bit_length(), content="6")
  inspect(1024N.bit_length(), content="11")
  inspect(10000000N.bit_length(), content="24")
  inspect((1N << 31).bit_length(), content="32")
  inspect((1N << 63).bit_length(), content="64")
}

///|
test "decimal digit hint avoids Int overflow" {
  let cases : Array[Int] = [0, 1, 4095, 4096, 1740261, 1740262, 2147483647]
  for bits in cases {
    let expected = (bits.to_int64() * 1234L / 4096L + 1L).to_int()
    @test.assert_eq(decimal_digit_hint(bits), expected)
  }
}

///|
test "BigInt::ctz" {
  inspect(0N.ctz(), content="0")
  inspect(1N.ctz(), content="0")
  inspect(8N.ctz(), content="3") // 1000
  inspect(12N.ctz(), content="2") // 1100
  inspect(174056N.ctz(), content="3") // 101010011111101000
  inspect((1N << 31).ctz(), content="31")
  inspect((1N << 63).ctz(), content="63")
}

///|
test {
  inspect(
    MyBigInt(-9223372036854775809N),
    content="{limbs : <FixedArray: [9223372036854775809, 0]>, sign : Negative, len : 1 }",
  ) // Int64.min_value - 1
  inspect(
    MyBigInt(-9223372036854775810N),
    content="{limbs : <FixedArray: [9223372036854775810, 0]>, sign : Negative, len : 1 }",
  ) // Int64.min_value - 2
}
