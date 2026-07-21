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
test "Bool::to_json" {
  debug_inspect(true.to_json(), content="True")
  debug_inspect(false.to_json(), content="False")
}

///|
test "Int::to_json" {
  debug_inspect((42).to_json(), content="Number(42)")
}

///|
test "UInt::to_json" {
  debug_inspect(42U.to_json(), content="Number(42)")
}

///|
test "Int64::to_json" {
  debug_inspect(
    42L.to_json(),
    content=(
      #|String("42")
    ),
  )
  debug_inspect(
    (-9223372036854775808L).to_json(),
    content=(
      #|String("-9223372036854775808")
    ),
  )
  debug_inspect(
    9223372036854775807L.to_json(),
    content=(
      #|String("9223372036854775807")
    ),
  )
}

///|
test "UInt64::to_json" {
  debug_inspect(
    42UL.to_json(),
    content=(
      #|String("42")
    ),
  )
  debug_inspect(
    18446744073709551615UL.to_json(),
    content=(
      #|String("18446744073709551615")
    ),
  )
}

///|
test "Double::to_json" {
  debug_inspect(42.0.to_json(), content="Number(42)")
  debug_inspect(
    @double.not_a_number.to_json(),
    content=(
      #|String("NaN")
    ),
  )
  debug_inspect(
    @double.infinity.to_json(),
    content=(
      #|String("Infinity")
    ),
  )
  debug_inspect(
    @double.neg_infinity.to_json(),
    content=(
      #|String("-Infinity")
    ),
  )
}

///|
test "Float::to_json" {
  debug_inspect((42.0 : Float).to_json(), content="Number(42)")
}

///|
test "String::to_json" {
  debug_inspect(
    "abc".to_json(),
    content=(
      #|String("abc")
    ),
  )
  debug_inspect(
    "a,\"b\",c".to_json(),
    content=(
      #|String("a,\"b\",c")
    ),
  )
  debug_inspect(
    "\"".to_json(),
    content=(
      #|String("\"")
    ),
  )
  debug_inspect(
    "\u{00}".to_json(),
    content=(
      #|String("\u{00}")
    ),
  )
  debug_inspect(
    "\n\r\b\t\\".to_json(),
    content=(
      #|String("\n\r\b\t\\")
    ),
  )
  debug_inspect(
    "\u{0c}\u{0d}\u{0f}".to_json(),
    content=(
      #|String("\u{0c}\r\u{0f}")
    ),
  )
}

///|
test "Char::to_json" {
  debug_inspect(
    'a'.to_json(),
    content=(
      #|String("a")
    ),
  )
  debug_inspect(
    '字'.to_json(),
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
    [1, 2, 3].to_json(),
    content="Array([Number(1), Number(2), Number(3)])",
  )
  debug_inspect(
    [[], ["1"], ["1", "2"]].to_json(),
    content=(
      #|Array([Array([]), Array([String("1")]), Array([String("1"), String("2")])])
    ),
  )
}

///|
test "FixedArray::to_json" {
  debug_inspect(
    ([1, 2, 3] : FixedArray[_]).to_json(),
    content="Array([Number(1), Number(2), Number(3)])",
  )
  debug_inspect(
    [[], ["1"], ["1", "2"]].to_json(),
    content=(
      #|Array([Array([]), Array([String("1")]), Array([String("1"), String("2")])])
    ),
  )
}

///|
test "Map::to_json" {
  debug_inspect(
    { "x": [1], "y": [2] }.to_json(),
    content=(
      #|Object({ "x": Array([Number(1)]), "y": Array([Number(2)]) })
    ),
  )
}

///|
struct Opt {
  x : Int?
  t : Int??
} derive(ToJson, FromJson, Eq, Debug)

///|
test "Option::to_json" {
  debug_inspect((Some(42) : Int?).to_json(), content="Array([Number(42)])")
  debug_inspect((None : Int?).to_json(), content="Null")
  debug_inspect((Some(None) : Unit??).to_json(), content="Array([Null])")
  debug_inspect(
    (Some(Some(None)) : Unit???).to_json(),
    content="Array([Array([Null])])",
  )
}

///|
test "optional field" {
  let opt = [
    { x: Some(42), t: Some(Some(42)) },
    { x: None, t: None },
    { x: None, t: Some(None) },
  ]
  inspect(
    opt.to_json().stringify(),
    content=(
      #|[{"x":42,"t":[42]},{},{"t":null}]
    ),
  )
}

///|
test "optional field round trip" {
  let opt = { x: Some(42), t: Some(Some(42)) }
  assert_true(@json.from_json(opt.to_json()) == opt)
  let opt = { x: None, t: None }
  assert_true(@json.from_json(opt.to_json()) == opt)
  let opt = { x: None, t: Some(None) }
  assert_true(@json.from_json(opt.to_json()) == opt)
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

///|
#deprecated("Use `==` / `!=` instead", skip_current_package=true)
pub extend Opt with Eq::{equal, not_equal}

///|
#deprecated("Use the `Debug` trait instead", skip_current_package=true)
pub extend Opt with @debug.Debug::{to_repr}

///|
#deprecated("Use the `FromJson` trait instead", skip_current_package=true)
pub extend Opt with @json.FromJson::{from_json}

///|
pub extend Opt with ToJson::{to_json}
