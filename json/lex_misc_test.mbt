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
test "read_char surrogate pair" {
  // Test data:
  // U+1F600 😀 (GRINNING FACE)
  // UTF-16: D83D DE00 (high surrogate: 0xD83D, low surrogate: 0xDE00)
  let json = "\"\uD83D\uDE00\""
  let result = @json.parse!(json)
  match result {
    Json::String(s) => inspect!(s, content="😀")
    _ => fail!("Expected string")
  }
}

///|
test "panic lex_assert_char with EOF" {
  // This case will trigger line L90 where we hit EOF
  let _ = @json.parse!("t")

}
