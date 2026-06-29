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
/// A non-streaming target for `lexscan` over a fixed `StringView`.
///
/// `LexscanInput` stores the view's backing `String`, the current cursor, and
/// the exclusive end of the scanned range. Both offsets are absolute UTF-16
/// code-unit offsets in the backing `String`, not offsets relative to the view.
///
/// The scanner mutates only `offset`. This type does not own a refillable buffer
/// and has no streaming/refill semantics.
#doc(hidden)
struct LexscanInput {
  input : String
  mut offset : Int
  end_offset : Int
}

///|
/// Creates a static lexscan target from `view`.
///
/// The initial cursor is `view.start_offset()`, and scanning must stop before
/// `view.start_offset() + view.length()`. The backing string is kept so 
/// `lexscan` can read UTF-16 code units by absolute offset.
#doc(hidden)
pub fn LexscanInput::from_stringview(view : StringView) -> LexscanInput {
  {
    input: view.data(),
    offset: view.start_offset(),
    end_offset: view.start_offset() + view.length(),
  }
}

///|
/// Returns the backing `String` for the scanned view.
///
/// This may be larger than the scanned range. Use `offset()` and
/// `end_offset()` to determine the active lexscan window.
#doc(hidden)
pub fn LexscanInput::input(self : LexscanInput) -> String {
  self.input
}

///|
/// Returns the current cursor as an absolute UTF-16 code-unit offset in
/// `input()`.
#doc(hidden)
pub fn LexscanInput::offset(self : LexscanInput) -> Int {
  self.offset
}

///|
/// Returns the exclusive end of the scanned range as an absolute UTF-16
/// code-unit offset in `input()`.
#doc(hidden)
pub fn LexscanInput::end_offset(self : LexscanInput) -> Int {
  self.end_offset
}

///|
/// Updates the current cursor.
///
/// The new offset should stay within the scanned range:
/// `from_stringview(view).offset()..=end_offset()`.
#doc(hidden)
pub fn LexscanInput::set_offset(self : LexscanInput, new_offset : Int) -> Unit {
  self.offset = new_offset
}
