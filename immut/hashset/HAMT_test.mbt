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

test "Set" {
  let map = loop 0, Set::make() {
    100, map => map
    i, map => continue i + 1, map.add(i)
  }
  for i = 0; i < 100; i = i + 1 {
    @assertion.assert_eq((i, map.contains(i)), (i, true))?
  }
  inspect((100, map.contains(100)), content="(100, false)")?
  let map = map.add(100)
  inspect((100, map.contains(100)), content="(100, true)")?
}

test "Set::size" {
  for i = 0, set = Set::make(); i < 20; i = i + 1, set = set.add(i) {
    @assertion.assert_eq(set.size(), i)?
  } else {
    @assertion.assert_eq(set.add(0).size(), 20)?
  }
}

test "Set::remove" {
  let map = loop 0, Set::make() {
    100, map => map
    i, map => continue i + 1, map.add(i)
  }
  for i = 0; i < 100; i = i + 1 {
    @assertion.assert_eq((i, map.contains(i)), (i, true))?
  }
  let map = loop 0, map {
    100, map => map.remove(100) // test for removing non-existing element
    i, map => continue i + 2, map.remove(i)
  }
  for i = 0; i < 100; i = i + 2 {
    @assertion.assert_eq(map.contains(i), false)?
    @assertion.assert_eq(map.contains(i + 1), true)?
  }
}

test "Set::as_iter" {
  let data = Set::["a", "b", "d", "e", "f"]
  let mut s = ""
  data.as_iter().iter(fn { k => s += " \(k)" })
  inspect(s, content=" d e b a f")?
}

test "Set::to_string" {
  let set = Set::make().add(1).add(3).add(0x0f_ff_ff_ff).add(42)
  inspect(set, content="@immutable_hashset.Set::[3, 42, 1, 268435455]")?
}

test "Set::from_array" {
  let set = Set::["1", "2", "42"]
  inspect(set.contains("1"), content="true")?
  inspect(set.contains("2"), content="true")?
  inspect(set.contains("42"), content="true")?
  inspect(set.contains("43"), content="false")?
}

test "Set::is_empty" {
  let set = Set::make()
  inspect(set.is_empty(), content="true")?
  let set = set.add(1)
  inspect(set.is_empty(), content="false")?
}
