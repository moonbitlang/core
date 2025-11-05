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
fn StringView::make_view(str : String, start : Int, end : Int) -> StringView = "%stringview.make"

///|
/// Iterates over all suffixes of the view, advancing by a Unicode character at
/// a time. Each yielded suffix is itself a view into the original string.
pub fn StringView::suffixes(self : StringView) -> Iterator[StringView] {
  let str = self.str()
  let end = self.end()
  let mut next_start = self.start()
  let mut finished = false
  Iterator::new(fn() -> StringView? {
    if finished {
      None
    } else {
      let suffix = StringView::make_view(str, next_start, end)
      if next_start == end {
        finished = true
      } else {
        let code = str.unsafe_charcode_at(next_start)
        if code.is_leading_surrogate() &&
          next_start + 1 < end &&
          str.unsafe_charcode_at(next_start + 1).is_trailing_surrogate() {
          next_start += 2
        } else {
          next_start += 1
        }
      }
      Some(suffix)
    }
  })
}
