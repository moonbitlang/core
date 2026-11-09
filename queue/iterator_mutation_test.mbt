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
/// `Queue::iter` goes through `Deque::iter`. Modifying the queue meanwhile only
/// promises memory safety; the expected value records current behaviour.
test "iter after pop does not read unwritten slots" {
  let q = @queue.Queue(["a", "b"], capacity=8)
  let it = q.iter()
  debug_inspect(it.next(), content="Some(\"a\")")
  q.pop() |> ignore
  debug_inspect(it.to_array(), content="[\"b\"]")
}

///|
test "each with a callback that pops and pushes" {
  // Which elements `each` visits is unspecified, but the queue stays
  // consistent.
  let q = @queue.Queue([1, 2, 3, 4])
  let mut done = false
  q.each(x => {
    if x == 2 && !done {
      done = true
      q.pop() |> ignore
      for i in 100..<140 {
        q.push(i)
      }
    }
  })
  inspect(q.length(), content="43")
  inspect(q.iter().count(), content="43")
}
