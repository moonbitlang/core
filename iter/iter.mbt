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
pub typealias T[X] = Iter[X]

///|
pub fn all[T](it : Iter[T], f : (T) -> Bool) -> Bool {
  it.all(f)
}

///|
pub fn any[T](it : Iter[T], f : (T) -> Bool) -> Bool {
  it.any(f)
}

///|
pub fn append[T](it : Iter[T], elt : T) -> Iter[T] {
  it.append(elt)
}

///|
pub fn collect[T](it : Iter[T]) -> Array[T] {
  it.collect()
}

///|
pub fn concat[T](it1 : Iter[T], it2 : Iter[T]) -> Iter[T] {
  it1.concat(it2)
}

///|
pub fn contains[A : Eq](it : Iter[A], elt : A) -> Bool {
  it.contains(elt)
}

///|
pub fn count[T](it : Iter[T]) -> Int {
  it.count()
}

///|
pub fn drop[T](it : Iter[T], n : Int) -> Iter[T] {
  it.drop(n)
}

///|
pub fn drop_while[T](it : Iter[T], f : (T) -> Bool) -> Iter[T] {
  it.drop_while(f)
}

///|
pub fn each[T](it : Iter[T], f : (T) -> Unit) -> Unit {
  it.each(f)
}

///|
pub fn eachi[T](it : Iter[T], f : (Int, T) -> Unit) -> Unit {
  it.eachi(f)
}

///|
pub fn empty[T]() -> Iter[T] {
  Iter::empty()
}

///|
pub fn filter[T](it : Iter[T], f : (T) -> Bool) -> Iter[T] {
  it.filter(f)
}

///|
pub fn filter_map[A, B](it : Iter[A], f : (A) -> B?) -> Iter[B] {
  it.filter_map(f)
}

///|
pub fn find_first[T](it : Iter[T], f : (T) -> Bool) -> T? {
  it.find_first(f)
}

///|
pub fn flat_map[T, R](it : Iter[T], f : (T) -> Iter[R]) -> Iter[R] {
  it.flat_map(f)
}

///|
pub fn fold[T, B](it : Iter[T], init~ : B, f : (B, T) -> B) -> B {
  it.fold(init~, f)
}

///|
pub fn head[A](it : Iter[A]) -> A? {
  it.head()
}

///|
pub fn intersperse[A](it : Iter[A], sep : A) -> Iter[A] {
  it.intersperse(sep)
}

///|
pub fn iter[T](it : Iter[T]) -> Iter[T] {
  it.iter()
}

///|
pub fn just_run[T](it : Iter[T], f : (T) -> IterResult) -> Unit {
  it.just_run(f)
}

///|
pub fn last[A](it : Iter[A]) -> A? {
  it.last()
}

///|
pub fn map[T, R](it : Iter[T], f : (T) -> R) -> Iter[R] {
  it.map(f)
}

///|
pub fn map_while[A, B](it : Iter[A], f : (A) -> B?) -> Iter[B] {
  it.map_while(f)
}

///|
pub fn new[T](f : ((T) -> IterResult) -> IterResult) -> Iter[T] {
  Iter::new(f)
}

///|
pub fn peek[T](it : Iter[T]) -> T? {
  it.peek()
}

///|
pub fn prepend[T](it : Iter[T], elt : T) -> Iter[T] {
  it.prepend(elt)
}

///|
pub fn repeat[T](elt : T) -> Iter[T] {
  Iter::repeat(elt)
}

///|
pub fn run[T](it : Iter[T], f : (T) -> IterResult) -> IterResult {
  it.run(f)
}

///|
pub fn singleton[T](elt : T) -> Iter[T] {
  Iter::singleton(elt)
}

///|
pub fn take[T](it : Iter[T], n : Int) -> Iter[T] {
  it.take(n)
}

///|
pub fn take_while[T](it : Iter[T], f : (T) -> Bool) -> Iter[T] {
  it.take_while(f)
}

///|
pub fn tap[T](it : Iter[T], f : (T) -> Unit) -> Iter[T] {
  it.tap(f)
}

///|
pub fn to_array[T](it : Iter[T]) -> Array[T] {
  it.to_array()
}
