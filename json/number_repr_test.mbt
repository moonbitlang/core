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
test "preserve every number spelling without changing its Double value" {
  for
    text in [
      "0", "-0", "1", "-42", "9007199254740991", "9007199254740993", "18446744073709551615",
      "1.0", "1.2300", "-0.00", "1e0", "1E+00", "-0e-10", "0.123456789012345678901234567890",
      "2.2250738585072014e-308", "5e-324", "1e-9999", "1e9999", "-1e9999",
    ] {
    let original = @json.parse(text)
    let preserved = @json.parse(text, preserve_number_repr=true)
    guard original is Number(value, ..) &&
      preserved is Number(other, repr=Some(repr)) else {
      fail("expected preserved number: \{text}")
    }
    assert_eq(repr, text)
    assert_eq(preserved.stringify(), text)
    assert_eq(value.reinterpret_as_int64(), other.reinterpret_as_int64())
  }
}

///|
test "default and explicit false preserve existing repr behavior" {
  for text in ["0", "-0", "42", "1.0", "1e0", "0.123456789012345678901"] {
    assert_true(@json.parse(text) is Number(_, repr=None))
    assert_true(
      @json.parse(text, preserve_number_repr=false) is Number(_, repr=None),
    )
  }
  for text in ["9007199254740993", "1e9999", "-1e9999"] {
    guard @json.parse(text) is Number(_, repr=Some(original)) &&
      @json.parse(text, preserve_number_repr=false)
      is Number(_, repr=Some(explicit)) else {
      fail("expected existing fallback repr")
    }
    assert_eq(original, text)
    assert_eq(explicit, text)
  }
}

///|
test "preserve number boundaries in nested objects and input views" {
  let text = "prefix \n {\"a\": [1, 1.00, {\"b\": -0E+00}], \"c\": 2e-03} \t suffix"
  let input = text[6:text.length() - 6]
  inspect(
    @json.parse(input, preserve_number_repr=true, reject_duplicate_keys=true).stringify(),
    content="{\"a\":[1,1.00,{\"b\":-0E+00}],\"c\":2e-03}",
  )
}

///|
test "preserving number repr does not accept malformed numbers" {
  for
    input in ["01", "-01", "1.", "1e", "1e+", "--1", "1 2", "1😀", "1.0😀"] {
    let original = expect_error(
      () => @json.parse(input) |> ignore,
      "expected parse error",
    )
    let preserved = expect_error(
      () => @json.parse(input, preserve_number_repr=true) |> ignore,
      "expected parse error with preservation",
    )
    assert_eq(original, preserved)
  }
}

///|
test "number preservation composes with duplicate key rejection" {
  let err = expect_error(
    () => {
      @json.parse(
        "{\"a\":1.0,\"a\":1e0}",
        preserve_number_repr=true,
        reject_duplicate_keys=true,
      )
      |> ignore
    },
    "expected duplicate key",
  )
  debug_inspect(err, content="DuplicateKey({ line: 1, column: 9 }, \"a\")")
}
