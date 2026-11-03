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
test "get_or_init propagates initialization errors without inserting" {
  let map = @sorted_map.SortedMap([(1, 10), (3, 30)])
  inspect(map.get_or_init(1, () => fail("must not run")), content="10")
  debug_inspect(
    @test.expect_error(() => {
      map.get_or_init(2, () => raise Failure::Failure("init failed"))
    }),
    content="Failure(\"init failed\")",
  )
  debug_inspect(map.to_array(), content="[(1, 10), (3, 30)]")
  inspect(map.length(), content="2")
  let mut calls = 0
  inspect(
    map.get_or_init(2, () => {
      calls += 1
      20
    }),
    content="20",
  )
  inspect(map.get_or_init(2, () => fail("must not run")), content="20")
  inspect(calls, content="1")
  debug_inspect(map.to_array(), content="[(1, 10), (2, 20), (3, 30)]")
}

///|
test "get_or_init preserves initializer side effects on error" {
  let value = Ref(10)
  let map = @sorted_map.SortedMap([(1, value)])
  debug_inspect(
    @test.expect_error(() => {
      map.get_or_init(2, () => {
        value.val = 20
        raise Failure::Failure("init failed")
      })
    }),
    content="Failure(\"init failed\")",
  )
  inspect(map.get(1).unwrap().val, content="20")
  inspect(map.contains(2), content="false")
  inspect(map.length(), content="1")
}
