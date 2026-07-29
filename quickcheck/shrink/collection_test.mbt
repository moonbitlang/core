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
test "shrink int list" {
  let il : @list.List[Int] = List([1, 2, 3, 4, 5, 6])
  debug_inspect(
    @shrink.Shrink::shrink(il).collect(),
    content=(
      #|[
      #|  <List: [1, 2, 3, 4, 5]>,
      #|  <List: [1, 2, 3, 4, 6]>,
      #|  <List: [1, 2, 3, 5, 6]>,
      #|  <List: [1, 2, 4, 5, 6]>,
      #|  <List: [1, 3, 4, 5, 6]>,
      #|  <List: [2, 3, 4, 5, 6]>,
      #|  <List: [1, 2, 3]>,
      #|  <List: [4, 5, 6]>,
      #|  <List: [0, 2, 3, 4, 5, 6]>,
      #|  <List: [1, 1, 3, 4, 5, 6]>,
      #|  <List: [1, 0, 3, 4, 5, 6]>,
      #|  <List: [1, 2, 2, 4, 5, 6]>,
      #|  <List: [1, 2, 0, 4, 5, 6]>,
      #|  <List: [1, 2, 3, 3, 5, 6]>,
      #|  <List: [1, 2, 3, 2, 5, 6]>,
      #|  <List: [1, 2, 3, 0, 5, 6]>,
      #|  <List: [1, 2, 3, 4, 4, 6]>,
      #|  <List: [1, 2, 3, 4, 3, 6]>,
      #|  <List: [1, 2, 3, 4, 0, 6]>,
      #|  <List: [1, 2, 3, 4, 5, 5]>,
      #|  <List: [1, 2, 3, 4, 5, 3]>,
      #|  <List: [1, 2, 3, 4, 5, 0]>,
      #|]
    ),
  )
}
