pub fn to_string[A : Debug, B : Debug](self : (A, B)) -> String {
  let buf = Buffer::make(10)
  Debug::debug_write(self, buf)
  buf.to_string()
}

pub fn to_string[A : Debug, B : Debug, C : Debug](self : (A, B, C)) -> String {
  let buf = Buffer::make(10)
  Debug::debug_write(self, buf)
  buf.to_string()
}

pub fn to_string[A : Debug, B : Debug, C : Debug, D : Debug](
  self : (A, B, C, D)
) -> String {
  let buf = Buffer::make(10)
  Debug::debug_write(self, buf)
  buf.to_string()
}

pub fn to_string[A : Debug, B : Debug, C : Debug, D : Debug, E : Debug](
  self : (A, B, C, D, E)
) -> String {
  let buf = Buffer::make(10)
  Debug::debug_write(self, buf)
  buf.to_string()
}
