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
  let (first_old_start, first_old_end) = edits[0].old_range()
  let (first_new_start, first_new_end) = edits[0].new_range()
  let mut old_end = first_old_end
  let mut new_end = first_new_end
  let mut found_old_end = false
  let mut found_new_end = false
  let mut i = edits.length()
  while i > 0 {
    i -= 1
    let edit = edits[i]
    let (edit_old_start, edit_old_end) = edit.old_range()
    let (edit_new_start, edit_new_end) = edit.new_range()
    if !found_old_end && edit_old_start != edit_old_end {
      old_end = edit_old_end
      found_old_end = true
    }
    if !found_new_end && edit_new_start != edit_new_end {
      new_end = edit_new_end
      found_new_end = true
    }
    if found_old_end && found_new_end {
      break
    }
  }
  HunkHeader(Range(first_old_start, old_end), Range(first_new_start, new_end))
}

///|
impl Show for HunkHeader with output(self, logger) {
  logger.write_string("@@ -\{self.0} +\{self.1} @@")
}

///|
pub struct Hunk[T] {
  edits : ArrayView[Edit]
  old : ArrayView[T]
  new : ArrayView[T]
}

///|
pub impl[T : Show] Show for Hunk[T] with output(self, logger) {
  let header = HunkHeader::new(self.edits).to_string()
  logger.write_string(header)
  logger.write_char('\n')
  for edit in self.edits {
    let (prefix, slice) = match edit {
      Insert(..) => ("+", edit.view_from(old=self.old, new=self.new))
      Delete(..) => ("-", edit.view_from(old=self.old, new=self.new))
      Equal(..) => (" ", edit.view_from(old=self.old, new=self.new))
    }
    for s in slice {
      logger.write_string("\{prefix}\{s}\n")
    }
  }
}
