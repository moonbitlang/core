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
test "try_fast_path overflow when shift is too large" {
  // When the shift (exponent - max_exponent_fast_path) is too large,
  // the multiplication of mantissa with int_pow10[shift] will overflow,
  // triggering line 130
  let result = @strconv.parse_double("9007199254740992e30")
  // The function successfully falls back to slow path
  inspect(result, content="9.007199254740992e+45")
}

///|
test "try_fast_path overflow when mantissa is too large" {
  // When the mantissa after shifting is larger than max_mantissa_fast_path,
  // line 133 will be triggered
  let result = @strconv.parse_double("9007199254740992e23")
  // The function successfully falls back to slow path
  inspect(result, content="9.007199254740991e+38")
}

///|
test "corner cases" {
  inspect(try? @strconv.parse_double(".123"), content="Ok(0.123)")
  inspect(try? @strconv.parse_double("."), content="Err(invalid syntax)")
  inspect(try? @strconv.parse_double("-"), content="Err(invalid syntax)")
}

///|
test "parse_double infinity and NaN with trailing characters should error" {
  // These should trigger the uncovered line 84 in parse_double
  // parse_inf_nan succeeds but doesn't consume the entire string
  inspect(try? @strconv.parse_double("infabc"), content="Err(invalid syntax)")
  inspect(try? @strconv.parse_double("nanxyz"), content="Err(invalid syntax)")
  inspect(
    try? @strconv.parse_double("+infinity123"),
    content="Err(invalid syntax)",
  )
  inspect(
    try? @strconv.parse_double("-inf_extra"),
    content="Err(invalid syntax)",
  )
  inspect(try? @strconv.parse_double("NaN!"), content="Err(invalid syntax)")
}
