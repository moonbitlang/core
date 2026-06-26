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
// `#valtype` keeps this struct stack-allocated on the native target.
// `scan_json_number` builds + returns one of these on every JSON
// number, and without the annotation each call boxes a ~32-byte heap
// object — measured as ~50 % of total alloc bytes in the all-integer
// json bench (300 k numbers → 9.16 MB / 300 k allocs eliminated).
#valtype
priv struct JsonNumberScan {
  negative : Bool
  is_integer : Bool
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
// Returns NaN to mean "fast path didn't apply; caller should fall
// back to strconv". The fast path itself can only produce 0 or a
// finite Double (the `checked_mul` guard rules out infinity), so NaN
// is a free sentinel — and dodging the `Double?` return means no
// per-number `Some` allocation on the json_parse hot path (one less
// ~16-byte boxed `Option<Double>` per number).
fn JsonNumberScan::try_fast_double(self : JsonNumberScan) -> Double {
  if self.mantissa == 0UL {
    let value = 0.0
    return if self.negative { -value } else { value }
  }
  if self.many_digits ||
    self.exponent < MIN_EXPONENT_FAST_PATH ||
    self.exponent > MAX_EXPONENT_DISGUISED_FAST_PATH ||
    self.mantissa > MAX_MANTISSA_FAST_PATH {
    return @double.not_a_number
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
      None => return @double.not_a_number
    }
    if mantissa > MAX_MANTISSA_FAST_PATH {
      return @double.not_a_number
    }
    mantissa.to_double() * json_pow10_fast_path(MAX_EXPONENT_FAST_PATH.to_int())
  }
  if self.negative {
    -value
  } else {
    value
  }
}

