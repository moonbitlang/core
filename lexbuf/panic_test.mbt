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
test "panic Lexbuf rejects an unretained view" {
  let lexbuf = @lexbuf.Lexbuf::from_string("a")
  lexbuf.__get_stringview(0, 1) |> ignore
}

///|
test "panic Lexbuf rejects a commit without retention" {
  let lexbuf = @lexbuf.Lexbuf::from_string("a")
  lexbuf.__commit_to(0)
}

///|
test "panic Lexbuf rejects refill with unread input" {
  let chunks = ["a"].iter()
  let lexbuf = @lexbuf.Lexbuf::from_fn(() => chunks.next())
  lexbuf.__refill()
  lexbuf.__refill()
}

///|
test "panic AsyncLexbuf rejects an unretained view" {
  let scheduler = LexbufTestScheduler::new()
  let lexbuf = @lexbuf.AsyncLexbuf::from_fn(async fn() {
    scheduler.pause()
    Some("a")
  })
  lexbuf.__get_stringview(0, 0) |> ignore
}

///|
test "panic AsyncLexbuf rejects a commit without retention" {
  let scheduler = LexbufTestScheduler::new()
  let lexbuf = @lexbuf.AsyncLexbuf::from_fn(async fn() {
    scheduler.pause()
    Some("a")
  })
  lexbuf.__commit_to(0)
}

///|
test "panic AsyncLexbuf rejects refill with unread input" {
  let scheduler = LexbufTestScheduler::new()
  scheduler.run_async(async fn() {
    let lexbuf = @lexbuf.AsyncLexbuf::from_fn(async fn() {
      scheduler.pause()
      Some("a")
    })
    lexbuf.__refill()
    lexbuf.__refill()
  })
}
