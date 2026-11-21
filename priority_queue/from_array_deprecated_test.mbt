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
#warnings("-pending_deprecated")
test "from_array aliases retain constructor semantics" {
  let source = [9, 2, 1, 2, 8]
  let view = source[1:4]
  let legacy_from_array = @priority_queue.PriorityQueue::from_array
  let by_method = legacy_from_array(view)
  let by_function = @priority_queue.from_array(view)
  let canonical = @priority_queue.PriorityQueue(view)
  source[2] = 99
  let values = by_method.to_array()
  let free_values = by_function.to_array()
  let canonical_values = canonical.to_array()
  values.sort()
  free_values.sort()
  canonical_values.sort()
  inspect(values == free_values, content="true")
  inspect(values == canonical_values, content="true")
  debug_inspect(values, content="[1, 2, 2]")
}
