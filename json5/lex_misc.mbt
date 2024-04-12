fn read_char(ctx : ParseContext) -> Option[Char] {
  if ctx.offset < ctx.end_offset {
    let c = ctx.input[ctx.offset]
    ctx.offset += 1
    let c1 = c.to_int()
    if c1 >= 0xD800 && c1 <= 0xDBFF {
      if ctx.offset < ctx.end_offset {
        let c2 = ctx.input[ctx.offset].to_int()
        if c2 >= 0xDC00 && c2 <= 0xDFFF {
          ctx.offset += 1
          let c3 = c1.lsl(10).lor(c2).lor(0x10000)
          return Some(Char::from_int(c3))
        }
      }
    }
    Some(c)
  } else {
    None
  }
}

fn lex_skip_whitespace(ctx : ParseContext) -> Result[Unit, ParseError] {
  for ; ; {
    match read_char(ctx) {
      Some('\t' | '\u000B' | '\u000C' | ' ' | '\n' | '\r') => continue
      Some('/') => {
        lex_comment(ctx)?
        continue
      }
      Some(c) => {
        if non_ascii_whitespace.contains(c) {
          continue
        }
        ctx.offset -= 1
        return Ok(())
      }
      None => return Ok(())
    }
  }
}

fn lex_after_array_value(ctx : ParseContext) -> Result[Token, ParseError] {
  lex_skip_whitespace(ctx)?
  match read_char(ctx) {
    Some(']') => Ok(Token::RBracket)
    Some(',') => Ok(Token::Comma)
    Some(_) => Err(invalid_char(ctx, ~shift=-1))
    None => Err(InvalidEof)
  }
}

fn lex_after_property_name(ctx : ParseContext) -> Result[Token, ParseError] {
  lex_skip_whitespace(ctx)?
  match read_char(ctx) {
    Some(':') => Ok(Token::Colon)
    Some(_) => Err(invalid_char(ctx, ~shift=-1))
    None => Err(InvalidEof)
  }
}

fn lex_after_object_value(ctx : ParseContext) -> Result[Token, ParseError] {
  lex_skip_whitespace(ctx)?
  match read_char(ctx) {
    Some('}') => Ok(Token::RBrace)
    Some(',') => Ok(Token::Comma)
    Some(_) => Err(invalid_char(ctx, ~shift=-1))
    None => Err(InvalidEof)
  }
}

fn lex_assert_char(ctx : ParseContext, c : Char) -> Result[Unit, ParseError] {
  match read_char(ctx) {
    Some(c2) => if c == c2 { Ok(()) } else { Err(invalid_char(ctx, ~shift=-1)) }
    None => Err(InvalidEof)
  }
}

fn lex_infinity(ctx : ParseContext) -> Result[Unit, ParseError] {
  lex_assert_char(ctx, 'n')?
  lex_assert_char(ctx, 'f')?
  lex_assert_char(ctx, 'i')?
  lex_assert_char(ctx, 'n')?
  lex_assert_char(ctx, 'i')?
  lex_assert_char(ctx, 't')?
  lex_assert_char(ctx, 'y')
}

fn lex_comment(ctx : ParseContext) -> Result[Unit, ParseError] {
  match read_char(ctx) {
    Some('/') =>
      for ; ; {
        match read_char(ctx) {
          Some('\n' | '\r' | '\u2028' | '\u2029') => {
            ctx.offset -= 1
            return Ok(())
          }
          None => return Ok(())
          _ => ()
        }
      }
    Some('*') =>
      for ; ; {
        match read_char(ctx) {
          Some('*') =>
            match read_char(ctx) {
              Some('/') => return Ok(())
              _ => ()
            }
          None => return Err(InvalidEof)
          _ => ()
        }
      }
    Some(_) => return Err(invalid_char(ctx, ~shift=-1))
    None => return Err(InvalidEof)
  }
}
