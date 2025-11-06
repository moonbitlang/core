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
pub fn StringView::str(self : StringView) -> String = "%stringview.str"

///|
pub fn StringView::start(self : StringView) -> Int = "%stringview.start"

///|
pub fn StringView::end(self : StringView) -> Int = "%stringview.end"

///|
pub fn StringView::make_view(
  str : String,
  start : Int,
  end : Int,
) -> StringView = "%stringview.make"

///|
fn count_chars_in_range(str : String, start : Int, end : Int) -> Int {
  for index = start, count = 0
      index < end
      index = index + 1, count = count + 1 {
    let c1 = str.unsafe_charcode_at(index)
    if c1.is_leading_surrogate() && index + 1 < end {
      let c2 = str.unsafe_charcode_at(index + 1)
      if c2.is_trailing_surrogate() {
        continue index + 2, count + 1
      } else {
        abort("invalid surrogate pair")
      }
    }
  } else {
    count
  }
}

///|
fn has_at_least_n_chars(str : String, start : Int, end : Int, n : Int) -> Bool {
  if n <= 0 {
    return true
  }
  for index = start, count = 0
      index < end && count < n
      index = index + 1, count = count + 1 {
    let c1 = str.unsafe_charcode_at(index)
    if c1.is_leading_surrogate() && index + 1 < end {
      let c2 = str.unsafe_charcode_at(index + 1)
      if c2.is_trailing_surrogate() {
        continue index + 2, count + 1
      } else {
        abort("invalid surrogate pair")
      }
    }
  } else {
    count >= n
  }
}

///|
fn char_length_equals(str : String, start : Int, end : Int, len : Int) -> Bool {
  if len < 0 {
    return false
  }
  for index = start, count = 0
      index < end && count < len
      index = index + 1, count = count + 1 {
    let c1 = str.unsafe_charcode_at(index)
    if c1.is_leading_surrogate() && index + 1 < end {
      let c2 = str.unsafe_charcode_at(index + 1)
      if c2.is_trailing_surrogate() {
        continue index + 2, count + 1
      } else {
        abort("invalid surrogate pair")
      }
    }
  } else {
    count == len && index == end
  }
}

///|
pub fn StringView::char_length(self : StringView) -> Int {
  count_chars_in_range(self.str(), self.start(), self.end())
}

///|
pub fn StringView::char_length_eq(self : StringView, len : Int) -> Bool {
  char_length_equals(self.str(), self.start(), self.end(), len)
}

///|
pub fn StringView::char_length_ge(self : StringView, len : Int) -> Bool {
  has_at_least_n_chars(self.str(), self.start(), self.end(), len)
}

///|
/// Iterates over all suffixes of the view, advancing by a Unicode character at
/// a time. Each yielded suffix is itself a view into the original string.
pub fn StringView::suffixes(
  self : StringView,
  include_empty? : Bool = false,
) -> Iterator[StringView] {
  let str = self.str()
  let end = self.end()
  let mut next_start = self.start()
  let mut finished = false
  Iterator::new(fn() -> StringView? {
    if finished {
      None
    } else if next_start == end {
      finished = true
      if include_empty {
        Some(StringView::make_view(str, next_start, end))
      } else {
        None
      }
    } else {
      let suffix = StringView::make_view(str, next_start, end)
      let code = str.unsafe_charcode_at(next_start)
      if code.is_leading_surrogate() &&
        next_start + 1 < end &&
        str.unsafe_charcode_at(next_start + 1).is_trailing_surrogate() {
        next_start += 2
      } else {
        next_start += 1
      }
      Some(suffix)
    }
  })
}
