// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
priv struct Range(Int, Int) // line number, length

///|
impl Show for Range with output(self, logger) {
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
priv struct HunkHeader(Range, Range)

///|
/// Creates a hunk header from a (non empty) array of edit
fn HunkHeader::new(edits : ArrayView[Edit]) -> Self {
  let first = edits[0]
  let last = edits[edits.length() - 1]
  let old_start = first.old_range().0
  let new_start = first.new_range().0
  let old_end = last.old_range().1
  let new_end = last.new_range().1
  HunkHeader(Range(old_start, old_end), Range(new_start, new_end))
}

///|
impl Show for HunkHeader with output(self, logger) {
  logger.write_string("@@ -\{self.0} +\{self.1} @@")
}

///|
pub struct Hunk(ArrayView[Edit])

///|
pub fn[T : Show] Hunk::render_with(
  self : Hunk,
  old~ : ArrayView[T],
  new~ : ArrayView[T],
) -> String {
  let buf = StringBuilder::new()
  let header = HunkHeader::new(self.0).to_string()
  buf.write_string(header)
  buf.write_char('\n')
  for edit in self.0 {
    let (prefix, slice) = match edit {
      Insert(..) => ("+", edit.view_from(old~, new~))
      Delete(..) => ("-", edit.view_from(old~, new~))
      Equal(..) => (" ", edit.view_from(old~, new~))
    }
    for s in slice {
      buf.write_string("\{prefix}\{s}\n")
    }
  }
  buf.to_string()
}
