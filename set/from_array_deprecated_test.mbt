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
#warnings("-deprecated")
test "deprecated from_array aliases retain constructor semantics" {
  let source = [9, 2, 1, 2, 8]
  let view = source[1:4]
  let by_method = @set.Set::from_array(view, capacity=8)
  let by_function = @set.from_array(view, capacity=8)
  inspect(by_method == by_function, content="true")
  inspect(by_method == Set(view, capacity=8), content="true")
  source[2] = 99
  debug_inspect(
    (by_method.length(), by_method.contains(1), by_method.contains(9)),
    content="(2, true, false)",
  )
}
