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
priv struct JsonAliasValue {
  count : Int
} derive(@json.ToJson)

///|
test "ToJson alias preserves derivation and Json constructor conversion" {
  let value = JsonAliasValue::{ count: 42, }
  let converted = @json.ToJson::to_json(value)
  inspect(converted.stringify(), content="{\"count\":42}")
  assert_true(converted == Json(value))
}

///|
test "Bool::to_json" {
  debug_inspect(Json(true), content="True")
  debug_inspect(Json(false), content="False")
}

///|
test "Int::to_json" {
  debug_inspect(Json(42), content="Number(42)")
}

///|
test "UInt::to_json" {
  debug_inspect(Json(42U), content="Number(42)")
}

///|
test "Int64::to_json" {
  debug_inspect(
    Json(42L),
    content=(
      #|String("42")
    ),
  )
  debug_inspect(
    Json(-9223372036854775808L),
    content=(
      #|String("-9223372036854775808")
    ),
  )
  debug_inspect(
    Json(9223372036854775807L),
    content=(
      #|String("9223372036854775807")
    ),
  )
}

///|
test "UInt64::to_json" {
  debug_inspect(
    Json(42UL),
    content=(
      #|String("42")
    ),
  )
  debug_inspect(
    Json(18446744073709551615UL),
    content=(
      #|String("18446744073709551615")
    ),
  )
}

///|
test "Double::to_json" {
  debug_inspect(Json(42.0), content="Number(42)")
  debug_inspect(
    Json(@double.not_a_number),
    content=(
      #|String("NaN")
    ),
  )
  debug_inspect(
    Json(@double.infinity),
    content=(
      #|String("Infinity")
    ),
  )
  debug_inspect(
    Json(@double.neg_infinity),
    content=(
      #|String("-Infinity")
    ),
  )
}

///|
test "Float::to_json" {
  debug_inspect(Json((42.0 : Float)), content="Number(42)")
}

///|
test "String::to_json" {
  debug_inspect(
    Json("abc"),
    content=(
      #|String("abc")
    ),
  )
  debug_inspect(
    Json("a,\"b\",c"),
    content=(
      #|String("a,\"b\",c")
    ),
  )
  debug_inspect(
    Json("\""),
    content=(
      #|String("\"")
    ),
  )
  debug_inspect(
    Json("\u{00}"),
    content=(
      #|String("\u{00}")
    ),
  )
  debug_inspect(
    Json("\n\r\b\t\\"),
    content=(
      #|String("\n\r\b\t\\")
    ),
  )
  debug_inspect(
    Json("\u{0c}\u{0d}\u{0f}"),
    content=(
      #|String("\u{0c}\r\u{0f}")
    ),
  )
}

///|
test "Char::to_json" {
  debug_inspect(
    Json('a'),
    content=(
      #|String("a")
    ),
  )
  debug_inspect(
    Json('字'),
    content=(
      #|String("字")
    ),
  )
}

///|
test "BigInt::to_json" {
  debug_inspect(
    BigInt::from_string("123456789012345678901234567890").to_json(),
    content="String(\"123456789012345678901234567890\")",
  )
}

///|
test "Array::to_json" {
  debug_inspect(
    Json([1, 2, 3]),
    content="Array([Number(1), Number(2), Number(3)])",
  )
  debug_inspect(
    Json([[], ["1"], ["1", "2"]]),
    content=(
      #|Array([Array([]), Array([String("1")]), Array([String("1"), String("2")])])
    ),
  )
}

///|
test "FixedArray::to_json" {
  debug_inspect(
    Json(([1, 2, 3] : FixedArray[_])),
    content="Array([Number(1), Number(2), Number(3)])",
  )
  debug_inspect(
    Json([[], ["1"], ["1", "2"]]),
    content=(
      #|Array([Array([]), Array([String("1")]), Array([String("1"), String("2")])])
    ),
  )
}

///|
test "Json constructor converts maps" {
  debug_inspect(
    Json({ "x": [1], "y": [2] }),
    content=(
      #|Object({ "x": Array([Number(1)]), "y": Array([Number(2)]) })
    ),
  )
}

///|
priv struct Opt {
  x : Int?
  t : Int??
} derive(ToJson, FromJson, Eq)

///|
test "Option::to_json" {
  debug_inspect(Json((Some(42) : Int?)), content="Array([Number(42)])")
  debug_inspect(Json((None : Int?)), content="Null")
  debug_inspect(Json((Some(None) : Unit??)), content="Array([Null])")
  debug_inspect(
    Json((Some(Some(None)) : Unit???)),
    content="Array([Array([Null])])",
  )
}

///|
test "optional field" {
  let opt = [
    { x: Some(42), t: Some(Some(42)), },
    { x: None, t: None, },
    { x: None, t: Some(None), },
  ]
  inspect(
    ToJson::to_json(opt).stringify(),
    content=(
      #|[{"x":42,"t":[42]},{},{"t":null}]
    ),
  )
}

///|
test "optional field round trip" {
  let opt = { x: Some(42), t: Some(Some(42)), }
  assert_true(@json.from_json(ToJson::to_json(opt)) == opt)
  let opt = { x: None, t: None, }
  assert_true(@json.from_json(ToJson::to_json(opt)) == opt)
  let opt = { x: None, t: Some(None), }
  assert_true(@json.from_json(ToJson::to_json(opt)) == opt)
}

