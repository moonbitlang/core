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
const SAFE_INTEGER_LIMIT : Int64 = 9007199254740991L

///|
const MAX_MANTISSA_FAST_PATH : UInt64 = 9007199254740992UL

///|
const MIN_EXPONENT_FAST_PATH : Int64 = -22L

///|
const MAX_EXPONENT_FAST_PATH : Int64 = 22L

///|
const MAX_EXPONENT_DISGUISED_FAST_PATH : Int64 = 37L

///|
const EXPONENT_CAP : Int64 = 100000L

///|
const MAX_UINT64 : UInt64 = 0xffffffffffffffffUL

///|
let pow10_table : ReadOnlyArray[Double] = [
  1.0, 10.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0, 10000000.0, 100000000.0,
  1000000000.0, 10000000000.0, 100000000000.0, 1000000000000.0, 10000000000000.0,
  100000000000000.0, 1000000000000000.0, 10000000000000000.0, 100000000000000000.0,
  1000000000000000000.0, 10000000000000000000.0, 100000000000000000000.0, 1000000000000000000000.0,
  10000000000000000000000.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
]

///|
let int_pow10_table : ReadOnlyArray[UInt64] = [
  1UL, 10UL, 100UL, 1000UL, 10000UL, 100000UL, 1000000UL, 10000000UL, 100000000UL,
  1000000000UL, 10000000000UL, 100000000000UL, 1000000000000UL, 10000000000000UL,
  100000000000000UL, 1000000000000000UL,
]

///|
priv struct JsonNumberScan {
  negative : Bool
  has_decimal : Bool
  has_exponent : Bool
  mantissa : UInt64
  exponent : Int64
  many_digits : Bool
}

///|
fn json_pow10_fast_path(exponent : Int) -> Double {
  pow10_table[exponent & 31]
}

///|
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
  if b.clz() == 0 || a.clz() == 0 {
    return None
  }
  let quotient = MAX_UINT64 / b
  if a > quotient {
    None
  } else {
    Some(a * b)
  }
}

///|
fn JsonNumberScan::try_fast_double(self : JsonNumberScan) -> Double? {
  if self.mantissa == 0UL {
    let value = 0.0
    return Some(if self.negative { -value } else { value })
  }
  if self.many_digits ||
    self.exponent < MIN_EXPONENT_FAST_PATH ||
    self.exponent > MAX_EXPONENT_DISGUISED_FAST_PATH ||
    self.mantissa > MAX_MANTISSA_FAST_PATH {
    return None
  }
  let value = if self.exponent <= MAX_EXPONENT_FAST_PATH {
    let value = self.mantissa.to_double()
    if self.exponent < 0L {
      value / json_pow10_fast_path(-self.exponent.to_int())
    } else {
      value * json_pow10_fast_path(self.exponent.to_int())
    }
  } else {
    let shift = self.exponent - MAX_EXPONENT_FAST_PATH
    let mantissa = match
      checked_mul(self.mantissa, int_pow10_table[shift.to_int()]) {
      Some(m) => m
      None => return None
    }
    if mantissa > MAX_MANTISSA_FAST_PATH {
      return None
    }
    mantissa.to_double() * json_pow10_fast_path(MAX_EXPONENT_FAST_PATH.to_int())
  }
  Some(if self.negative { -value } else { value })
}

///|
fn ParseContext::scan_json_number(
  ctx : ParseContext,
  start : Int,
  end : Int,
) -> JsonNumberScan {
  let mut i = start
  let negative = if ctx.input.unsafe_get(i) == '-' {
    i += 1
    true
  } else {
    false
  }
  let mut has_decimal = false
  let mut has_exponent = false
  let mut exponent_negative = false
  let mut exponent_part = 0L
  let mut fractional_digits = 0
  let mut mantissa = 0UL
  let mut significant_digits = 0
  let mut seen_nonzero = false
  while i < end {
    let c = ctx.input.unsafe_get(i)
    if c is ('0'..='9') {
      let digit = c.to_int() - '0'
      if has_exponent {
        if exponent_part < EXPONENT_CAP {
          exponent_part = exponent_part * 10L + digit.to_int64()
          if exponent_part > EXPONENT_CAP {
            exponent_part = EXPONENT_CAP
          }
        }
      } else {
        if has_decimal {
          fractional_digits += 1
        }
        if digit != 0 || seen_nonzero {
          seen_nonzero = true
          significant_digits += 1
          if significant_digits <= 19 {
            mantissa = mantissa * 10UL +
              UInt64::extend_uint(digit.reinterpret_as_uint())
          }
        }
      }
    } else if c == '.' {
      has_decimal = true
    } else if c == 'e' || c == 'E' {
      has_exponent = true
      if i + 1 < end {
        let next = ctx.input.unsafe_get(i + 1)
        if next == '-' {
          exponent_negative = true
          i += 1
        } else if next == '+' {
          i += 1
        }
      }
    }
    i += 1
  }
  let exponent_part = if exponent_negative {
    -exponent_part
  } else {
    exponent_part
  }
  {
    negative,
    has_decimal,
    has_exponent,
    mantissa,
    exponent: exponent_part - fractional_digits.to_int64(),
    many_digits: significant_digits > 19,
  }
}

