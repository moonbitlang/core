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
test "lex_string with forward slash escape" {
  inspect!(
    @json.parse!("\"\\/\""),
    content="String(\"/\")"
  )
}

///|
test "lex_hex_digits incomplete hex digits" {
  inspect!(@json.parse?("\"\\u123"), content="Err(Unexpected end of file)")
}

///|
test "lex_string with basic escape sequences" {
  let result = @json.parse!("\"\\n\\r\\t\\\"\\\\\"")
  match result {
    Json::String(s) => assert_eq!(s, "\n\r\t\"\\")
    _ => fail!("Expected string")
  }
}

///|
test "lex_string with invalid escape sequence" {
  inspect!(
    @json.parse?("\"\\a\""),
    content="Err(Invalid character 'a' at line 1, column 2)"
  )
}

///|
test "lex_string with incomplete unicode sequence" {
  let result = @json.parse?("\"\\u12\"")
  inspect!(result, content=
    #|Err(Invalid character '"' at line 1, column 5)
  )
  // match result {
  //   Ok(_) => fail!("Expected error for incomplete unicode sequence")
  //   Err(e) => assert_eq!(e.to_string(), "Unexpected end of file")
  // }
}

///|
test "lex_string with simple unicode escape" {
  let result = @json.parse!("\"\\u0020\"")
  match result {
    Json::String(s) => assert_eq!(s, " ")
    _ => fail!("Expected string")
  }
}
