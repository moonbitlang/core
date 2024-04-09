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

pub trait FromStr {
  from_string(String) -> Result[Self, String]
}

pub fn FromStr::from_string(str : String) -> Result[Bool, String] {
  parse_bool(str)
}

pub fn FromStr::from_string(str : String) -> Result[Int, String] {
  parse_int(str)
}

pub fn FromStr::from_string(str : String) -> Result[Int64, String] {
  parse_int64(str)
}

pub fn FromStr::from_string(str : String) -> Result[Double, String] {
  parse_double(str)
}

pub fn parse[A : FromStr](str : String) -> Result[A, String] {
  A::from_string(str)
}

test "parse" {
  let b : Bool = parse("true")?
  @assertion.assert_eq(b, true)?
  let i : Int = parse("12345")?
  @assertion.assert_eq(i, 12345)?
  let i64 : Int64 = parse("9223372036854775807")?
  @assertion.assert_eq(i64, 9223372036854775807L)?
  let d : Double = parse("1234.56789")?
  @assertion.assert_eq(d, 1234.56789)?
}
