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

fn UninitializedArray::make[T](size : Int) -> UninitializedArray[T] = "%make_array_maybe_uninit"

fn op_get[T](self : UninitializedArray[T], index : Int) -> T = "%array_get"

fn op_set[T](self : UninitializedArray[T], index : Int, value : T) = "%array_set"

fn copy_to[T](
  self : UninitializedArray[T],
  other : UninitializedArray[T],
  src_index : Int,
  dest_index : Int,
  len : Int
) -> Unit {
  for i = 0; i < len; i = i + 1 {
    other[dest_index + i] = self[src_index + i]
  }
}

/// Converts the vector to a string.
pub fn to_string[T : Show](self : ImmutableVec[T]) -> String {
  if self.len == 0 {
    "ImmutableVector::[]"
  } else {
    let first = self.buf[0]
    for i = 1, init = "ImmutableVector::[\(first)" {
      if i >= self.len {
        break "\(init)]"
      }
      let cur = self.buf[i]
      continue i + 1, "\(init), \(cur)"
    }
  }
}

pub fn debug_write[T : Show](self : ImmutableVec[T], buf : Buffer) -> Unit {
  buf.write_string(self.to_string())
}

pub fn ImmutableVec::from_array[T](arr : Array[T]) -> ImmutableVec[T] {
  let len = arr.length()
  let buf = UninitializedArray::make(len)
  for i = 0; i < len; i = i + 1 {
    buf[i] = arr[i]
  }
  { buf, len }
}

test "to_string" {
  let empty : ImmutableVec[Int] = ImmutableVec::[]
  inspect(empty, content="ImmutableVector::[]")?
  let a0 = ImmutableVec::[1, 2, 3]
  inspect(a0, content="ImmutableVector::[1, 2, 3]")?
  let a1 = ImmutableVec::[1, 2, 3, 4, 5]
  inspect(a1, content="ImmutableVector::[1, 2, 3, 4, 5]")?
}

pub fn op_get[T](self : ImmutableVec[T], index : Int) -> T {
  if index < 0 || index >= self.len {
    abort("index out of bounds")
  }
  self.buf[index]
}

pub fn op_set[T](self : ImmutableVec[T], index : Int, value : T) -> Unit {
  if index < 0 || index >= self.len {
    abort("index out of bounds")
  }
  self.buf[index] = value
}

pub fn op_equal[T : Eq](
  self : ImmutableVec[T],
  other : ImmutableVec[T]
) -> Bool {
  if self.len != other.len {
    false
  } else {
    for i = 0; i < self.len; i = i + 1 {
      if self.buf[i] != other.buf[i] {
        return false
      }
    }
    true
  }
}

pub fn slice[T](
  self : ImmutableVec[T],
  start : Int,
  end : Int
) -> ImmutableVec[T] {
  if start < 0 || end > self.len || start > end {
    abort("slice index out of bounds")
  }
  let len = end - start
  let buf = UninitializedArray::make(len)
  copy_to(self.buf, buf, start, 0, len)
  { buf, len }
}

pub fn clone[T](self : ImmutableVec[T]) -> ImmutableVec[T] {
  let buf = UninitializedArray::make(self.len)
  copy_to(self.buf, buf, 0, 0, self.len)
  { buf, len: self.len }
}

pub fn pop[T](self : ImmutableVec[T]) -> (Option[T], ImmutableVec[T]) {
  match self.len {
    0 => (None, self)
    n => (Some(self.buf[n - 1]), self.slice(0, n - 1))
  }
}

pub fn pop_exn[T](self : ImmutableVec[T]) -> (T, ImmutableVec[T]) {
  match self.len {
    0 => abort("pop_exn: empty vector")
    n => (self.buf[n - 1], self.slice(0, n - 1))
  }
}

test "pop_exn" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[1, 2, 3]
  inspect(a0.pop_exn(), content="(3, ImmutableVector::[1, 2])")?
  inspect(a0.pop_exn().1.pop_exn(), content="(2, ImmutableVector::[1])")?
}

pub fn push[T](self : ImmutableVec[T], value : T) -> ImmutableVec[T] {
  let len = self.len + 1
  let buf = UninitializedArray::make(len)
  copy_to(self.buf, buf, 0, 0, self.len)
  buf[self.len] = value
  { buf, len }
}

test "push" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[]
  let a1 = a0.push(1)
  inspect(a1, content="ImmutableVector::[1]")?
  let a2 = a1.push(2)
  inspect(a2, content="ImmutableVector::[1, 2]")?
  let a3 = a2.push(3)
  inspect(a3, content="ImmutableVector::[1, 2, 3]")?
}

pub fn append[T](
  self : ImmutableVec[T],
  other : ImmutableVec[T]
) -> ImmutableVec[T] {
  let len = self.len + other.len
  let buf = UninitializedArray::make(len)
  copy_to(self.buf, buf, 0, 0, self.len)
  copy_to(other.buf, buf, 0, self.len, other.len)
  { buf, len }
}

