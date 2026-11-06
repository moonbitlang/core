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
test "BytesLexbuf retains captures across chunks and commits lookahead" {
  let chunks = [|b"ab", b"cd", b"!"|]
  let lexbuf = @lexbuf.BytesLexbuf::from_fn(() => chunks.next())
  lexbuf.__refill()
  lexbuf.__advance(1)
  lexbuf.__retain_from_cursor()
  lexbuf.__advance(1)
  lexbuf.__refill()
  lexbuf.__advance(2)
  let captured = lexbuf.__get_bytesview(1, 4)
  lexbuf.__commit_to(3)
  inspect(
    captured,
    content=(
      #|b"bcd"
    ),
  )
  inspect(lexbuf.__get_cursor(), content="3")
  inspect(lexbuf.__unsafe_code_unit_at(3), content="100")
  lexbuf.__advance(1)
  lexbuf.__refill()
  inspect(lexbuf.__unsafe_code_unit_at(4), content="33")
}

///|
test "BytesLexbuf discards consumed input without retention" {
  let chunks = [|b"ab", b"", b"cd"|]
  let lexbuf = @lexbuf.BytesLexbuf::from_fn(() => chunks.next())
  lexbuf.__refill()
  lexbuf.__advance(2)
  lexbuf.__refill()
  inspect(lexbuf.__get_cursor(), content="2")
  inspect(lexbuf.__buffer_end(), content="4")
  inspect(lexbuf.__unsafe_code_unit_at(2), content="99")
}

///|
test "BytesLexbuf reports source EOF while buffered input remains" {
  let chunks = [|b"a"|]
  let lexbuf = @lexbuf.BytesLexbuf::from_fn(() => chunks.next())
  inspect(lexbuf.__eof_reached(), content="false")
  lexbuf.__refill()
  inspect(lexbuf.__eof_reached(), content="false")
  lexbuf.__advance(1)
  lexbuf.__refill()
  inspect(lexbuf.__eof_reached(), content="true")
  inspect(lexbuf.__buffer_end(), content="1")
}

///|
test "BytesLexbuf can commit before a capture-only retention" {
  let chunks = [|b"ab"|]
  let lexbuf = @lexbuf.BytesLexbuf::from_fn(() => chunks.next())
  lexbuf.__refill()
  lexbuf.__advance(1)
  lexbuf.__retain_from_cursor()
  lexbuf.__advance(1)
  inspect(
    lexbuf.__get_bytesview(1, 2),
    content=(
      #|b"b"
    ),
  )
  lexbuf.__commit_to(0)
  inspect(lexbuf.__get_cursor(), content="0")
  inspect(lexbuf.__unsafe_code_unit_at(0), content="97")
}

///|
test "BytesLexbuf retains a token across many chunks" {
  let chunk_count = 4096
  let chunks = Array::make(chunk_count, b"x").iter()
  let lexbuf = @lexbuf.BytesLexbuf::from_fn(() => chunks.next())
  lexbuf.__refill()
  lexbuf.__retain_from_cursor()
  for _ in 0..<chunk_count {
    inspect(lexbuf.__unsafe_code_unit_at(lexbuf.__get_cursor()), content="120")
    lexbuf.__advance(1)
    if lexbuf.__get_cursor() == lexbuf.__buffer_end() {
      lexbuf.__refill()
    }
  }
  let captured = lexbuf.__get_bytesview(0, chunk_count)
  lexbuf.__commit_to(chunk_count - 1)
  inspect(captured.length(), content="4096")
  inspect(lexbuf.__unsafe_code_unit_at(chunk_count - 1), content="120")
}

///|
test "BytesLexbuf reads bytes above 0x7F across chunk boundaries" {
  // The UTF-8 encoding of "é" split between two chunks.
  let chunks = [|b"a\xc3", b"\xa9b"|]
  let lexbuf = @lexbuf.BytesLexbuf::from_fn(() => chunks.next())
  lexbuf.__refill()
  lexbuf.__retain_from_cursor()
  lexbuf.__advance(2)
  lexbuf.__refill()
  lexbuf.__advance(2)
  inspect(lexbuf.__unsafe_code_unit_at(1), content="195")
  inspect(lexbuf.__unsafe_code_unit_at(2), content="169")
  inspect(
    lexbuf.__get_bytesview(0, 4),
    content=(
      #|b"a\xc3\xa9b"
    ),
  )
}

