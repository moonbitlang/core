/// Convert Char to String
pub fn to_string(self : Char) -> String {
  let bytes = Bytes::make(4, 0)
  let len = bytes.set_utf8_char(0, self)
  bytes.sub_string(0, len)
}

pub fn debug_write(self : Char, buf : Buffer) -> Unit {
  buf.write_char('\'')
  match self {
    '\n' => buf.write_string("\\n")
    '\r' => buf.write_string("\\r")
    '\'' => buf.write_string("\\'")
    '\\' => buf.write_string("\\\\")
    _ => buf.write_char(self)
  }
  buf.write_char('\'')
}
