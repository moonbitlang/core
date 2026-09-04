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

// Deep arithmetic properties for BigInt, complementing quickcheck_test.mbt.
// That suite pins small-value semantics (an Int64 oracle) and
// construction-path invariance; this one drives the large-operand
// algorithm paths that only engage far beyond 64 bits:
//
// * multiplication straddling the Karatsuba threshold (50 limbs),
//   cross-checked against products reassembled from sub-threshold chunks
//   and against closed forms with maximal carry chains;
// * Knuth and recursive wide-digit division with adversarial divisor top
//   limbs, where quotient-digit estimation is famously fragile;
// * shifts, radix round-trips, pow/modpow, octet round-trips, and
//   fixed-width truncation, at sizes crossing many limb boundaries.
//
// All inputs are deterministic functions of literal seeds (SplitMix64),
// so every target runs the identical value stream — any cross-target
// divergence is itself a failure. This suite found two such divergences,
// moonbitlang/core#4050 (non-js `to_uint`/`to_uint64` truncation of
// large negatives) and moonbitlang/core#4052 (js `to_octets` length
// validation); their dedicated regression tests live alongside the
// respective fixes (truncation_regression_test.mbt and
// octets_regression_test.mbt).

///|
fn mix64(s : UInt64) -> UInt64 {
  let z = s * 6364136223846793005UL + 1442695040888963407UL
  let z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9UL
  let z = (z ^ (z >> 27)) * 0x94D049BB133111EBUL
  z ^ (z >> 31)
}

///|
fn seed_u64(i : Int) -> UInt64 {
  i.to_int64().reinterpret_as_uint64()
}

///|
/// A pseudorandom positive BigInt with exactly `limbs` 32-bit limbs (the
/// top byte is forced nonzero), built through the octet path.
fn mag_of_limbs(seed : UInt64, limbs : Int) -> @bigint.BigInt {
  let n = limbs * 4
  let bytes = Bytes::makei(n, i => {
    let b = (mix64(seed + seed_u64(i)) & 0xffUL).to_int()
    let b = if i == 0 && b == 0 { 1 } else { b }
    b.to_byte()
  })
  @bigint.BigInt::from_octets(bytes)
}

///|
/// Multiplication reassembled from 1024-bit (32-limb) chunk products.
/// Every chunk product stays below the Karatsuba threshold, so this is an
/// independently-routed oracle for the Karatsuba path.
fn chunked_mul(a : @bigint.BigInt, b : @bigint.BigInt) -> @bigint.BigInt {
  let chunk_bits = 1024
  let mask = (1N << chunk_bits) - 1N
  let mut acc = 0N
  let mut x = a
  let mut shift_a = 0
  while x > 0N {
    let xa = x & mask
    if xa > 0N {
      let mut y = b
      let mut shift_b = 0
      while y > 0N {
        let yb = y & mask
        if yb > 0N {
          acc += (xa * yb) << (shift_a + shift_b)
        }
        y = y >> chunk_bits
        shift_b += chunk_bits
      }
    }
    x = x >> chunk_bits
    shift_a += chunk_bits
  }
  acc
}

///|
test "multiplication straddling the Karatsuba threshold" {
  // dense sweep right at the cutoff (50 limbs), where the operand split
  // and recombination is most likely to go wrong
  for la in 47..<54 {
    for lb in 47..<54 {
      let a = mag_of_limbs(seed_u64(la * 100 + lb), la)
      let b = mag_of_limbs(seed_u64(la * 313 + lb) + 1UL, lb)
      assert_eq(a * b, chunked_mul(a, b))
      // all-ones magnitude: every partial product carries
      let ones = (1N << (32 * la)) - 1N
      assert_eq(ones * b, chunked_mul(ones, b))
    }
  }
  // asymmetric and large sizes, plus the sign table
  let sizes : Array[(Int, Int)] = [
    (50, 99),
    (99, 50),
    (100, 100),
    (150, 77),
    (255, 256),
    (300, 129),
  ]
  for si in 0..<sizes.length() {
    let (la, lb) = sizes[si]
    let a = mag_of_limbs(seed_u64(si) * 0x10001UL + 3UL, la)
    let b = mag_of_limbs(seed_u64(si) * 0x20003UL + 5UL, lb)
    let p = a * b
    assert_eq(p, chunked_mul(a, b))
    assert_eq(-a * b, -p)
    assert_eq(a * -b, -p)
    assert_eq(-a * -b, p)
  }
}