///|
test "BytesLexbuf reads multiple chunks after compaction" {
  let chunks = [|b"ab", b"cd", b"ef"|]
  let lexbuf = @lexbuf.BytesLexbuf::from_fn(() => chunks.next())
  lexbuf.__refill()
  lexbuf.__retain_from_cursor()
  lexbuf.__advance(2)
  lexbuf.__refill()
  lexbuf.__advance(2)
  lexbuf.__refill()
  lexbuf.__commit_to(1)
  lexbuf.__advance(5)
  lexbuf.__refill()
  inspect(lexbuf.__buffer_end(), content="6")
  inspect(lexbuf.__eof_reached(), content="true")
}

///|
test "BytesLexbuf returns an empty retained view" {
  let chunks = [|b"abc"|]
  let lexbuf = @lexbuf.BytesLexbuf::from_fn(() => chunks.next())
  lexbuf.__refill()
  lexbuf.__retain_from_cursor()
  inspect(
    lexbuf.__get_bytesview(0, 0),
    content=(
      #|b""
    ),
  )
  lexbuf.__commit_to(0)
}

///|
test "AsyncBytesLexbuf retains captures across asynchronous refills" {
  let scheduler = LexbufTestScheduler::new()
  scheduler.run_async(async fn() {
    let mut index = 0
    let chunks : ReadOnlyArray[Bytes] = [b"ab", b"cd", b"!"]
    let lexbuf = @lexbuf.AsyncBytesLexbuf::from_fn(async fn() noraise {
      scheduler.pause()
      if index < chunks.length() {
        let chunk = chunks[index]
        index += 1
        Some(chunk)
      } else {
        None
      }
    })
    lexbuf.__refill()
    lexbuf.__advance(1)
    lexbuf.__retain_from_cursor()
    lexbuf.__advance(1)
    lexbuf.__refill()
    lexbuf.__advance(2)
    let captured = lexbuf.__get_bytesview(1, 4)
    lexbuf.__commit_to(3)
    guard captured == b"bcd" else { abort("unexpected async capture") }
    guard lexbuf.__get_cursor() == 3 else { abort("unexpected async cursor") }
    guard lexbuf.__unsafe_code_unit_at(3) == 100 else {
      abort("unexpected async byte")
    }
    lexbuf.__advance(1)
    lexbuf.__refill()
    guard lexbuf.__unsafe_code_unit_at(4) == 33 else {
      abort("unexpected async refill")
    }
  })
}

///|
test "AsyncBytesLexbuf retains a token across many chunks" {
  let scheduler = LexbufTestScheduler::new()
  scheduler.run_async(async fn() {
    let chunk_count = 512
    let mut remaining = chunk_count
    let lexbuf = @lexbuf.AsyncBytesLexbuf::from_fn(async fn() {
      scheduler.pause()
      if remaining > 0 {
        remaining -= 1
        Some(b"\xff")
      } else {
        None
      }
    })
    lexbuf.__refill()
    lexbuf.__retain_from_cursor()
    for _ in 0..<chunk_count {
      guard lexbuf.__unsafe_code_unit_at(lexbuf.__get_cursor()) == 255 else {
        abort("unexpected async byte")
      }
      lexbuf.__advance(1)
      if lexbuf.__get_cursor() == lexbuf.__buffer_end() {
        lexbuf.__refill()
      }
    }
    let captured = lexbuf.__get_bytesview(0, chunk_count)
    lexbuf.__commit_to(chunk_count - 1)
    guard captured.length() == chunk_count else {
      abort("unexpected async capture length")
    }
    guard lexbuf.__unsafe_code_unit_at(chunk_count - 1) == 255 else {
      abort("unexpected async committed byte")
    }
  })
}

///|
test "AsyncBytesLexbuf ignores empty chunks and reports EOF" {
  let scheduler = LexbufTestScheduler::new()
  scheduler.run_async(async fn() {
    let mut index = 0
    let chunks : ReadOnlyArray[Bytes] = [b"", b"a", b""]
    let lexbuf = @lexbuf.AsyncBytesLexbuf::from_fn(async fn() noraise {
      scheduler.pause()
      if index < chunks.length() {
        let chunk = chunks[index]
        index += 1
        Some(chunk)
      } else {
        None
      }
    })
    inspect(lexbuf.__eof_reached(), content="false")
    lexbuf.__refill()
    inspect(lexbuf.__buffer_end(), content="1")
    inspect(lexbuf.__eof_reached(), content="false")
    lexbuf.__advance(1)
    lexbuf.__refill()
    inspect(lexbuf.__eof_reached(), content="true")
    lexbuf.__refill()
    inspect(lexbuf.__buffer_end(), content="1")
  })
}
