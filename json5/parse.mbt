pub fn parse(input : String) -> Result[@json.JsonValue, ParseError] {
  let ctx = ParseContext::make(input)
  let val = parse_value(ctx)?
  lex_skip_whitespace(ctx)?
  if ctx.offset >= ctx.end_offset {
    Ok(val)
  } else {
    Err(invalid_char(ctx))
  }
}

fn parse_value(ctx : ParseContext) -> Result[@json.JsonValue, ParseError] {
  let tok = lex_value(ctx)?
  parse_value2(ctx, tok)
}

fn parse_value2(ctx : ParseContext, tok : Token) -> Result[@json.JsonValue, ParseError] {
  match tok {
    Null => Ok(Null)
    True => Ok(Boolean(true))
    False => Ok(Boolean(false))
    Number(n) => Ok(Number(n))
    String(s) => Ok(String(s))
    LBrace => parse_object(ctx)
    LBracket => parse_array(ctx)
    _ => abort("unreachable")
  }
}

fn parse_object(ctx : ParseContext) -> Result[@json.JsonValue, ParseError] {
  let mut map = @map.empty()
  for ; ; {
    let tok = lex_propery_name(ctx)?
    match tok {
      RBrace => break
      String(name) => {
        let tok2 = lex_after_property_name(ctx)?
        match tok2 {
          Colon => {
            let val = parse_value(ctx)?
            map = map.insert(name, val)
            let tok3 = lex_after_object_value(ctx)?
            match tok3 {
              Comma => continue
              RBrace => break
              _ => abort("unreachable")
            }
          }
          _ => abort("unreachable")
        }
      }
      _ => abort("unreachable")
    }
  }
  Ok(Object(map))
}

fn parse_array(ctx : ParseContext) -> Result[@json.JsonValue, ParseError] {
  let vec = @vec.new()
  for ; ; {
    let tok = lex_value(ctx, ~allow_rbracket=true)?
    match tok {
      RBracket => break
      _ => {
        vec.push(parse_value2(ctx, tok)?)
        let tok2 = lex_after_array_value(ctx)?
        match tok2 {
          Comma => continue
          RBracket => break
          _ => abort("unreachable")
        }
      }
    }
  }
  Ok(Array(vec))
}
