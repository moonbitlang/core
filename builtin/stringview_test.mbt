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
