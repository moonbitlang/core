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
/// A synchronous byte input buffer for `lexscan` with bytes regexes, fed
/// by `Bytes` chunks. It is the bytes counterpart of `Lexbuf`: offsets
/// are absolute byte offsets in the stream. Chunks may be released after
/// `lexscan` has finished consuming them.
pub struct BytesLexbuf {
  priv source : () -> Bytes?
  priv storage : BytesLexbufStorage
  priv mut cursor : Int32
  priv mut retained_from : Int32
  priv mut eof : Bool
}

///|
/// Creates an initially empty lexbuf. `source` returns the next chunk, or
/// `None` at EOF. Empty chunks are ignored.
pub fn BytesLexbuf::from_fn(source : () -> Bytes?) -> BytesLexbuf {
  {
    source,
    storage: BytesLexbufStorage(),
    cursor: 0,
    retained_from: -1,
    eof: false,
  }
}

///|
/// Compiler protocol: returns the absolute offset of the next byte.
/// The cursor must stay in the buffered range. Generated `lexscan` code calls
/// this when starting a scan and when recording or comparing scan positions.
#doc(hidden)
pub fn BytesLexbuf::__get_cursor(self : BytesLexbuf) -> Int32 {
  self.cursor
}

///|
/// Compiler protocol: returns the absolute end of the buffered input.
/// The cursor must not exceed this offset. Generated `lexscan` code calls this
/// before reading a byte and before deciding whether to refill.
#doc(hidden)
pub fn BytesLexbuf::__buffer_end(self : BytesLexbuf) -> Int32 {
  self.storage.buffer_end
}

///|
/// Compiler protocol: returns whether the source has reported EOF.
/// Buffered input may still remain; generated `lexscan` code calls this only
/// after the cursor reaches `__buffer_end`, to choose between EOF and refill.
#doc(hidden)
pub fn BytesLexbuf::__eof_reached(self : BytesLexbuf) -> Bool {
  self.eof
}

///|
/// Compiler protocol: reads the byte at an absolute offset, as an `Int32`.
/// `position` must be in the currently buffered half-open range. Generated
/// `lexscan` code calls this only after checking against `__buffer_end`.
#doc(hidden)
pub fn BytesLexbuf::__unsafe_code_unit_at(
  self : BytesLexbuf,
  position : Int32,
) -> Int32 {
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
pub fn BytesLexbuf::__advance(self : BytesLexbuf, count : Int32) -> Unit {
  debug_assert(() => count >= 0 && self.cursor + count <= self.__buffer_end())
  self.cursor += count
}

///|
/// Compiler protocol: retains input starting at the current cursor.
/// The cursor must be in the buffered range; repeated calls retain the earliest
/// cursor. Generated `lexscan` code calls this when later refills must preserve
/// input from this position, such as for captures or committing after lookahead.
#doc(hidden)
pub fn BytesLexbuf::__retain_from_cursor(self : BytesLexbuf) -> Unit {
  if self.retained_from < 0 || self.cursor < self.retained_from {
    self.retained_from = self.cursor
  }
}

///|
/// Compiler protocol: returns a view over an absolute byte range.
/// The range must be ordered, buffered, and covered by the active retention.
/// Generated `lexscan` code calls this to materialize captures before commit.
#doc(hidden)
pub fn BytesLexbuf::__get_bytesview(
  self : BytesLexbuf,
  start : Int32,
  end : Int32,
) -> BytesView {
  guard self.retained_from >= 0 &&
    self.retained_from <= start &&
    start <= end &&
    start >= self.storage.buffer_start &&
    end <= self.__buffer_end() else {
    abort("BytesLexbuf::__get_bytesview: range was not retained")
  }
  self.storage.get_bytesview(start, end)
}

///|
/// Compiler protocol: commits a match position and ends the active retention.
/// Retention must be active and `position` must be buffered and no later than
/// the current cursor. Generated `lexscan` code calls this after selecting a case.
#doc(hidden)
pub fn BytesLexbuf::__commit_to(self : BytesLexbuf, position : Int32) -> Unit {
  guard self.retained_from >= 0 &&
    self.storage.buffer_start <= position &&
    position <= self.cursor else {
    abort("BytesLexbuf::__commit_to: position is not retained")
  }
  self.cursor = position
  self.retained_from = -1
}

///|
/// Compiler protocol: loads the next non-empty chunk.
/// The cursor must equal `__buffer_end`. Generated `lexscan` code calls this
/// after exhausting buffered input when `__eof_reached` is false.
#doc(hidden)
pub fn BytesLexbuf::__refill(self : BytesLexbuf) -> Unit {
  guard self.cursor == self.__buffer_end() else {
    abort("BytesLexbuf::__refill: unread buffered input remains")
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
fn BytesLexbuf::compact_buffer(self : BytesLexbuf) -> Unit {
  let keep_from = if self.retained_from >= 0 {
    self.retained_from
  } else {
    self.cursor
  }
  self.storage.discard_before(keep_from)
}
