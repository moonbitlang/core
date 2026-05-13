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
test "from_json round-trips whatever to_json produced" {
  for map in (@quickcheck.samples(50) : Array[@hashmap.HashMap[String, Int]]) {
    let restored : @hashmap.HashMap[String, Int] = @json.from_json(
      @json.to_json(map),
    )
    @debug.assert_eq(restored, map)
  }
}

///|
test "from_json decodes an object" {
  let restored : @hashmap.HashMap[String, Int] = @json.from_json({
    "key1": 42,
    "key2": 100,
    "key3": -5,
  })
  inspect(restored.length(), content="3")
  debug_inspect(restored.get("key1"), content="Some(42)")
  debug_inspect(restored.get("key3"), content="Some(-5)")
  debug_inspect(restored.get("missing"), content="None")
}

///|
test "from_json decodes an empty object and nested values" {
  let empty : @hashmap.HashMap[String, Int] = @json.from_json({})
  inspect(empty.length(), content="0")
  let nested : @hashmap.HashMap[String, Array[Int]] = @json.from_json({
    "a": [1, 2],
    "b": [],
  })
  debug_inspect(nested.get("a"), content="Some([1, 2])")
  debug_inspect(nested.get("b"), content="Some([])")
}

///|
test "from_json rejects a non-object" {
  let bad : Json = 1
  try (@json.from_json(bad) : @hashmap.HashMap[String, Int]) catch {
    err =>
      inspect(
        err,
        content="JsonDecodeError((, @hashmap.from_json: expected object))",
      )
  } noraise {
    _ => fail("expected JsonDecodeError")
  }
}

///|
test "from_json reports the path of the value that failed" {
  // The decoder extends the path with each key, so a failure inside one
  // entry has to name that entry rather than the object as a whole.
  let bad : Json = { "ok": 1, "wrong": "not an int" }
  try (@json.from_json(bad) : @hashmap.HashMap[String, Int]) catch {
    err =>
      inspect(
        err,
        content="JsonDecodeError((/wrong, Int::from_json: expected number))",
      )
  } noraise {
    _ => fail("expected JsonDecodeError")
  }
}
