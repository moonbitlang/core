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
/// Internal cell representation. Kept private so users go through the
/// `head` / `tail` / `iter` accessors and cannot observe (or accidentally
/// force) the underlying `@lazy.Lazy` representation.
priv enum LazyListCell[A] {
  Empty
  Cons(A, tail~ : @lazy.Lazy[LazyList[A]])
}

///|
/// A persistent linked list with a memoized lazy tail. The head element
/// of each cell is always strict; the tail is computed on first access
/// and cached, so repeated traversals share evaluation work.
///
/// Unlike `Iter[A]`, which is a single-use pull-based iterator, a
/// `LazyList[A]` can be re-traversed any number of times.
struct LazyList[A] {
  cell : LazyListCell[A]
}
