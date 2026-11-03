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
  let map = @hashmap.HashMap([("a", 1), ("b", 2)])
  inspect(map.get_or_init("a", () => fail("must not run")), content="1")
  debug_inspect(
    @test.expect_error(() => {
      map.get_or_init("c", () => raise Failure::Failure("init failed"))
    }),
    content="Failure(\"init failed\")",
  )
  let entries = map.to_array()
  entries.sort()
  debug_inspect(entries, content="[(\"a\", 1), (\"b\", 2)]")
  inspect(map.length(), content="2")
  let mut calls = 0
  inspect(
    map.get_or_init("c", () => {
      calls += 1
      3
    }),
    content="3",
  )
  inspect(map.get_or_init("c", () => fail("must not run")), content="3")
  inspect(calls, content="1")
  inspect(map.length(), content="3")
}

///|
test "get_or_init preserves initializer side effects on error" {
  let map : @hashmap.HashMap[String, Int32] = HashMap([])
  debug_inspect(
    @test.expect_error(() => {
      map.get_or_init("a", () => {
        map["a"] = 10
        map["b"] = 20
        raise Failure::Failure("init failed")
      })
    }),
    content="Failure(\"init failed\")",
  )
  let entries = map.to_array()
  entries.sort()
  debug_inspect(entries, content="[(\"a\", 10), (\"b\", 20)]")
  map.remove("a")
  inspect(map.get_or_init("a", () => 30), content="30")
  inspect(map.length(), content="2")
}
