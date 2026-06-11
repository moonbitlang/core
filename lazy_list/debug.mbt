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
/// @debug.Debug implementation. Walks only the cells whose tails have already
/// been forced — never runs a thunk — so it is safe on infinite or
/// effectful streams.
///
/// A fully forced list renders as `<LazyList: [1, 2, 3]>`. A list whose
/// spine is still lazy renders the prefix that has been evaluated and
/// then `...` to mark the unforced tail, e.g. `<LazyList: [1, 2, ...]>`.
///
/// Caveat: a deliberately constructed forced cycle (e.g. a `lazy_cons`
/// whose thunk returns an ancestor cell, then forced) will cause this
/// impl to loop. `@list.List`'s `@debug.Debug` has the same property; cycle
/// detection is not provided.
pub impl[A : @debug.Debug] @debug.Debug for LazyList[A] with fn to_repr(self) {
  let parts = []
  for cur = self {
    match cur.cell {
      Empty => break
      Cons(x, tail~) => {
        parts.push(@debug.to_repr(x))
        match tail.peek() {
          Some(next) => continue next
          None => {
            parts.push(@debug.Repr::omitted())
            break
          }
        }
      }
    }
  }
  @debug.Repr::opaque_("LazyList", @debug.Repr::array(parts))
}
