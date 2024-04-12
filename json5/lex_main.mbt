fn lex_value(ctx : ParseContext, ~allow_rbracket: Bool = false) -> Result[Token, ParseError] {
  for ; ; {
    match read_char(ctx) {
      Some('\t' | '\u000B' | '\u000C' | ' ' | '\n' | '\r') => continue
      Some('/') => {
        lex_comment(ctx)?
        continue
      }
      Some('{') => return Ok(LBrace)
      Some('[') => return Ok(LBracket)
      Some(']') => {
        if allow_rbracket {
          return Ok(RBracket)
        } else {
          return Err(invalid_char(ctx, ~shift=-1))
        }
      }
      Some('n') => {
        lex_assert_char(ctx, 'u')?
        lex_assert_char(ctx, 'l')?
        lex_assert_char(ctx, 'l')?
        return Ok(Null)
      }
      Some('t') => {
        lex_assert_char(ctx, 'r')?
        lex_assert_char(ctx, 'u')?
        lex_assert_char(ctx, 'e')?
        return Ok(True)
      }
      Some('f') => {
        lex_assert_char(ctx, 'a')?
        lex_assert_char(ctx, 'l')?
        lex_assert_char(ctx, 's')?
        lex_assert_char(ctx, 'e')?
        return Ok(False)
      }
      Some(('-' | '+') as c) => {
        match read_char(ctx) {
          Some('I') => {
            lex_infinity(ctx)?
            return Ok(Number(Double::inf(if c == '-' { -1 } else { 1 })))
          }
          Some('N') => {
            lex_assert_char(ctx, 'a')?
            lex_assert_char(ctx, 'N')?
            return Ok(Number(Double::nan()))
          }
          Some(c2) => {
            let sign = if c == '-' { -1 } else { 1 }
            if c2 >= '1' || c2 <= '9' {
              let n = lex_decimal_integer(ctx, sign, c2.to_int() - 48)?
              return Ok(Number(n))
            } else if c2 == '0' {
              let n = lex_zero(ctx, sign)?
              return Ok(Number(n))
            }
            return Err(invalid_char(ctx, ~shift=-1))
          }
          None => return Err(InvalidEof)
        }
      }
      Some('.') => {
        let n = lex_decimal_point_leading(ctx, 1)?
        return Ok(Number(n))
      }
      Some('0') => {
        let n = lex_zero(ctx, 1)?
        return Ok(Number(n))
      }
      Some(('1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9') as c) => {
        let n = lex_decimal_integer(ctx, 1, c.to_int() - '0'.to_int())?
        return Ok(Number(n))
      }
      Some('I') => {
        lex_infinity(ctx)?
        return Ok(Number(Double::inf(1)))
      }
      Some('N') => {
        lex_assert_char(ctx, 'a')?
        lex_assert_char(ctx, 'N')?
        return Ok(Number(Double::nan()))
      }
      Some('"') => {
        let s = lex_string(ctx, '"')?
        return Ok(String(s))
      }
      Some('\'') => {
        let s = lex_string(ctx, '\'')?
        return Ok(String(s))
      }
      Some(c) => {
        if non_ascii_whitespace.contains(c) {
          continue
        }
        return Err(invalid_char(ctx, ~shift=-1))
      }
      None => return Err(InvalidEof)
    }
  }
}
