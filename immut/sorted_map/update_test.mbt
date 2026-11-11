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
  let m = @sorted_map.SortedMap([(1, "a"), (2, "b")])
  let m2 = m
    .update(1, v => Some(v.unwrap() + "!"))
    .update(3, v => {
      assert_eq(v, None)
      Some("c")
    })
    .update(2, _ => None)
    .update(4, _ => None)
  debug_inspect(m2.to_array(), content="[(1, \"a!\"), (3, \"c\")]")
  inspect(m2.length(), content="2")
  // the original is untouched
  debug_inspect(m.to_array(), content="[(1, \"a\"), (2, \"b\")]")
}

///|
test "update agrees with add and remove" {
  let m = @sorted_map.SortedMap([(1, "a"), (2, "b")])
  assert_eq(m.update(1, _ => Some("z")), m.add(1, "z"))
  assert_eq(m.update(5, _ => Some("z")), m.add(5, "z"))
  assert_eq(m.update(1, _ => None), m.remove(1))
  assert_eq(m.update(5, _ => None), m)
}

///|
test "update propagates errors" {
  let m = @sorted_map.SortedMap([(1, "a")])
  debug_inspect(
    @test.expect_error(() => m.update(1, _ => raise Failure::Failure("boom"))),
    content="Failure(\"boom\")",
  )
}
