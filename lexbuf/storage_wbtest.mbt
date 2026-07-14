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
test "LexbufStorage merges input into the last small chunk" {
  let storage = LexbufStorage()
  for _ in 0..<LEXBUF_MERGED_CHUNK_LIMIT {
    storage.append("x")
  }
  inspect(storage.chunks.length(), content="1")
  inspect(storage.chunks[0].length(), content="512")
  inspect(storage.chunk_starts.length(), content="1")
  inspect(storage.chunk_starts[0], content="0")
  inspect(
    storage.get_stringview(0, LEXBUF_MERGED_CHUNK_LIMIT).length(),
    content="512",
  )
}

///|
test "LexbufStorage caps merged chunks" {
  let storage = LexbufStorage()
  for _ in 0..<(LEXBUF_MERGED_CHUNK_LIMIT * 2) {
    storage.append("x")
  }
  inspect(storage.chunks.length(), content="2")
  inspect(storage.chunks[0].length(), content="512")
  inspect(storage.chunks[1].length(), content="512")
  inspect(storage.chunk_starts.length(), content="2")
  inspect(storage.chunk_starts[0], content="0")
  inspect(storage.chunk_starts[1], content="512")
  inspect(storage.unsafe_code_unit_at(511), content="120")
  inspect(storage.unsafe_code_unit_at(512), content="120")
}

///|
test "LexbufStorage preserves offsets while merging uneven chunks" {
  let storage = LexbufStorage()
  for chunk in ["a", "b", "cde", "f", "g", "hijk"] {
    storage.append(chunk)
  }
  inspect(storage.chunks.length(), content="1")
  inspect(storage.chunks[0], content="abcdefghijk")
  inspect(storage.chunk_starts.length(), content="1")
  inspect(storage.chunk_starts[0], content="0")
  inspect(storage.get_stringview(1, 10), content="bcdefghij")
}

///|
test "LexbufStorage searches backward from the cached chunk" {
  let storage = LexbufStorage()
  let chunk = "x".repeat(LEXBUF_MERGED_CHUNK_LIMIT + 1)
  storage.append(chunk)
  storage.append(chunk)
  inspect(
    storage.unsafe_code_unit_at(LEXBUF_MERGED_CHUNK_LIMIT + 1),
    content="120",
  )
  inspect(storage.unsafe_code_unit_at(LEXBUF_MERGED_CHUNK_LIMIT), content="120")
}

///|
test "LexbufStorage uses binary search in both directions" {
  let storage = LexbufStorage()
  let chunk = "x".repeat(LEXBUF_MERGED_CHUNK_LIMIT + 1)
  for _ in 0..<4 {
    storage.append(chunk)
  }
  inspect(
    storage.unsafe_code_unit_at(3 * (LEXBUF_MERGED_CHUNK_LIMIT + 1)),
    content="120",
  )
  inspect(storage.unsafe_code_unit_at(0), content="120")
}

///|
test "LexbufStorage discards complete chunks and preserves absolute offsets" {
  let storage = LexbufStorage()
  let chunk = "x".repeat(LEXBUF_MERGED_CHUNK_LIMIT + 1)
  storage.append(chunk)
  storage.append("y".repeat(LEXBUF_MERGED_CHUNK_LIMIT + 1))
  storage.append("z".repeat(LEXBUF_MERGED_CHUNK_LIMIT + 1))
  storage.discard_before(LEXBUF_MERGED_CHUNK_LIMIT + 1)
  inspect(storage.chunks.length(), content="2")
  inspect(storage.buffer_start, content="513")
  inspect(
    storage.unsafe_code_unit_at(LEXBUF_MERGED_CHUNK_LIMIT + 1),
    content="121",
  )
  let view = storage.get_stringview(
    LEXBUF_MERGED_CHUNK_LIMIT + 1,
    2 * (LEXBUF_MERGED_CHUNK_LIMIT + 1) + 1,
  )
  inspect(view.length(), content="514")
  inspect(view.unsafe_get(0).to_int(), content="121")
  inspect(view.unsafe_get(view.length() - 1).to_int(), content="122")
}

///|
test "panic LexbufStorage rejects an unbuffered position" {
  let storage = LexbufStorage::from_string("a")
  storage.unsafe_code_unit_at(1) |> ignore
}

///|
test "panic LexbufStorage rejects a range past the buffer end" {
  let storage = LexbufStorage()
  storage.append("a".repeat(LEXBUF_MERGED_CHUNK_LIMIT + 1))
  storage.append("b".repeat(LEXBUF_MERGED_CHUNK_LIMIT + 1))
  storage.get_stringview(0, storage.buffer_end + 1) |> ignore
}

///|
test "panic LexbufStorage rejects an invalid discard position" {
  let storage = LexbufStorage::from_string("a")
  storage.discard_before(2)
}
