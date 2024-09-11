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

test "Bool::to_json" {
  inspect!(true.to_json(), content="True")
  inspect!(false.to_json(), content="False")
}

test "Int::to_json" {
  inspect!((42).to_json(), content="Number(42)")
}

test "Int64::to_json" {
  inspect!(42L.to_json(), content="Number(42)")
}

test "Double::to_json" {
  inspect!(42.0.to_json(), content="Number(42)")
}

test "Float::to_json" {
  inspect!((42.0 : Float).to_json(), content="Number(42)")
}

test "String::to_json" {
  inspect!(
    "abc".to_json(),
    content=
      #|String("abc")
    ,
  )
  inspect!(
    "a,\"b\",c".to_json(),
    content=
      #|String("a,\"b\",c")
    ,
  )
  inspect!(
    "\"".to_json(),
    content=
      #|String("\"")
    ,
  )
  inspect!(
    "\x00".to_json(),
    content=
      #|String("\\u0000")
    ,
  )
  inspect!(
    "\n\r\b\t\\".to_json(),
    content=
      #|String("\\n\\r\\b\\t\\")
    ,
  )
  inspect!(
    "\x0c\x0d\x0f".to_json(),
    content=
      #|String("\\f\\r\\u000f")
    ,
  )
}

test "Char::to_json" {
  inspect!(
    'a'.to_json(),
    content=
      #|String("a")
    ,
  )
  inspect!(
    '字'.to_json(),
    content=
      #|String("字")
    ,
  )
}

test "BigInt::to_json" {
  inspect!(
    BigInt::from_string("123456789012345678901234567890").to_json(),
    content="String(\"123456789012345678901234567890\")",
  )
}

test "Array::to_json" {
  inspect!(
    [1, 2, 3].to_json(),
    content="Array([Number(1), Number(2), Number(3)])",
  )
  inspect!(
    [[], ["1"], ["1", "2"]].to_json(),
    content=
      #|Array([Array([]), Array([String("1")]), Array([String("1"), String("2")])])
    ,
  )
}

test "FixedArray::to_json" {
  inspect!(
    ([1, 2, 3] : FixedArray[_]).to_json(),
    content="Array([Number(1), Number(2), Number(3)])",
  )
  inspect!(
    [[], ["1"], ["1", "2"]].to_json(),
    content=
      #|Array([Array([]), Array([String("1")]), Array([String("1"), String("2")])])
    ,
  )
}

test "Map::to_json" {
  inspect!(
    { "x": [1], "y": [2] }.to_json(),
    content=
      #|Object({"x": Array([Number(1)]), "y": Array([Number(2)])})
    ,
  )
}
