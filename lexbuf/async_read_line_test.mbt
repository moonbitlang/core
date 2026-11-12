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
async fn async_lines(
  scheduler : LexbufTestScheduler,
  chunks : Array[String],
) -> Array[String] {
  let chunks = chunks.iter()
  let input = @lexbuf.AsyncLexbuf::from_fn(async fn() noraise {
    scheduler.pause()
    chunks.next()
  })
  let lines = []
  while input.read_line() is Some(line) {
    lines.push(line.to_owned())
  }
  lexscan input {
    re"^$" => ()
    _ => fail("expected EOF")
  }
  lines
}

///|
test "AsyncLexbuf::read_line handles every split across asynchronous refills" {
  let scheduler = LexbufTestScheduler::new()
  scheduler.run_async(async fn() {
    let text = "αβ\r\n😀 x\n\n日本語\r\r\nlast😀"
    let expected = sync_lines([text])
    let cuts = char_boundaries(text)
    for i in cuts {
      for j in cuts {
        if i <= j {
          assert_eq(async_lines(scheduler, split_at(text, [i, j])), expected)
        }
      }
    }
    debug_inspect(async_lines(scheduler, ["", ""]), content="[]")
    debug_inspect(
      async_lines(scheduler, ["\r", "", "\n", "a\rb\r"]),
      content=(
        #|["", "a\rb\r"]
      ),
    )
  })
}

///|
test "AsyncLexbuf::read_line returns a complete line without another refill" {
  let scheduler = LexbufTestScheduler::new()
  scheduler.run_async(async fn() {
    for text in ["hello\n", "hello\r\n", "\n", "\r\n"] {
      let mut pulls = 0
      let input = @lexbuf.AsyncLexbuf::from_fn(async fn() {
        scheduler.pause()
        pulls += 1
        guard pulls == 1 else { fail("unexpected refill") }
        Some(text)
      })
      assert_true(input.read_line() is Some(_))
      assert_eq(pulls, 1)
    }
  })
}

///|
test "AsyncLexbuf::read_line mixes with lexscan and keeps returned views" {
  let scheduler = LexbufTestScheduler::new()
  scheduler.run_async(async fn() {
    let chunks = ["# header\nke", "y=value\r", "\nlast"].iter()
    let input = @lexbuf.AsyncLexbuf::from_fn(async fn() noraise {
      scheduler.pause()
      chunks.next()
    })
    let header = input.read_line().unwrap()
    lexscan input {
      (re"^[a-z]+" as key) + re"=" => {
        let value = input.read_line().unwrap()
        inspect(key, content="key")
        inspect(value, content="value")
      }
      _ => fail("expected key=value")
    }
    inspect(input.read_line().unwrap(), content="last")
    assert_true(input.read_line() is None)
    inspect(header, content="# header")
  })
}

///|
test "AsyncLexbuf::read_line propagates errors during a line" {
  let scheduler = LexbufTestScheduler::new()
  scheduler.run_async(async fn() {
    let mut pulls = 0
    let input = @lexbuf.AsyncLexbuf::from_fn(async fn() {
      scheduler.pause()
      pulls += 1
      if pulls == 1 {
        Some("partial")
      } else {
        fail("source failed")
      }
    })
    let raised = try input.read_line() catch {
      _ => true
    } noraise {
      _ => false
    }
    assert_true(raised)
    inspect(pulls, content="2")
  })
}
