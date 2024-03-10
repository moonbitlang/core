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
  let mut i = 0
  while i < self.length() {
    f(self[i])
    i = i + 1
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
  let mut i = 0
  while i < self.length() {
    f(i, self[i])
    i = i + 1
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
  let mut i = self.length() - 1
  while i >= 0 {
    f(self[i])
    i = i - 1
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
  let mut i = self.length() - 1
  while i >= 0 {
    f(i, self[i])
    i = i - 1
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
  let mut str = ""
  self.iter(fn(elem) { str = str.push(f(elem)) })
  str
}

test "map" {
  let str = "12345"
  let strm = str.map(fn(elem) { '1' })
  @assertion.assert_eq(strm, "11111")?
}

/// Convert string to array.
pub fn to_array(self : String) -> Array[Char] {
  let arr = Array::make(self.length(), self[0])
  self.iteri(fn(i, elem) { arr[i] = elem })
  return arr
}

test "to array" {
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
  let mut str = ""
  self.iter_rev(fn(elem) { str = str.push(elem) })
  str
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
  let mut list : List[Char] = Nil
  self.iter_rev(fn(elem) { list = Cons(elem, list) })
  list
}

test "to list" {
  let str = "12345"
  let list = str.to_list()
  @assertion.assert_eq(list, @list.from_array(['1', '2', '3', '4', '5']))?
}

/// Get string form array
pub fn String::from_array(arr : Array[Char]) -> String {
  let mut str = ""
  arr.iter(fn(elem) { str = str.push(elem) })
  str
}

test "from_array" {
  let str = String::['1', '2', '3', '4', '5']
  @assertion.assert_eq(str, "12345")?
}

/// Get string from list
pub fn String::from_list(list : List[Char]) -> String {
  let mut str = ""
  list.iter(fn(elem) { str = str.push(elem) })
  str
}

test "from_list" {
  let str = from_list(@list.from_array(['1', '2', '3', '4', '5']))
  @assertion.assert_eq(str, "12345")?
}
