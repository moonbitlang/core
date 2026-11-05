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
test "to_array tolerates a size that disagrees with the tree" {
  let set = SortedSet(["b", "a", "c"])
  for size in [0, 1, 3, 5] {
    set.size = size
    assert_true(set.to_array() == ["a", "b", "c"])
  }
  let empty : SortedSet[String] = SortedSet([])
  empty.size = 3
  inspect(empty.to_array().length(), content="0")
}
