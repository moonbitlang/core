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

// Black-box tests covering json paths the existing suites miss: zero / negative
// integer lexing, the "disguised" fast-path for large exponents, unterminated
// escapes, nesting-depth limits, and the `Show` instance for `Json`.

///|
/// Whether parsing `s` raises a `ParseError`.
fn parse_raises(s : String) -> Bool {
  try {
    @json.parse(s) |> ignore
    false
  } catch {
    _ => true
  }
}

///|
test "parse bare and negative zero" {
  inspect(@json.parse("0") is Number(0.0, ..), content="true")
  inspect(@json.parse("-0") is Number(_), content="true")
  inspect(@json.parse("0.5") is Number(0.5, ..), content="true")
  inspect(@json.parse("-0.25") is Number(-0.25, ..), content="true")
}

///|
test "parse small negative integers" {
  inspect(@json.parse("-5") is Number(-5.0, ..), content="true")
  inspect(@json.parse("-123456") is Number(-123456.0, ..), content="true")
}

///|
test "parse numbers on the disguised fast path for large exponents" {
  // exponent in (22, 37] with a small mantissa exercises the disguised
  // fast-path multiply (mantissa * 10^shift)
  inspect(@json.parse("1e23") is Number(_), content="true")
  inspect(@json.parse("2e23") is Number(_), content="true")
  // a large mantissa with a large disguised exponent overflows the checked
  // multiply and falls back to the slow path
  inspect(@json.parse("9007199254740992e37") is Number(_), content="true")
}

///|
test "parse very large integers keeps the original representation" {
  // overflowing the safe-integer range returns infinity tagged with the
  // original digits as `repr`
  inspect(
    @json.parse("99999999999999999999999") is Number(_, repr=Some(_)),
    content="true",
  )
  inspect(
    @json.parse("-99999999999999999999999") is Number(_, repr=Some(_)),
    content="true",
  )
}

///|
test "invalid leading-minus inputs are rejected" {
  // '-' followed by a non-digit
  inspect(parse_raises("-x"), content="true")
  // '-' at end of input
  inspect(parse_raises("-"), content="true")
}

///|
test "unterminated string escape raises an error" {
  // a backslash at end of input has no escaped character to read
  inspect(parse_raises("\"\\"), content="true")
}

///|
test "nesting beyond the default depth limit is rejected" {
  // 1025 nested arrays exceed the default max nesting depth of 1024
  let deep_array = String::make(1025, '[') + String::make(1025, ']')
  inspect(parse_raises(deep_array), content="true")
  // the same for deeply nested objects (a separate depth check)
  let sb = StringBuilder::new()
  for _ in 0..<1025 {
    sb.write_string("{\"a\":")
  }
  sb.write_string("1")
  for _ in 0..<1025 {
    sb.write_string("}")
  }
  inspect(parse_raises(sb.to_string()), content="true")
  // a shallow document parses fine
  inspect(parse_raises("[[1]]"), content="false")
}

///|
test "Int64 and UInt64 from_json reject non-numeric strings" {
  let bad = @json.parse("\"not-a-number\"")
  let i64 = try {
    (@json.from_json(bad) : Int64) |> ignore
    false
  } catch {
    _ => true
  }
  inspect(i64, content="true")
  let u64 = try {
    (@json.from_json(bad) : UInt64) |> ignore
    false
  } catch {
    _ => true
  }
  inspect(u64, content="true")
}

///|
/// Render a `Json` through its (deprecated) `Show` instance.
#warnings("-deprecated")
fn show_json(j : Json) -> String {
  j.to_string()
}

///|
test "Show instance renders every Json shape" {
  inspect(show_json(@json.parse("null")), content="Null")
  inspect(show_json(@json.parse("true")), content="True")
  inspect(show_json(@json.parse("false")), content="False")
  inspect(show_json(@json.parse("\"hi\"")), content="String(hi)")
  inspect(
    show_json(@json.parse("[1, 2]")),
    content="Array([Number(1), Number(2)])",
  )
  inspect(
    show_json(@json.parse("{\"a\": 1}")),
    content="Object({a: Number(1)})",
  )
  // a Number carrying a repr renders the repr too
  let big = @json.parse("123456789012345678901234567890")
  inspect(show_json(big).contains("repr="), content="true")
}
