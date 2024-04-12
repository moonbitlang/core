fn lex_propery_name(ctx : ParseContext) -> Result[Token, ParseError] {
  match read_char(ctx) {
    Some('}') => Ok(RBrace)
    Some('\'' | '"' as c) => {
      let s = lex_string(ctx, c)?
      Ok(String(s))
    }
    Some('$' | '_') => {
      let s = lex_ident(ctx, ctx.offset - 1)?
      Ok(String(s))
    }
    Some(c) => {
      if c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || non_ascii_id_start.contains(
        c,
      ) {
        let s = lex_ident(ctx, ctx.offset - 1)?
        return Ok(String(s))
      }
      Err(invalid_char(ctx, ~shift=-1))
    }
    None => Err(InvalidEof)
  }
}

fn lex_ident(ctx : ParseContext, start : Int) -> Result[String, ParseError] {
  let buf = Buffer::make(0)
  let mut start = start
  fn flush(end : Int) {
    if start > 0 && end > start {
      buf.write_sub_string(ctx.input, start, end - start)
    }
  }

  for ; ; {
    match read_char(ctx) {
      Some('\\') => {
        flush(ctx.offset - 1)
        lex_assert_char(ctx, 'u')?
        let c = lex_hex_digits(ctx, 4)?
        buf.write_char(Char::from_int(c))
        start = ctx.offset
        continue
      }
      Some('$' | '_') => continue
      Some(c) => {
        if c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c >= '0' && c <= '9' ||
        non_ascii_id_continue.contains(c) {
          continue
        }
        ctx.offset -= 1
        break
      }
      None => break
    }
  }
  flush(ctx.offset)
  Ok(buf.to_string())
}
