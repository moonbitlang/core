// Copyright 2024 International Digital Economy Academy
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

test "hash" {
  let d1 = 123.456
  let d2 = 789.012
  let d3 = 123.456
  assert_eq!(Hash::hash(d1), d1.reinterpret_as_i64() |> Hash::hash())
  assert_ne!(Hash::hash(d1), Hash::hash(d2))
  assert_eq!(Hash::hash(d1), Hash::hash(d3))
}
