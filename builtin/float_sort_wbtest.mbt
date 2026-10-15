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
test "quicksort heap fallback orders NaNs first" {
  let nan = 0.0 / 0.0
  let arr = Array::makei(64, i => {
    if i % 3 == 0 {
      nan
    } else {
      (64 - i).to_double()
    }
  })
  let expected = arr.copy()
  expected.sort_by(compare)
  fixed_quick_sort(arr.mut_view(), None, 0)
  inspect(
    arr.map(Double::to_string) == expected.map(Double::to_string),
    content="true",
  )
}
