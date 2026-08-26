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

// Specification tests for `parse_double`.
//
// `parse_double` has three routes to an answer — Clinger's fast path, its
// "disguised" extension, and the decimal slow path — chosen from the shape
// of the input rather than from its value. That makes the interesting
// specification a *representation-independence* one: two spellings of the
// same exact decimal must produce the same double, even when they take
// different routes. Padding a mantissa with zeros is enough to force the
// slow path, so the properties below compare spellings that are equal by
// construction and let the implementation pick different routes for them.

///|
/// Compares doubles by bit pattern, so `0.0` and `-0.0` are distinguished
/// and two NaNs with the same payload compare equal.
fn same_double(a : Double, b : Double) -> Bool {
  a.reinterpret_as_uint64() == b.reinterpret_as_uint64()
}

///|
fn parsed(text : String) -> Double? {
  Some(@strconv.parse_double(text)) catch {
    _ => None
  }
}

///|
fn repeat_char(c : Char, n : Int) -> String {
  String::from_array(Array::make(n, c))
}

///|
/// A decimal literal: `digits` scaled by `10^exponent`, optionally negative.
/// Every spelling produced from one of these denotes the same exact number.
struct Literal {
  neg : Bool
  digits : String
  exponent : Int
}

///|
/// `length` is taken up to 45 digits so that mantissas routinely exceed the
/// 19 the fast path can hold — that is what makes the two routes diverge if
/// they are going to.
fn Literal::make(
  neg : Bool,
  raw : ArrayView[Int],
  length_code : Int,
  exponent : Int,
) -> Literal {
  let length = wrap_index(length_code, 45) + 1
  let digits = String::from_array(
    Array::makei(length, i => {
      let seed = if raw.length() == 0 { i } else { raw[i % raw.length()] + i }
      (wrap_index(seed, 10) + '0').unsafe_to_char()
    }),
  )
  { neg, digits, exponent }
}

///|
fn Literal::sign(self : Literal) -> String {
  if self.neg {
    "-"
  } else {
    ""
  }
}

///|
/// `digits e exponent` — the plain spelling.
fn Literal::plain(self : Literal) -> String {
  "\{self.sign()}\{self.digits}e\{self.exponent}"
}

///|
/// The decimal point moved `p` digits in from the left, with the exponent
/// compensating. `p == len` is the plain spelling with a trailing point.
fn Literal::pointed(self : Literal, p : Int) -> String {
  let len = self.digits.length()
  let p = wrap_index(p, len + 1)
  let head = self.digits[0:p].to_owned()
  let tail = self.digits[p:len].to_owned()
  let head = if head == "" { "0" } else { head }
  "\{self.sign()}\{head}.\{tail}e\{self.exponent + len - p}"
}

///|
/// `k` zeros appended to the mantissa, with the exponent compensating. This
/// is the spelling that forces the slow path once the digit count passes
/// the fast path's limit.
fn Literal::padded(self : Literal, k : Int) -> String {
  let k = wrap_index(k, 30)
  "\{self.sign()}\{self.digits}\{repeat_char('0', k)}e\{self.exponent - k}"
}

///|
/// `k` insignificant zeros in front of the mantissa.
fn Literal::leading(self : Literal, k : Int) -> String {
  let k = wrap_index(k, 30)
  "\{self.sign()}\{repeat_char('0', k)}\{self.digits}e\{self.exponent}"
}

///|
/// `0.000…digits`, with the exponent compensating — the same value written
/// as a pure fraction.
fn Literal::fractional(self : Literal, k : Int) -> String {
  let k = wrap_index(k, 30)
  let len = self.digits.length()
  "\{self.sign()}0.\{repeat_char('0', k)}\{self.digits}e\{self.exponent + len + k}"
}

///|
/// Every spelling of the same exact decimal must parse to the same double.
test "quickcheck: parse_double is independent of the spelling" {
  @quickcheck.check(
    (input : (Bool, Array[Int], Int, Int, Int, Int)) => {
      let (neg, raw, len_code, exp_code, p, k) = input
      // Exponents span the whole interesting range: subnormal, normal, and
      // both saturating ends.
      let exponent = wrap_index(exp_code, 700) - 350
      let lit = Literal::make(neg, raw, len_code, exponent)
      let reference = parsed(lit.plain())
      [
        lit.pointed(p),
        lit.padded(k),
        lit.leading(k),
        lit.fractional(k),
        lit.padded(k + 17),
        lit.pointed(p + 1),
      ].all(spelling => {
        match (parsed(spelling), reference) {
          (Some(a), Some(b)) => same_double(a, b)
          (None, None) => true
          _ => false
        }
      })
    },
    count=20000,
  )
}

///|
/// Clinger's theorem: when the mantissa is exactly representable and the
/// power of ten is too, one rounding gives the correctly rounded result. So
/// on that subset the parser must agree with plain double arithmetic.
test "quickcheck: parse_double is exact on the Clinger subset" {
  @quickcheck.check(
    (input : (Int64, Int)) => {
      let (raw, exp_code) = input
      // |mantissa| <= 2^53 and |exponent| <= 22 keep both operands exact.
      let mantissa = raw % 9007199254740993L
      let exponent = wrap_index(exp_code, 45) - 22
      let text = "\{mantissa}e\{exponent}"
      // Built by repeated multiplication rather than `pow`: every power of
      // ten up to 10^22 is exactly representable, so this is exact.
      let mut power = 1.0
      for _ in 0..<exponent.abs() {
        power = power * 10.0
      }
      let expected = if exponent >= 0 {
        mantissa.to_double() * power
      } else {
        mantissa.to_double() / power
      }
      parsed(text) is Some(v) && same_double(v, expected)
    },
    count=20000,
  )
}

///|
/// Parsing is monotone: at a fixed exponent, a larger mantissa cannot parse
/// to a smaller double.
test "quickcheck: parse_double is monotone in the mantissa" {
  @quickcheck.check(
    (input : (UInt64, UInt64, Int)) => {
      let (a, b, exp_code) = input
      let lo = if a <= b { a } else { b }
      let hi = if a <= b { b } else { a }
      let exponent = wrap_index(exp_code, 700) - 350
      match (parsed("\{lo}e\{exponent}"), parsed("\{hi}e\{exponent}")) {
        (Some(x), Some(y)) => x <= y
        // Overflow is reported as an error rather than an infinity, so the
        // larger mantissa may drop out where the smaller one does not.
        // The reverse would mean the order was inverted.
        (Some(_), None) => true
        (None, None) => true
        (None, Some(_)) => false
      }
    },
    count=20000,
  )
}

///|
/// `Double::to_string` produces a decimal that reads back as the same
/// double — the round-trip the shortest-representation printer promises.
test "quickcheck: to_string round-trips through parse_double" {
  @quickcheck.check(
    (d : Double) => {
      if d.is_nan() || d.is_inf() {
        return true
      }
      parsed(d.to_string()) is Some(back) && same_double(back, d)
    },
    count=20000,
  )
}
