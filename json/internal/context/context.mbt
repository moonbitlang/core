///|
pub struct ParseContext {
  mut offset : Int
  input : String
  end_offset : Int
}

///|
pub fn make(input : String) -> ParseContext {
  { offset: 0, input, end_offset: input.length() }
}

///|
pub fn ParseContext::read_char(ctx : ParseContext) -> Char? {
  if ctx.offset < ctx.end_offset {
    let c = ctx.input[ctx.offset]
    ctx.offset += 1
    let c1 = c.to_int()
    if c1 >= 0xD800 && c1 <= 0xDBFF {
      if ctx.offset < ctx.end_offset {
        let c2 = ctx.input[ctx.offset].to_int()
        if c2 >= 0xDC00 && c2 <= 0xDFFF {
          ctx.offset += 1
          let c3 = (c1 << 10) + c2 - 0x35fdc00
          return Some(Char::from_int(c3))
        }
      }
    }
    Some(c)
  } else {
    None
  }
}

///|
pub fn ParseContext::lex_skip_whitespace(ctx : ParseContext) -> Unit {
  for {
    match ctx.read_char() {
      Some('\t' | '\u000B' | '\u000C' | ' ' | '\n' | '\r') => continue
      Some(c) => {
        if c > '\x7f' && non_ascii_whitespace.contains(c) {
          continue
        }
        ctx.offset -= 1
        break
      }
      None => break
    }
  }
}

///|
priv type CharClass Array[(Char, Char)]

///|
fn CharClass::of(array : Array[(Char, Char)]) -> CharClass {
  CharClass(array)
}

///|
fn CharClass::from_array(array : Array[(Char, Char)]) -> CharClass {
  CharClass(array)
}

///|
fn contains(self : CharClass, c : Char) -> Bool {
  for left = 0, right = self._.length(); left < right; {
    let middle = (left + right) / 2
    let (min, max) = self._[middle]
    if c < min {
      continue left, middle
    } else if c > max {
      continue middle + 1, right
    } else {
      break true
    }
  } else {
    false
  }
}

///|
let non_ascii_whitespace : CharClass = CharClass::of([
  ('\u00A0', '\u00A0'),
  ('\u1680', '\u1680'),
  ('\u2000', '\u200A'),
  ('\u2028', '\u2029'),
  ('\u202F', '\u202F'),
  ('\u205F', '\u205F'),
  ('\u3000', '\u3000'),
  ('\uFEFF', '\uFEFF'),
])