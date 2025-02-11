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
pub fn ParseContext::lex_decimal_integer(
  ctx : ParseContext,
  start~ : Int
) -> Double!ParseError {
  for {
    match ctx.read_char() {
      Some('.') => return ctx.lex_decimal_point!(start~)
      Some('e' | 'E') => return ctx.lex_decimal_exponent!(start~)
      Some(c) => {
        if c >= '0' && c <= '9' {
          continue
        }
        ctx.offset -= 1
        return ctx.lex_number_end!(start, ctx.offset)
      }
      None => return ctx.lex_number_end!(start, ctx.offset)
    }
  }
}

///|
fn ParseContext::lex_decimal_point(
  ctx : ParseContext,
  start~ : Int
) -> Double!ParseError {
  match ctx.read_char() {
    Some(c) =>
      if c >= '0' && c <= '9' {
        ctx.lex_decimal_fraction!(start~)
      } else {
        ctx.invalid_char!(shift=-1)
      }
    None => raise InvalidEof
  }
}

///|
fn ParseContext::lex_decimal_fraction(
  ctx : ParseContext,
  start~ : Int
) -> Double!ParseError {
  for {
    match ctx.read_char() {
      Some('e' | 'E') => return ctx.lex_decimal_exponent!(start~)
      Some(c) => {
        if c >= '0' && c <= '9' {
          continue
        }
        ctx.offset -= 1
        return ctx.lex_number_end!(start, ctx.offset)
      }
      None => return ctx.lex_number_end!(start, ctx.offset)
    }
  }
}

///|
fn ParseContext::lex_decimal_exponent(
  ctx : ParseContext,
  start~ : Int
) -> Double!ParseError {
  match ctx.read_char() {
    Some('+') | Some('-') => return ctx.lex_decimal_exponent_sign!(start~)
    Some(c) => {
      if c >= '0' && c <= '9' {
        return ctx.lex_decimal_exponent_integer!(start~)
      }
      ctx.offset -= 1
      ctx.invalid_char!()
    }
    None => raise InvalidEof
  }
}

///|
fn ParseContext::lex_decimal_exponent_sign(
  ctx : ParseContext,
  start~ : Int
) -> Double!ParseError {
  match ctx.read_char() {
    Some(c) => {
      if c >= '0' && c <= '9' {
        return ctx.lex_decimal_exponent_integer!(start~)
      }
      ctx.offset -= 1
      ctx.invalid_char!()
    }
    None => raise InvalidEof
  }
}

///|
fn ParseContext::lex_decimal_exponent_integer(
  ctx : ParseContext,
  start~ : Int
) -> Double!ParseError {
  for {
    match ctx.read_char() {
      Some(c) => {
        if c >= '0' && c <= '9' {
          continue
        }
        ctx.offset -= 1
        return ctx.lex_number_end!(start, ctx.offset)
      }
      None => return ctx.lex_number_end!(start, ctx.offset)
    }
  }
}

///|
pub fn ParseContext::lex_zero(ctx : ParseContext, start~ : Int) -> Double!ParseError {
  match ctx.read_char() {
    Some('.') => ctx.lex_decimal_point!(start~)
    Some('e' | 'E') => ctx.lex_decimal_exponent!(start~)
    Some(c) => {
      if c >= '0' && c <= '9' {
        ctx.offset -= 1
        ctx.invalid_char!()
      }
      ctx.offset -= 1
      return ctx.lex_number_end!( start, ctx.offset)
    }
    None => return ctx.lex_number_end!( start, ctx.offset)
  }
}

///|
pub fn ParseContext::lex_number_end(
  ctx : ParseContext,
  start : Int,
  end : Int
) -> Double!ParseError {
  let s = ctx.input.substring(start~, end~)
  try {
    @strconv.parse_double!(s)
  } catch {
    _ => raise InvalidNumber(offset_to_position(ctx.input, start), s)
  }
}


///|
pub fn ParseContext::invalid_char[T](
  ctx : ParseContext,
  shift~ : Int = 0
) -> T!ParseError {
  let offset = ctx.offset + shift
  raise InvalidChar(offset_to_position(ctx.input, offset), ctx.input[offset])
}

pub fn invalid_eof[T]() -> T!ParseError {
  raise InvalidEof
}