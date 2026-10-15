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
test "duplicate keys keep the last value by default and when explicitly allowed" {
  let input = "{\"b\":1,\"a\":2,\"b\":3}"
  inspect(@json.parse(input).stringify(), content="{\"b\":3,\"a\":2}")
  inspect(
    @json.parse(input, reject_duplicate_keys=false).stringify(),
    content="{\"b\":3,\"a\":2}",
  )
}

///|
test "reject duplicate decoded keys at the second opening quote" {
  let err = expect_error(
    () => {
      @json.parse(
        "{\n  \"a\": null,\n  \"\\u0061\": 2\n}",
        reject_duplicate_keys=true,
      )
      |> ignore
    },
    "expected duplicate key",
  )
  debug_inspect(err, content="DuplicateKey({ line: 3, column: 2 }, \"a\")")
  inspect(err.to_string(), content="Duplicate key \"a\" at line 3, column 2")
}

///|
test "duplicate detection applies inside objects and arrays" {
  for
    input in [
      "{\"a\":1,\"a\":2}", "{\"outer\":{\"a\":1,\"a\":2}}", "[{\"a\":1,\"a\":2}]",
      "{\"outer\":[{\"a\":1,\"a\":2}]}", "{\"\":1,\"\":2}", "{\"😀\":1,\"\\uD83D\\uDE00\":2}",
    ] {
    let err = expect_error(
      () => @json.parse(input, reject_duplicate_keys=true) |> ignore,
      "expected duplicate key",
    )
    assert_true(err is DuplicateKey(_, _))
  }
}

///|
test "keys in separate objects are independent" {
  let input = "{\"a\":{\"a\":1},\"b\":[{\"a\":2},{\"a\":3}],\"empty\":{}}"
  inspect(
    @json.parse(input, reject_duplicate_keys=true).stringify(),
    content=input,
  )
}

///|
test "duplicate key position is relative to the input view" {
  let input = "prefix{\"a\":1, \"a\":2}suffix"
  let err = expect_error(
    () => @json.parse(input[6:21], reject_duplicate_keys=true) |> ignore,
    "expected duplicate key",
  )
  debug_inspect(err, content="DuplicateKey({ line: 1, column: 8 }, \"a\")")
}
