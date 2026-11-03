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
test "update_or_default commits only after callback succeeds" {
  let map = @sorted_map.SortedMap([ for key in 1..<=7 => (key, key * 10) ])
  let inputs = []
  for key in [1, 4, 7] {
    @test.assert_raise(() => {
      map.update_or_default(key, 99, old => {
        inputs.push(old)
        raise Failure::Failure("update failed")
      })
    })
  }
  debug_inspect(inputs, content="[10, 40, 70]")
  debug_inspect(
    map.to_array(),
    content="[(1, 10), (2, 20), (3, 30), (4, 40), (5, 50), (6, 60), (7, 70)]",
  )
  inspect(map.length(), content="7")
  map.update_or_default(8, 80, _ => fail("must not run"))
  map.update_or_default(4, 99, old => old + 1)
  map.remove(1)
  debug_inspect(
    map.to_array(),
    content="[(2, 20), (3, 30), (4, 41), (5, 50), (6, 60), (7, 70), (8, 80)]",
  )
  inspect(map.length(), content="7")
}

///|
test "update_or_default preserves callback side effects on error" {
  let value = Ref(10)
  let map = @sorted_map.SortedMap([(1, value)])
  debug_inspect(
    @test.expect_error(() => {
      map.update_or_default(1, Ref(99), old => {
        old.val = 20
        raise Failure::Failure("update failed")
      })
    }),
    content="Failure(\"update failed\")",
  )
  inspect(map.get(1).unwrap().val, content="20")
  inspect(map.length(), content="1")
  map.update_or_default(1, Ref(99), old => Ref(old.val + 1))
  inspect(map.get(1).unwrap().val, content="21")
}