pub fn op_add[T](
  self : ImmutableVec[T],
  other : ImmutableVec[T]
) -> ImmutableVec[T] {
  self.append(other)
}

pub fn iter[T](self : ImmutableVec[T], f : (T) -> Unit) -> Unit {
  for i = 0; i < self.len; i = i + 1 {
    f(self[i])
  }
}

pub fn iter_rev[T](self : ImmutableVec[T], f : (T) -> Unit) -> Unit {
  for i = self.len - 1; i >= 0; i = i - 1 {
    f(self[i])
  }
}

pub fn iteri[T](self : ImmutableVec[T], f : (Int, T) -> Unit) -> Unit {
  for i = 0; i < self.len; i = i + 1 {
    f(i, self[i])
  }
}

pub fn iter_revi[T](self : ImmutableVec[T], f : (Int, T) -> Unit) -> Unit {
  for i = 0; i < self.len; i = i + 1 {
    f(i, self[self.len - i - 1])
  }
}

pub fn map[T, U](self : ImmutableVec[T], f : (T) -> U) -> ImmutableVec[U] {
  let len = self.len
  let buf = UninitializedArray::make(len)
  for i = 0; i < len; i = i + 1 {
    buf[i] = f(self[i])
  }
  { buf, len }
}

pub fn mapi[T, U](self : ImmutableVec[T], f : (Int, T) -> U) -> ImmutableVec[U] {
  let len = self.len
  let buf = UninitializedArray::make(len)
  for i = 0; i < len; i = i + 1 {
    buf[i] = f(i, self[i])
  }
  { buf, len }
}

pub fn is_sorted[T : Compare](self : ImmutableVec[T]) -> Bool {
  for i = 1; i < self.len; i = i + 1 {
    if self[i - 1] > self[i] {
      break false
    }
  } else {
    true
  }
}

pub fn reverse[T](self : ImmutableVec[T]) -> ImmutableVec[T] {
  let len = self.len
  let buf = UninitializedArray::make(len)
  for i = 0; i < len; i = i + 1 {
    buf[i] = self[len - i - 1]
  }
  { buf, len }
}

pub fn split_at[T](
  self : ImmutableVec[T],
  index : Int
) -> (ImmutableVec[T], ImmutableVec[T]) {
  if index < 0 || index > self.len {
    abort("split_at: index out of bounds")
  }
  let left = self.slice(0, index)
  let right = self.slice(index, self.len)
  (left, right)
}

pub fn contains[T : Eq](self : ImmutableVec[T], value : T) -> Bool {
  for i = 0; i < self.len; i = i + 1 {
    if self[i] == value {
      break true
    }
  } else {
    false
  }
}

pub fn starts_with[T : Eq](
  self : ImmutableVec[T],
  prefix : ImmutableVec[T]
) -> Bool {
  if prefix.len > self.len {
    return false
  }
  for i = 0; i < prefix.len; i = i + 1 {
    if self[i] != prefix[i] {
      break false
    }
  } else {
    true
  }
}

pub fn ends_with[T : Eq](
  self : ImmutableVec[T],
  suffix : ImmutableVec[T]
) -> Bool {
  if suffix.len > self.len {
    return false
  }
  for i = 0; i < suffix.len; i = i + 1 {
    if self[self.len - suffix.len + i] != suffix[i] {
      break false
    }
  } else {
    true
  }
}

pub fn strip_prefix[T : Eq](
  self : ImmutableVec[T],
  prefix : ImmutableVec[T]
) -> Option[ImmutableVec[T]] {
  if self.starts_with(prefix) {
    Some(self.slice(prefix.len, self.len))
  } else {
    None
  }
}

pub fn strip_suffix[T : Eq](
  self : ImmutableVec[T],
  suffix : ImmutableVec[T]
) -> Option[ImmutableVec[T]] {
  if self.ends_with(suffix) {
    Some(self.slice(0, self.len - suffix.len))
  } else {
    None
  }
}

pub fn search[T : Eq](self : ImmutableVec[T], value : T) -> Option[Int] {
  for i = 0; i < self.len; i = i + 1 {
    if self[i] == value {
      break Some(i)
    }
  } else {
    None
  }
}

pub fn swap[T](self : ImmutableVec[T], i : Int, j : Int) -> ImmutableVec[T] {
  if i < 0 || i >= self.len || j < 0 || j >= self.len {
    abort("swap: index out of bounds")
  }
  let buf = UninitializedArray::make(self.len)
  copy_to(self.buf, buf, 0, 0, self.len)
  let tmp = buf[i]
  buf[i] = buf[j]
  buf[j] = tmp
  { buf, len: self.len }
}

