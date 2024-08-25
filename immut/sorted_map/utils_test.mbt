// Copyright 2024 International Digital Economy Academy
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

test "op_get with existing key" {
  let map = @sorted_map.of(
    [(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")],
  )
  assert_eq!(map[3], Some("three"))
}

test "op_get with non-existing key" {
  let map = @sorted_map.of(
    [(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")],
  )
  assert_eq!(map[4], None)
}

test "op_get after insertion" {
  let map = @sorted_map.of(
    [(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")],
  )
  let map = map.insert(4, "four")
  assert_eq!(map[4], Some("four"))
}

test "op_get after removal" {
  let map = @sorted_map.of(
    [(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")],
  )
  let map = map.remove(3)
  assert_eq!(map[3], None)
}

test "iter" {
  let map = [(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")]
    |> @sorted_map.of
  let buf = Buffer::new()
  for k, v in map {
    buf.write_object(k)
    buf.write_string(": ")
    buf.write_object(v)
    buf.write_string("\n")
  }
  for kv in map {
    buf.write_object(kv)
    buf.write_string("\n")
  }
  inspect!(
    buf,
    content=
      #|0: zero
      #|1: one
      #|2: two
      #|3: three
      #|8: eight
      #|(0, "zero")
      #|(1, "one")
      #|(2, "two")
      #|(3, "three")
      #|(8, "eight")
      #|
    ,
  )
}

test "op_get with empty map" {
  let map : @sorted_map.T[Int, String] = @sorted_map.empty()
  assert_eq!(map[3], None)
}
