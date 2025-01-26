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
pub enum L {
  Nil
  Cons(Int, mut tail~ : L)
} derive(Eq, Show)

///|
/// tail recursive map using dps
pub fn map(self : L, f : (Int) -> Int) -> L {
  match self {
    Nil => Nil
    Cons(head, tail~) => {
      let cell = Cons(f(head), tail=Nil)
      map_dps(f, tail, cell)
      cell
    }
  }
}

///|
fn map_dps(f : (Int) -> Int, lst : L, dest : L) -> Unit {
  loop lst, dest {
    Nil, Cons(_, ..) as c => c.tail = Nil
    // c.tail = lst
    // this is a common error
    Cons(head, tail~), Cons(_, ..) as c => {
      let cell = Cons(f(head), tail=Nil)
      c.tail = cell
      continue tail, cell
    }
    _, Nil => abort("map_dps: dest is Nil")
  }
}

test "map" {
  let lstL : L = Cons(
    1,
    tail=Cons(2, tail=Cons(3, tail=Cons(4, tail=Cons(5, tail=Nil)))),
  )
  let lst : L = map(lstL, fn { x => x * 2 })
  inspect!(
    lst,
    content="Cons(2, tail=Cons(4, tail=Cons(6, tail=Cons(8, tail=Cons(10, tail=Nil)))))",
  )
}
