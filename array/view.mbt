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

///|
pub fn rev_inplace[T](self : ArrayView[T]) -> Unit {
  let mid_len = self.length() / 2
  for i = 0; i < mid_len; i = i + 1 {
    let j = self.length() - i - 1
    self.swap(i, j)
  }
}

///|
pub fn each[T](self : ArrayView[T], f : (T) -> Unit) -> Unit {
  for i = 0; i < self.length(); i = i + 1 {
    f(self[i])
  }
}

pub fn rev_each[T](self : ArrayView[T], f : (T) -> Unit) -> Unit {
  let len = self.length()
  for i in 0..<len {
    f(self[len - i - 1])
  }
}

pub fn eachi[T](self : ArrayView[T], f : (Int, T) -> Unit) -> Unit {
  for i, v in self {
    f(i, v)
  }
}

pub fn rev_eachi[T](self : ArrayView[T], f : (Int, T) -> Unit) -> Unit {
  let len = self.length()
  for i in 0..<len {
    f(i, self[len - i - 1])
  }
}

///|
/// Compares two arrayviews for equality.
pub fn op_equal[T : Eq](self : ArrayView[T], other : ArrayView[T]) -> Bool {
  guard self.length() == other.length() else { return false }
  for i in 0..<self.length() {
    if self[i] != other[i] {
      break false
    }
  } else {
    true
  }
}

pub fn compare[T : Compare](self : ArrayView[T], other : ArrayView[T]) -> Int {
  let len_self = self.length()
  let len_other = other.length()
  if len_self < len_other {
    -1
  } else if len_self > len_other {
    1
  } else {
    for i in 0..<len_self {
      let cmp = self[i].compare(other[i])
      if cmp != 0 {
        break cmp
      }
    } else {
      0
    }
  }
}

pub fn filter[T](self : ArrayView[T], f : (T) -> Bool) -> ArrayView[T] {
  let arr = []
  for v in self {
    if f(v) {
      arr.push(v)
    }
  }
  arr[:]
}

pub fn all[T](self : ArrayView[T], f : (T) -> Bool) -> Bool {
  for i in 0..<self.length() {
    if f(self[i]).not() {
      return false
    }
  }
  true
}

pub fn contains[T : Eq](self : ArrayView[T], value : T) -> Bool {
  for v in self {
    if v == value {
      break true
    }
  } else {
    false
  }
}

pub fn starts_with[T : Eq](self : ArrayView[T], prefix : ArrayView[T]) -> Bool {
  if prefix.length() > self.length() {
    return false
  }
  for i in 0..<self.length() {
    if self[i] != prefix[i] {
      break false
    }
  } else {
    true
  }
}

pub fn ends_with[T : Eq](self : ArrayView[T], suffix : ArrayView[T]) -> Bool {
  if suffix.length() > self.length() {
    return false
  }
  for i in 0..<suffix.length() {
    if self[self.length() - suffix.length() + i] != suffix[i] {
      break false
    }
  } else {
    true
  }
}

pub fn is_sorted[T : Compare](self : ArrayView[T]) -> Bool {
  for i in 0..<self.length() {
    if self[i - 1] > self[i] {
      break false
    }
  } else {
    true
  }
}

pub fn search[T : Eq](self : ArrayView[T], value : T) -> Int? {
  for i = 0; i < self.length(); i = i + 1 {
    if self[i] == value {
      return Some(i)
    }
  }
  None
}

pub fn search_by[T](self : ArrayView[T], f : (T) -> Bool) -> Int? {
  for i, v in self {
    if f(v) {
      break Some(i)
    }
  } else {
    None
  }
}

pub fn last[T](self : ArrayView[T]) -> T? {
  match self {
    [] => None
    [.., last] => Some(last)
  }
}

pub fn map_option[A, B](self : ArrayView[A], f : (A) -> B?) -> ArrayView[B] {
  let result = []
  self.each(
    fn {
      x =>
        match f(x) {
          None => ()
          Some(x) => result.push(x)
        }
    },
  )
  result[:]
}
