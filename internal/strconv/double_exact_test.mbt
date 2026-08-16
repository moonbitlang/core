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

// `parse_double` against exact arithmetic.
//
// The properties in `double_quickcheck_test.mbt` pin down internal
// consistency: every spelling of a decimal agrees with every other, the
// result is monotone, and it round-trips. All of that would still hold if
// the parser were uniformly off by an ulp. What settles the remaining
// question is the definition itself — the nearest double to the exact
// rational `mantissa x 10^exponent`, ties to even — so the oracle below
// computes exactly that in `BigInt` and compares bit patterns.
//
// The exact value is held as `num / den` with both sides integral. Scaling
// it by a power of two puts the quotient in `[2^52, 2^53)`, and the
// remainder decides the rounding. Nothing here shares code, tables, or
// approximations with the implementation.

///|

///|
let big_one : @bigint.BigInt = @bigint.BigInt::from_int(1)

///|
let big_two : @bigint.BigInt = @bigint.BigInt::from_int(2)

///|
let big_ten : @bigint.BigInt = @bigint.BigInt::from_int(10)

///|
/// `round(a / b)` to nearest, ties to even. `b` must be positive.
fn div_round_even(a : @bigint.BigInt, b : @bigint.BigInt) -> @bigint.BigInt {
  let q = a / b
  let r = a % b
  let twice = r * big_two
  match twice.compare(b) {
    c if c < 0 => q
    c if c > 0 => q + big_one
    // Exactly halfway: take the even neighbour.
    _ => if (q % big_two).is_zero() { q } else { q + big_one }
  }
}

///|
/// Builds the double `magnitude * 2^(exponent)` from an integral
/// significand, by assembling the IEEE-754 bit pattern directly rather than
/// going through arithmetic that could round a second time.
///
/// `significand` is in `[2^52, 2^53)` for a normal number, or below `2^52`
/// with `unbiased == -1074` for a subnormal.
fn assemble(neg : Bool, significand : UInt64, unbiased : Int) -> Double {
  let sign = if neg { 0x8000000000000000UL } else { 0UL }
  let bits = if significand < 0x10000000000000UL {
    // Subnormal (or zero): the exponent field is 0 and the significand is
    // the fraction outright.
    sign | significand
  } else {
    let biased = (unbiased + 1023).to_uint64()
    sign | (biased << 52) | (significand - 0x10000000000000UL)
  }
  bits.reinterpret_as_double()
}

///|
/// The correctly rounded double nearest to `sign * digits * 10^exponent`,
/// or `None` when the magnitude overflows the format — matching the
/// implementation's choice to report overflow as an error rather than as an
/// infinity. Underflow is a signed zero, not an error.
fn oracle_double(neg : Bool, digits : String, exponent : Int) -> Double? {
  let mantissa = @bigint.BigInt::from_string(digits)
  if mantissa.is_zero() {
    return Some(assemble(neg, 0UL, 0))
  }
  // The exact value as num / den.
  let mut num = mantissa
  let mut den = big_one
  if exponent >= 0 {
    num = num * big_ten.pow(@bigint.BigInt::from_int(exponent))
  } else {
    den = big_ten.pow(@bigint.BigInt::from_int(-exponent))
  }
  // `p` is the position of the leading bit: the largest p with
  // num/den >= 2^p. Start from the bit lengths and correct by one.
  let mut p = num.bit_length() - den.bit_length()
  if scaled_compare(num, den, p) < 0 {
    p = p - 1
  }
  // Round the significand at 52 bits below the leading bit, except in the
  // subnormal range where the exponent is pinned at -1074.
  let shift = if p < -1022 { 1074 } else { 52 - p }
  let (a, b) = if shift >= 0 {
    (num.shl(shift), den)
  } else {
    (num, den.shl(-shift))
  }
  let mut q = div_round_even(a, b)
  let mut unbiased = if p < -1022 { -1074 } else { p }
  // Rounding up can carry into the next binade.
  if q.compare(big_one.shl(53)) >= 0 {
    q = q.shr(1)
    unbiased = unbiased + 1
  }
  if unbiased > 1023 {
    return None
  }
  Some(assemble(neg, q.to_uint64_exact(), unbiased))
}

///|
/// Compares `num / den` with `2^p` without dividing.
fn scaled_compare(num : @bigint.BigInt, den : @bigint.BigInt, p : Int) -> Int {
  if p >= 0 {
    num.compare(den.shl(p))
  } else {
    num.shl(-p).compare(den)
  }
}

///|
/// `BigInt` has no `to_uint64`; the significand always fits in 53 bits, so
/// go through the low 64 bits of the two's complement representation.
fn @bigint.BigInt::to_uint64_exact(self : @bigint.BigInt) -> UInt64 {
  self.to_int64().reinterpret_as_uint64()
}

///|
test "quickcheck: parse_double is the correctly rounded value" {
  @quickcheck.check(
    (input : (Bool, Array[Int], Int, Int)) => {
      let (neg, raw, len_code, exp_code) = input
      let exponent = wrap_index(exp_code, 760) - 380
      let lit = Literal::make(neg, raw, len_code, exponent)
      match (parsed(lit.plain()), oracle_double(neg, lit.digits, exponent)) {
        (Some(a), Some(b)) => same_double(a, b)
        (None, None) => true
        _ => false
      }
    },
    count=20000,
  )
}

///|
/// The same comparison aimed at the hard cases: mantissas just either side
/// of a rounding boundary, where a parser that is even slightly imprecise
/// picks the wrong neighbour.
test "quickcheck: parse_double rounds correctly at the boundaries" {
  @quickcheck.check(
    (input : (UInt64, Int, Int)) => {
      let (raw, exp_code, nudge) = input
      // Start from an actual double, take its exact decimal expansion, and
      // step a few units in the last decimal place. Halfway cases between
      // two doubles land in this neighbourhood.
      let significand = raw % 9007199254740992UL + 4503599627370496UL
      let exponent = wrap_index(exp_code, 60) - 30
      let stepped = significand.reinterpret_as_int64() +
        (wrap_index(nudge, 11) - 5).to_int64()
      let digits = stepped.to_string()
      match
        (
          parsed("\{digits}e\{exponent}"),
          oracle_double(false, digits, exponent),
        ) {
        (Some(a), Some(b)) => same_double(a, b)
        (None, None) => true
        _ => false
      }
    },
    count=20000,
  )
}
