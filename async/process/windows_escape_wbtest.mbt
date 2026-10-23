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
#cfg(any(target="wasm", platform="windows"))
fn test_arg(arg : String) -> String {
  StringBuilder()..write_arg_with_windows_escape(arg).to_string()
}

///|
#cfg(any(target="wasm", platform="windows"))
test "windows command line arg escape" {
  // These tests come from
  // https://learn.microsoft.com/en-us/cpp/c-language/parsing-c-command-line-arguments
  let test_str =
    #|a b c
  inspect(
    test_arg(test_str),
    content=(
      #|"a b c"
    ),
  )
  let test_str =
    #|ab"c
  inspect(
    test_arg(test_str),
    content=(
      #|"ab\"c"
    ),
  )
  let test_str =
    #|\
  inspect(test_arg(test_str), content="\\")
  let test_str =
    #|a\\\c
  inspect(test_arg(test_str), content="a\\\\\\c")
  let test_str =
    #|a\"c
  inspect(
    test_arg(test_str),
    content=(
      #|"a\\\"c"
    ),
  )
  let test_str =
    #|a\\b c
  inspect(
    test_arg(test_str),
    content=(
      #|"a\\b c"
    ),
  )
  let test_str =
    #|ab" c d
  inspect(
    test_arg(test_str),
    content=(
      #|"ab\" c d"
    ),
  )
}

///|
#cfg(any(target="wasm", platform="windows"))
test "windows command line arg escape empty" {
  let test_str = ""
  inspect(
    test_arg(test_str),
    content=(
      #|""
    ),
  )
}

///|
#cfg(any(target="wasm", platform="windows"))
test "windows command line arg escape leading quote" {
  let test_str =
    #|"abcd
  inspect(
    test_arg(test_str),
    content=(
      #|"\"abcd"
    ),
  )
}

///|
#cfg(any(target="wasm", platform="windows"))
test "windows command line arg truncate on NUL" {
  let test_str = "ab\u{0000}cd"
  inspect(
    test_arg(test_str),
    content=(
      #|"ab"
    ),
  )
}
