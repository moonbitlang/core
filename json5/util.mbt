fn offset_to_position(input : String, offset : Int) -> Position {
  let mut line = 1
  let mut column = 0
  for i = 0; i < offset; i = i + 1 {
    let c = input[i]
    if c == '\n' {
      line += 1
      column = 0
    } else {
      column += 1
    }
  }
  return Position::{ line, column }
}

fn invalid_char(ctx: ParseContext, ~shift : Int = 0) -> ParseError {
  let offset = ctx.offset + shift
  InvalidChar(offset_to_position(ctx.input, offset), ctx.input[offset])
}
