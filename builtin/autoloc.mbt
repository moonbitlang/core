pub type SourceLoc

pub fn SourceLoc::to_string(self: SourceLoc) -> String = "%loc_to_string"

pub fn SourceLoc::debug_write(self: SourceLoc, buf: Buffer) -> Unit {
  buf.write_string(self.to_string())
}

pub type ArgsLoc Array[Option[SourceLoc]]

pub fn ArgsLoc::to_string(self: ArgsLoc) -> String {
  self.0.to_string()
}

pub fn ArgsLoc::to_json(self: ArgsLoc) -> String {
  let buf = Buffer::make(10)
  buf.write_char('[')
  for i = 0; i < self.0.length(); i = i + 1 {
    if i != 0 { 
      buf.write_string(", ")
    }
    let item = self.0[i];
    match item {
      None => { buf.write_string("null") }
      Some(loc) => {
        loc.to_string().debug_write(buf)
      }
    }
  }
  buf.write_char(']')
  buf.to_string()
}
