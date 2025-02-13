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
test "parse invalid decimal exponent sign" {
  inspect!(@json.parse?("1e"), content="Err(Unexpected end of file)")
}

///|
test "lex_zero invalid case" {
  inspect!(
    @json.parse?("01"),
    content="Err(Invalid character '1' at line 1, column 1)",
  )
}

///|
test "invalid number" {
  inspect!(
    @json.parse?("1e999999999"),
    content="Err(Invalid number 1e999999999 at line 1, column 0)",
  )
}

///|
test "parse incomplete exponent sign" {
  inspect!(@json.parse?("1e+"), content="Err(Unexpected end of file)")
}
