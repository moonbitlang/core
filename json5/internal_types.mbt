struct ParseContext {
  mut offset : Int
  input : String
  end_offset : Int
}

fn ParseContext::make(input : String) -> ParseContext {
  { offset: 0, input: input, end_offset: input.length() }
}

type CharClass Array[(Char, Char)]

fn CharClass::from_array(array: Array[(Char,Char)]) -> CharClass {
  CharClass(array)
}

fn CharClass::contains(self : CharClass, c : Char) -> Bool {
  for left = 0, right = self.0.length(); left < right; {
    let middle = (left + right) / 2
    let (min, max) = self.0[middle]
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

enum Token {
  Null
  True
  False
  Number(Double)
  String(String)
  LBrace
  RBrace
  LBracket
  RBracket
  Comma
  Colon
} derive(Eq, Debug, Show)
