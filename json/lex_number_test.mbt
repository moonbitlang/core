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

// shadow @json.inspect

///|
using @builtin {inspect}

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
    content=(
      #|Ok(Number(Infinity, repr=Some("1e999999999")))
    ),
  )
}

///|
test "parse negative huge exponent" {
  inspect(
    try? @json.parse("-1e999999999"),
    content=(
      #|Ok(Number(-Infinity, repr=Some("-1e999999999")))
    ),
  )
}

///|
test "parse and stringify large integers" {
  // Test integers at Int boundaries
  let min_int = "-2147483648" // Int.min_value
  let parsed_min = @json.parse("\{min_int}")
  inspect(parsed_min, content="Number(-2147483648)")
  inspect(parsed_min.stringify(), content="-2147483648")
  let max_int = "2147483647" // Int.max_value
  let parsed_max = @json.parse("\{max_int}")
  inspect(parsed_max, content="Number(2147483647)")
  inspect(parsed_max.stringify(), content="2147483647")

  // Test integers beyond safe JavaScript integer precision (±2^53)
  let beyond_js_safe = "9007199254740993" // 2^53 + 1
  let parsed_beyond = @json.parse(beyond_js_safe)
  inspect(
    parsed_beyond,
    content=(
      #|Number(Infinity, repr=Some("9007199254740993"))
    ),
  )
  inspect(parsed_beyond.stringify(), content="9007199254740993")

  // Test very large integers
  let very_large = "12345678901234567890123456789"
  let parsed_large = @json.parse(very_large)
  inspect(
    parsed_large,
    content=(
      #|Number(Infinity, repr=Some("12345678901234567890123456789"))
    ),
  )
  inspect(parsed_large.stringify(), content="12345678901234567890123456789")
}

///|
test "parse and stringify large double" {
  let very_large = "10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003.141592653589793238462643383279"
  let parsed_large = @json.parse(very_large)
  inspect(
    parsed_large,
    content=(
      #|Number(Infinity, repr=Some("10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003.141592653589793238462643383279"))
    ),
  )
}
