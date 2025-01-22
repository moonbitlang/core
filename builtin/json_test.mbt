// Copyright 2025 International Digital Economy Academy
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

test "Json default value" {
  let j = @builtin.Json::default()
  inspect!(j, content="False")
}

test "Int64 to_json" {
  let i : Int64 = 42L
  inspect!(i.to_json(), content="String(\"42\")")
}

test "UInt to_json" {
  let x = 42U
  let json = UInt::to_json(x)
  inspect!(json, content="Number(42)")
}

test "double to json with positive infinity" {
  let pos_inf = 1.0 / 0.0
  inspect!(pos_inf.to_json(), content="Null")
}

test "test_float_to_json" {
  let float : Float = 3.14
  let json_val = float.to_json()
  inspect!(json_val, content="Number(3.140000104904175)")
}

test "to_json on empty fixed array" {
  let arr : FixedArray[Int] = FixedArray::make(0, 0)
  inspect!(arr.to_json(), content="Array([])")
}

test "test empty array view to json" {
  let arr : Array[Int] = []
  let view : ArrayView[Int] = arr[:]
  let json = @builtin.ArrayView::to_json(view)
  inspect!(json, content="Array([])")
}

test "test map with string values" {
  let m : Map[String, Int] = {}
  inspect!(m.to_json(), content="Object({})")
}

test "Option::to_json with None" {
  let none : Int? = None
  inspect!(none.to_json(), content="Null")
}

test "Option::to_json with Some value" {
  let some : Int? = Some(42)
  inspect!(some.to_json(), content="Array([Number(42)])")
}

test "Result to_json with Ok value" {
  let ok : Result[Int, String] = Ok(42)
  inspect!(ok.to_json(), content="Object({\"Ok\": Number(42)})")
}

test "Unit::to_json" {
  let r = ().to_json()
  inspect!(r, content="Null")
}

test "Bool::to_json false" {
  inspect!(false.to_json(), content="False")
}

test "test UInt64::to_json" {
  let num : UInt64 = UInt64::default()
  let json = num.to_json()
  inspect!(json, content="String(\"0\")")
}

test "escape control characters" {
  let str = "abc\x01def" // Control character with code 1
  let json = str.to_json()
  inspect!(json, content="String(\"abc\\\\u0001def\")")
}

test "test carriage return and backspace" {
  let test_string = "CR\rBS\b"
  let json = test_string.to_json()
  inspect!(json, content="String(\"CR\\\\rBS\\\\b\")")
}

test "test form feed" {
  let test_string = "Form\u000CFeed"
  let json = test_string.to_json()
  inspect!(json, content="String(\"Form\\\\fFeed\")")
}

test "to_json BigInt" {
  let n = BigInt::from_int(42)
  inspect!(@builtin.BigInt::to_json(n), content="String(\"42\")")
}

test "Result to_json with Err value" {
  let err : Result[Int, String] = Err("error")
  inspect!(err.to_json(), content="Object({\"Err\": String(\"error\")})")
}

test "Bool::to_json true" {
  let result = true.to_json()
  assert_eq!(result, Json::True)
}

test "to_hex_digit" {
  let str = "\n\r\b\t\x0C\x00"
  let escaped = str.to_json().as_string().unwrap()
  inspect!(escaped, content="\\n\\r\\b\\t\\f\\u0000")
}

test "Char::to_json converts char to JSON string" {
  let c = 'A'
  let json = c.to_json()
  inspect!(json, content="String(\"A\")")
}
