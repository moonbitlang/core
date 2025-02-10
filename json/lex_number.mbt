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
  start~ : @string.Index
) -> Double!ParseError {
  for {
    match read_char(ctx) {
      Some('.') => return lex_decimal_point!(ctx, start~)
      Some('e' | 'E') => return lex_decimal_exponent!(ctx, start~)
      Some(c) => {
        if c >= '0' && c <= '9' {
          continue
        }
        unsafe_backoff(ctx, 1)
        return lex_number_end!(ctx, start, ctx.offset)
      }
      None => return lex_number_end!(ctx, start, ctx.offset)
    }
  }
}

///|
fn lex_decimal_point(
  ctx : ParseContext,
  start~ : @string.Index
) -> Double!ParseError {
  match read_char(ctx) {
    Some(c) =>
      if c >= '0' && c <= '9' {
        lex_decimal_fraction!(ctx, start~)
      } else {
        invalid_char!(ctx, shift=-1)
      }
    None => raise InvalidEof
  }
}

///|
fn lex_decimal_fraction(
  ctx : ParseContext,
  start~ : @string.Index
) -> Double!ParseError {
  for {
    match read_char(ctx) {
      Some('e' | 'E') => return lex_decimal_exponent!(ctx, start~)
      Some(c) => {
        if c >= '0' && c <= '9' {
          continue
        }
        backoff(ctx, 1)
        return lex_number_end!(ctx, start, ctx.offset)
      }
      None => return lex_number_end!(ctx, start, ctx.offset)
    }
  }
}

///|
fn lex_decimal_exponent(
  ctx : ParseContext,
  start~ : @string.Index
) -> Double!ParseError {
  match read_char(ctx) {
    Some('+') | Some('-') => return lex_decimal_exponent_sign!(ctx, start~)
    Some(c) => {
      if c >= '0' && c <= '9' {
        return lex_decimal_exponent_integer!(ctx, start~)
      }
      backoff(ctx, 1)
      invalid_char!(ctx)
    }
    None => raise InvalidEof
  }
}

///|
fn lex_decimal_exponent_sign(
  ctx : ParseContext,
  start~ : @string.Index
) -> Double!ParseError {
  match read_char(ctx) {
    Some(c) => {
      if c >= '0' && c <= '9' {
        return lex_decimal_exponent_integer!(ctx, start~)
      }
      backoff(ctx, 1)
      invalid_char!(ctx)
    }
    None => raise InvalidEof
  }
}

///|
fn lex_decimal_exponent_integer(
  ctx : ParseContext,
  start~ : @string.Index
) -> Double!ParseError {
  for {
    match read_char(ctx) {
      Some(c) => {
        if c >= '0' && c <= '9' {
          continue
        }
        backoff(ctx, 1)
        return lex_number_end!(ctx, start, ctx.offset)
      }
      None => return lex_number_end!(ctx, start, ctx.offset)
    }
  }
}

///|
fn lex_zero(ctx : ParseContext, start~ : @string.Index) -> Double!ParseError {
  match read_char(ctx) {
    Some('.') => lex_decimal_point!(ctx, start~)
    Some('e' | 'E') => lex_decimal_exponent!(ctx, start~)
    Some(c) => {
      if c >= '0' && c <= '9' {
        unsafe_backoff(ctx, 1)
        invalid_char!(ctx)
      }
      backoff(ctx, 1)
      return lex_number_end!(ctx, start, ctx.offset)
    }
    None => return lex_number_end!(ctx, start, ctx.offset)
  }
}

///|
fn lex_number_end(
  ctx : ParseContext,
  start : @string.Index,
  end : @string.Index
) -> Double!ParseError {
  // todo: we can change parse_double to handle view to avoid copy here
  let s = ctx.input.as_view(start~, end~).to_string()
  try {
    @strconv.parse_double!(s)
  } catch {
    _ => raise InvalidNumber(offset_to_position(ctx.input, start), s)
  }
}
