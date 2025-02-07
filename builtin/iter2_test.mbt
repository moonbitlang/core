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
test "iter2_to_iter" {
  let numbers = [1, 2, 3]
  let iter2_numbers = numbers.iter2() // creates Iter2[Int, Int] from Array
  let iter = @builtin.Iter2::iter(iter2_numbers) // converts Iter2 to Iter of tuples
  let result = iter.to_array() // collect results to array for inspection
  inspect!(result, content="[(0, 1), (1, 2), (2, 3)]")
}

///|
test "iter2 identity function should return its input" {
  let m : @builtin.Map[String, Int] = @builtin.Map::new()
  m.set("x", 1)
  m.set("y", 2)
  let iter2 = m.iter2()
  let same_iter2 = @builtin.Iter2::iter2(iter2)
  let result = same_iter2.to_array()
  inspect!(result, content="[(\"x\", 1), (\"y\", 2)]")
}

///|
test "Iter2::concat" {
  inspect!(
    "abcde".iter2().concat("fghij".iter2()).to_array(),
    content="[(0, 'a'), (1, 'b'), (2, 'c'), (3, 'd'), (4, 'e'), (0, 'f'), (1, 'g'), (2, 'h'), (3, 'i'), (4, 'j')]",
  )
}

///|
test "Iter2::concat with early return" {
  let first = Iter2::new(fn(y) {
    for i, v in "abcde" {
      ignore(y(i, v))
    }
    IterEnd
  })
  inspect!(
    first.concat("fghij".iter2()).to_array(),
    content="[(0, 'a'), (1, 'b'), (2, 'c'), (3, 'd'), (4, 'e')]",
  )
}
