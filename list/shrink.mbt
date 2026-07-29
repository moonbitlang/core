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
fn[T] removes(k : Int, n : Int, xs : List[T]) -> Iter[List[T]] {
  guard k <= n else { [||] }
  let xs_drop = xs.drop(k)
  if xs_drop.is_empty() {
    [|Empty|]
  } else {
    let xs_take = xs.take(k)
    removes(k, n - k, xs_drop).map(x => xs_take.concat(x)).add([|xs_drop|])
  }
}

///|
pub impl[T : @shrink.Shrink] @shrink.Shrink for List[T] with fn shrink(xs) {
  let n = xs.length()
  fn shr_sub_terms(lst : List[T]) {
    match lst {
      Empty => Iter::empty()
      More(x, tail=xs) =>
        @shrink.Shrink::shrink(x)
        .map(x_ => xs.add(x_))
        .concat(shr_sub_terms(xs).map(xs_ => xs_.add(x)))
    }
  }

  [
    for k = n / 2; k > 0; k = k / 2 => k
  ]
  .rev_iter()
  .flat_map(k => removes(k, n, xs))
  .concat(shr_sub_terms(xs))
}
