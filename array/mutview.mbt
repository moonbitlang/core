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
pub fn[X] MutArrayView::iterator(self : MutArrayView[X]) -> Iterator[X] {
  let mut i = 0
  Iterator::new(fn() {
    guard i < self.length() else { None }
    let elem = self.unsafe_get(i)
    i += 1
    Some(elem)
  })
}

///|
pub fn[X] MutArrayView::rev_iterator(self : MutArrayView[X]) -> Iterator[X] {
  let mut i = self.length()
  Iterator::new(fn() {
    guard i > 0 else { None }
    i -= 1
    Some(self.unsafe_get(i))
  })
}

///|
pub fn[X] MutArrayView::iterator2(self : MutArrayView[X]) -> Iterator2[Int, X] {
  let mut i = 0
  Iterator2::new(fn() {
    guard i < self.length() else { None }
    let result = Some((i, self.unsafe_get(i)))
    i += 1
    result
  })
}

///|
pub impl[X : Show] Show for MutArrayView[X] with output(self, logger) {
  self[:].output(logger)
}

///|
pub impl[T : Eq] Eq for MutArrayView[T] with equal(self, other) -> Bool {
  self[:] == other[:]
}

///|
pub impl[T : Compare] Compare for MutArrayView[T] with compare(self, other) -> Int {
  self[:].compare(other[:])
}

///|
pub impl[A : Hash] Hash for MutArrayView[A] with hash_combine(self, hasher) {
  self[:].hash_combine(hasher)
}
