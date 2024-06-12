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

test "new_counter" {
  let counter = CoverageCounter::new(2)
  let result = counter.to_string()
  // @assertion.assert_eq(result, "[0, 0]")?
  if result != "[0, 0]" {
    return Err("Expected: [0, 0], got: " + result)
  }
}

test "incr_counter" {
  let counter = CoverageCounter::new(10)
  counter.incr(0)
  counter.incr(9)
  let result = counter.to_string()
  // @assertion.assert_eq(result, "[1, 0, 0, 0, 0, 0, 0, 0, 0, 1]")?
  if result != "[1, 0, 0, 0, 0, 0, 0, 0, 0, 1]" {
    return Err("Expected: [1, 0, 0, 0, 0, 0, 0, 0, 0, 1], got: " + result)
  }
}

test "backslash escape" {
  let s = "\n\r\t\b\"'\\"
  let expected = "\\n\\r\\t\\b\\\"'\\\\"
  // @assertion.assert_eq(escape(s), expected)?
  let escape_s = escape(s)
  if escape_s != expected {
    return Err("Expected: " + expected + ", got: " + escape_s)
  }
}

// FIXME: formatting string does not work, this test will be destroyed by formatting
// test "hex escape" {
//   let s = "\x11\x12\x01\x02"
//   let expected = "\\x11\\x12\\x01\\x02"
//   @assertion.assert_eq(s.escape(), expected)?
// }

test "log" {
  let test_counter_a = CoverageCounter::new(2)
  let test_counter_b = CoverageCounter::new(2)
  test_counter_a.incr(0)
  test_counter_b.incr(1)
  let counters : MList[(String, CoverageCounter)] = MCons(
    ("foo/foo", test_counter_a),
    MCons(("foo/bar", test_counter_b), MNil),
  )
  let buf = Buffer::make(1024)
  log(counters, buf)
  let result = buf.to_string()
  let expected =
    #|{ "foo/foo": [1, 0]
    #|, "foo/bar": [0, 1]
    #|}
    #|

  // @assertion.assert_eq(result, expected)?
  if result != expected {
    return Err("Expected: " + expected + ", got: " + result)
  }
}