///|
fn ParseContext::scan_json_number(
  ctx : ParseContext,
  start : Int,
  end : Int,
) -> JsonNumberScan {
  let negative = ctx.input.unsafe_get(start) == '-'
  let mut has_decimal = false
  let mut has_exponent = false
  let mut exponent_negative = false
  let mut exponent_part = 0L
  let mut fractional_digits = 0
  let mut mantissa = 0UL
  let mut significant_digits = 0
  let mut seen_nonzero = false
  for i = (if negative { start + 1 } else { start }); i < end; i = i + 1 {
    match ctx.input.unsafe_get(i) {
      '0'..='9' as c => {
        let digit = c.to_int() - '0'
        if has_exponent {
          if exponent_part < EXPONENT_CAP {
            let next_exponent = exponent_part * 10L + digit.to_int64()
            exponent_part = if next_exponent > EXPONENT_CAP {
              EXPONENT_CAP
            } else {
              next_exponent
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
      }
      '.' => has_decimal = true
      'e' | 'E' => {
        has_exponent = true
        if i + 1 < end {
          let next = ctx.input.unsafe_get(i + 1)
          if next == '-' {
            exponent_negative = true
          }
        }
      }
      _ => ()
    }
  }
  let exponent_part = if exponent_negative {
    -exponent_part
  } else {
    exponent_part
  }
  {
    negative,
    is_integer: !has_decimal && !has_exponent,
    mantissa,
    exponent: exponent_part - fractional_digits.to_int64(),
    many_digits: significant_digits > 19,
  }
}

///|
// Shared result type for the number lexing helpers. `#valtype` keeps it
// stack-allocated on the native target, so returning it does not heap-allocate
// the way the previous `(Double, StringView?)` tuple did (one box per parsed
// number).
// `repr` is `Some` only for the rare out-of-range values that fall back to a
// string-preserving representation; it is `None` in the common case.
// Field order matters: the reference field (`repr`) must precede the `Double`
// (`value`). With `value` first, the Wasm backend currently mis-compiles the
// destructuring in `lex_value` (`i32.wrap_i64 expected i64, found f64`), so keep
// `repr` first.
#valtype
priv struct LexedNumber {
  repr : StringView?
  value : Double
}

///|
fn ParseContext::lex_integer_end(
  ctx : ParseContext,
  start : Int,
  end : Int,
) -> LexedNumber {
  let negative = ctx.input.unsafe_get(start) == '-'
  let number_start = if negative { start + 1 } else { start }
  for i = number_start, acc = 0L {
    if i >= end {
      let value = if negative { -acc } else { acc }
      break { value: value.to_double(), repr: None }
    }
    let digit = (ctx.input.unsafe_get(i).to_int() - '0').to_int64()
    if acc > (SAFE_INTEGER_LIMIT - digit) / 10L {
      let s = ctx.input.view(start_offset=start, end_offset=end)
      return if negative {
        { value: @double.neg_infinity, repr: Some(s) }
      } else {
        { value: @double.infinity, repr: Some(s) }
      }
    }
    continue i + 1, acc * 10L + digit
  }
}

///|
fn ParseContext::lex_decimal_integer(
  ctx : ParseContext,
  start~ : Int,
) -> LexedNumber raise ParseError {
  for ;; {
    match ctx.read_char() {
      Some('.') => return ctx.lex_decimal_point(start~)
      Some('e' | 'E') => return ctx.lex_decimal_exponent(start~)
      Some('0'..='9') => continue
      Some(_) => {
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
) -> LexedNumber raise ParseError {
  match ctx.read_char() {
    Some('0'..='9') => ctx.lex_decimal_fraction(start~)
    Some(_) => ctx.invalid_char(shift=-1)
    None => raise InvalidEof
  }
}

///|
fn ParseContext::lex_decimal_fraction(
  ctx : ParseContext,
  start~ : Int,
) -> LexedNumber raise ParseError {
  for ;; {
    match ctx.read_char() {
      Some('e' | 'E') => return ctx.lex_decimal_exponent(start~)
      Some('0'..='9') => continue
      Some(_) => {
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
) -> LexedNumber raise ParseError {
  match ctx.read_char() {
    Some('+' | '-') => return ctx.lex_decimal_exponent_sign(start~)
    Some('0'..='9') => return ctx.lex_decimal_exponent_integer(start~)
    Some(_) => {
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
) -> LexedNumber raise ParseError {
  match ctx.read_char() {
    Some('0'..='9') => return ctx.lex_decimal_exponent_integer(start~)
    Some(_) => {
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
) -> LexedNumber {
  for ;; {
    match ctx.read_char() {
      Some('0'..='9') => continue
      Some(_) => {
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
) -> LexedNumber raise ParseError {
  match ctx.read_char() {
    Some('.') => ctx.lex_decimal_point(start~)
    Some('e' | 'E') => ctx.lex_decimal_exponent(start~)
    Some('0'..='9') => {
      ctx.offset -= 1
      ctx.invalid_char()
    }
    Some(_) => {
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
) -> LexedNumber {
  // Fast path for JSON numbers: the lexer has already validated the grammar,
  // so scan raw UTF-16 digits once and bypass the general strconv parser for
  // safe integers and Clinger-style fast-path doubles. Fall back to strconv for
  // large or precision-sensitive numbers so existing rounding behavior is kept.
  let scan = ctx.scan_json_number(start, end)
  if scan.is_integer {
    // `is_integer` is set by `scan_json_number` only when no `.` and no `e/E`
    // are seen, so for that branch `scan.exponent` is structurally 0 and
    // `scan.mantissa` is exactly the unsigned absolute value of the integer
    // literal. The `scan.exponent == 0L` guard restates that invariant
    // locally so a future relaxation of `is_integer` cannot silently make
    // this branch return an unscaled value; in that case we just fall
    // through to `lex_integer_end`.
    //
    // The mantissa <= 2^53 - 1 check (`SAFE_INTEGER_LIMIT`) keeps the
    // returned Double lossless. `reinterpret_as_uint64` / `reinterpret_as_int64`
    // are value-preserving here because both operands sit in [0, 2^53), well
    // inside the overlap of Int64+ and UInt64.
    if !scan.many_digits &&
      scan.exponent == 0L &&
      scan.mantissa <= SAFE_INTEGER_LIMIT.reinterpret_as_uint64() {
      let v = scan.mantissa.reinterpret_as_int64()
      let signed = if scan.negative { -v } else { v }
      return { value: signed.to_double(), repr: None }
    }
    return ctx.lex_integer_end(start, end)
  }
  let fast = scan.try_fast_double()
  if !fast.is_nan() {
    return { value: fast, repr: None }
  }
  let s = ctx.input.view(start_offset=start, end_offset=end)
  try {
    let d = @internal/strconv.parse_double(s)
    // For normal values, return without string representation
    { value: d, repr: None }
  } catch {
    // If parsing fails as a double, treat it as infinity and preserve the string
    _ =>
      if scan.negative {
        { value: @double.neg_infinity, repr: Some(s) }
      } else {
        { value: @double.infinity, repr: Some(s) }
      }
  }
}
