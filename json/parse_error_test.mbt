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
#warnings("-deprecated")
test "parse error branches" {
  guard (try? @json.parse("")) is Err(InvalidEof) else {
    fail("expected InvalidEof for empty input")
  }
  guard (try? @json.parse("@")) is Err(InvalidChar(_, _)) else {
    fail("expected InvalidChar for invalid start")
  }
  guard (try? @json.parse("nullx")) is Err(InvalidChar(_, _)) else {
    fail("expected InvalidChar for trailing data")
  }
  guard (try? @json.parse("\u{00A0}null")) is Err(InvalidChar(_, _)) else {
    fail("expected InvalidChar for leading non-breaking space")
  }
  guard (try? @json.parse("tx")) is Err(InvalidChar(_, _)) else {
    fail("expected InvalidChar for invalid literal")
  }
  guard (try? @json.parse("-x")) is Err(InvalidChar(_, _)) else {
    fail("expected InvalidChar for invalid minus")
  }
  guard (try? @json.parse("-")) is Err(InvalidEof) else {
    fail("expected InvalidEof for dangling minus")
  }
  guard (try? @json.parse("1.")) is Err(InvalidEof) else {
    fail("expected InvalidEof for trailing dot")
  }
  guard (try? @json.parse("1.a")) is Err(InvalidChar(_, _)) else {
    fail("expected InvalidChar for bad fraction")
  }
  guard (try? @json.parse("1eA")) is Err(InvalidChar(_, _)) else {
    fail("expected InvalidChar for bad exponent")
  }
  guard (try? @json.parse("1e+a")) is Err(InvalidChar(_, _)) else {
    fail("expected InvalidChar for bad exponent sign")
  }
  guard (try? @json.parse("1e+")) is Err(InvalidEof) else {
    fail("expected InvalidEof for missing exponent")
  }
  guard (try? @json.parse("\"line\nbreak\"")) is Err(InvalidChar(_, _)) else {
    fail("expected InvalidChar for newline in string")
  }
  guard (try? @json.parse("\"\\q\"")) is Err(InvalidChar(_, _)) else {
    fail("expected InvalidChar for invalid escape")
  }
  guard (try? @json.parse("\"a\u{1}b\"")) is Err(InvalidChar(_, _)) else {
    fail("expected InvalidChar for control char")
  }
  guard (try? @json.parse("\"unterminated")) is Err(InvalidEof) else {
    fail("expected InvalidEof for unterminated string")
  }
  guard (try? @json.parse("\"endswith\\")) is Err(InvalidEof) else {
    fail("expected InvalidEof for trailing escape")
  }
  guard (try? @json.parse("\"\\u:000\"")) is Err(InvalidChar(_, _)) else {
    fail("expected InvalidChar for invalid hex digit")
  }
  guard (try? @json.parse("\"\\u/000\"")) is Err(InvalidChar(_, _)) else {
    fail("expected InvalidChar for invalid hex digit")
  }
  guard (try? @json.parse("\"\\uG000\"")) is Err(InvalidChar(_, _)) else {
    fail("expected InvalidChar for invalid hex letter")
  }
  guard (try? @json.parse("[1")) is Err(InvalidEof) else {
    fail("expected InvalidEof for incomplete array")
  }
  guard (try? @json.parse("{\"a\"")) is Err(InvalidEof) else {
    fail("expected InvalidEof for missing colon")
  }
  guard (try? @json.parse("{\"a\":1")) is Err(InvalidEof) else {
    fail("expected InvalidEof for incomplete object")
  }
  guard (try? @json.parse("{\"a\":1,")) is Err(InvalidEof) else {
    fail("expected InvalidEof after trailing comma")
  }
  let depth_result : Result[Json, _] = try? @json.parse(
    "{\"a\":{}}",
    max_nesting_depth=1,
  )
  guard depth_result is Err(err) else { fail("expected DepthLimitExceeded") }
  guard err is DepthLimitExceeded else { fail("expected DepthLimitExceeded") }
  inspect(
    err.to_string(),
    content="Depth limit exceeded, please increase the max_nesting_depth parameter",
  )
  ignore(@json.parse("-999999999999999999999999999999999999"))
  ignore(@json.parse("-1e999999999999999999999999999999999999"))
}