///|
test "multiplication closed forms with maximal carry chains" {
  // (2^n - 1)(2^m - 1) and (2^n + 1)(2^m + 1) have shift-and-add closed
  // forms, giving an oracle that never routes through multiplication.
  // 1600 bits = 50 limbs, exactly the Karatsuba threshold.
  let cases : Array[(Int, Int)] = [
    (1599, 1601),
    (1600, 1600),
    (3199, 1601),
    (3200, 3200),
    (1600, 33),
    (1601, 1),
  ]
  for c in cases {
    let (n, m) = c
    let p = ((1N << n) - 1N) * ((1N << m) - 1N)
    assert_eq(p, (1N << (n + m)) - (1N << n) - (1N << m) + 1N)
    let q = ((1N << n) + 1N) * ((1N << m) + 1N)
    assert_eq(q, (1N << (n + m)) + (1N << n) + (1N << m) + 1N)
  }
}

///|
test "quickcheck: distributivity across mixed size classes" {
  // sizes span 1 limb to 120 limbs so that schoolbook, single-limb, and
  // Karatsuba paths all participate in the same identity
  @quickcheck.check(
    (input : (Int, Int, Int, Int)) => {
      let (s, i, j, k) = input
      let szs : Array[Int] = [1, 2, 49, 50, 51, 120]
      let sa = szs[(i & 0x7fffffff) % szs.length()]
      let sb = szs[(j & 0x7fffffff) % szs.length()]
      let sc = szs[(k & 0x7fffffff) % szs.length()]
      let seed = seed_u64(s) * 0x9E3779B9UL
      let a = mag_of_limbs(seed + 1UL, sa)
      let b = mag_of_limbs(seed + 2UL, sb)
      let c = mag_of_limbs(seed + 3UL, sc)
      a * (b + c) == a * b + a * c &&
      a + b - b == a &&
      a * b / b == a &&
      (a * b % b).is_zero()
    },
    count=60,
  )
}

///|
test "quickcheck: truncated division law across mixed size classes" {
  @quickcheck.check(
    (input : (Int, Int, Int, Bool, Bool)) => {
      let (s, i, j, na, nb) = input
      // `mag_of_limbs` counts 32-bit chunks. Extending through 256 chunks
      // crosses the native/wasm recursive-division threshold at 128 chunks.
      let la = 1 + (i & 255)
      let lb = 1 + (j & 255)
      let seed = seed_u64(s) * 0xDEADBEEFUL + 12345UL
      let a0 = mag_of_limbs(seed, la)
      let b0 = mag_of_limbs(seed + 424242UL, lb)
      let a = if na { -a0 } else { a0 }
      let b = if nb { -b0 } else { b0 }
      let q = a / b
      let r = a % b
      guard q * b + r == a else { return false }
      let abs_r = if r < 0N { -r } else { r }
      let abs_b = if b < 0N { -b } else { b }
      guard abs_r < abs_b else { return false }
      // truncated convention: remainder takes the dividend's sign,
      // quotient rounds toward zero
      guard r.is_zero() || (r < 0N) == (a < 0N) else { return false }
      guard q.is_zero() || (q < 0N) == ((a < 0N) != (b < 0N)) else {
        return false
      }
      true
    },
    count=120,
  )
}

///|
test "recursive division across threshold and block boundaries" {
  // Exact bit lengths put divisors immediately below, at, and above the
  // 64-limb native/wasm threshold, with both normalized and heavily shifted
  // top limbs. Quotients range from a partial block through several blocks.
  let sizes : Array[(Int, Int)] = [
    (4032, 4109),
    (4033, 8197),
    (4096, 12293),
    (4097, 8203),
    (8192, 16391),
    (8209, 24631),
  ]
  for size in sizes {
    let (divisor_bits, quotient_bits) = size
    let divisor = (1N << (divisor_bits - 1)) +
      (1N << (divisor_bits / 2)) +
      0xfedcba987654321N
    let quotient = (1N << quotient_bits) - 1N
    for remainder in ([0N, 1N, divisor >> 1, divisor - 1N] : Array[_]) {
      let dividend = quotient * divisor + remainder
      assert_eq(dividend / divisor, quotient)
      assert_eq(dividend % divisor, remainder)
    }
  }
}

