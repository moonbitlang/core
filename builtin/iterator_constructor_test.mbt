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
test "Iter constructor defers callbacks and preserves size hints" {
  let mut reads = 0
  let iter = Iter(
    () => {
      reads += 1
      if reads <= 2 {
        Some(reads)
      } else {
        None
      }
    },
    size_hint=2,
  )
  debug_inspect((reads, iter.size_hint()), content="(0, Some(2))")
  debug_inspect(iter.next(), content="Some(1)")
  debug_inspect((reads, iter.size_hint()), content="(1, Some(1))")
  debug_inspect(iter.to_array(), content="[2]")
  debug_inspect(iter.size_hint(), content="Some(0)")
}

///|
test "Iter2 tuple constructor supports callback iterators and destructuring" {
  let mut next = 0
  let iter = Iter2(
    Iter(
      () => {
        guard next < 2 else { None }
        let key = next
        next += 1
        Some((key, key + 10))
      },
      size_hint=2,
    ),
  )
  let Iter2(inner) = iter
  debug_inspect(inner.size_hint(), content="Some(2)")
  let values = [ for key, value in Iter2(inner) => (key, value) ]
  debug_inspect(values, content="[(0, 10), (1, 11)]")
  debug_inspect(inner.size_hint(), content="Some(0)")
}

///|
#warnings("-deprecated")
test "deprecated iterator constructors retain callbacks and size hints" {
  let source = [1, 2].iter()
  let iter = Iter::new(() => source.next(), size_hint=2)
  debug_inspect(iter.size_hint(), content="Some(2)")
  debug_inspect(iter.to_array(), content="[1, 2]")
  let pairs = [(1, "one"), (2, "two")].iter()
  let iter2 = Iter2::new(() => pairs.next(), size_hint=2)
  debug_inspect(iter2.iter().size_hint(), content="Some(2)")
  debug_inspect(iter2.to_array(), content="[(1, \"one\"), (2, \"two\")]")
  let negative : Iter2[Int32, Int32] = Iter2::new(() => None, size_hint=-1)
  debug_inspect(negative.iter().size_hint(), content="Some(0)")
}
