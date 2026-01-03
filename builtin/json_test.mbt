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
test "Json default value" {
  let j = @builtin.Json::default()
  inspect(j, content="False")
}

///|
test "Json null and bool equality" {
  let n1 = Json::null()
  let n2 = Json::null()
  inspect(n1 == n2, content="true")
  inspect(false.to_json() == false.to_json(), content="true")
  inspect(Json::null(), content="Null")
}

///|
test "Json number equality" {
  let a = Json::number(1.5)
  let b = Json::number(1.5)
  let c = Json::number(2.0)
  inspect(a == b, content="true")
  inspect(a == c, content="false")
}

///|
test "Json string equality" {
  let a = Json::string("hi")
  let b = Json::string("hi")
  let c = Json::string("bye")
  inspect(a == b, content="true")
  inspect(a == c, content="false")
}

///|
test "Json array equality" {
  let a = Json::array([Json::number(1), Json::string("x")])
  let b = Json::array([Json::number(1), Json::string("x")])
  let c = Json::array([Json::number(2)])
  inspect(a == b, content="true")
  inspect(a == c, content="false")
}

///|
test "Json object equality" {
  let a = Json::object({ "x": Json::number(1), "y": Json::string("a") })
  let b = Json::object({ "x": Json::number(1), "y": Json::string("a") })
  let c = Json::object({ "x": Json::number(2) })
  inspect(a == b, content="true")
  inspect(a == c, content="false")
}

///|
test "Json equality mismatch" {
  let a = Json::null()
  let b = Json::string("x")
  inspect(a == b, content="false")
}

///|
test "Int64 to_json" {
  let i : Int64 = 42L
  inspect(i.to_json(), content="String(\"42\")")
}

///|
test "UInt to_json" {
  let x = 42U
  let json = UInt::to_json(x)
  inspect(json, content="Number(42)")
}

///|
test "double to json with positive infinity" {
  let pos_inf = 1.0 / 0.0
  inspect(
    pos_inf.to_json(),
    content=(
      #|String("Infinity")
    ),
  )
  @json.inspect(pos_inf, content="Infinity")
}

///|
test "double to json with negative infinity" {
  let neg_inf = -1.0 / 0.0
  inspect(
    neg_inf.to_json(),
    content=(
      #|String("-Infinity")
    ),
  )
  @json.inspect(neg_inf, content="-Infinity")
  @json.inspect(0.0 / 0.0, content="NaN")
}

///|
test "test_float_to_json" {
  let float : Float = 3.14
  let json_val = float.to_json()
  inspect(json_val, content="Number(3.140000104904175)")
}

///|
test "to_json on empty fixed array" {
  let arr : FixedArray[Int] = FixedArray::make(0, 0)
  inspect(arr.to_json(), content="Array([])")
}

///|
test "test map with string values" {
  let m : Map[String, Int] = {}
  inspect(m.to_json(), content="Object({})")
}

///|
test "Option::to_json with None" {
  let none : Int? = None
  inspect(none.to_json(), content="Null")
}

///|
test "Option::to_json with Some value" {
  let some : Int? = Some(42)
  inspect(some.to_json(), content="Array([Number(42)])")
}

///|
test "Result to_json with Ok value" {
  let ok : Result[Int, String] = Ok(42)
  inspect(ok.to_json(), content="Object({\"Ok\": Number(42)})")
}

///|
test "Unit::to_json" {
  let r = ().to_json()
  inspect(r, content="Null")
}

///|
test "Bool::to_json false" {
  inspect(false.to_json(), content="False")
}

///|
test "test UInt64::to_json" {
  let num : UInt64 = UInt64::default()
  let json = num.to_json()
  inspect(json, content="String(\"0\")")
}

///|
test "escape control characters" {
  let str = "abc\u{01}def" // Control character with code 1
  let json = str.to_json()
  inspect(
    json,
    content=(
      #|String("abc\u{01}def")
    ),
  )
}

///|
test "test carriage return and backspace" {
  let test_string = "CR\rBS\b"
  let json = test_string.to_json()
  inspect(
    json,
    content=(
      #|String("CR\rBS\b")
    ),
  )
}

///|
test "test form feed" {
  let test_string = "Form\u000CFeed"
  let json = test_string.to_json()
  inspect(
    json,
    content=(
      #|String("Form\u{0c}Feed")
    ),
  )
}

///|
test "to_json BigInt" {
  let n = BigInt::from_int(42)
  inspect(BigInt::to_json(n), content="String(\"42\")")
}

///|
test "Result to_json with Err value" {
  let err : Result[Int, String] = Err("error")
  inspect(err.to_json(), content="Object({\"Err\": String(\"error\")})")
}

///|
test "Bool::to_json true" {
  let result = true.to_json()
  assert_eq(result, Json::boolean(true))
}

///|
test "to_hex_digit" {
  let str = "\n\r\b\t\u{0C}\u{00}"
  guard Json::string(str) is String(escaped)
  assert_eq(escaped, "\n\r\b\t\u{0c}\u{00}")
}

///|
test "Char::to_json converts char to JSON string" {
  let c = 'A'
  let json = c.to_json()
  inspect(json, content="String(\"A\")")
}

///|
test "Byte::to_json" {
  inspect(b'\x00'.to_json(), content="Number(0)")
  inspect(b'\xff'.to_json(), content="Number(255)")
  inspect(b'\x42'.to_json(), content="Number(66)")
}

///|
test "Iter[X] to_json" {
  let v = "a b c d".split(" ")
  @json.inspect(v, content=["a", "b", "c", "d"])
}
