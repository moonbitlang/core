// Copyright 2025 International Digital Economy Academy
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
test "iterator" {
  let arr = [1, 2, 3, 4, 5]
  let iter = arr.iterator().map(x => x * 2)
  inspect(iter.to_array(), content="[2, 4, 6, 8, 10]")
}

///|
test "rev_iterator" {
  let arr = [1, 2, 3, 4, 5]
  let iter = arr.rev_iterator().map(x => x * 2)
  inspect(iter.to_array(), content="[10, 8, 6, 4, 2]")
}

///|
test "iterator2" {
  let arr = [1, 2, 3, 4, 5]
  let iter = arr.iterator2()
  inspect(iter.to_string(), content="[(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]")
}
