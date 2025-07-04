// Copyright 2025 International Digital Economy Academy
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
// shadow @json.inspect
fnalias @builtin.inspect

///| shadow

///|
test "parse invalid decimal exponent sign" {
  inspect(try? @json.parse("1e"), content="Err(Unexpected end of file)")
}

///|
test "lex_zero invalid case" {
  inspect(
    try? @json.parse("01"),
    content="Err(Invalid character '1' at line 1, column 1)",
  )
}

///|
test "parse numbers" {
  // Basic float parsing
  inspect(@json.parse("123.45"), content="Number(123.45)")
  inspect(@json.parse("-123.45"), content="Number(-123.45)")

  // Exponential notation
  // Note: The actual format depends on the implementation details of Double.to_string()
  let exp_plus = @json.parse("123.45e+10")
  inspect(exp_plus, content="Number(1234500000000)")
  inspect(exp_plus.stringify(), content="1234500000000")
  let exp_minus = @json.parse("123.45e-10")
  inspect(exp_minus, content="Number(1.2345e-8)")
  inspect(exp_minus.stringify(), content="1.2345e-8")
  let exp_upper_plus = @json.parse("123.45E+10")
  inspect(exp_upper_plus.stringify(), content="1234500000000")
  let exp_upper_minus = @json.parse("123.45E-10")
  inspect(exp_upper_minus.stringify(), content="1.2345e-8")

  // Very large number
  inspect(
    try? @json.parse("1e999999999"),
    content=
      #|Ok(Number(Infinity, repr=Some("1e999999999")))
    ,
  )
}

///|
test "parse and stringify large integers" {
  // Test integers at Int boundaries
  let min_int = "-2147483648" // Int.min_value
  let parsed_min_str = @json.parse("\"" + min_int + "\"").stringify()
  assert_eq(parsed_min_str, "\"" + min_int + "\"")
  let max_int = "2147483647" // Int.max_value
  let parsed_max_str = @json.parse("\"" + max_int + "\"").stringify()
  assert_eq(parsed_max_str, "\"" + max_int + "\"")

  // Test integers beyond safe JavaScript integer precision (±2^53)
  let beyond_js_safe = "9007199254740993" // 2^53 + 1
  let json_beyond = "\"" + beyond_js_safe + "\""
  let parsed_beyond_str = @json.parse(json_beyond).stringify()
  assert_eq(parsed_beyond_str, json_beyond)

  // Test very large integers
  let very_large = "12345678901234567890123456789"
  let json_large = "\"" + very_large + "\""
  let parsed_large_str = @json.parse(json_large).stringify()
  assert_eq(parsed_large_str, json_large)
}
