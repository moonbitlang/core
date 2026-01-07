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
test "pretty_printer: empty_content prints empty" {
  @builtin.inspect(print_content(empty_content().no_wrap()), content="")
}

///|
test "pretty_printer: surround_lines handles empty and singleton" {
  let empty = surround("(", ")", verbatim(""))
  @builtin.inspect(print_content(empty), content="()")
  let single = surround("(", ")", verbatim("x"))
  @builtin.inspect(print_content(single), content="(x)")
}

///|
test "pretty_printer: compact_lines handles empty and multiline" {
  let content = comma_seq("", "", [verbatim("a"), verbatim("b"), verbatim("c")])
  let compact = content.compact()
  @builtin.inspect(print_content(compact.no_wrap()), content="a, b, c")
}

///|
test "pretty_printer: comma_seq_lines filters empty lines" {
  let empty = comma_seq("", "", [])
  @builtin.inspect(print_content(empty.no_wrap()), content="")
}
