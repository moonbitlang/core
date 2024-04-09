// Copyright 2024 International Digital Economy Academy
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

let min_19digit_int : UInt64 = new_UInt64_Int64(100_0000_0000_0000_0000L)

let int_pow10 = [
  1L, 10L, 100L, 1000L, 10000L, 100000L, 1000000L, 10000000L, 100000000L, 1000000000L,
  10000000000L, 100000000000L, 1000000000000L, 10000000000000L, 100000000000000L,
  1000000000000000L,
]

struct Number {
  exponent : Int64
  mantissa : UInt64
  negative : Bool
  many_digits : Bool
} derive(Debug)

fn parse_8digits(v : Int64) -> Int64 {
  let mask = 0x0000_00FF_0000_00FFL
  let mask_32 = 0xFFFFFFFFL
  let mul1 = 0x000F_4240_0000_0064L
  let mul2 = 0x0000_2710_0000_0001L
  let v = v - 0x3030_3030_3030_3030L
  let v = v * 10L + v.lsr(8) // will not overflow, fits in 63 bits
  let v1 = v.land(mask) * mul1
  let v2 = v.lsr(16).land(mask) * mul2
  (v1 + v2).lsr(32).land(mask_32)
}

fn is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

fn to_digit(c : Char) -> Int {
  c.to_int() - 48
}

/// Returns the accumulated value and the slice left.
fn fold_digits[T](
  s : StringSlice,
  init : T,
  f : (Int, T) -> T
) -> (StringSlice, T) {
  let mut ret = init
  for i = 0; i < s.length(); i = i + 1 {
    if not(is_digit(s[i])) {
      return (s.step(i), ret)
    }
    ret = f(to_digit(s[i]), ret)
  }
  (s.step(s.length()), ret)
}

/// Returns the remaining slice and the parsed number.
fn try_parse_digits(s : StringSlice, x : UInt64) -> (StringSlice, UInt64) {
  fold_digits(
    s,
    x,
    fn(digit, acc : UInt64) { acc * new_UInt64_Int(10) + new_UInt64_Int(digit) },
  )
}

fn try_parse_19digits(s : StringSlice, x : UInt64) -> (StringSlice, UInt64) {
  let mut x = x
  let mut s = s
  while x < min_19digit_int && not(s.is_empty()) && is_digit(s[0]) {
    x = x * new_UInt64_Int(10) + new_UInt64_Int(to_digit(s[0])) // no overflows here
    let a = s[0]
    // println("now x: \(x), \(a)")
    s = s.step(1)
  }
  (s, x)
}

fn parse_scientific(s : StringSlice) -> (StringSlice, Int64) {
  // the first character is 'e'/'E' and scientific mode is enabled
  let start = s
  let mut s = s.step(1)
  let exp_num = 0L
  let mut neg_exp = false
  if not(s.is_empty()) && (s[0] == '-' || s[0] == '+') {
    neg_exp = s[0] == '-'
    s = s.step(1)
  }
  if not(s.is_empty()) && is_digit(s[0]) {
    // println("parse sci: \(s)")
    let (s, exp_num) = fold_digits(
      s,
      exp_num,
      fn(digit, exp_num : Int64) {
        if exp_num < (0x10000L) {
          10L * exp_num + digit.to_int64() // no overflows here
        } else {
          exp_num
        }
      },
    )
    // println("parse sci: \(s), \(exp_num)")
    if neg_exp {
      (s, -exp_num)
    } else {
      (s, exp_num)
    }
  } else {
    (start, 0L)
  }
}

