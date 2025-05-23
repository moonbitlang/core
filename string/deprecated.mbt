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
#deprecated("Use `@string.concat` instead")
pub fn String::concat(self : Array[String], separator~ : String = "") -> String {
  concat(self, separator~)
}

///|
type StringIndex Int derive(Show, Eq)

///|
#deprecated("StringIndex is deprecated, use String::index_of_nth_char instead")
#coverage.skip
pub fn index_at(
  self : String,
  offset_by : Int,
  start~ : StringIndex = 0
) -> StringIndex? {
  self.index_at_(offset_by, start~)
}

///|
#deprecated("StringIndex is deprecated, use String::index_of_nth_char instead")
#coverage.skip
pub fn index_at_rev(
  self : String,
  offset_by : Int,
  end? : StringIndex
) -> StringIndex? {
  self.index_at_rev_(offset_by, end?)
}

///|
fn index_at_(
  self : String,
  offset_by : Int,
  start~ : StringIndex = 0
) -> StringIndex? {
  if self.offset_of_nth_char(offset_by, start_offset=start._) is Some(index) {
    Some(index)
  } else if offset_by == self.char_length(start_offset=start._) {
    Some(self.length())
  } else {
    None
  }
}

///|
fn index_at_rev_(
  self : String,
  offset_by : Int,
  end? : StringIndex
) -> StringIndex? {
  match end {
    Some(end) =>
      if offset_by == 0 {
        Some(end)
      } else if self.offset_of_nth_char(-offset_by, end_offset=end._)
        is Some(index) {
        Some(index)
      } else {
        None
      }
    None =>
      if offset_by == 0 {
        Some(self.length())
      } else if self.offset_of_nth_char(-offset_by) is Some(index) {
        Some(index)
      } else {
        None
      }
  }
}

///|
#deprecated("use str.charcodes(start = str.offset_of_nth_char(i).unwrap(), end = str.offset_of_nth_char(j).unwrap()) to replace str[i:j]")
#coverage.skip
pub fn String::op_as_view(self : String, start~ : Int = 0, end? : Int) -> View {
  let str_len = self.length()
  let start = if start >= 0 {
    self.index_at_(start, start=0).unwrap()._
  } else {
    self.index_at_rev_(-start, end=str_len).unwrap()._
  }
  let end = match end {
    Some(end) =>
      if end >= 0 {
        self.index_at_(end, start=0).unwrap()._
      } else {
        self.index_at_rev_(-end, end=str_len).unwrap()._
      }
    None => str_len
  }
  guard start >= 0 && start <= end && end <= str_len else {
    abort("Invalid index for View")
  }
  { str: self, start, end }
}

///|
#deprecated("use view.charcodes(start = view.offset_of_nth_char(i).unwrap(), end = view.offset_of_nth_char(j).unwrap()) to replace view[i:j]")
#coverage.skip
pub fn View::op_as_view(self : View, start~ : Int = 0, end? : Int) -> View {
  let start = if start >= 0 {
    self.str.index_at_(start, start=self.start).unwrap()._
  } else {
    self.str.index_at_rev_(-start, end=self.end).unwrap()._
  }
  let end = match end {
    Some(end) =>
      if end >= 0 {
        self.str.index_at_(end, start=self.start).unwrap()._
      } else {
        self.str.index_at_rev_(-end, end=self.end).unwrap()._
      }
    None => self.end
  }
  guard start >= self.start &&
    start <= self.end &&
    end >= self.start &&
    end <= self.end &&
    start <= end else {
    abort("Invalid index for View")
  }
  { str: self.str, start, end }
}
