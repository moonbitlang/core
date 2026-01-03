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
fn parse_digits(s : StringView, x : UInt64) -> (StringView, UInt64, Int) {
  s.fold_digits(x, (digit, acc : UInt64) => acc * 10UL +
    UInt64::extend_uint(digit.reinterpret_as_uint()))
}

///|
fn try_parse_19digits(s : StringView, x : UInt64) -> (StringView, UInt64, Int) {
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
fn parse_scientific(s : StringView) -> (StringView, Int64)? {
  let mut s = s
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
/// Parse the number from the string, raising StrConvError if invalid.
fn parse_number(s : StringView) -> Number? raise StrConvError {
  let start = s

  // handle optional +/- sign
  let (s, negative) = match s {
    ['-', .. rest] => (rest, true)
    ['+', .. rest] | rest => (rest, false)
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
    // the digits are stored as consecutive bytes in the string.
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
  if s is ['e' | 'E', .. rest] {
    let (new_s, exp_number) = match parse_scientific(rest) {
      Some(res) => res
      None => return None
    }
    s = new_s
    exponent += exp_number
  }
  guard s is "" else { syntax_err() }

  // handle uncommon case with many digits
  if n_digits <= 19 {
    return Some({ exponent, mantissa, negative, many_digits: false })
  }
  n_digits -= 19
  let mut many_digits = false
  loop start {
    ['0' | '.' as ch, .. rest] => {
      n_digits -= (ch.to_int() - 46) / 2 // '0' = b'.' + 2
      continue rest
    }
    _ => ()
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
      // fractional component, skip the '.'
      guard s is [_, .. s] else { return None }
      let (_, new_mantissa, consumed_digit) = try_parse_19digits(s, mantissa)
      mantissa = new_mantissa
      consumed_digit
    }).to_int64()
    exponent += exp_number
  } // add back the explicit part
  Some({ exponent, mantissa, negative, many_digits })
}

///|
/// Parse the number from the string, raising `StrConvError` if invalid.
fn parse_inf_nan(rest : StringView) -> Double raise StrConvError {
  let (pos, rest) = match rest {
    ['-', .. rest] => (false, rest)
    ['+', .. rest] | rest => (true, rest)
  }
  match rest {
    ['n' | 'N', 'a' | 'A', 'n' | 'N'] => @double.not_a_number
    ['i' | 'I', 'n' | 'N', 'f' | 'F', .. rest] => {
      guard rest
        is ([] | ['i' | 'I', 'n' | 'N', 'i' | 'I', 't' | 'T', 'y' | 'Y']) else {
        syntax_err()
      }
      if pos {
        @double.infinity
      } else {
        @double.neg_infinity
      }
    }
    _ => syntax_err()
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