/// Parse the number from the string, returning the number and the length of the parsed string.
fn parse_number(s : String) -> Option[(Number, Int)] {
  let mut s = full_slice(s)
  let start = s

  // handle optional +/- sign
  let mut negative = false
  if s[0] == '-' {
    negative = true
    s = s.step(1)
  } else if s[0] == '+' {
    s = s.step(1)
  }
  if s.length() == 0 {
    return None
  }

  // parse initial digits before dot
  let digit_start = s
  let (s, mantissa) = try_parse_digits(s, new_UInt64_Int(0))
  let mut mantissa = mantissa
  let mut s = s // TODO: remove this once mut is supported in pattern matching
  let mut n_digits = digit_start.length() - s.length()

  // handle dot with the following digits
  let mut n_after_dot = 0
  let mut exponent = 0L
  let int_end = s
  if s[0] == '.' {
    s = s.step(1)
    let before_len = s.length()
    // TODO: optimization chance. In the original Rust implementation,
    // the the digits are stored as consecutive bytes in the string.
    // It directly reads 8 bytes to `u64`.
    let (new_s, new_mantissa) = try_parse_digits(s, mantissa)
    s = new_s
    mantissa = new_mantissa
    n_after_dot = before_len - s.length()
    exponent = -n_after_dot.to_int64()
  }
  n_digits += n_after_dot
  // println("debug \(n_digits) \(n_after_dot)")
  if n_digits == 0 {
    return None
  }

  // handle scientific format
  let exp_number = 0L
  if s[0] == 'e' || s[0] == 'E' {
    let (new_s, exp_number) = parse_scientific(s)
    // println("new_s \(new_s), exp_number \(exp_number)")

    s = new_s // TODO: how to do in-place update for `s`?
    exponent += exp_number
  }
  let len = start.length() - s.length()
  // let ss = s.length()
  // println("debug len: \(len) \(start_length) \(ss)")

  // handle uncommon case with many digits
  if n_digits <= 19 {
    return Some(({ exponent, mantissa, negative, many_digits: false }, len))
  }
  // println("debug: \(n_digits), \(mantissa), \(exponent), \(start)")
  n_digits -= 19
  let mut many_digits = false
  let mut p = start
  while p[0] == '0' || p[0] == '.' {
    n_digits -= (p[0].to_int() - 46) / 2 // '0' = b'.' + 2
    p = p.step(1)
  }
  let mut mantissa = mantissa // TODO: remove this once mut is supported in pattern matching
  // println("before debug: \(n_digits), \(mantissa), \(exponent)")
  if n_digits > 0 {
    // at this point we have more than 19 significant digits, let's try again
    many_digits = true
    mantissa = new_UInt64_Int64(0L)
    let s = start

    // println("before 19 1: \(mantissa) \(s)")
    let (s, new_mantissa) = try_parse_19digits(s, mantissa)
    // println("after 19 1: \(new_mantissa) \(s)")
    mantissa = new_mantissa
    exponent = (if mantissa >= min_19digit_int {
      s.length() - int_end.length() // big int
    } else {
      let s = s.step(1) // fractional component, skip the '.'
      let before = s
      let (s, new_mantissa) = try_parse_19digits(s, mantissa)
      mantissa = new_mantissa
      // println("debug: \(n_digits), \(mantissa), \(exponent)");
      -(s.length() - before.length())
    }).to_int64()
    exponent += exp_number
  } // add back the explicit part
  Some(({ exponent, mantissa, negative, many_digits }, len))
}

/// Parse the number from the string, returning the number and the length of the parsed string.
fn parse_inf_nan(s : String) -> Option[(Double, Int)] {
  fn parse_inf_rest(s : StringSlice) -> Int {
    if s.length() >= 8 && s.subfix(3).eq_ignore_case("inity") {
      8
    } else {
      3
    }
  }

  let s = full_slice(s)
  if s.length() >= 3 {
    if s.eq_ignore_case("nan") {
      return Some((Double::nan(), 3))
    } else if s.eq_ignore_case("inf") {
      return Some((Double::inf(1), parse_inf_rest(s)))
    } else if s.length() >= 4 {
      if s[0] == '+' {
        let s = s.step(1)
        if s.eq_ignore_case("nan") {
          return Some((Double::nan(), 4))
        } else if s.eq_ignore_case("inf") {
          return Some((Double::inf(1), 1 + parse_inf_rest(s)))
        }
      } else if s[0] == '-' {
        let s = s.step(1)
        if s.eq_ignore_case("nan") {
          return Some((Double::nan(), 4))
        } else if s.eq_ignore_case("inf") {
          return Some((Double::inf(-1), 1 + parse_inf_rest(s)))
        }
      }
    }
  }
  None
}