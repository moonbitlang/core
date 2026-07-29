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
test "shrink option" {
  debug_inspect(
    @shrink.Shrink::shrink((None : Unit?)).collect(),
    content=(
      #|[]
    ),
  )
  debug_inspect(
    @shrink.Shrink::shrink(Some(1000)).collect(),
    content=(
      #|[
      #|  Some(999),
      #|  Some(997),
      #|  Some(993),
      #|  Some(985),
      #|  Some(969),
      #|  Some(938),
      #|  Some(875),
      #|  Some(750),
      #|  Some(500),
      #|  Some(0),
      #|  None,
      #|]
    ),
  )
}

///|
test "shrink result" {
  let b : Result[Bool, Int] = Err(100)
  let x : Result[Bool, Int] = Ok(true)
  debug_inspect(
    @shrink.Shrink::shrink(b).collect(),
    content=(
      #|[Err(99), Err(97), Err(94), Err(88), Err(75), Err(50), Err(0)]
    ),
  )
  debug_inspect(
    @shrink.Shrink::shrink(x).collect(),
    content=(
      #|[Ok(false)]
    ),
  )
}

///|
test "shrink array" {
  let ar = [1, 2, 3, 4, 5, 6]
  debug_inspect(
    @shrink.Shrink::shrink(ar).collect(),
    content=(
      #|[
      #|  [2, 3, 4, 5, 6],
      #|  [1, 3, 4, 5, 6],
      #|  [1, 2, 4, 5, 6],
      #|  [1, 2, 3, 5, 6],
      #|  [1, 2, 3, 4, 6],
      #|  [4, 5, 6],
      #|  [0, 2, 3, 4, 5, 6],
      #|  [1, 1, 3, 4, 5, 6],
      #|  [1, 0, 3, 4, 5, 6],
      #|  [1, 2, 2, 4, 5, 6],
      #|  [1, 2, 0, 4, 5, 6],
      #|  [1, 2, 3, 3, 5, 6],
      #|  [1, 2, 3, 2, 5, 6],
      #|  [1, 2, 3, 0, 5, 6],
      #|  [1, 2, 3, 4, 4, 6],
      #|  [1, 2, 3, 4, 3, 6],
      #|  [1, 2, 3, 4, 0, 6],
      #|  [1, 2, 3, 4, 5, 5],
      #|  [1, 2, 3, 4, 5, 3],
      #|  [1, 2, 3, 4, 5, 0],
      #|]
    ),
  )
}

///|
test "shrink iter" {
  let it = [|1, 2, 3, 4, 5, 6|]
  debug_inspect(
    @shrink.Shrink::shrink(it).map(candidate => candidate.collect()).collect(),
    content=(
      #|[
      #|  [2, 3, 4, 5, 6],
      #|  [1, 3, 4, 5, 6],
      #|  [1, 2, 4, 5, 6],
      #|  [1, 2, 3, 5, 6],
      #|  [1, 2, 3, 4, 6],
      #|  [1, 2, 3, 4, 5],
      #|  [0, 2, 3, 4, 5, 6],
      #|  [1, 1, 3, 4, 5, 6],
      #|  [1, 0, 3, 4, 5, 6],
      #|  [1, 2, 2, 4, 5, 6],
      #|  [1, 2, 0, 4, 5, 6],
      #|  [1, 2, 3, 3, 5, 6],
      #|  [1, 2, 3, 2, 5, 6],
      #|  [1, 2, 3, 0, 5, 6],
      #|  [1, 2, 3, 4, 4, 6],
      #|  [1, 2, 3, 4, 3, 6],
      #|  [1, 2, 3, 4, 0, 6],
      #|  [1, 2, 3, 4, 5, 5],
      #|  [1, 2, 3, 4, 5, 3],
      #|  [1, 2, 3, 4, 5, 0],
      #|]
    ),
  )
}
