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
/// A synchronous UTF-16 lexing buffer fed by string chunks.
///
/// All positions are absolute UTF-16 code-unit offsets. The buffer may discard
/// consumed input during `refill` unless `retain_from_cursor` has retained it.
pub struct Lexbuf {
  priv source : () -> String?
  priv storage : LexbufStorage
  priv mut cursor : Int
  priv mut retained_from : Int
  priv mut eof : Bool
}

///|
/// Creates an initially empty lexbuf. `source` returns the next chunk, or
/// `None` at EOF. Empty chunks are ignored.
pub fn Lexbuf::Lexbuf(source : () -> String?) -> Lexbuf {
  {
    source,
    storage: LexbufStorage::new(),
    cursor: 0,
    retained_from: -1,
    eof: false,
  }
}

///|
/// Creates a lexbuf backed by an iterator of string chunks.
pub fn Lexbuf::from_chunks(chunks : Iter[String]) -> Lexbuf {
  Lexbuf(() => chunks.next())
}

///|
/// Creates a lexbuf whose complete input is already available.
pub fn Lexbuf::from_string(content : String) -> Lexbuf {
  {
    source: () => None,
    storage: LexbufStorage::from_string(content),
    cursor: 0,
    retained_from: -1,
    eof: true,
  }
}

///|
/// Returns the absolute offset of the next code unit to be consumed.
pub fn Lexbuf::get_cursor(self : Lexbuf) -> Int {
  self.cursor
}

///|
/// Returns the absolute end offset of the currently buffered input.
pub fn Lexbuf::buffer_end(self : Lexbuf) -> Int {
  self.storage.buffer_end
}

///|
/// Returns whether the source has reported EOF. Buffered input may still
/// remain and must be consumed before treating the cursor as being at EOF.
pub fn Lexbuf::eof_reached(self : Lexbuf) -> Bool {
  self.eof
}

///|
/// Returns the UTF-16 code unit at the absolute offset `position` as an `Int`.
/// The position must be in `[buffer_start, buffer_end)`.
pub fn Lexbuf::unsafe_code_unit_at(self : Lexbuf, position : Int) -> Int {
  guard position >= self.storage.buffer_start && position < self.buffer_end() else {
    abort("Lexbuf::unsafe_code_unit_at: position is not buffered")
  }
  self.storage.unsafe_code_unit_at(position)
}

///|
/// Advances the cursor without discarding input. `count` must be non-negative,
/// and the resulting cursor must not pass `buffer_end()`.
pub fn Lexbuf::advance(self : Lexbuf, count : Int) -> Unit {
  guard count >= 0 && self.cursor + count <= self.buffer_end() else {
    abort("Lexbuf::advance: invalid count")
  }
  self.cursor += count
}

///|
/// Retains input starting at the current cursor. Repeated calls retain from
/// the earliest requested cursor and require only one later `commit_to` call.
pub fn Lexbuf::retain_from_cursor(self : Lexbuf) -> Unit {
  if self.retained_from < 0 || self.cursor < self.retained_from {
    self.retained_from = self.cursor
  }
}

///|
/// Returns a view over an absolute UTF-16 range. The range must have been kept
/// alive by `retain_from_cursor`. The returned view remains valid after
/// `commit_to` because it owns a reference to the immutable backing string.
pub fn Lexbuf::get_stringview(
  self : Lexbuf,
  start : Int,
  end : Int,
) -> StringView {
  guard self.retained_from >= 0 &&
    self.retained_from <= start &&
    start <= end &&
    start >= self.storage.buffer_start &&
    end <= self.buffer_end() else {
    abort("Lexbuf::get_stringview: range was not retained")
  }
  self.storage.get_stringview(start, end)
}

///|
/// Commits the selected match position and ends the current retention. The
/// position may be behind the current cursor when the scanner read lookahead.
pub fn Lexbuf::commit_to(self : Lexbuf, position : Int) -> Unit {
  guard self.retained_from >= 0 &&
    self.storage.buffer_start <= position &&
    position <= self.cursor else {
    abort("Lexbuf::commit_to: position is not retained")
  }
  self.cursor = position
  self.retained_from = -1
}

///|
/// Loads the next non-empty chunk. Call this only when the cursor is at the
/// current buffer end. A refill that reaches EOF leaves the buffer unchanged.
pub fn Lexbuf::refill(self : Lexbuf) -> Unit {
  guard self.cursor == self.buffer_end() else {
    abort("Lexbuf::refill: unread buffered input remains")
  }
  self.compact_buffer()
  while !self.eof {
    match (self.source)() {
      None => {
        self.eof = true
        break
      }
      Some(chunk) =>
        if !chunk.is_empty() {
          self.storage.append(chunk)
          break
        }
    }
  }
}

///|
fn Lexbuf::compact_buffer(self : Lexbuf) -> Unit {
  let keep_from = if self.retained_from >= 0 {
    self.retained_from
  } else {
    self.cursor
  }
  self.storage.discard_before(keep_from)
}