///|
test "recursive division with highly unbalanced operands" {
  // On native/wasm the divisor is exactly at the 64-limb recursive threshold
  // while the quotient spans 64 recursive blocks. This exercises repeated
  // in-place replacement of the bounded high window without copying the long
  // unprocessed low prefix.
  let divisor = mag_of_limbs(0x64d1a150UL, 128)
  let quotient = mag_of_limbs(0x4000b10cUL, 4096)
  for remainder in ([0N, 1N, divisor >> 1, divisor - 1N] : Array[_]) {
    let dividend = quotient * divisor + remainder
    assert_eq(dividend / divisor, quotient)
    assert_eq(dividend % divisor, remainder)
  }
}

///|
test "division with adversarial divisor top limbs" {
  // Knuth 4.3.1 quotient-digit estimation is most fragile when the
  // normalized divisor's top limb is minimal (0x80000000) or maximal
  // (0xffffffff) and the quotient digits are all-ones. Exact roundtrip
  // (q*b + r) / b == q with 0 <= r < b catches any mis-estimation.
  let bs : Array[@bigint.BigInt] = []
  for blen in ([2, 3, 5, 20, 60] : Array[_]) {
    bs.push(1N << (32 * blen - 1)) // 0x80000000 0...0
    bs.push((1N << (32 * blen - 1)) + 1N)
    bs.push((1N << (32 * blen)) - 1N) // all 0xffffffff
    bs.push((1N << (32 * blen - 1)) + ((1N << (32 * (blen - 1))) - 1N))
    bs.push((1N << (32 * blen)) - (1N << 32)) // 0xff.. with a zero low limb
  }
  let qs : Array[@bigint.BigInt] = []
  for qlen in ([1, 2, 3, 51, 70] : Array[_]) {
    qs.push((1N << (32 * qlen)) - 1N)
    qs.push(1N << (32 * qlen - 1))
    qs.push((1N << (32 * qlen - 1)) + 1N)
  }
  for b in bs {
    for q in qs {
      for r in ([0N, 1N, b - 1N, b >> 1, b - 2N] : Array[_]) {
        let a = q * b + r
        assert_eq(a / b, q)
        assert_eq(a % b, r)
      }
    }
  }
}

///|
test "division qh estimation corners, three-limb divisors" {
  let pats : Array[UInt] = [
    0U, 1U, 0x7fffffffU, 0x80000000U, 0x80000001U, 0xffffffffU,
  ]
  let big_qs : Array[@bigint.BigInt] = [
    (1N << 1920) - 1N, // 60 all-ones limbs
    (1N << 1600) + 1N,
    ((1N << 96) - 1N) << 512,
  ]
  for v1 in pats {
    if v1 == 0 {
      continue
    }
    for v2 in pats {
      for v3 in pats {
        let b = (@bigint.BigInt::from_uint(v1) << 64) |
          (@bigint.BigInt::from_uint(v2) << 32) |
          @bigint.BigInt::from_uint(v3)
        let qs : Array[@bigint.BigInt] = []
        for q1 in pats {
          if q1 == 0 {
            continue
          }
          qs.push(
            (@bigint.BigInt::from_uint(q1) << 32) |
            @bigint.BigInt::from_uint(0xffffffffU),
          )
        }
        for bq in big_qs {
          qs.push(bq)
        }
        for q in qs {
          for r in ([0N, 1N, b - 1N, b >> 1] : Array[_]) {
            let a = q * b + r
            assert_eq(a / b, q)
            assert_eq(a % b, r)
          }
        }
      }
    }
  }
}

///|
test "shifts against multiplication and floor division" {
  let ks : Array[Int] = [1, 31, 32, 33, 63, 64, 65, 95, 1023, 1024, 1025, 1600]
  for t in 0..<4 {
    let m = mag_of_limbs(0xBEEF00UL + seed_u64(t), 40 + t * 17)
    for a in ([m, -m] : Array[_]) {
      for k in ks {
        let p = 1N << k
        assert_eq(a << k, a * p)
        // a >> k is the floor: the unique q with q*2^k <= a < (q+1)*2^k
        let q = a >> k
        assert_true(q * p <= a)
        assert_true(a < q * p + p)
      }
    }
  }
  // extremes and exact limb-width multiples on negative values
  assert_eq(5N >> 100000, 0N)
  assert_eq(-5N >> 100000, -1N)
  assert_eq(-1N >> 1, -1N)
  assert_eq(-2N >> 1, -1N)
  assert_eq(-3N >> 1, -2N)
  let v = -((1N << 96) + 1N)
  assert_eq(v >> 32, -((1N << 64) + 1N))
  assert_eq(v >> 96, -2N)
  assert_eq(-(1N << 96) >> 96, -1N)
}

