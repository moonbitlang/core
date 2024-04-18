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

fn lex_decimal_integer(
  ctx : ParseContext,
  ~start : Int
) -> Result[Double, ParseError] {
  for ; ; {
    match read_char(ctx) {
      Some('.') => return lex_decimal_point(ctx, ~start)
      Some('e' | 'E') => return lex_decimal_exponent(ctx, ~start)
      Some(c) => {
        if c >= '0' && c <= '9' {
          continue
        }
        ctx.offset -= 1
        return lex_number_end(ctx, start, ctx.offset)
      }
      None => return lex_number_end(ctx, start, ctx.offset)
    }
  }
}

fn lex_decimal_point_leading(
  ctx : ParseContext,
  ~start : Int
) -> Result[Double, ParseError] {
  match read_char(ctx) {
    Some(c) => {
      if c >= '0' && c <= '9' {
        return lex_decimal_fraction(ctx, ~start)
      }
      ctx.offset -= 1
      return Err(invalid_char(ctx))
    }
    None => Err(InvalidEof)
  }
}

fn lex_decimal_point(
  ctx : ParseContext,
  ~start : Int
) -> Result[Double, ParseError] {
  match read_char(ctx) {
    Some('e' | 'E') => return lex_decimal_exponent(ctx, ~start)
    Some(c) => {
      if c >= '0' && c <= '9' {
        return lex_decimal_fraction(ctx, ~start)
      }
      ctx.offset -= 1
      return lex_number_end(ctx, start, ctx.offset)
    }
    None => return lex_number_end(ctx, start, ctx.offset)
  }
}

fn lex_decimal_fraction(
  ctx : ParseContext,
  ~start : Int
) -> Result[Double, ParseError] {
  for ; ; {
    match read_char(ctx) {
      Some('e' | 'E') => return lex_decimal_exponent(ctx, ~start)
      Some(c) => {
        if c >= '0' && c <= '9' {
          continue
        }
        ctx.offset -= 1
        return lex_number_end(ctx, start, ctx.offset)
      }
      None => return lex_number_end(ctx, start, ctx.offset)
    }
  }
}

fn lex_decimal_exponent(
  ctx : ParseContext,
  ~start : Int
) -> Result[Double, ParseError] {
  match read_char(ctx) {
    Some('+') | Some('-') => return lex_decimal_exponent_sign(ctx, ~start)
    Some(c) => {
      if c >= '0' && c <= '9' {
        return lex_decimal_exponent_integer(ctx, ~start)
      }
      ctx.offset -= 1
      return Err(invalid_char(ctx))
    }
    None => Err(InvalidEof)
  }
}

fn lex_decimal_exponent_sign(
  ctx : ParseContext,
  ~start : Int
) -> Result[Double, ParseError] {
  match read_char(ctx) {
    Some(c) => {
      if c >= '0' && c <= '9' {
        return lex_decimal_exponent_integer(ctx, ~start)
      }
      ctx.offset -= 1
      return Err(invalid_char(ctx))
    }
    None => Err(InvalidEof)
  }
}

fn lex_decimal_exponent_integer(
  ctx : ParseContext,
  ~start : Int
) -> Result[Double, ParseError] {
  for ; ; {
    match read_char(ctx) {
      Some(c) => {
        if c >= '0' && c <= '9' {
          continue
        }
        ctx.offset -= 1
        return lex_number_end(ctx, start, ctx.offset)
      }
      None => return lex_number_end(ctx, start, ctx.offset)
    }
  }
}

fn lex_zero(
  ctx : ParseContext,
  ~neg : Bool,
  ~start : Int
) -> Result[Double, ParseError] {
  match read_char(ctx) {
    Some('.') => return lex_decimal_point(ctx, ~start)
    Some('e' | 'E') => return lex_decimal_exponent(ctx, ~start)
    Some('x' | 'X') => return lex_hexadecimal(ctx, ~neg)
    Some(c) => {
      if c >= '0' && c <= '9' {
        ctx.offset -= 1
        return Err(invalid_char(ctx))
      }
      ctx.offset -= 1
      return lex_number_end(ctx, start, ctx.offset)
    }
    None => return lex_number_end(ctx, start, ctx.offset)
  }
}

fn lex_hexadecimal(
  ctx : ParseContext,
  ~neg : Bool
) -> Result[Double, ParseError] {
  match read_char(ctx) {
    Some(c) => {
      if c >= '0' && c <= '9' || c >= 'a' && c <= 'f' || c >= 'A' && c <= 'F' {
        let n = lex_hexadecimal_integer(ctx, hex_digit_to_int(c))?
        return Ok(if neg { -n } else { n })
      }
      ctx.offset -= 1
      return Err(invalid_char(ctx))
    }
    None => Err(InvalidEof)
  }
}

fn lex_hexadecimal_integer(
  ctx : ParseContext,
  n : Int
) -> Result[Double, ParseError] {
  for n = n.to_double() {
    match read_char(ctx) {
      Some(c) => {
        if c >= '0' && c <= '9' || c >= 'a' && c <= 'f' || c >= 'A' && c <= 'F' {
          continue n * 16.0 + hex_digit_to_int(c).to_double()
        }
        ctx.offset -= 1
        return Ok(n)
      }
      None => return Ok(n)
    }
  }
}

fn lex_number_end(
  ctx : ParseContext,
  start : Int,
  end : Int
) -> Result[Double, ParseError] {
  let s = ctx.input.substring(~start, ~end)
  match @strconv.parse_double(s) {
    Ok(d) => Ok(d)
    Err(_) => Err(InvalidNumber(offset_to_position(ctx.input, start), s))
  }
}
