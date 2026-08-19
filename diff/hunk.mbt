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
impl Show for Range with fn output(self, logger) {
  let mut beginning = self.0 + 1 // from array index to line number
  let len = self.1 - self.0
  if len == 1 {
    logger.write_object(beginning)
  } else {
    if len == 0 {
      // empty ranges begin at line just before the range
      beginning -= 1
    }
    logger <+ "\{l => l.write_object(beginning)},\{l => l.write_object(len)}"
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
impl Show for HunkHeader with fn output(self, logger) {
  logger <+ "@@ -\{self.0} +\{self.1} @@"
}

///|
/// A contiguous diff hunk with its edit script and the matching source ranges.
///
/// The type is abstract; render it with `render`.
struct Hunk[T] {
  edits : ArrayView[Edit]
  old : ArrayView[T]
  new : ArrayView[T]
}

///|
/// The hunk's unified-diff header, e.g. `@@ -1,3 +1,3 @@`.
///
/// The numbering rules (1-based lines, single-line ranges shown without a
/// length, empty ranges anchored to the previous line) are canonical and easy
/// to get subtly wrong, so they live here rather than in each renderer.
pub fn[T] Hunk::header(self : Hunk[T]) -> String {
  Show::to_string(HunkHeader::new(self.edits))
}

///|
/// The hunk's slice of the edit script.
///
/// Together with `old_view` / `new_view` this is the primitive for custom
/// renderers (terminal colors, HTML, side-by-side, ...); `render` is the
/// built-in unified-text one. Edit indices are absolute positions in
/// `old_view()` / `new_view()`: slice `old_view()` with `old_index`/`old_len`
/// for `Delete`, `new_view()` with `new_index`/`new_len` for `Insert`, and
/// either view for `Equal`.
pub fn[T] Hunk::edits(self : Hunk[T]) -> ArrayView[Edit] {
  self.edits
}

///|
/// The complete original input sequence that the hunk's `old_index` values
/// refer to (not a hunk-local view), so a received `Hunk` is self-contained.
pub fn[T] Hunk::old_view(self : Hunk[T]) -> ArrayView[T] {
  self.old
}

///|
/// The complete updated input sequence that the hunk's `new_index` values
/// refer to (not a hunk-local view), so a received `Hunk` is self-contained.
pub fn[T] Hunk::new_view(self : Hunk[T]) -> ArrayView[T] {
  self.new
}

///|
/// Render the hunk as unified-diff text: an `@@ -a,b +c,d @@` header followed
/// by `-`/`+`/` `-prefixed lines, each terminated by a newline.
///
/// `show` converts one element to its line text. It is a callback rather than
/// a `Show` bound so that element types need no `Show` impl and callers
/// control the rendering (e.g. a field of a record).
pub fn[T] Hunk::render(self : Hunk[T], show~ : (T) -> String) -> String {
  let buf = StringBuilder::new()
  buf <+ "\{self.header()}\n"
  for edit in self.edits {
    let (prefix, slice) = match edit {
      Insert(..) => ("+", edit.view_from(old=self.old, new=self.new))
      Delete(..) => ("-", edit.view_from(old=self.old, new=self.new))
      Equal(..) => (" ", edit.view_from(old=self.old, new=self.new))
    }
    for s in slice {
      buf <+ "\{prefix}\{show(s)}\n"
    }
  }
  buf.to_string()
}
