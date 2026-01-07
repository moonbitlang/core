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
test {
  assert_eq((Option::None : Unit?), Option::None)
  assert_eq(Option::Some(1), Option::Some(1))
  assert_not_eq(Option::Some(1), Option::Some(2))
  assert_not_eq(Option::None, Option::Some(1))
  assert_not_eq(Option::Some(1), Option::None)
}

///|
test "to_string for Option None" {
  let x : Int? = None
  inspect(x.to_string(), content="None")
}

///|
test "to_string for Option Some" {
  let x : Int? = Some(42)
  inspect(x.to_string(), content="Some(42)")
}

///|
test "unwrap_or variants" {
  let some : Int? = Some(10)
  let none : Int? = None
  inspect(some.unwrap_or(5), content="10")
  inspect(none.unwrap_or(5), content="5")
  inspect(some.unwrap_or_else(() => 7), content="10")
  inspect(none.unwrap_or_else(() => 7), content="7")
  inspect(none.unwrap_or_default(), content="0")
}

///|
test "compare default iter" {
  inspect(Some(1).compare(Some(2)), content="-1")
  inspect(Some(2).compare(Some(1)), content="1")
  inspect((None : Int?).compare(Some(1)), content="-1")
  inspect((None : Int?).compare(None), content="0")
  let default_opt : Int? = Default::default()
  inspect(default_opt, content="None")
  let iter_values = []
  (Some(3) : Int?).iter().each(iter_values.push(_))
  inspect(iter_values, content="[3]")
  let iter_empty = []
  (None : Int?).iter().each(iter_empty.push(_))
  inspect(iter_empty, content="[]")
}

///|
test "map_or and filter" {
  let some : Int? = Some(3)
  let none : Int? = None
  inspect(some.map_or(10, x => x * 2), content="6")
  inspect(none.map_or(10, x => x * 2), content="10")
  inspect(some.map_or_else(() => 7, x => x * 2), content="6")
  inspect(none.map_or_else(() => 7, x => x * 2), content="7")
  inspect(none.filter(_ => true), content="None")
}

///|
test "unwrap_or_error" {
  assert_eq(
    (None : String?).unwrap_or_error(Failure::Failure("boom")) catch {
      Failure(err) => err
    },
    "boom",
  )
  assert_eq(
    Some("ok").unwrap_or_error(Failure::Failure("boom")) catch {
      Failure(err) => err
    },
    "ok",
  )
}

///|
test "unwrap_or_default Some" {
  let some : Int? = Some(5)
  inspect(some.unwrap_or_default(), content="5")
}

///|
test "Option compare Some vs None" {
  let some : Int? = Some(1)
  let none : Int? = None
  inspect(some.compare(none), content="1")
}
