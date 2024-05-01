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

test "slice" {
  let v = Vec::[1, 2, 3, 4, 5]
  let s = v.op_as_view(start=1, end=4)
  @assertion.assert_eq(s.length(), 3)?
  @assertion.assert_eq(s[0], 2)?
  @assertion.assert_eq(s[1], 3)?
}