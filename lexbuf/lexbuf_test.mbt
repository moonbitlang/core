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
test "Lexbuf retains captures across chunks and commits lookahead" {
  let chunks = ["ab", "cd", "!"].iter()
  let lexbuf = @lexbuf.Lexbuf::from_fn(() => chunks.next())
  lexbuf.__refill()
  lexbuf.__advance(1)
  lexbuf.__retain_from_cursor()
  lexbuf.__advance(1)
  lexbuf.__refill()
  lexbuf.__advance(2)
  let captured = lexbuf.__get_stringview(1, 4)
  lexbuf.__commit_to(3)
  inspect(captured, content="bcd")
  inspect(lexbuf.__get_cursor(), content="3")
  inspect(lexbuf.__unsafe_code_unit_at(3), content="100")
  lexbuf.__advance(1)
  lexbuf.__refill()
  inspect(lexbuf.__unsafe_code_unit_at(4), content="33")
}

///|
test "Lexbuf discards consumed input without retention" {
  let chunks = ["ab", "", "cd"].iter()
  let lexbuf = @lexbuf.Lexbuf::from_fn(() => chunks.next())
  lexbuf.__refill()
  lexbuf.__advance(2)
  lexbuf.__refill()
  inspect(lexbuf.__get_cursor(), content="2")
  inspect(lexbuf.__buffer_end(), content="4")
  inspect(lexbuf.__unsafe_code_unit_at(2), content="99")
}

///|
test "Lexbuf reports source EOF while buffered input remains" {
  let lexbuf = @lexbuf.Lexbuf::from_string("a")
  inspect(lexbuf.__eof_reached(), content="true")
  lexbuf.__advance(1)
  inspect(lexbuf.__eof_reached(), content="true")
}

///|
test "Lexbuf can commit before a capture-only retention" {
  let chunks = ["ab"].iter()
  let lexbuf = @lexbuf.Lexbuf::from_fn(() => chunks.next())
  lexbuf.__refill()
  lexbuf.__advance(1)
  lexbuf.__retain_from_cursor()
  lexbuf.__advance(1)
  inspect(lexbuf.__get_stringview(1, 2), content="b")
  lexbuf.__commit_to(0)
  inspect(lexbuf.__get_cursor(), content="0")
  inspect(lexbuf.__unsafe_code_unit_at(0), content="97")
}

///|
test "Lexbuf retains a token across many chunks" {
  let chunk_count = 4096
  let chunks = Array::make(chunk_count, "x").iter()
  let lexbuf = @lexbuf.Lexbuf::from_fn(() => chunks.next())
  lexbuf.__refill()
  lexbuf.__retain_from_cursor()
  for _ in 0..<chunk_count {
    inspect(lexbuf.__unsafe_code_unit_at(lexbuf.__get_cursor()), content="120")
    lexbuf.__advance(1)
    if lexbuf.__get_cursor() == lexbuf.__buffer_end() {
      lexbuf.__refill()
    }
  }
  let captured = lexbuf.__get_stringview(0, chunk_count)
  lexbuf.__commit_to(chunk_count - 1)
  inspect(captured.length(), content="4096")
  inspect(lexbuf.__unsafe_code_unit_at(chunk_count - 1), content="120")
}

///|
test "Lexbuf preserves UTF-16 chunk boundaries" {
  let input = "a😀b"
  let chunks = [
    input.unsafe_substring(start=0, end=2),
    input.unsafe_substring(start=2, end=4),
  ].iter()
  let lexbuf = @lexbuf.Lexbuf::from_fn(() => chunks.next())
  lexbuf.__refill()
  lexbuf.__retain_from_cursor()
  lexbuf.__advance(2)
  lexbuf.__refill()
  lexbuf.__advance(2)
  inspect(lexbuf.__unsafe_code_unit_at(1), content="55357")
  inspect(lexbuf.__unsafe_code_unit_at(2), content="56832")
  inspect(lexbuf.__get_stringview(0, 4), content="a😀b")
}

