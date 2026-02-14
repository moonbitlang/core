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
test "compile/basic_execute" {
  let regex = @bytes.BytesRegex("[[:digit:]]+")
  guard regex.execute(b"a12b") is Some(m) else { fail("Expected match") }
  inspect(m.content(), content="b\"12\"")
}

///|
test "execute/non_capture_group" {
  let regex = @bytes.BytesRegex("(?:ab)(c)(?:d)")
  guard regex.execute(b"abcd") is Some(m) else { fail("Expected match") }
  inspect(m.group(0).unwrap(), content="b\"abcd\"")
  inspect(m.group(1).unwrap(), content="b\"c\"")
  inspect(m.group(2), content="None")
}

///|
test "execute/non_capture_with_named_group" {
  let regex = @bytes.BytesRegex("(?:a)(b)(?:c)(?<d>d)")
  guard regex.execute(b"abcd") is Some(m) else { fail("Expected match") }
  inspect(m.group(1).unwrap(), content="b\"b\"")
  inspect(m.group(2).unwrap(), content="b\"d\"")
  inspect(m.named_group("d").unwrap(), content="b\"d\"")
}

///|
test "compile/error_unclosed_group" {
  guard (try? @bytes.BytesRegex("(")) is Err(_) else {
    fail("Expected compile failure for unclosed group")
  }
}

///|
test "compile/error_unclosed_char_class" {
  guard (try? @bytes.BytesRegex("[abc")) is Err(_) else {
    fail("Expected compile failure for unclosed char class")
  }
}
