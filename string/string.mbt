// Copyright 2024 International Digital Economy Academy
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

/// Compare two strings.
/// String with longer length is bigger.
/// strings of the same length are compared in lexicalgraphic order.
pub fn compare(self : String, other : String) -> Int {
  let len = self.length()
  match len.compare(other.length()) {
    0 => {
      for i = 0; i < len; i = i + 1 {
        let order = self[i].compare(other[i])
        if order != 0 {
          return order
        }
      }
      0
    }
    order => order
  }
}

/// The empty string
pub fn String::default() -> String {
  ""
}

/// `String` holds a sequence of UTF-16 code units encoded in little endian format
pub fn to_bytes(self : String) -> Bytes {
  let len = self.length()
  let bytes = Bytes::make(len * 2)
  bytes.blit_from_string(0, self, 0, len)
  bytes
}

pub fn hash(self : String) -> Int {
  self.to_bytes().hash()
}

/// Converts the String into an array of Chars.
pub fn to_array(self : String) -> Array[Char] {
  self.iter().fold(
    fn(rv, c) {
      rv.push(c)
      rv
    },
    Array::new(capacity=self.length()),
  )
}

/// @intrinsic %string.substring
fn unsafe_substring(str : String, start : Int, end : Int) -> String {
  let len = end - start
  let buf = Buffer::new(size_hint=len)
  buf.write_sub_string(str, start, len)
  buf.to_string()
}

/// Get substring of the string from [start] to [end] exclusive.
pub fn substring(
  self : String,
  ~start : Int = 0,
  ~end : Int = self.length()
) -> String {
  if start < 0 {
    abort("String::substring: start index is negative")
  }
  if end < 0 {
    abort("String::substring: end index is negative")
  }
  if start > end {
    abort("String::substring: start index is greater than end index")
  }
  if end > self.length() {
    abort(
      "String::substring: end index is greater than the length of the string",
    )
  }
  unsafe_substring(self, start, end)
}

pub fn iter(self : String) -> Iter[Char] {
  Iter::_unstable_internal_make(
    fn(yield) {
      let len = self.length()
      for index = 0; index < len; index = index + 1 {
        let c = self[index].to_int()
        if c >= 0xD800 && c <= 0xDBFF && index + 1 < len {
          let c2 = self[index + 1].to_int()
          if c2 >= 0xDC00 && c2 <= 0xDFFF {
            let c = Char::from_int((c - 0xD800) * 0x400 + c2 - 0xDC00 + 0x10000)
            if yield(c) == IterContinue {
              continue index + 2
            } else {
              break IterEnd
            }
          }
        }
        //TODO: handle garbage input
        if yield(Char::from_int(c)) == IterEnd {
          break IterEnd
        }
      } else {
        IterContinue
      }
    },
  )
}

pub fn starts_with(self : String, str : String) -> Bool {
  if str.length() > self.length() {
    false
  } else {
    self.substring(end=str.length()).compare(str) == 0
  }
}

pub fn ends_with(self : String, str : String) -> Bool {
  if str.length() > self.length() {
    false
  } else {
    self.substring(start=self.length() - str.length()).compare(str) == 0
  }
}

// TODO: improve the perf later
pub fn index_of(self : String, str : String) -> Int {
  let len = self.length()
  let sub_len = str.length()
  if sub_len == 0 {
    0
  } else if sub_len > len {
    -1
  } else {
    for i = 0; i < len - sub_len + 1; i = i + 1 {
      if self.substring(start=i, end=i + sub_len).compare(str) == 0 {
        return i
      }
    }
    -1
  }
}
