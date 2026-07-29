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
fn[T] removes_array(k : Int, n : Int, xs : Array[T]) -> Array[Array[T]] {
  if k > n {
    []
  } else {
    let xs2 = xs[:k].to_owned()
    let xs1 = xs[k:].to_owned()
    if xs1.is_empty() {
      []
    } else {
      [xs1, ..removes_array(k, n - k, xs1).map(x => xs2 + x)]
    }
  }
}

///|
fn shrink_decimal(x : Double) -> Iter[Double] {
  guard !x.is_nan() else { [|0.0, 1.0, -1.0, 2.0|] }
  guard !x.is_inf() else { [|0.0, 1.0, -1.0, 1000.0, -1000.0|] }
  guard x >= 0.0 else {
    Iter::singleton(-x).concat(shrink_decimal(-x).map(Double::neg))
  }
  guard x != 0.0 else { Iter::empty() }
  [|1.0, 10.0, 100.0, 1000.0, 10000.0, 100000.0|].flat_map(p => {
    let m = (x * p + 0.5).floor().to_int64()
    if p != 1.0 && m % 10L == 0L {
      return Iter::empty()
    }
    Iter::singleton(m)
    .concat(Shrink::shrink(m))
    .map(n => n.to_double() / p)
    .filter(y => y >= 0.0 && y < x)
  })
}
