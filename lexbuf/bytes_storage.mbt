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
/// Chunked byte storage shared by `BytesLexbuf` and `AsyncBytesLexbuf`, the
/// bytes counterpart of `LexbufStorage`. Source chunks are retained without
/// rebuilding the whole buffer. New input is merged into the last chunk up to
/// `LEXBUF_MERGED_CHUNK_LIMIT` bytes to reduce lookup overhead. Captured
/// ranges are joined once, on demand.
priv struct BytesLexbufStorage {
  mut chunks : Array[Bytes]
  mut chunk_starts : Array[Int32]
  mut lookup_chunk : Int32
  mut buffer_start : Int32
  mut buffer_end : Int32
}

///|
fn BytesLexbufStorage::BytesLexbufStorage() -> BytesLexbufStorage {
  {
    chunks: [],
    chunk_starts: [],
    lookup_chunk: 0,
    buffer_start: 0,
    buffer_end: 0,
  }
}

///|
fn BytesLexbufStorage::append(self : BytesLexbufStorage, chunk : Bytes) -> Unit {
  guard !chunk.is_empty() else { abort("BytesLexbufStorage: empty chunk") }
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
fn BytesLexbufStorage::chunk_contains(
  self : BytesLexbufStorage,
  index : Int32,
  position : Int32,
) -> Bool {
  if index < 0 || index >= self.chunks.length() {
    return false
  }
  let start = self.chunk_starts.unsafe_get(index)
  start <= position && position < start + self.chunks.unsafe_get(index).length()
}

///|
fn BytesLexbufStorage::find_chunk(
  self : BytesLexbufStorage,
  position : Int32,
) -> Int32 {
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
    abort("BytesLexbufStorage: position is not buffered")
  }
  self.lookup_chunk = index
  index
}

///|
fn BytesLexbufStorage::unsafe_code_unit_at(
  self : BytesLexbufStorage,
  position : Int32,
) -> Int32 {
  let index = self.find_chunk(position)
  let chunk = self.chunks.unsafe_get(index)
  chunk.unsafe_get(position - self.chunk_starts.unsafe_get(index)).to_int()
}

///|
fn BytesLexbufStorage::get_bytesview(
  self : BytesLexbufStorage,
  start : Int32,
  end : Int32,
) -> BytesView {
  if start == end {
    return b""
  }
  let first = self.find_chunk(start)
  let first_chunk = self.chunks.unsafe_get(first)
  let first_start = self.chunk_starts.unsafe_get(first)
  let first_end = first_start + first_chunk.length()
  if end <= first_end {
    return first_chunk.unsafe_view(
      start=start - first_start,
      end=end - first_start,
    )
  }
  let joined = FixedArray::make(end - start, b'\x00')
  joined.blit_from_bytesview(
    0,
    first_chunk.unsafe_view(start=start - first_start, end=first_chunk.length()),
  )
  for index in (first + 1)..<self.chunks.length() {
    let chunk = self.chunks.unsafe_get(index)
    let chunk_start = self.chunk_starts.unsafe_get(index)
    let chunk_end = chunk_start + chunk.length()
    if end <= chunk_end {
      joined.blit_from_bytesview(
        chunk_start - start,
        chunk.unsafe_view(start=0, end=end - chunk_start),
      )
      break
    }
    joined.blit_from_bytes(chunk_start - start, chunk, 0, chunk.length())
  } nobreak {
    abort("BytesLexbufStorage: range is not buffered")
  }
  joined.unsafe_reinterpret_as_bytes()
}

///|
fn BytesLexbufStorage::discard_before(
  self : BytesLexbufStorage,
  position : Int32,
) -> Unit {
  guard self.buffer_start <= position && position <= self.buffer_end else {
    abort("BytesLexbufStorage: invalid retention state")
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
    let chunks : Array[Bytes] = []
    let chunk_starts : Array[Int32] = []
    for index in first..<length {
      chunks.push(self.chunks.unsafe_get(index))
      chunk_starts.push(self.chunk_starts.unsafe_get(index))
    }
    self.chunks = chunks
    self.chunk_starts = chunk_starts
  }
  self.lookup_chunk = 0
}
