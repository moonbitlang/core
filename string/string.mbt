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

pub fn iter(self : String, f : (Char) -> Unit) {
  for i = 0; i < self.length(); i = i + 1 {
    f(self[i])
  }
}

test "iter" {
  let mut i = 0
  let mut failed = false
  "12345".iter(
    fn(elem) { if elem != (i + 1).to_string()[0] { failed = true }; i = i + 1 },
  )
  @assertion.assert_false(failed)?
}

pub fn iteri(self : String, f : (Int, Char) -> Unit) {
  for i = 0; i < self.length(); i = i + 1 {
    f(i, self[i])
  }
}

test "iteri" {
  let mut i = 0
  let mut failed = false
  "12345".iteri(
    fn(index, elem) {
      if index != i || elem != (i + 1).to_string()[0] {
        failed = true
      }
      i = i + 1
    },
  )
  @assertion.assert_false(failed)?
}

pub fn iter_rev(self : String, f : (Char) -> Unit) {
  for i = self.length() - 1; i >= 0; i = i - 1 {
    f(self[i])
  }
}

test "iter rev" {
  let mut i = 6
  let mut failed = false
  "12345".iter_rev(
    fn(elem) { if elem != (i - 1).to_string()[0] { failed = true }; i = i - 1 },
  )
  @assertion.assert_false(failed)?
}

pub fn iteri_rev(self : String, f : (Int, Char) -> Unit) {
  for i = self.length() - 1; i >= 0; i = i - 1 {
    f(i, self[i])
  }
}

test "iteri rev" {
  let mut i = 6
  let mut failed = false
  "12345".iteri_rev(
    fn(index, elem) {
      if index != i - 2 || elem != (i - 1).to_string()[0] {
        failed = true
      }
      i = i - 1
    },
  )
  @assertion.assert_false(failed)?
}

pub fn map(self : String, f : (Char) -> Char) -> String {
  if self.length() == 0 {
    return ""
  }
  for i = 0, str = ""; i < self.length(); {
    continue i + 1,
      str.push(f(self[i]))
  } else {
    str
  }
}

test "map" {
  let str = "12345"
  let strm = str.map(fn(_elem) { '1' })
  @assertion.assert_eq(strm, "11111")?
}

/// Convert string to array.
pub fn to_array(self : String) -> Array[Char] {
  if self.length() == 0 {
    return Array::default()
  }
  let arr = Array::make(self.length(), self[0])
  for i = 1; i < self.length(); i = i + 1 {
    arr[i] = self[i]
  }
  arr
}

test "to_array" {
  let str = "12345"
  let array = str.to_array()
  @assertion.assert_eq(array, ['1', '2', '3', '4', '5'])?
}

/// Add a character at the end of the string
pub fn push(self : String, ch : Char) -> String {
  self + ch.to_string()
}

test "push" {
  let str = push("1234", '5')
  @assertion.assert_eq(str, "12345")?
}

/// Reserve a string
pub fn reserve(self : String) -> String {
  for i = self.length() - 1, str = ""; i >= 0; {
    continue i - 1,
      str.push(self[i])
  } else {
    str
  }
}

test "reserve" {
  let str = "12345"
  let strr = str.reserve()
  @assertion.assert_eq(strr, "54321")?
}

/// Concat two string
pub fn concat(self : String, tail : String) -> String {
  self + tail
}

test "concat" {
  let str = "12345"
  let strc = str.concat("54321")
  @assertion.assert_eq(strc, "1234554321")?
}

/// Convert string to list.
pub fn to_list(self : String) -> List[Char] {
  for i = self.length() - 1, acc = (Nil : List[Char]); i >= 0; {
    continue i - 1,
      Cons(self[i], acc)
  } else {
    acc
  }
}

test "to_list" {
  let str = "12345"
  let list = str.to_list()
  @assertion.assert_eq(list, @list.from_array(['1', '2', '3', '4', '5']))?
}

/// Get string form array
pub fn String::from_array(arr : Array[Char]) -> String {
  for i = 0, str = ""; i < arr.length(); {
    continue i + 1,
      str.push(arr[i])
  } else {
    str
  }
}

test "from_array" {
  let str = String::['1', '2', '3', '4', '5']
  @assertion.assert_eq(str, "12345")?
}

/// Get string from list
pub fn String::from_list(list : List[Char]) -> String {
  loop list, "" {
    Nil, str => str
    Cons(x, rest), str => continue rest, str.push(x)
  }
}

test "from_list" {
  let str = from_list(@list.from_array(['1', '2', '3', '4', '5']))
  @assertion.assert_eq(str, "12345")?
}
