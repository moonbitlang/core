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
test "from_array aliases preserve constructor semantics on views" {
  let source = [9, 3, 1, 3, 8]
  let view = source[1:4]
  let by_method = @list.List::from_array(view)
  let by_function = @list.from_array(view)
  inspect(by_method == List(view), content="true")
  inspect(by_function == by_method, content="true")
  debug_inspect(by_method.to_array(), content="[3, 1, 3]")
  let empty_items : ArrayView[Int32] = []
  inspect(@list.List::from_array(empty_items).is_empty(), content="true")
  inspect(@list.from_array(empty_items).is_empty(), content="true")
}