///|
test "Tuple::to_json" {
  let tuple = (0, 1)
  debug_inspect(ToJson::to_json(tuple), content="Array([Number(0), Number(1)])")
  let tuple = (0, 1, 2)
  debug_inspect(
    ToJson::to_json(tuple),
    content="Array([Number(0), Number(1), Number(2)])",
  )
  let tuple = (0, 1, 2, 3)
  debug_inspect(
    ToJson::to_json(tuple),
    content="Array([Number(0), Number(1), Number(2), Number(3)])",
  )
  let tuple = (0, 1, 2, 3, 4)
  debug_inspect(
    ToJson::to_json(tuple),
    content="Array([Number(0), Number(1), Number(2), Number(3), Number(4)])",
  )
  let tuple = (0, 1, 2, 3, 4, 5)
  debug_inspect(
    ToJson::to_json(tuple),
    content="Array([Number(0), Number(1), Number(2), Number(3), Number(4), Number(5)])",
  )
  let tuple = (0, 1, 2, 3, 4, 5, 6)
  debug_inspect(
    ToJson::to_json(tuple),
    content=(
      #|Array(
      #|  [
      #|    Number(0),
      #|    Number(1),
      #|    Number(2),
      #|    Number(3),
      #|    Number(4),
      #|    Number(5),
      #|    Number(6),
      #|  ],
      #|)
    ),
  )
  let tuple = (0, 1, 2, 3, 4, 5, 6, 7)
  debug_inspect(
    ToJson::to_json(tuple),
    content=(
      #|Array(
      #|  [
      #|    Number(0),
      #|    Number(1),
      #|    Number(2),
      #|    Number(3),
      #|    Number(4),
      #|    Number(5),
      #|    Number(6),
      #|    Number(7),
      #|  ],
      #|)
    ),
  )
  let tuple = (0, 1, 2, 3, 4, 5, 6, 7, 8)
  debug_inspect(
    ToJson::to_json(tuple),
    content=(
      #|Array(
      #|  [
      #|    Number(0),
      #|    Number(1),
      #|    Number(2),
      #|    Number(3),
      #|    Number(4),
      #|    Number(5),
      #|    Number(6),
      #|    Number(7),
      #|    Number(8),
      #|  ],
      #|)
    ),
  )
  let tuple = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
  debug_inspect(
    ToJson::to_json(tuple),
    content=(
      #|Array(
      #|  [
      #|    Number(0),
      #|    Number(1),
      #|    Number(2),
      #|    Number(3),
      #|    Number(4),
      #|    Number(5),
      #|    Number(6),
      #|    Number(7),
      #|    Number(8),
      #|    Number(9),
      #|  ],
      #|)
    ),
  )
  let tuple = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
  debug_inspect(
    ToJson::to_json(tuple),
    content=(
      #|Array(
      #|  [
      #|    Number(0),
      #|    Number(1),
      #|    Number(2),
      #|    Number(3),
      #|    Number(4),
      #|    Number(5),
      #|    Number(6),
      #|    Number(7),
      #|    Number(8),
      #|    Number(9),
      #|    Number(10),
      #|  ],
      #|)
    ),
  )
  let tuple = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11)
  debug_inspect(
    ToJson::to_json(tuple),
    content=(
      #|Array(
      #|  [
      #|    Number(0),
      #|    Number(1),
      #|    Number(2),
      #|    Number(3),
      #|    Number(4),
      #|    Number(5),
      #|    Number(6),
      #|    Number(7),
      #|    Number(8),
      #|    Number(9),
      #|    Number(10),
      #|    Number(11),
      #|  ],
      #|)
    ),
  )
  let tuple = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)
  debug_inspect(
    ToJson::to_json(tuple),
    content=(
      #|Array(
      #|  [
      #|    Number(0),
      #|    Number(1),
      #|    Number(2),
      #|    Number(3),
      #|    Number(4),
      #|    Number(5),
      #|    Number(6),
      #|    Number(7),
      #|    Number(8),
      #|    Number(9),
      #|    Number(10),
      #|    Number(11),
      #|    Number(12),
      #|  ],
      #|)
    ),
  )
  let tuple = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13)
  debug_inspect(
    ToJson::to_json(tuple),
    content=(
      #|Array(
      #|  [
      #|    Number(0),
      #|    Number(1),
      #|    Number(2),
      #|    Number(3),
      #|    Number(4),
      #|    Number(5),
      #|    Number(6),
      #|    Number(7),
      #|    Number(8),
      #|    Number(9),
      #|    Number(10),
      #|    Number(11),
      #|    Number(12),
      #|    Number(13),
      #|  ],
      #|)
    ),
  )
  let tuple = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
  debug_inspect(
    ToJson::to_json(tuple),
    content=(
      #|Array(
      #|  [
      #|    Number(0),
      #|    Number(1),
      #|    Number(2),
      #|    Number(3),
      #|    Number(4),
      #|    Number(5),
      #|    Number(6),
      #|    Number(7),
      #|    Number(8),
      #|    Number(9),
      #|    Number(10),
      #|    Number(11),
      #|    Number(12),
      #|    Number(13),
      #|    Number(14),
      #|  ],
      #|)
    ),
  )
  let tuple = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
  debug_inspect(
    ToJson::to_json(tuple),
    content=(
      #|Array(
      #|  [
      #|    Number(0),
      #|    Number(1),
      #|    Number(2),
      #|    Number(3),
      #|    Number(4),
      #|    Number(5),
      #|    Number(6),
      #|    Number(7),
      #|    Number(8),
      #|    Number(9),
      #|    Number(10),
      #|    Number(11),
      #|    Number(12),
      #|    Number(13),
      #|    Number(14),
      #|    Number(15),
      #|  ],
      #|)
    ),
  )
}
