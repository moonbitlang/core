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
test "update commits only after callback succeeds" {
  let map = { "a": 1, "b": 2 }
  let inputs = []
  debug_inspect(
    @test.expect_error(() => {
      map.update("a", old => {
        inputs.push(old)
        raise Failure::Failure("update failed")
      })
    }),
    content="Failure(\"update failed\")",
  )
  debug_inspect(
    @test.expect_error(() => {
      map.update("c", old => {
        inputs.push(old)
        raise Failure::Failure("update failed")
      })
    }),
    content="Failure(\"update failed\")",
  )
  debug_inspect(inputs, content="[Some(1), None]")
  debug_inspect(map.to_array(), content="[(\"a\", 1), (\"b\", 2)]")
  inspect(map.length(), content="2")
  map.update("a", old => Some(old.unwrap_or(0) + 10))
  map.update("b", _ => None)
  map.update("c", _ => Some(3))
  map.update("missing", _ => None)
  debug_inspect(map.to_array(), content="[(\"a\", 11), (\"c\", 3)]")
  inspect(map.length(), content="2")
}

///|
test "update preserves callback mutations on error" {
  let map = { "a": 1, "b": 2 }
  debug_inspect(
    @test.expect_error(() => {
      map.update("a", _ => {
        map.clear()
        map["a"] = 10
        map["c"] = 30
        raise Failure::Failure("update failed")
      })
    }),
    content="Failure(\"update failed\")",
  )
  debug_inspect(map.to_array(), content="[(\"a\", 10), (\"c\", 30)]")
  debug_inspect(
    @test.expect_error(() => {
      map.update("d", _ => {
        map["d"] = 40
        raise Failure::Failure("update failed")
      })
    }),
    content="Failure(\"update failed\")",
  )
  debug_inspect(
    map.to_array(),
    content="[(\"a\", 10), (\"c\", 30), (\"d\", 40)]",
  )
  map.update("a", _ => None)
  inspect(map.contains("a"), content="false")
  inspect(map.length(), content="2")
}
