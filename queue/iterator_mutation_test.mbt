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
