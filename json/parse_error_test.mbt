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
test "parse error branches" {
  guard expect_parse_error("", "expected InvalidEof for empty input")
    is InvalidEof else {
    fail("expected InvalidEof for empty input")
  }
  guard expect_parse_error(
      " \t\r\n", "expected InvalidEof for whitespace-only input",
    )
    is InvalidEof else {
    fail("expected InvalidEof for whitespace-only input")
  }
  guard expect_parse_error("@", "expected InvalidChar for invalid start")
    is InvalidChar(_, _) else {
    fail("expected InvalidChar for invalid start")
  }
  guard expect_parse_error("nullx", "expected InvalidChar for trailing data")
    is InvalidChar(_, _) else {
    fail("expected InvalidChar for trailing data")
  }
  guard expect_parse_error(
      "\u{00A0}null", "expected InvalidChar for leading non-breaking space",
    )
    is InvalidChar(_, _) else {
    fail("expected InvalidChar for leading non-breaking space")
  }
  guard expect_parse_error("tx", "expected InvalidChar for invalid literal")
    is InvalidChar(_, _) else {
    fail("expected InvalidChar for invalid literal")
  }
  guard expect_parse_error("-x", "expected InvalidChar for invalid minus")
    is InvalidChar(_, _) else {
    fail("expected InvalidChar for invalid minus")
  }
  guard expect_parse_error("-", "expected InvalidEof for dangling minus")
    is InvalidEof else {
    fail("expected InvalidEof for dangling minus")
  }
  guard expect_parse_error("1.", "expected InvalidEof for trailing dot")
    is InvalidEof else {
    fail("expected InvalidEof for trailing dot")
  }
  guard expect_parse_error("1.a", "expected InvalidChar for bad fraction")
    is InvalidChar(_, _) else {
    fail("expected InvalidChar for bad fraction")
  }
  guard expect_parse_error("1eA", "expected InvalidChar for bad exponent")
    is InvalidChar(_, _) else {
    fail("expected InvalidChar for bad exponent")
  }
  guard expect_parse_error("1e+a", "expected InvalidChar for bad exponent sign")
    is InvalidChar(_, _) else {
    fail("expected InvalidChar for bad exponent sign")
  }
  guard expect_parse_error("1e+", "expected InvalidEof for missing exponent")
    is InvalidEof else {
    fail("expected InvalidEof for missing exponent")
  }
  guard expect_parse_error(
      "\"line\nbreak\"", "expected InvalidChar for newline in string",
    )
    is InvalidChar(_, _) else {
    fail("expected InvalidChar for newline in string")
  }
  guard expect_parse_error("\"\\q\"", "expected InvalidChar for invalid escape")
    is InvalidChar(_, _) else {
    fail("expected InvalidChar for invalid escape")
  }
  guard expect_parse_error(
      "\"a\u{1}b\"", "expected InvalidChar for control char",
    )
    is InvalidChar(_, _) else {
    fail("expected InvalidChar for control char")
  }
  guard expect_parse_error(
      "\"unterminated", "expected InvalidEof for unterminated string",
    )
    is InvalidEof else {
    fail("expected InvalidEof for unterminated string")
  }
  guard expect_parse_error(
      "\"endswith\\", "expected InvalidEof for trailing escape",
    )
    is InvalidEof else {
    fail("expected InvalidEof for trailing escape")
  }
  guard expect_parse_error(
      "\"\\u:000\"", "expected InvalidChar for invalid hex digit",
    )
    is InvalidChar(_, _) else {
    fail("expected InvalidChar for invalid hex digit")
  }
  guard expect_parse_error(
      "\"\\u/000\"", "expected InvalidChar for invalid hex digit",
    )
    is InvalidChar(_, _) else {
    fail("expected InvalidChar for invalid hex digit")
  }
  guard expect_parse_error(
      "\"\\uG000\"", "expected InvalidChar for invalid hex letter",
    )
    is InvalidChar(_, _) else {
    fail("expected InvalidChar for invalid hex letter")
  }
  guard expect_parse_error("[1", "expected InvalidEof for incomplete array")
    is InvalidEof else {
    fail("expected InvalidEof for incomplete array")
  }
  guard expect_parse_error("{\"a\"", "expected InvalidEof for missing colon")
    is InvalidEof else {
    fail("expected InvalidEof for missing colon")
  }
  guard expect_parse_error(
      "{\"a\":1", "expected InvalidEof for incomplete object",
    )
    is InvalidEof else {
    fail("expected InvalidEof for incomplete object")
  }
  guard expect_parse_error(
      "{\"a\":1,", "expected InvalidEof after trailing comma",
    )
    is InvalidEof else {
    fail("expected InvalidEof after trailing comma")
  }
  let err = expect_parse_error(
    String::make(1025, '[') + String::make(1025, ']'),
    "expected DepthLimitExceeded",
  )
  guard err is DepthLimitExceeded else { fail("expected DepthLimitExceeded") }
  inspect(
    err.to_string(),
    content="Depth limit exceeded, please increase the max_nesting_depth parameter",
  )
  ignore(@json.parse("-999999999999999999999999999999999999"))
  ignore(@json.parse("-1e999999999999999999999999999999999999"))
}
