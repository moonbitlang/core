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
/// Chunked storage shared by synchronous and asynchronous lexing buffers.
/// Source chunks are retained without rebuilding the whole buffer. New input
/// is merged into the last chunk up to a fixed limit to reduce lookup overhead.
/// Captured ranges are joined once, on demand.
priv struct LexbufStorage {
  mut chunks : Array[String]
  mut chunk_starts : Array[Int]
  mut lookup_chunk : Int
  mut buffer_start : Int
  mut buffer_end : Int
}

///|
const LEXBUF_MERGED_CHUNK_LIMIT : Int = 512

///|
fn LexbufStorage::LexbufStorage() -> LexbufStorage {
  {
    chunks: [],
    chunk_starts: [],
    lookup_chunk: 0,
    buffer_start: 0,
    buffer_end: 0,
  }
}

///|
fn LexbufStorage::from_string(content : String) -> LexbufStorage {
  let storage = LexbufStorage()
  if !content.is_empty() {
    storage.append(content)
  }
  storage
}

///|
fn LexbufStorage::append(self : LexbufStorage, chunk : String) -> Unit {
  guard !chunk.is_empty() else { abort("LexbufStorage: empty chunk") }
  if self.chunks is [.., last] &&
    last.length() + chunk.length() <= LEXBUF_MERGED_CHUNK_LIMIT {
    self.chunks[self.chunks.length() - 1] = last + chunk
    self.buffer_end += chunk.length()
    return
  }
  self.chunk_starts.push(self.buffer_end)
  self.chunks.push(chunk)
  self.buffer_end += chunk.length()
}

///|
fn LexbufStorage::chunk_contains(
  self : LexbufStorage,
  index : Int,
  position : Int,
) -> Bool {
  if index < 0 || index >= self.chunks.length() {
    return false
  }
  let start = self.chunk_starts.unsafe_get(index)
  start <= position && position < start + self.chunks.unsafe_get(index).length()
}

///|
fn LexbufStorage::find_chunk(self : LexbufStorage, position : Int) -> Int {
  let cached = self.lookup_chunk
  if self.chunk_contains(cached, position) {
    return cached
  }
  if self.chunk_contains(cached + 1, position) {
    self.lookup_chunk = cached + 1
    return cached + 1
  }
  if self.chunk_contains(cached - 1, position) {
    self.lookup_chunk = cached - 1
    return cached - 1
  }
  let low = for low = 0, high = self.chunks.length(); low < high; {
    let middle = low + (high - low) / 2
    if self.chunk_starts.unsafe_get(middle) <= position {
      continue middle + 1, high
    } else {
      continue low, middle
    }
  } nobreak {
    low
  }
  let index = low - 1
  guard self.chunk_contains(index, position) else {
    abort("LexbufStorage: position is not buffered")
  }
  self.lookup_chunk = index
  index
}

///|
fn LexbufStorage::unsafe_code_unit_at(
  self : LexbufStorage,
  position : Int,
) -> Int {
  let index = self.find_chunk(position)
  let chunk = self.chunks.unsafe_get(index)
  chunk.unsafe_get(position - self.chunk_starts.unsafe_get(index)).to_int()
}

///|
fn LexbufStorage::get_stringview(
  self : LexbufStorage,
  start : Int,
  end : Int,
) -> StringView {
  if start == end {
    return ""
  }
  let first = self.find_chunk(start)
  let first_chunk = self.chunks.unsafe_get(first)
  let first_start = self.chunk_starts.unsafe_get(first)
  let first_end = first_start + first_chunk.length()
  // Use views rather than `s[a:b]`: lexbuf offsets and chunk boundaries are raw
  // UTF-16 code-unit positions, so they may fall inside a surrogate pair.
  if end <= first_end {
    return first_chunk.view(
      start_offset=start - first_start,
      end_offset=end - first_start,
    )
  }
  let builder = StringBuilder(size_hint=(end - start) * 2)
  builder.write_view(first_chunk.view(start_offset=start - first_start))
  for index in (first + 1)..<self.chunks.length() {
    let chunk = self.chunks.unsafe_get(index)
    let chunk_start = self.chunk_starts.unsafe_get(index)
    let chunk_end = chunk_start + chunk.length()
    if end <= chunk_end {
      builder.write_view(chunk.view(end_offset=end - chunk_start))
      break
    }
    builder.write_string(chunk)
  } nobreak {
    abort("LexbufStorage: range is not buffered")
  }
  builder.to_string()
}

///|
fn LexbufStorage::discard_before(self : LexbufStorage, position : Int) -> Unit {
  guard self.buffer_start <= position && position <= self.buffer_end else {
    abort("LexbufStorage: invalid retention state")
  }
  let length = self.chunks.length()
  let first = for index in 0..<length {
    let chunk_end = self.chunk_starts.unsafe_get(index) +
      self.chunks.unsafe_get(index).length()
    if chunk_end > position {
      break index
    }
  } nobreak {
    length
  }
  self.buffer_start = position
  if first == length {
    self.chunks.clear()
    self.chunk_starts.clear()
  } else if first > 0 {
    let chunks : Array[String] = []
    let chunk_starts : Array[Int] = []
    for index in first..<length {
      chunks.push(self.chunks.unsafe_get(index))
      chunk_starts.push(self.chunk_starts.unsafe_get(index))
    }
    self.chunks = chunks
    self.chunk_starts = chunk_starts
  }
  self.lookup_chunk = 0
}
