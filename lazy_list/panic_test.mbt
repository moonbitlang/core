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
test "panic reentrant force on a tail aborts" {
  // A thunk that forces the very tail it is producing. Letting it through
  // would re-run the thunk and break the at-most-once guarantee, so it
  // aborts instead — the same trade-off `@lazy.Lazy::force` makes.
  let slot : Array[@lazy_list.LazyList[Int]] = []
  let xs = @lazy_list.lazy_cons(1, () => slot[0].tail().unwrap())
  slot.push(xs)
  ignore(xs.tail())
}

///|
test "panic reentrant force through a suspended concat aborts" {
  // Same, but the reentrant force lands on a suspended append rather
  // than on a thunk.
  let slot : Array[@lazy_list.LazyList[Int]] = []
  let left = @lazy_list.lazy_cons(1, () => slot[0].tail().unwrap())
  let both = left.concat(@lazy_list.from_iter([|2|]))
  slot.push(both)
  ignore(both.tail())
}
