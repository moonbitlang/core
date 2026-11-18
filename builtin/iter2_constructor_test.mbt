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
test "Iter2 supports direct construction, destructuring and pair loops" {
  let iter = Iter2([|(0, 10), (1, 11)|])
  let Iter2(inner) = iter
  debug_inspect(inner.size_hint(), content="Some(2)")
  let values = [ for key, value in Iter2(inner) => (key, value) ]
  debug_inspect(values, content="[(0, 10), (1, 11)]")
  debug_inspect(inner.size_hint(), content="Some(0)")
}

///|
#warnings("-deprecated")
test "deprecated Iter2 new preserves lazy callbacks and size hints" {
  let pairs = [(1, "one"), (2, "two")].iter()
  let mut reads = 0
  let legacy = Iter2::new(
    () => {
      reads += 1
      pairs.next()
    },
    size_hint=2,
  )
  debug_inspect((reads, legacy.iter().size_hint()), content="(0, Some(2))")
  debug_inspect(legacy.next(), content="Some((1, \"one\"))")
  debug_inspect((reads, legacy.iter().size_hint()), content="(1, Some(1))")
  debug_inspect(legacy.to_array(), content="[(2, \"two\")]")
  let unknown : Iter2[Int32, Int32] = Iter2::new(() => None)
  debug_inspect(unknown.iter().size_hint(), content="None")
  let negative : Iter2[Int32, Int32] = Iter2::new(() => None, size_hint=-1)
  debug_inspect(negative.iter().size_hint(), content="Some(0)")
}