///|
test "radix roundtrip for every base 2..36" {
  for base in 2..<=36 {
    for t in 0..<3 {
      let limbs = [1, 8, 40][t]
      let m = mag_of_limbs(seed_u64(base * 100 + t) + 0xD00DUL, limbs)
      for a in ([m, -m] : Array[_]) {
        let s = a.to_string(radix=base)
        assert_eq(@bigint.BigInt::from_string(s, radix=base), a)
      }
    }
  }
}

///|
test "huge decimal roundtrip anchored to a hex literal" {
  // the hex printer is plain bit manipulation, so a parse/print pair that
  // reproduces the original 800-digit hex string anchors the value; the
  // decimal round-trip then exercises the batched base-10^7 converter and
  // the per-digit decimal parser against each other at ~500 limbs
  let digits = "0123456789abcdef"
  let sb = StringBuilder()
  for i in 0..<800 {
    let d = (mix64(0xFACEUL + seed_u64(i)) & 15UL).to_int()
    let d = if i == 0 && d == 0 { 15 } else { d }
    sb.write_char(digits.get_char(d).unwrap())
  }
  let hex = sb.to_string()
  let a = @bigint.BigInt::from_string(hex, radix=16)
  assert_eq(a.to_string(radix=16), hex)
  assert_eq(@bigint.BigInt::from_string(a.to_string()), a)
  let big = mag_of_limbs(0xC0FFEEUL, 500)
  assert_eq(@bigint.BigInt::from_string(big.to_string()), big)
  assert_eq(@bigint.BigInt::from_string((-big).to_string()), -big)
}

///|
test "recursive decimal conversion at power-table boundaries" {
  // The conversion table starts at 10^(19*16) and squares from there. Values
  // around twice and four times that exponent exercise exact divisors and the
  // zero padding on either side of every recursive split.
  for digits in ([607, 608, 609, 1215, 1216, 1217, 2432] : Array[_]) {
    let power = 10N.pow(@bigint.BigInt::from_int(digits))
    let exact = StringBuilder(size_hint=digits + 1)
    exact.write_char('1')
    for _ in 0..<digits {
      exact.write_char('0')
    }
    assert_eq(power.to_string(), exact.to_string())

    let below = StringBuilder(size_hint=digits)
    for _ in 0..<digits {
      below.write_char('9')
    }
    assert_eq((power - 1N).to_string(), below.to_string())

    let above = StringBuilder(size_hint=digits + 1)
    above.write_char('1')
    for _ in 1..<digits {
      above.write_char('0')
    }
    above.write_char('1')
    assert_eq((power + 1N).to_string(), above.to_string())
  }
}

///|
test "pow against iterated multiplication, modpow against reduction" {
  for t in 0..<4 {
    let base0 = mag_of_limbs(0xAB0BAUL + seed_u64(t) * 131UL, 3)
    for b in ([base0, -base0] : Array[_]) {
      let m = mag_of_limbs(0x60D5EEDUL + seed_u64(t), 2)
      let mut acc = 1N
      for e in 0..<9 {
        let eb = @bigint.BigInt::from_int(e)
        assert_eq(b.pow(eb), acc)
        // modpow result is canonical: in [0, m) even for negative bases
        assert_eq(b.pow(eb, modulus=m), (acc % m + m) % m)
        acc = acc * b
      }
    }
  }
}

///|
test "octets roundtrip at every length" {
  let lens : Array[Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 63, 64, 65]
  for li in 0..<lens.length() {
    let n = lens[li]
    let bytes = Bytes::makei(n, i => {
      let b = (mix64(0x0C7E75UL + seed_u64(li * 1000 + i)) & 0xffUL).to_int()
      let b = if i == 0 && b == 0 { 1 } else { b }
      b.to_byte()
    })
    let x = @bigint.BigInt::from_octets(bytes)
    assert_eq(x.to_octets(length=n), bytes)
    assert_eq(x.to_octets(), bytes)
  }
}

