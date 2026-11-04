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

// An iterator over a queue that is modified gets unspecified results, but the
// results must stay memory-safe. The expected values record the current
// behaviour (the buffer is captured up front), not a contract.

///|
test "iter: pop and reallocate during iteration" {
  let q = @queue.from_array([1, 2, 3])
  let it = q.iter()
  debug_inspect(it.next(), content="Some(1)")
  q.pop() |> ignore
  for i in 0..<16 {
    q.push(100 + i)
  }
  debug_inspect(it.next(), content="Some(2)")
  debug_inspect(it.next(), content="Some(3)")
  debug_inspect(it.next(), content="None")
}

///|
test "each: pop and reallocate during iteration" {
  let q = @queue.from_array(["a", "b", "c", "d"])
  let seen = []
  q.each(x => {
    if seen.is_empty() {
      q.pop() |> ignore
      for _ in 0..<16 {
        q.push("z")
      }
    }
    seen.push(x)
  })
  debug_inspect(seen, content="[\"a\", \"b\", \"c\", \"d\"]")
}
