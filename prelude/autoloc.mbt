pub type SourceLoc

pub fn SourceLoc::to_string(self : SourceLoc) -> String = "%loc_to_string"

pub fn SourceLoc::debug_write(self : SourceLoc, buf : Buffer) -> Unit {
  buf.write_string(self.to_string())
}

pub type ArgsLoc Array[Option[SourceLoc]]

pub fn ArgsLoc::to_string(self : ArgsLoc) -> String {
  self.0.to_string()
}
