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
test "Debug for JSON metadata" {
  @debug.debug_inspect(
    @json.Position::{ line: 2, column: 3, },
    content="{ line: 2, column: 3 }",
  )
  @debug.debug_inspect(
    @json.Replacer((_, value) => Some(value)),
    content="{ f: <function: ...> }",
  )
}

///|
test "Debug for JSON parse errors" {
  let position = @json.Position::{ line: 2, column: 3, }
  let errors : Array[@json.ParseError] = [
    InvalidChar(position, 'x'),
    InvalidEof,
    InvalidNumber(position, "1e"),
    InvalidIdentEscape(position),
    DuplicateKey(position, "key"),
    DepthLimitExceeded,
  ]
  @debug.debug_inspect(
    errors,
    content=(
      #|[
      #|  InvalidChar({ line: 2, column: 3 }, 'x'),
      #|  InvalidEof,
      #|  InvalidNumber({ line: 2, column: 3 }, "1e"),
      #|  InvalidIdentEscape({ line: 2, column: 3 }),
      #|  DuplicateKey({ line: 2, column: 3 }, "key"),
      #|  DepthLimitExceeded,
      #|]
    ),
  )
}

///|
test "Debug for JSON decode paths uses JSON Pointer escaping" {
  let value : @json.Json = { "a/~": [true] }
  let result : Result[Map[String, Array[Int32]], @json.JsonDecodeError] = Ok(
    @json.from_json(value),
  ) catch {
    error => Err(error)
  }
  guard result is Err(error) else { fail("expected a decode error") }
  @debug.debug_inspect(
    error,
    content=(
      #|JsonDecodeError((<JsonPath: "/a~1~0/0">, "Int::from_json: expected number"))
    ),
  )
}
