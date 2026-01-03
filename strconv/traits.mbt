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

// TODO:
// 
// - Format functions.
// - Support hexadecimal floating point number.
// - Implements Eisel-Lemire algorithm to speed up floating point parsing.

///|
pub(open) trait FromStr {
  #as_free_fn
  from_str(StringView) -> Self raise StrConvError = _
  #deprecated("use `from_str` instead", skip_current_package=true)
  from_string(String) -> Self raise StrConvError = _
}

///|
#deprecated("replace `impl from_string` with `impl from_str`")
impl FromStr with from_str(str) {
  FromStr::from_string(str.to_string())
}

///|
impl FromStr with from_string(str) {
  FromStr::from_str(str)
}

///|
pub impl FromStr for Bool with from_str(str) {
  parse_bool(str)
}

///|
pub impl FromStr for Int with from_str(str) {
  parse_int(str)
}

///|
pub impl FromStr for Int64 with from_str(str) {
  parse_int64(str)
}

///|
pub impl FromStr for UInt with from_str(str) {
  parse_uint(str)
}

///|
pub impl FromStr for UInt64 with from_str(str) {
  parse_uint64(str)
}

///|
pub impl FromStr for Double with from_str(str) {
  parse_double(str)
}

///|
test "parse" {
  let b : Bool = from_str("true")
  inspect(b, content="true")
  let i : Int = from_str("12345")
  inspect(i, content="12345")
  let i64 : Int64 = from_str("9223372036854775807")
  assert_eq(i64, 9223372036854775807L)
  let ui : UInt = from_str("4294967295")
  inspect(ui, content="4294967295")
  let ui64 : UInt64 = from_str("18446744073709551615")
  assert_eq(ui64, 18446744073709551615UL)
  let d : Double = from_str("1234.56789")
  assert_eq(d, 1234.56789)
}
