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
pub impl[T : Shrink] Shrink for T? with fn shrink(x) {
  match x {
    None => Iter::empty()
    Some(v) =>
      Shrink::shrink(v).map(v1 => Some(v1)).concat(Iter::singleton(None))
  }
}

///|
pub impl[T : Shrink, E : Shrink] Shrink for Result[T, E] with fn shrink(x) {
  match x {
    Ok(v) => Shrink::shrink(v).map(v1 => Ok(v1))
    Err(e) => Shrink::shrink(e).map(e1 => Err(e1))
  }
}

///|
pub impl[X : Shrink] Shrink for Array[X] with fn shrink(xs) {
  let view = xs[:]
  let n = view.length()
  fn shr_sub_terms(arr : ArrayView[X]) {
    match arr {
      [] => Iter::empty()
      [x, .. xs] =>
        X::shrink(x)
        .map(x_ => [x_, ..xs])
        .concat(shr_sub_terms(xs).map(xs_ => [x, ..xs_]))
    }
  }

  [
    for k = n / 2; k > 0; k = k / 2 => k
  ]
  .rev_iter()
  .flat_map(k => removes_array(k, n, xs).iter())
  .concat(shr_sub_terms(view))
}

///|
pub impl[X : Shrink] Shrink for Iter[X] with fn shrink(xs) {
  let arr = xs.to_array()
  let its : Array[_] = Array::makei(arr.length(), x => {
    X::shrink(arr[x])
    .map(y => {
      let cp = arr.copy()
      cp[x] = y
      cp.iter()
    })
    .to_array()
  }).flatten()
  let rms : Array[Iter[X]] = arr.mapi((i, _) => {
    let a = arr.copy()
    a.remove(i) |> ignore
    a.iter()
  })
  rms.iter().concat(its.iter())
}
