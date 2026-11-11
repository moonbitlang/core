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
test "update replaces, inserts and removes" {
  let map = @sorted_map.SortedMap([(1, "a"), (2, "b")])
  map.update(1, v => Some(v.unwrap() + "!"))
  map.update(3, v => {
    assert_eq(v, None)
    Some("c")
  })
  map.update(2, _ => None)
  map.update(4, _ => None)
  debug_inspect(map.to_array(), content="[(1, \"a!\"), (3, \"c\")]")
  inspect(map.length(), content="2")
}

///|
test "update propagates errors without modifying the map" {
  let map = @sorted_map.SortedMap([(1, "a")])
  debug_inspect(
    @test.expect_error(() => map.update(1, _ => raise Failure::Failure("boom"))),
    content="Failure(\"boom\")",
  )
  debug_inspect(
    @test.expect_error(() => map.update(2, _ => raise Failure::Failure("boom"))),
    content="Failure(\"boom\")",
  )
  debug_inspect(map.to_array(), content="[(1, \"a\")]")
}

///|
test "update applies the result after f writes to the map" {
  let map = @sorted_map.SortedMap([(1, "a")])
  map.update(1, v => {
    map.remove(1)
    map.set(2, "b")
    v
  })
  debug_inspect(map.to_array(), content="[(1, \"a\"), (2, \"b\")]")
  map.update(2, _ => {
    map.set(2, "x")
    None
  })
  debug_inspect(map.to_array(), content="[(1, \"a\")]")
}