///|
test "Lexbuf reads multiple chunks after compaction" {
  let chunks = ["ab", "cd", "ef"].iter()
  let lexbuf = @lexbuf.Lexbuf::from_fn(() => chunks.next())
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
test "Lexbuf returns an empty retained view" {
  let lexbuf = @lexbuf.Lexbuf::from_string("abc")
  lexbuf.__retain_from_cursor()
  inspect(lexbuf.__get_stringview(0, 0), content="")
  lexbuf.__commit_to(0)
}

///|
async fn[T] lexbuf_test_suspend(register : ((T) -> Unit) -> Unit) -> T noraise = "%async.suspend"

///|
fn lexbuf_test_run_async(work : async () -> Unit noraise) -> Unit = "%async.run"

///|
struct LexbufTestScheduler {
  continuations : Array[() -> Unit]
}

///|
fn LexbufTestScheduler::new() -> LexbufTestScheduler {
  { continuations: [] }
}

///|
fn LexbufTestScheduler::run_async(
  self : LexbufTestScheduler,
  work : async () -> Unit,
) -> Unit {
  lexbuf_test_run_async(() => work() catch { _ => panic() })
  let mut index = 0
  while index < self.continuations.length() {
    let continue_ = self.continuations[index]
    index += 1
    continue_()
  }
}

///|
async fn LexbufTestScheduler::pause(self : LexbufTestScheduler) -> Unit noraise {
  lexbuf_test_suspend(continue_ => self.continuations.push(() => continue_(())))
}

///|
test "AsyncLexbuf retains captures across asynchronous refills" {
  let scheduler = LexbufTestScheduler::new()
  scheduler.run_async(async fn() {
    let mut index = 0
    let chunks : ReadOnlyArray[String] = ["ab", "cd", "!"]
    let lexbuf = @lexbuf.AsyncLexbuf::from_fn(async fn() noraise {
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
    let captured = lexbuf.__get_stringview(1, 4)
    lexbuf.__commit_to(3)
    guard captured == "bcd" else { abort("unexpected async capture") }
    guard lexbuf.__get_cursor() == 3 else { abort("unexpected async cursor") }
    guard lexbuf.__unsafe_code_unit_at(3) == 100 else {
      abort("unexpected async code unit")
    }
    lexbuf.__advance(1)
    lexbuf.__refill()
    guard lexbuf.__unsafe_code_unit_at(4) == 33 else {
      abort("unexpected async refill")
    }
  })
}

///|
test "AsyncLexbuf retains a token across many chunks" {
  let scheduler = LexbufTestScheduler::new()
  scheduler.run_async(async fn() {
    let chunk_count = 512
    let mut remaining = chunk_count
    let lexbuf = @lexbuf.AsyncLexbuf::from_fn(async fn() {
      scheduler.pause()
      if remaining > 0 {
        remaining -= 1
        Some("x")
      } else {
        None
      }
    })
    lexbuf.__refill()
    lexbuf.__retain_from_cursor()
    for _ in 0..<chunk_count {
      guard lexbuf.__unsafe_code_unit_at(lexbuf.__get_cursor()) == 120 else {
        abort("unexpected async code unit")
      }
      lexbuf.__advance(1)
      if lexbuf.__get_cursor() == lexbuf.__buffer_end() {
        lexbuf.__refill()
      }
    }
    let captured = lexbuf.__get_stringview(0, chunk_count)
    lexbuf.__commit_to(chunk_count - 1)
    guard captured.length() == chunk_count else {
      abort("unexpected async capture length")
    }
    guard lexbuf.__unsafe_code_unit_at(chunk_count - 1) == 120 else {
      abort("unexpected async committed code unit")
    }
  })
}

///|
test "AsyncLexbuf ignores empty chunks and reports EOF" {
  let scheduler = LexbufTestScheduler::new()
  scheduler.run_async(async fn() {
    let mut index = 0
    let chunks : ReadOnlyArray[String] = ["", "a", ""]
    let lexbuf = @lexbuf.AsyncLexbuf::from_fn(async fn() noraise {
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
