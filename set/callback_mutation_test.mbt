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

// A callback that modifies the set it is traversing gets unspecified results,
// but the results must stay memory-safe and well-formed.

///|
test "filter: callback re-adds the current element" {
  let s = @set.Set([1, 2, 3])
  let r = s.filter(x => {
    if x == 1 {
      s.remove(1)
      s.add(1)
    }
    true
  })
  inspect(r.length(), content="3")
  debug_inspect(r.to_array(), content="[1, 2, 3]")
  debug_inspect(s.to_array(), content="[2, 3, 1]")
}
