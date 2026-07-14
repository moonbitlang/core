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
/// A synchronous UTF-16 input buffer for `lexscan`, fed by string chunks.
/// Chunks may be released after `lexscan` has finished consuming them.
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
pub fn Lexbuf::from_fn(source : () -> String?) -> Lexbuf {
  { source, storage: LexbufStorage(), cursor: 0, retained_from: -1, eof: false }
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
/// Compiler protocol: returns the absolute offset of the next code unit.
/// The cursor must stay in the buffered range. Generated `lexscan` code calls
/// this when starting a scan and when recording or comparing scan positions.
#doc(hidden)
pub fn Lexbuf::__get_cursor(self : Lexbuf) -> Int {
  self.cursor
}

///|
/// Compiler protocol: returns the absolute end of the buffered input.
/// The cursor must not exceed this offset. Generated `lexscan` code calls this
/// before reading a code unit and before deciding whether to refill.
#doc(hidden)
pub fn Lexbuf::__buffer_end(self : Lexbuf) -> Int {
  self.storage.buffer_end
}

///|
/// Compiler protocol: returns whether the source has reported EOF.
/// Buffered input may still remain; generated `lexscan` code calls this only
/// after the cursor reaches `__buffer_end`, to choose between EOF and refill.
#doc(hidden)
pub fn Lexbuf::__eof_reached(self : Lexbuf) -> Bool {
  self.eof
}

///|
/// Compiler protocol: reads a UTF-16 code unit at an absolute offset.
/// `position` must be in the currently buffered half-open range. Generated
/// `lexscan` code calls this only after checking against `__buffer_end`.
#doc(hidden)
pub fn Lexbuf::__unsafe_code_unit_at(self : Lexbuf, position : Int) -> Int {
  debug_assert(() => {
    position >= self.storage.buffer_start && position < self.__buffer_end()
  })
  self.storage.unsafe_code_unit_at(position)
}

///|
/// Compiler protocol: advances the cursor without discarding input.
/// `count` must be non-negative and the new cursor must not pass
/// `__buffer_end`. Generated `lexscan` code calls this after consuming input.
#doc(hidden)
pub fn Lexbuf::__advance(self : Lexbuf, count : Int) -> Unit {
  debug_assert(() => count >= 0 && self.cursor + count <= self.__buffer_end())
  self.cursor += count
}

///|
/// Compiler protocol: retains input starting at the current cursor.
/// The cursor must be in the buffered range; repeated calls retain the earliest
/// cursor. Generated `lexscan` code calls this when later refills must preserve
/// input from this position, such as for captures or committing after lookahead.
#doc(hidden)
pub fn Lexbuf::__retain_from_cursor(self : Lexbuf) -> Unit {
  if self.retained_from < 0 || self.cursor < self.retained_from {
    self.retained_from = self.cursor
  }
}

///|
/// Compiler protocol: returns a view over an absolute UTF-16 range.
/// The range must be ordered, buffered, and covered by the active retention.
/// Generated `lexscan` code calls this to materialize captures before commit.
#doc(hidden)
pub fn Lexbuf::__get_stringview(
  self : Lexbuf,
  start : Int,
  end : Int,
) -> StringView {
  guard self.retained_from >= 0 &&
    self.retained_from <= start &&
    start <= end &&
    start >= self.storage.buffer_start &&
    end <= self.__buffer_end() else {
    abort("Lexbuf::__get_stringview: range was not retained")
  }
  self.storage.get_stringview(start, end)
}

///|
/// Compiler protocol: commits a match position and ends the active retention.
/// Retention must be active and `position` must be buffered and no later than
/// the current cursor. Generated `lexscan` code calls this after selecting a case.
#doc(hidden)
pub fn Lexbuf::__commit_to(self : Lexbuf, position : Int) -> Unit {
  guard self.retained_from >= 0 &&
    self.storage.buffer_start <= position &&
    position <= self.cursor else {
    abort("Lexbuf::__commit_to: position is not retained")
  }
  self.cursor = position
  self.retained_from = -1
}

///|
/// Compiler protocol: loads the next non-empty chunk.
/// The cursor must equal `__buffer_end`. Generated `lexscan` code calls this
/// after exhausting buffered input when `__eof_reached` is false.
#doc(hidden)
pub fn Lexbuf::__refill(self : Lexbuf) -> Unit {
  guard self.cursor == self.__buffer_end() else {
    abort("Lexbuf::__refill: unread buffered input remains")
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
