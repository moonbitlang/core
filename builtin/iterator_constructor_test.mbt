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
#warnings("-deprecated")
test "deprecated Iter constructor retains callbacks and size hints" {
  let source = [1, 2].iter()
  let iter = Iter::new(() => source.next(), size_hint=2)
  debug_inspect(iter.size_hint(), content="Some(2)")
  debug_inspect(iter.to_array(), content="[1, 2]")
}
