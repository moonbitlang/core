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

let min_19digit_int : UInt64 = 100_0000_0000_0000_0000UL

priv struct Number {
  exponent : Int64
  mantissa : UInt64
  negative : Bool
  many_digits : Bool
}

fn is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

fn to_digit(c : Char) -> Int {
  c.to_int() - 48
}

/// Returns the remaining slice, the parsed number, and the number of digits parsed.
fn parse_digits(s : StringSlice, x : UInt64) -> (StringSlice, UInt64, Int) {
  fold_digits(
    s,
    x,
    fn(digit, acc : UInt64) {
      acc * 10UL + UInt64::extend_uint(digit.reinterpret_as_uint())
    },
  )
}

fn try_parse_19digits(
  s : StringSlice,
  x : UInt64
) -> (StringSlice, UInt64, Int) {
  let mut x = x
  let mut s = s
  let mut len = 0
  while (x < min_19digit_int && s.first_is_digit()) || s.first_is('_') {
    if s.first_is('_') {
      s = s.step_1_unchecked()
    }
    len += 1
    x = x * 10UL + UInt64::extend_uint(to_digit(s[0]).reinterpret_as_uint()) // no overflows here
    s = s.step_1_unchecked()
  }
  (s, x, len)
}

fn parse_scientific(s : StringSlice) -> (StringSlice, Int64)? {
  // the first character is 'e'/'E' and scientific mode is enabled
  let mut s = match s.step(1) {
    Some(s) => s
    None => return None
  }
  let exp_num = 0L
  let mut neg_exp = false
  if s.first_is_either('-', '+') {
    neg_exp = s[0] == '-'
    s = s.step_1_unchecked()
  }
  if s.first_is_digit() {
    let (s, exp_num, _) = fold_digits(
      s,
      exp_num,
      fn(digit, exp_num : Int64) {
        if exp_num < 0x10000L {
          10L * exp_num + digit.to_int64() // no overflows here
        } else {
          exp_num
        }
      },
    )
    if neg_exp {
      Some((s, -exp_num))
    } else {
      Some((s, exp_num))
    }
  } else {
    None
  }
}

/// Parse the number from the string, returning the number and the length of the parsed string.
fn parse_number(s : String) -> (Number, Int)? {
  let mut s = full_slice(s)
  let start = s

  // handle optional +/- sign
  let mut negative = false
  if s.first_is('-') {
    negative = true
    s = s.step_1_unchecked()
  } else if s.first_is('+') {
    s = s.step_1_unchecked()
  }
  if s.is_empty() {
    return None
  }

  // parse initial digits before dot
  let (s, mantissa, consumed) = parse_digits(s, 0UL)
  let mut mantissa = mantissa
  let mut s = s
  let mut n_digits = consumed

  // handle dot with the following digits
  let mut n_after_dot = 0
  let mut exponent = 0L
  if s.first_is('.') {
    s = s.step_1_unchecked()
    // TODO: optimization chance. In the original Rust implementation,
    // the the digits are stored as consecutive bytes in the string.
    // It directly reads 8 bytes to `u64`.
    let (new_s, new_mantissa, consumed_digit) = parse_digits(s, mantissa)
    s = new_s
    mantissa = new_mantissa
    n_after_dot = consumed_digit
    exponent = -n_after_dot.to_int64()
  }
  n_digits += n_after_dot
  if n_digits == 0 {
    return None
  }

  // handle scientific format
  let exp_number = 0L
  if s.first_is_either('e', 'E') {
    let (new_s, exp_number) = match parse_scientific(s) {
      Some(res) => res
      None => return None
    }
    s = new_s
    exponent += exp_number
  }
  let len = start.length() - s.length()

  // handle uncommon case with many digits
  if n_digits <= 19 {
    return Some(({ exponent, mantissa, negative, many_digits: false }, len))
  }
  n_digits -= 19
  let mut many_digits = false
  let mut p = start
  while p.first_is_either('0', '.') {
    n_digits -= (p[0].to_int() - 46) / 2 // '0' = b'.' + 2
    p = p.step_1_unchecked()
  }
  let mut mantissa = mantissa
  if n_digits > 0 {
    // at this point we have more than 19 significant digits, let's try again
    many_digits = true
    mantissa = 0UL
    let s = start
    let (s, new_mantissa, consumed_digit) = try_parse_19digits(s, mantissa)
    mantissa = new_mantissa
    exponent = (if mantissa >= min_19digit_int {
      consumed_digit // big int
    } else {
      let s = match s.step(1) {
        Some(s) => s
        None => return None
      } // fractional component, skip the '.'
      let (_, new_mantissa, consumed_digit) = try_parse_19digits(s, mantissa)
      mantissa = new_mantissa
      consumed_digit
    }).to_int64()
    exponent += exp_number
  } // add back the explicit part
  Some(({ exponent, mantissa, negative, many_digits }, len))
}

/// Parse the number from the string, returning the number and the length of the parsed string.
fn parse_inf_nan(s : String) -> (Double, Int)? {
  fn parse_inf_rest(s : StringSlice) -> Int {
    if s.length() >= 8 && s.subfix_unchecked(3).prefix_eq_ignore_case("inity") {
      8
    } else {
      3
    }
  }

  let s = full_slice(s)
  if s.length() >= 3 {
    if s.prefix_eq_ignore_case("nan") {
      return Some((@double.not_a_number, 3))
    } else if s.prefix_eq_ignore_case("inf") {
      return Some((@double.infinity, parse_inf_rest(s)))
    } else if s.length() >= 4 {
      if s.first_is('+') {
        let s = s.step_1_unchecked()
        if s.prefix_eq_ignore_case("nan") {
          return Some((@double.not_a_number, 4))
        } else if s.prefix_eq_ignore_case("inf") {
          return Some((@double.infinity, 1 + parse_inf_rest(s)))
        }
      } else if s.first_is('-') {
        let s = s.step_1_unchecked()
        if s.prefix_eq_ignore_case("nan") {
          return Some((@double.not_a_number, 4))
        } else if s.prefix_eq_ignore_case("inf") {
          return Some((@double.neg_infinity, 1 + parse_inf_rest(s)))
        }
      }
    }
  }
  None
}

/// Returns None if the multiplication might overflow (there are some false-negative corner cases).
/// Otherwise, returns Some(m), where m = self * b.
fn checked_mul(a : UInt64, b : UInt64) -> UInt64? {
  if a == 0UL || b == 0UL {
    return Some(0UL)
  }
  if a == 1UL {
    return Some(b)
  }
  if b == 1UL {
    return Some(a)
  }
  if b < 0UL || a < 0UL {
    return None
  }
  let r : UInt64 = @uint64.max_value / b
  let q : UInt64 = 1UL / b
  if r + r + q < a {
    return None
  }
  Some(a * b)
}
