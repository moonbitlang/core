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
  let source = [
    (9, "outside"),
    (2, "first"),
    (1, "one"),
    (2, "last"),
    (8, "outside"),
  ]
  let view = source[1:4]
  let legacy_from_array = @sorted_map.SortedMap::from_array
  let by_method = legacy_from_array(view)
  let by_function = @sorted_map.from_array(view)
  inspect(by_method == by_function, content="true")
  inspect(by_method == SortedMap(view), content="true")
  source[3] = (2, "changed")
  debug_inspect(
    (by_method.length(), by_method.get(2)),
    content="(2, Some(\"last\"))",
  )
}
