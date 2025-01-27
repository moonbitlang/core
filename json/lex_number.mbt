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
fn lex_decimal_integer(
  ctx : ParseContext,
  builder : Builder
) -> Double!ParseError {
  for {
    match ctx.peek() {
      Some('.') => {
        ctx.bump(builder~)
        return lex_decimal_point!(ctx, builder)
      }
      Some('e' | 'E') => {
        ctx.bump(builder~)
        return lex_decimal_exponent!(ctx, builder)
      }
      Some(c) => {
        if c >= '0' && c <= '9' {
          ctx.bump(builder~)
          continue
        }
        return build_number!(builder)
      }
      None => return build_number!(builder)
    }
  }
}

///|
fn lex_decimal_point(
  ctx : ParseContext,
  builder : Builder
) -> Double!ParseError {
  match ctx.peek() {
    Some(c) =>
      if c >= '0' && c <= '9' {
        ctx.bump(builder~)
        lex_decimal_fraction!(ctx, builder)
      } else {
        invalid_char!(ctx, c)
      }
    None => raise InvalidEof
  }
}

///|
fn lex_decimal_fraction(
  ctx : ParseContext,
  builder : Builder
) -> Double!ParseError {
  for {
    match ctx.peek() {
      Some('e' | 'E') => {
        ctx.bump(builder~)
        return lex_decimal_exponent!(ctx, builder)
      }
      Some(c) => {
        if c >= '0' && c <= '9' {
          ctx.bump(builder~)
          continue
        }
        return build_number!(builder)
      }
      None => return build_number!(builder)
    }
  }
}

///|
fn lex_decimal_exponent(
  ctx : ParseContext,
  builder : Builder
) -> Double!ParseError {
  match ctx.peek() {
    Some('+') | Some('-') => {
      ctx.bump(builder~)
      return lex_decimal_exponent_sign!(ctx, builder)
    }
    Some(c) => {
      if c >= '0' && c <= '9' {
        ctx.bump(builder~)
        return lex_decimal_exponent_integer!(ctx, builder)
      }
      invalid_char!(ctx, c)
    }
    None => raise InvalidEof
  }
}

///|
fn lex_decimal_exponent_sign(
  ctx : ParseContext,
  builder : Builder
) -> Double!ParseError {
  match ctx.peek() {
    Some(c) => {
      if c >= '0' && c <= '9' {
        ctx.bump(builder~)
        return lex_decimal_exponent_integer!(ctx, builder)
      }
      invalid_char!(ctx, c)
    }
    None => raise InvalidEof
  }
}

///|
fn lex_decimal_exponent_integer(
  ctx : ParseContext,
  builder : Builder
) -> Double!ParseError {
  for {
    match ctx.peek() {
      Some(c) => {
        if c >= '0' && c <= '9' {
          ctx.bump(builder~)
          continue
        }
        return build_number!(builder)
      }
      None => return build_number!(builder)
    }
  }
}

///|
fn lex_zero(ctx : ParseContext, builder : Builder) -> Double!ParseError {
  match ctx.peek() {
    Some('.') => {
      ctx.bump(builder~)
      lex_decimal_point!(ctx, builder)
    }
    Some('e' | 'E') => {
      ctx.bump(builder~)
      lex_decimal_exponent!(ctx, builder)
    }
    Some(c) => {
      if c >= '0' && c <= '9' {
        invalid_char!(ctx, c)
      }
      return build_number!(builder)
    }
    None => return build_number!(builder)
  }
}

///|
fn build_number(builder : Builder) -> Double!ParseError {
  let s = builder.builder.to_string()
  try {
    @strconv.parse_double!(s)
  } catch {
    _ => raise InvalidNumber(builder.start_pos, s)
  }
}