pub fn remove[T](self : ImmutableVec[T], index : Int) -> (T, ImmutableVec[T]) {
  if index < 0 || index >= self.len {
    abort("remove: index out of bounds")
  }
  let len = self.len - 1
  let buf = UninitializedArray::make(len)
  copy_to(self.buf, buf, 0, 0, index)
  copy_to(self.buf, buf, index + 1, index, len - index)
  (self.buf[index], { buf, len })
}

test "remove" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[1, 2, 3]
  inspect(a0.remove(1), content="(2, ImmutableVector::[1, 3])")?
  inspect(a0.remove(0).1.remove(0), content="(2, ImmutableVector::[3])")?
}

pub fn retain[T](self : ImmutableVec[T], f : (T) -> Bool) -> ImmutableVec[T] {
  let mut len = 0
  let tags = UninitializedArray::make(self.len)
  for i = 0; i < self.len; i = i + 1 {
    tags[i] = if f(self[i]) {
      len += 1
      1
    } else {
      0
    }
  }
  let buf = UninitializedArray::make(len)
  let mut j = 0
  for i = 0; i < self.len; i = i + 1 {
    if tags[i] == 1 {
      buf[j] = self[i]
      j += 1
    }
  }
  { buf, len }
}

pub fn insert[T](
  self : ImmutableVec[T],
  index : Int,
  value : T
) -> ImmutableVec[T] {
  if index < 0 || index > self.len {
    abort("insert: index out of bounds")
  }
  let len = self.len + 1
  let buf = UninitializedArray::make(len)
  copy_to(self.buf, buf, 0, 0, index)
  buf[index] = value
  copy_to(self.buf, buf, index, index + 1, self.len - index)
  { buf, len }
}

pub fn flatten[T](self : ImmutableVec[ImmutableVec[T]]) -> ImmutableVec[T] {
  let mut len = 0
  for i = 0; i < self.len; i = i + 1 {
    len += self[i].len
  }
  let buf = UninitializedArray::make(len)
  let mut j = 0
  for i = 0; i < self.len; i = i + 1 {
    copy_to(self[i].buf, buf, 0, j, self[i].len)
    j += self[i].len
  }
  { buf, len }
}

pub fn repeat[T](self : ImmutableVec[T], times : Int) -> ImmutableVec[T] {
  let len = self.len * times
  let buf = UninitializedArray::make(len)
  for i = 0; i < times; i = i + 1 {
    copy_to(self.buf, buf, 0, i * self.len, self.len)
  }
  { buf, len }
}

pub fn join[T](
  self : ImmutableVec[ImmutableVec[T]],
  sep : ImmutableVec[T]
) -> ImmutableVec[T] {
  let mut len = 0
  for i = 0; i < self.len; i = i + 1 {
    len += self[i].len
  }
  len += sep.len * (self.len - 1)
  let buf = UninitializedArray::make(len)
  let mut j = 0
  for i = 0; i < self.len; i = i + 1 {
    copy_to(self[i].buf, buf, 0, j, self[i].len)
    j += self[i].len
    if i < self.len - 1 {
      copy_to(sep.buf, buf, 0, j, sep.len)
      j += sep.len
    }
  }
  { buf, len }
}

pub fn fold_left[T, U](self : ImmutableVec[T], init : U, f : (U, T) -> U) -> U {
  for i = 0, acc = init; i < self.len; {
    continue i + 1, f(acc, self[i])
  } else {
    acc
  }
}

pub fn fold_right[T, U](self : ImmutableVec[T], init : U, f : (T, U) -> U) -> U {
  for i = self.len - 1, acc = init; i >= 0; {
    continue i - 1, f(self[i], acc)
  } else {
    acc
  }
}

pub fn fold_lefti[T, U](
  self : ImmutableVec[T],
  init : U,
  f : (U, Int, T) -> U
) -> U {
  for i = 0, acc = init; i < self.len; {
    continue i + 1, f(acc, i, self[i])
  } else {
    acc
  }
}

pub fn fold_righti[T, U](
  self : ImmutableVec[T],
  init : U,
  f : (Int, T, U) -> U
) -> U {
  for i = self.len - 1, acc = init; i >= 0; {
    continue i - 1, f(i, self[i], acc)
  } else {
    acc
  }
}

pub fn from_vector[T](vec : @vec.Vec[T]) -> ImmutableVec[T] {
  let len = vec.length()
  let buf = UninitializedArray::make(len)
  for i = 0; i < len; i = i + 1 {
    buf[i] = vec[i]
  }
  { buf, len }
}

pub fn to_vector[T](self : ImmutableVec[T]) -> @vec.Vec[T] {
  let vec = @vec.Vec::with_capacity(self.len)
  for i = 0; i < self.len; i = i + 1 {
    vec.push(self[i])
  }
  vec
}
