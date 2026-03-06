///|
pub struct Range(Int, Int) // line number, length

///|
pub impl Show for Range with output(self, logger) {
  let mut beginning = self.0 + 1 // from array index to line number
  let len = self.1 - self.0
  if len == 1 {
    logger.write_string(beginning.to_string())
  } else {
    if len == 0 {
      // empty ranges begin at line just before the range
      beginning -= 1
    }
    logger.write_string(beginning.to_string())
    logger.write_char(',')
    logger.write_string(len.to_string())
  }
}

///|
pub struct HunkHeader(Range, Range)

///|
/// Creates a hunk header from a (non empty) array of edit
pub fn HunkHeader::new(edits : Array[Edit]) -> Self {
  let first = edits[0]
  let last = edits[edits.length() - 1]
  let old_start = first.old_range().0
  let new_start = first.new_range().0
  let old_end = last.old_range().1
  let new_end = last.new_range().1
  HunkHeader(Range(old_start, old_end), Range(new_start, new_end))
}

///|
pub impl Show for HunkHeader with output(self, logger) {
  logger.write_string("@@ -\{self.0} +\{self.1} @@")
}
