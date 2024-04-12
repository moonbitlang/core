pub struct Position {
  line : Int // 1-based
  column : Int // 0-based
} derive(Eq, Debug)

pub enum ParseError {
  InvalidChar(Position, Char)
  InvalidEof
} derive(Eq, Debug)
