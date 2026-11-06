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
test "BytesLexbufStorage merges input into the last small chunk" {
  let storage = BytesLexbufStorage()
  for _ in 0..<LEXBUF_MERGED_CHUNK_LIMIT {
    storage.append(b"x")
  }
  inspect(storage.chunks.length(), content="1")
  inspect(storage.chunks[0].length(), content="64")
  inspect(storage.chunk_starts.length(), content="1")
  inspect(storage.chunk_starts[0], content="0")
  inspect(
    storage.get_bytesview(0, LEXBUF_MERGED_CHUNK_LIMIT).length(),
    content="64",
  )
}

///|
test "BytesLexbufStorage caps merged chunks" {
  let storage = BytesLexbufStorage()
  for _ in 0..<(LEXBUF_MERGED_CHUNK_LIMIT * 2) {
    storage.append(b"x")
  }
  inspect(storage.chunks.length(), content="2")
  inspect(storage.chunks[0].length(), content="64")
  inspect(storage.chunks[1].length(), content="64")
  inspect(storage.chunk_starts.length(), content="2")
  inspect(storage.chunk_starts[0], content="0")
  inspect(storage.chunk_starts[1], content="64")
  inspect(
    storage.unsafe_code_unit_at(LEXBUF_MERGED_CHUNK_LIMIT - 1),
    content="120",
  )
  inspect(storage.unsafe_code_unit_at(LEXBUF_MERGED_CHUNK_LIMIT), content="120")
}

///|
test "BytesLexbufStorage preserves offsets while merging uneven chunks" {
  let storage = BytesLexbufStorage()
  for chunk in [b"a", b"b", b"cde", b"f", b"g", b"hijk"] {
    storage.append(chunk)
  }
  inspect(storage.chunks.length(), content="1")
  inspect(
    storage.chunks[0],
    content=(
      #|b"abcdefghijk"
    ),
  )
  inspect(storage.chunk_starts.length(), content="1")
  inspect(storage.chunk_starts[0], content="0")
  inspect(
    storage.get_bytesview(1, 10),
    content=(
      #|b"bcdefghij"
    ),
  )
}

///|
test "BytesLexbufStorage searches backward from the cached chunk" {
  let storage = BytesLexbufStorage()
  let chunk = b"x".repeat(LEXBUF_MERGED_CHUNK_LIMIT + 1)
  storage.append(chunk)
  storage.append(chunk)
  inspect(
    storage.unsafe_code_unit_at(LEXBUF_MERGED_CHUNK_LIMIT + 1),
    content="120",
  )
  inspect(storage.unsafe_code_unit_at(LEXBUF_MERGED_CHUNK_LIMIT), content="120")
}

///|
test "BytesLexbufStorage uses binary search in both directions" {
  let storage = BytesLexbufStorage()
  let chunk = b"x".repeat(LEXBUF_MERGED_CHUNK_LIMIT + 1)
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
test "BytesLexbufStorage discards complete chunks and preserves absolute offsets" {
  let storage = BytesLexbufStorage()
  let chunk = b"x".repeat(LEXBUF_MERGED_CHUNK_LIMIT + 1)
  storage.append(chunk)
  storage.append(b"y".repeat(LEXBUF_MERGED_CHUNK_LIMIT + 1))
  storage.append(b"z".repeat(LEXBUF_MERGED_CHUNK_LIMIT + 1))
  storage.discard_before(LEXBUF_MERGED_CHUNK_LIMIT + 1)
  inspect(storage.chunks.length(), content="2")
  inspect(storage.buffer_start, content="65")
  inspect(
    storage.unsafe_code_unit_at(LEXBUF_MERGED_CHUNK_LIMIT + 1),
    content="121",
  )
  let view = storage.get_bytesview(
    LEXBUF_MERGED_CHUNK_LIMIT + 1,
    2 * (LEXBUF_MERGED_CHUNK_LIMIT + 1) + 1,
  )
  inspect(view.length(), content="66")
  inspect(view.unsafe_get(0).to_int(), content="121")
  inspect(view.unsafe_get(view.length() - 1).to_int(), content="122")
}

///|
test "BytesLexbufStorage joins a range across several chunks" {
  let storage = BytesLexbufStorage()
  let big = LEXBUF_MERGED_CHUNK_LIMIT + 1
  storage.append(b"\x00".repeat(big))
  storage.append(b"\xff".repeat(big))
  storage.append(b"\x80".repeat(big))
  // From the last byte of the first chunk to the first byte of the third.
  let view = storage.get_bytesview(big - 1, 2 * big + 1)
  inspect(view.length(), content="67")
  inspect(view.unsafe_get(0).to_int(), content="0")
  inspect(view.unsafe_get(1).to_int(), content="255")
  inspect(view.unsafe_get(65).to_int(), content="255")
  inspect(view.unsafe_get(66).to_int(), content="128")
  // A range that ends exactly at a chunk end.
  inspect(storage.get_bytesview(big - 1, 2 * big).length(), content="66")
  // Bytes above 0x7F read as 128 to 255.
  inspect(storage.unsafe_code_unit_at(big), content="255")
  inspect(storage.unsafe_code_unit_at(2 * big), content="128")
}

///|
test "BytesLexbufStorage returns an empty range" {
  let storage = BytesLexbufStorage()
  storage.append(b"ab")
  inspect(storage.get_bytesview(1, 1).length(), content="0")
}

///|
test "panic BytesLexbufStorage rejects an unbuffered position" {
  let storage = BytesLexbufStorage()
  storage.append(b"a")
  storage.unsafe_code_unit_at(1) |> ignore
}

///|
test "panic BytesLexbufStorage rejects a range past the buffer end" {
  let storage = BytesLexbufStorage()
  storage.append(b"a".repeat(LEXBUF_MERGED_CHUNK_LIMIT + 1))
  storage.append(b"b".repeat(LEXBUF_MERGED_CHUNK_LIMIT + 1))
  storage.get_bytesview(0, storage.buffer_end + 1) |> ignore
}

///|
test "panic BytesLexbufStorage rejects an invalid discard position" {
  let storage = BytesLexbufStorage()
  storage.append(b"a")
  storage.discard_before(2)
}

///|
test "panic BytesLexbufStorage rejects an empty chunk" {
  BytesLexbufStorage().append(b"")
}
