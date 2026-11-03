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
  let map = { "a": 1, "b": 2 }
  let inputs = []
  debug_inspect(
    @test.expect_error(() => {
      map.update_or_default("a", 99, old => {
        inputs.push(old)
        raise Failure::Failure("update failed")
      })
    }),
    content="Failure(\"update failed\")",
  )
  debug_inspect(inputs, content="[1]")
  debug_inspect(map.to_array(), content="[(\"a\", 1), (\"b\", 2)]")
  inspect(map.length(), content="2")
  map.update_or_default("c", 3, _ => fail("must not run"))
  map.update_or_default("a", 99, old => old + 10)
  debug_inspect(map.to_array(), content="[(\"a\", 11), (\"b\", 2), (\"c\", 3)]")
  inspect(map.length(), content="3")
}

///|
test "update_or_default preserves callback mutations on error" {
  let map = { "a": 1, "b": 2 }
  debug_inspect(
    @test.expect_error(() => {
      map.update_or_default("a", 99, _ => {
        map.clear()
        map["c"] = 30
        raise Failure::Failure("update failed")
      })
    }),
    content="Failure(\"update failed\")",
  )
  debug_inspect(map.to_array(), content="[(\"c\", 30)]")
  inspect(map.length(), content="1")
  map.update_or_default("a", 10, _ => fail("must not run"))
  map.update_or_default("c", 0, old => old + 1)
  debug_inspect(map.to_array(), content="[(\"c\", 31), (\"a\", 10)]")
}
