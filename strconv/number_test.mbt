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
test "parse_inf_nan positive NaN" {
  let result = @strconv.parse_double("+nan")
  inspect(result.is_nan(), content="true")
}

///|
test "parse_inf_nan negative NaN" {
  let result = @strconv.parse_double("-nan")
  inspect(result.is_nan(), content="true")
}

///|
test "from_str generic" {
  let i : Int = @strconv.from_str("123")
  inspect(i, content="123")
  let j : Int64 = @strconv.from_str("1234567890123")
  inspect(j, content="1234567890123")
}
