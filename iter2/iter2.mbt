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
pub typealias T[X, Y] = Iter2[X, Y]

///|
pub fn each[A, B](it : Iter2[A, B], f : (A, B) -> Unit) -> Unit {
  it.each(f)
}

///|
pub fn iter[A, B](it : Iter2[A, B]) -> Iter[(A, B)] {
  it.iter()
}

///|
pub fn iter2[A, B](it : Iter2[A, B]) -> Iter2[A, B] {
  it.iter2()
}

///|
pub fn new[A, B](f : ((A, B) -> IterResult) -> IterResult) -> Iter2[A, B] {
  Iter2::new(f)
}

///|
pub fn run[A, B](it : Iter2[A, B], f : (A, B) -> IterResult) -> IterResult {
  it.run(f)
}

///|
pub fn to_array[A, B](it : Iter2[A, B]) -> Array[(A, B)] {
  it.to_array()
}