///|
fn ParseContext::lex_integer_end(
  ctx : ParseContext,
  start : Int,
  end : Int,
) -> (Double, StringView?) {
  let mut i = start
  let negative = if ctx.input.unsafe_get(i) == '-' {
    i += 1
    true
  } else {
    false
  }
  let mut acc = 0L
  while i < end {
    let digit = (ctx.input.unsafe_get(i).to_int() - '0').to_int64()
    if acc > (SAFE_INTEGER_LIMIT - digit) / 10L {
      let s = ctx.input.view(start_offset=start, end_offset=end)
      return if negative {
        (@double.neg_infinity, Some(s))
      } else {
        (@double.infinity, Some(s))
      }
    }
    acc = acc * 10L + digit
    i += 1
  }
  let value = if negative { -acc } else { acc }
  (value.to_double(), None)
}

///|
fn ParseContext::lex_decimal_integer(
  ctx : ParseContext,
  start~ : Int,
) -> (Double, StringView?) raise ParseError {
  for ;; {
    match ctx.read_char() {
      Some('.') => return ctx.lex_decimal_point(start~)
      Some('e' | 'E') => return ctx.lex_decimal_exponent(start~)
      Some(c) => {
        if c is ('0'..='9') {
          continue
        }
        ctx.offset -= 1
        return ctx.lex_number_end(start, ctx.offset)
      }
      None => return ctx.lex_number_end(start, ctx.offset)
    }
  }
}

///|
fn ParseContext::lex_decimal_point(
  ctx : ParseContext,
  start~ : Int,
) -> (Double, StringView?) raise ParseError {
  match ctx.read_char() {
    Some(c) =>
      if c is ('0'..='9') {
        ctx.lex_decimal_fraction(start~)
      } else {
        ctx.invalid_char(shift=-1)
      }
    None => raise InvalidEof
  }
}

///|
fn ParseContext::lex_decimal_fraction(
  ctx : ParseContext,
  start~ : Int,
) -> (Double, StringView?) raise ParseError {
  for ;; {
    match ctx.read_char() {
      Some('e' | 'E') => return ctx.lex_decimal_exponent(start~)
      Some(c) => {
        if c is ('0'..='9') {
          continue
        }
        ctx.offset -= 1
        return ctx.lex_number_end(start, ctx.offset)
      }
      None => return ctx.lex_number_end(start, ctx.offset)
    }
  }
}

///|
fn ParseContext::lex_decimal_exponent(
  ctx : ParseContext,
  start~ : Int,
) -> (Double, StringView?) raise ParseError {
  match ctx.read_char() {
    Some('+') | Some('-') => return ctx.lex_decimal_exponent_sign(start~)
    Some(c) => {
      if c is ('0'..='9') {
        return ctx.lex_decimal_exponent_integer(start~)
      }
      ctx.offset -= 1
      ctx.invalid_char()
    }
    None => raise InvalidEof
  }
}

///|
fn ParseContext::lex_decimal_exponent_sign(
  ctx : ParseContext,
  start~ : Int,
) -> (Double, StringView?) raise ParseError {
  match ctx.read_char() {
    Some(c) => {
      if c is ('0'..='9') {
        return ctx.lex_decimal_exponent_integer(start~)
      }
      ctx.offset -= 1
      ctx.invalid_char()
    }
    None => raise InvalidEof
  }
}

///|
fn ParseContext::lex_decimal_exponent_integer(
  ctx : ParseContext,
  start~ : Int,
) -> (Double, StringView?) {
  for ;; {
    match ctx.read_char() {
      Some(c) => {
        if c is ('0'..='9') {
          continue
        }
        ctx.offset -= 1
        return ctx.lex_number_end(start, ctx.offset)
      }
      None => return ctx.lex_number_end(start, ctx.offset)
    }
  }
}

///|
fn ParseContext::lex_zero(
  ctx : ParseContext,
  start~ : Int,
) -> (Double, StringView?) raise ParseError {
  match ctx.read_char() {
    Some('.') => ctx.lex_decimal_point(start~)
    Some('e' | 'E') => ctx.lex_decimal_exponent(start~)
    Some(c) => {
      if c is ('0'..='9') {
        ctx.offset -= 1
        ctx.invalid_char()
      }
      ctx.offset -= 1
      return ctx.lex_number_end(start, ctx.offset)
    }
    None => return ctx.lex_number_end(start, ctx.offset)
  }
}

///|
fn ParseContext::lex_number_end(
  ctx : ParseContext,
  start : Int,
  end : Int,
) -> (Double, StringView?) {
  let scan = ctx.scan_json_number(start, end)
  if !scan.has_decimal && !scan.has_exponent {
    return ctx.lex_integer_end(start, end)
  }
  match scan.try_fast_double() {
    Some(d) => (d, None)
    None => {
      let s = ctx.input.view(start_offset=start, end_offset=end)
      let parsed_double = try? @internal/strconv.parse_double(s)
      match parsed_double {
        // For normal values, return without string representation
        Ok(d) => (d, None)
        // If parsing fails as a double, treat it as infinity and preserve the string
        Err(_) =>
          if scan.negative {
            (@double.neg_infinity, Some(s))
          } else {
            (@double.infinity, Some(s))
          }
      }
    }
  }
}