///|
test "fixed-width conversion boundaries and truncation" {
  let int64s : Array[Int64] = [
    0L, 1L, -1L, 2147483647L, -2147483648L, 2147483648L, -2147483649L, 4294967295L,
    4294967296L, -4294967296L, 9223372036854775807L, -9223372036854775808L,
  ]
  for x in int64s {
    let b = @bigint.BigInt::from_int64(x)
    assert_eq(b.to_int64(), x)
    assert_eq(@bigint.BigInt::from_string(x.to_string()), b)
  }
  let uint64s : Array[UInt64] = [
    0UL, 1UL, 4294967295UL, 4294967296UL, 9223372036854775807UL, 9223372036854775808UL,
    18446744073709551615UL,
  ]
  for u in uint64s {
    let b = @bigint.BigInt::from_uint64(u)
    assert_eq(b.to_uint64(), u)
  }
  // truncation keeps the low bits in two's complement — regression for
  // the magnitude-limb defect on negatives beyond one modulus
  assert_eq(((1N << 80) + 5N).to_uint64(), 5UL)
  assert_eq((-(1N << 80) - 5N).to_uint64(), 0UL - 5UL)
  assert_eq((-(1N << 65) - 5N).to_uint64(), 0UL - 5UL)
  assert_eq(((1N << 80) + 5N).to_uint(), 5U)
  assert_eq((-(1N << 80) - 5N).to_uint(), 0U - 5U)
  assert_eq((-(1N << 33) - 5N).to_uint(), 0U - 5U)
  assert_eq((-(1N << 34)).to_uint(), 0U)
  assert_eq((-(1N << 33) - 4294967295N).to_uint(), 1U)
}

///|
test "comparison sign agrees with subtraction" {
  let sizes : Array[Int] = [1, 2, 3, 40, 60, 100]
  for si in 0..<sizes.length() {
    for sj in 0..<sizes.length() {
      let a0 = mag_of_limbs(seed_u64(si * 31 + sj) + 5UL, sizes[si])
      let b0 = mag_of_limbs(seed_u64(sj * 17 + si) + 11UL, sizes[sj])
      for signs in 0..<4 {
        let a = if (signs & 1) == 0 { a0 } else { -a0 }
        let b = if (signs & 2) == 0 { b0 } else { -b0 }
        // compare's contract is sign-only (the exact magnitude differs
        // between targets), so normalize before comparing
        let c0 = a.compare(b)
        let c = if c0 < 0 { -1 } else if c0 == 0 { 0 } else { 1 }
        let diff = a - b
        let d = if diff < 0N { -1 } else if diff.is_zero() { 0 } else { 1 }
        assert_eq(c, d)
        assert_eq(a == b, c == 0)
      }
    }
  }
}

///|
test "parse rejections and canonical acceptances agree across targets" {
  // the js target routes bases 2/8/10/16 through native BigInt parsing;
  // every other target uses the pure implementation — the accepted
  // language must be identical
  let bad10 : Array[String] = [
    "", "-", "12a", "1 2", " 12", "12 ", "+5", "1_2", "0x5", "١٢", "12.0", "1e3",
    "--1", "-+1", "0b1", "-0x1",
  ]
  for s in bad10 {
    assert_true(
      @test.expect_error(() => @bigint.parse_bigint(s)) is Failure::Failure(_),
    )
  }
  let bad16 : Array[String] = [
    "", "-", "g", "0x5", " f", "f ", "+f", "f_f", "--f",
  ]
  for s in bad16 {
    assert_true(
      @test.expect_error(() => @bigint.parse_bigint(s, base=16))
      is Failure::Failure(_),
    )
  }
  inspect(@bigint.parse_bigint("0005"), content="5")
  inspect(@bigint.parse_bigint("-0"), content="0")
  inspect(@bigint.parse_bigint("-0000"), content="0")
  inspect(@bigint.parse_bigint("00ff", base=16), content="255")
  inspect(@bigint.parse_bigint("-00FF", base=16), content="-255")
  inspect(@bigint.parse_bigint("-0000", base=16), content="0")
  inspect(@bigint.parse_bigint("z", base=36), content="35")
  inspect(@bigint.parse_bigint("-Z", base=36), content="-35")
  inspect(@bigint.parse_bigint("0007", base=8), content="7")
  inspect(@bigint.parse_bigint("-101", base=2), content="-5")
}
