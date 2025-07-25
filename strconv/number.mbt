// Copyright 2025 International Digital Economy Academy
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
let min_19digit_int : UInt64 = 100_0000_0000_0000_0000UL

///|
priv struct Number {
  exponent : Int64
  mantissa : UInt64
  negative : Bool
  many_digits : Bool
}

///|
/// Returns the remaining slice, the parsed number, and the number of digits parsed.
fn parse_digits(s : @string.View, x : UInt64) -> (@string.View, UInt64, Int) {
  s.fold_digits(x, (digit, acc : UInt64) => acc * 10UL +
    UInt64::extend_uint(digit.reinterpret_as_uint()))
}

///|
fn try_parse_19digits(
  s : @string.View,
  x : UInt64,
) -> (@string.View, UInt64, Int) {
  let mut x = x
  let mut len = 0
  loop s {
    ['0'..='9' as ch, .. rest] if x < min_19digit_int => {
      len += 1
      x = x * 10UL +
        UInt64::extend_uint((ch.to_int() - '0').reinterpret_as_uint()) // no overflows here
      continue rest
    }
    ['_', .. rest] => continue rest
    s => return (s, x, len)
  }
}

///|
fn parse_scientific(s : @string.View) -> (@string.View, Int64)? {
  // the first character is 'e'/'E' and scientific mode is enabled
  let mut s = match s.step(1) {
    Some(s) => s
    None => return None
  }
  let exp_num = 0L
  let mut neg_exp = false
  if s is ['+' | '-' as ch, .. rest] {
    neg_exp = ch == '-'
    s = rest
  }
  if s is ['0'..='9', ..] {
    let (s, exp_num, _) = s.fold_digits(exp_num, (digit, exp_num : Int64) => if exp_num <
      0x10000L {
      10L * exp_num + digit.to_int64() // no overflows here
    } else {
      exp_num
    })
    if neg_exp {
      Some((s, -exp_num))
    } else {
      Some((s, exp_num))
    }
  } else {
    None
  }
}

///|
/// Parse the number from the string, returning the number and the length of the parsed string.
fn parse_number(s : @string.View) -> (Number, Int)? {
  let mut s = s
  let start = s

  // handle optional +/- sign
  let mut negative = false
  if s is ['-', .. rest] {
    negative = true
    s = rest
  } else if s is ['+', .. rest] {
    s = rest
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
  if s is ['.', .. rest] {
    s = rest
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
  if s is ['e' | 'E', ..] {
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
  while p is ['0' | '.' as ch, .. rest] {
    n_digits -= (ch.to_int() - 46) / 2 // '0' = b'.' + 2
    p = rest
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

///|
/// Parse the number from the string, returning the number and the length of the parsed string.
fn parse_inf_nan(s : @string.View) -> (Double, Int)? {
  let mut s = s
  let mut pos = true
  let mut len = 0
  if s is ['-' | '+' as ch, .. rest] {
    pos = ch == '+'
    s = rest
    len += 1
  }
  if s is ['n' | 'N', 'a' | 'A', 'n' | 'N', ..] {
    Some((@double.not_a_number, len + 3))
  } else if s is ['i' | 'I', 'n' | 'N', 'f' | 'F', .. rest] {
    len += 3
    if rest is ['i' | 'I', 'n' | 'N', 'i' | 'I', 't' | 'T', 'y' | 'Y', ..] {
      len += 5
    }
    if pos {
      Some((@double.infinity, len))
    } else {
      Some((@double.neg_infinity, len))
    }
  } else {
    None
  }
}

///|
/// Returns None if the multiplication might overflow (there are some false-negative corner cases).
/// Otherwise, returns Some(m), where m = self * b.
/// WARNING: Note this function is only used internally in the strconv module, 
/// the current implementation is not completely safe against overflows.
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
  // Can only multiply by 1 or 0, which is handled above.
  if b.clz() == 0 || a.clz() == 0 {
    return None
  }
  let quotient : UInt64 = @uint64.max_value / b
  if a > quotient {
    return None
  }
  Some(a * b)
}
