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
test "BytesLexbuf constructor from prelude" {
  let chunks = [b"", b"\xff\x00", b""].iter()
  let input = BytesLexbuf(() => chunks.next())
  input.__refill()
  inspect(input.__unsafe_code_unit_at(0), content="255")
  inspect(input.__unsafe_code_unit_at(1), content="0")
  input.__advance(2)
  input.__refill()
  assert_true(input.__eof_reached())
}

///|
fn run_lexbuf_test(work : async () -> Unit noraise) -> Unit = "%async.run"

///|
test "AsyncLexbuf and AsyncBytesLexbuf constructors from prelude" {
  let mut completed = false
  // These in-memory sources never suspend, so the test finishes synchronously.
  run_lexbuf_test(async fn() noraise {
    try {
      let chunks = ["ab", "cd"].iter()
      let input = AsyncLexbuf(() => chunks.next())
      lexscan input {
        re"^[a-z]+" as word => inspect(word, content="abcd")
        _ => fail("expected word")
      }
      lexscan input {
        re"^$" => ()
        _ => fail("expected EOF")
      }
      let chunks = [b"", b"\xff\x00", b""].iter()
      let input = AsyncBytesLexbuf(() => chunks.next())
      input.__refill()
      inspect(input.__unsafe_code_unit_at(0), content="255")
      inspect(input.__unsafe_code_unit_at(1), content="0")
      input.__advance(2)
      input.__refill()
      assert_true(input.__eof_reached())
      completed = true
    } catch {
      _ => panic()
    }
  })
  assert_true(completed)
}
