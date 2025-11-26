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
test "StringView::suffixes" {
  let str = "za🤣b"
  let start = str.offset_of_nth_char(1).unwrap()
  let view = str.view(start_offset=start)
  let suffixes = view.suffixes().map(v => v.to_string()).collect()
  @json.inspect(suffixes, content=["a🤣b", "🤣b", "b"])
  let suffixes_with_empty = view
    .suffixes(include_empty=true)
    .map(v => v.to_string())
    .collect()
  @json.inspect(suffixes_with_empty, content=["a🤣b", "🤣b", "b", ""])
  let suffixes_no_empty = view
    .suffixes(include_empty=false)
    .map(v => v.to_string())
    .collect()
  @json.inspect(suffixes_no_empty, content=["a🤣b", "🤣b", "b"])
}

///|
test "code_unit_at" {
  let s = "Hello, 世界!😀"
  assert_true(s[:].code_unit_at(0) is 'H')
  assert_true(s[:].code_unit_at(7) is '世')
  assert_true(s[:].code_unit_at(8) is '界')
  assert_true(s[:].code_unit_at(0) is ('A'..='Z'))
  inspect(s[:].code_unit_at(0), content="72") // 'H'
  inspect(s[:].code_unit_at(7), content="19990") // '世'
  inspect(s[:].code_unit_at(8), content="30028") // '界'
  inspect(s[:].code_unit_at(10), content="55357") // High surrogate of '😀'
  inspect(s[:].code_unit_at(11), content="56832") // Low surrogate of '😀'
  let view = s[7:] // "世界!😀"
  inspect(view.code_unit_at(0), content="19990") // '世'
  inspect(view.code_unit_at(1), content="30028") // '界'
  inspect(view.code_unit_at(3), content="55357") // High surrogate of '😀'
  inspect(view.code_unit_at(4), content="56832") // Low surrogate of '😀'
}
