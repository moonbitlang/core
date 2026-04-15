// Copyright 2026 International Digital Economy Academy
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
/// `Pile[T]` models one pile in patience sorting.
///
/// `top` is the visible card consulted by binary search. `stack` retains older
/// cards underneath it so the pile still behaves like a stack.
priv struct Pile[T](Array[T])

///|
fn[T] Pile::new(top : T) -> Pile[T] {
  Pile([top])
}

///|
/// Push a new card onto the pile, demoting the old top underneath it.
fn[T] Pile::push(self : Pile[T], t : T) -> Unit {
  self.0.push(t)
}

///|
fn[T] Pile::top(self : Pile[T]) -> T {
  self.0[self.0.length() - 1]
}
