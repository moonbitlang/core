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
type TestX = Map[String, Int]

///|
test {
  let u = { "x": 3, "y": 4 }
  let j = u.to_json()
  let h : TestX = @json.from_json(j)
  inspect(
    (j, h),
    content=(
      #|(Object({"x": Number(3), "y": Number(4)}), {"x": 3, "y": 4})
    ),
  )
}

///|
test {
  let u = Json::array([Json::number(1), Json::string("str")])
  let v : Result[Array[Int], _] = try? @json.from_json(u)
  inspect(
    v,
    content=(
      #|Err(JsonDecodeError((/1, "Int::from_json: expected number")))
    ),
  )
}

///|
test {
  let u = Json::object({
    "x": Json::object({ "xx": Json::number(1) }),
    "y": Json::object({ "yy": Json::string("str") }),
  })
  let v : Result[Map[String, Map[String, Double]], _] = try? @json.from_json(u)
  inspect(
    v,
    content=(
      #|Err(JsonDecodeError((/y/yy, "Double::from_json: expected number")))
    ),
  )
}

///|
test "tuple" {
  let u : Json = [1, 2]
  let v : (Int, Int) = @json.from_json(u)
  inspect(v, content="(1, 2)")
  let u : Json = [1, 2, 3]
  let v : (Int, Int, Int) = @json.from_json(u)
  inspect(v, content="(1, 2, 3)")
  let u : Json = [1, 2, 3, 4]
  let v : (Int, Int, Int, Int) = @json.from_json(u)
  inspect(v, content="(1, 2, 3, 4)")
  let u : Json = [1, 2, 3, 4, 5]
  let v : (Int, Int, Int, Int, Int) = @json.from_json(u)
  inspect(v, content="(1, 2, 3, 4, 5)")
  let u : Json = [1, 2, 3, 4, 5, 6]
  let v : (Int, Int, Int, Int, Int, Int) = @json.from_json(u)
  inspect(v, content="(1, 2, 3, 4, 5, 6)")
  let u : Json = [1, 2, 3, 4, 5, 6, 7]
  let v : (Int, Int, Int, Int, Int, Int, Int) = @json.from_json(u)
  inspect(v, content="(1, 2, 3, 4, 5, 6, 7)")
  let u : Json = [1, 2, 3, 4, 5, 6, 7, 8]
  let v : (Int, Int, Int, Int, Int, Int, Int, Int) = @json.from_json(u)
  inspect(v, content="(1, 2, 3, 4, 5, 6, 7, 8)")
  let u : Json = [1, 2, 3, 4, 5, 6, 7, 8, 9]
  let v : (Int, Int, Int, Int, Int, Int, Int, Int, Int) = @json.from_json(u)
  inspect(v, content="(1, 2, 3, 4, 5, 6, 7, 8, 9)")
  let u : Json = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  let v : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = @json.from_json(
    u,
  )
  inspect(v, content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)")
  let u : Json = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
  let v : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = @json.from_json(
    u,
  )
  inspect(v, content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11)")
  let u : Json = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
  let v : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = @json.from_json(
    u,
  )
  inspect(v, content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)")
  let u : Json = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
  let v : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = @json.from_json(
    u,
  )
  inspect(v, content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13)")
  let u : Json = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
  let v : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = @json.from_json(
    u,
  )
  inspect(v, content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)")
  let u : Json = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
  let v : (
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
  ) = @json.from_json(u)
  inspect(v, content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)")
  let u : Json = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
  let v : (
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
  ) = @json.from_json(u)
  inspect(v, content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16)")
}

///|
test "tuple roundtrip" {
  let u = [1, 2]
  inspect((@json.from_json(u.to_json()) : (Int, Int)), content="(1, 2)")
  let u = [1, 2, 3]
  inspect((@json.from_json(u.to_json()) : (Int, Int, Int)), content="(1, 2, 3)")
  let u = [1, 2, 3, 4]
  inspect(
    (@json.from_json(u.to_json()) : (Int, Int, Int, Int)),
    content="(1, 2, 3, 4)",
  )
  let u = [1, 2, 3, 4, 5]
  inspect(
    (@json.from_json(u.to_json()) : (Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5)",
  )
  let u = [1, 2, 3, 4, 5, 6]
  inspect(
    (@json.from_json(u.to_json()) : (Int, Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5, 6)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7]
  inspect(
    (@json.from_json(u.to_json()) : (Int, Int, Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5, 6, 7)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7, 8]
  inspect(
    (@json.from_json(u.to_json()) : (Int, Int, Int, Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5, 6, 7, 8)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7, 8, 9]
  inspect(
    (
      @json.from_json(u.to_json()) :
      (Int, Int, Int, Int, Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5, 6, 7, 8, 9)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  inspect(
    (
      @json.from_json(u.to_json()) :
      (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
  inspect(
    (
      @json.from_json(u.to_json()) :
      (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
  inspect(
    (
      @json.from_json(u.to_json()) :
      (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
  inspect(
    (
      @json.from_json(u.to_json()) :
      (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
  inspect(
    (
      @json.from_json(u.to_json()) :
      (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
  inspect(
    (
      @json.from_json(u.to_json()) :
      (
        Int,
        Int,
        Int,
        Int,
        Int,
        Int,
        Int,
        Int,
        Int,
        Int,
        Int,
        Int,
        Int,
        Int,
        Int,
      )),
    content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
  inspect(
    (
      @json.from_json(u.to_json()) :
      (
        Int,
        Int,
        Int,
        Int,
        Int,
        Int,
        Int,
        Int,
        Int,
        Int,
        Int,
        Int,
        Int,
        Int,
        Int,
        Int,
      )),
    content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16)",
  )
}

///|
test "tuple failure" {
  let u = [1, 2]
  let v : Result[(Int, Int, Int), _] = try? @json.from_json(u.to_json())
  inspect(
    v.unwrap_err(),
    content=(
      #|JsonDecodeError((, "expected tuple of size 3"))
    ),
  )
  let u = ((1, 2), (3, 4))
  let v : Result[((Int, Int), Int), _] = try? @json.from_json(
    ToJson::to_json(u),
  )
  inspect(
    v.unwrap_err(),
    content=(
      #|JsonDecodeError((/1, "Int::from_json: expected number"))
    ),
  )
}

///|
test "fixedarray" {
  let u = ([1, 2] : FixedArray[_])
  let v : FixedArray[Int] = @json.from_json(u.to_json())
  inspect(v, content="[1, 2]")
  let u = (["123", "456"] : FixedArray[_])
  let v : FixedArray[String] = @json.from_json(u.to_json())
  inspect(
    v,
    content=(
      #|["123", "456"]
    ),
  )
  let u = ([(), ()] : FixedArray[Unit])
  let v : FixedArray[Unit] = @json.from_json(u.to_json())
  inspect(v, content="[(), ()]")
  let u = ([] : FixedArray[Unit])
  let v : FixedArray[Unit] = @json.from_json(u.to_json())
  inspect(v, content="[]")
}

///|
test "Option" {
  let u : Json = (None : Int?).to_json()
  let v : Int? = @json.from_json(u)
  inspect(v, content="None")
  let u = Some(1).to_json()
  let v : Int? = @json.from_json(u)
  inspect(v, content="Some(1)")
  let nested : Json = (Some(None) : Unit??).to_json()
  let v : Unit?? = @json.from_json(nested)
  inspect(v, content="Some(None)")
  let nested : Json = (Some(Some(None)) : Unit???).to_json()
  let v : Unit??? = @json.from_json(nested)
  inspect(v, content="Some(Some(None))")
}

///|
test "Result" {
  let u : Json = (Ok(1) : Result[Int, String]).to_json()
  let v : Result[Int, String] = @json.from_json(u)
  inspect(v, content="Ok(1)")
  let u = (Err("error") : Result[Int, String]).to_json()
  let v : Result[Int, String] = @json.from_json(u)
  inspect(v.unwrap_err(), content="error")
}

///|
test "Unit" {
  let u = ().to_json()
  let v : Unit = @json.from_json(u)
  inspect(v, content="()")
}

///|
test "bigint" {
  let u = BigInt::from_string("10238490123489120893478175871203124819").to_json()
  let v : BigInt = @json.from_json(u)
  inspect(v, content="10238490123489120893478175871203124819")
}

///|
test "jsonvalue" {
  let u = Json::string("str")
  let v : Json = @json.from_json(u)
  inspect(v, content="String(\"str\")")
  let u = Json::number(123)
  let v : Json = @json.from_json(u)
  inspect(v, content="Number(123)")
  let u = Json::boolean(true)
  let v : Json = @json.from_json(u)
  inspect(v, content="True")
  let u = Json::boolean(false)
  let v : Json = @json.from_json(u)
  inspect(v, content="False")
  let u = null
  let v : Json = @json.from_json(u)
  inspect(v, content="Null")
  let u = Json::array([Json::number(1), Json::string("str")])
  let v : Json = @json.from_json(u)
  inspect(
    v,
    content=(
      #|Array([Number(1), String("str")])
    ),
  )
  let u = Json::object({ "x": Json::number(1) })
  let v : Json = @json.from_json(u)
  inspect(
    v,
    content=(
      #|Object({"x": Number(1)})
    ),
  )
}

///|
test "bool roundtrip" {
  let u = true.to_json()
  let v : Bool = @json.from_json(u)
  inspect(v, content="true")
  let u = false.to_json()
  let v : Bool = @json.from_json(u)
  inspect(v, content="false")
}

///|
test "int roundtrip" {
  let u = (123).to_json()
  let v : Int = @json.from_json(u)
  inspect(v, content="123")
  let u = (-123).to_json()
  let v : Int = @json.from_json(u)
  inspect(v, content="-123")
}

///|
test "uint roundtrip" {
  let u = 123U.to_json()
  let v : UInt = @json.from_json(u)
  inspect(v, content="123")
  let u = 4294967295U.to_json()
  let v : UInt = @json.from_json(u)
  inspect(v, content="4294967295")
}

///|
test "uint" {
  // valid max
  let v : UInt = @json.from_json(Json::number(4294967295))
  inspect(v, content="4294967295")
  // negative should error
  let neg_res : Result[UInt, _] = try? @json.from_json(Json::number(-1))
  inspect(
    neg_res,
    content=(
      #|Err(JsonDecodeError((, "UInt::from_json: overflow")))
    ),
  )
  // overflow should error
  let ovf_res : Result[UInt, _] = try? @json.from_json(Json::number(4294967296))
  inspect(
    ovf_res,
    content=(
      #|Err(JsonDecodeError((, "UInt::from_json: overflow")))
    ),
  )
}

///|
test "Int from_json overflow should error" {
  let json = @json.parse("2147483648") // INT_MAX + 1 for 32-bit
  let res : Result[Int, _] = try? @json.from_json(json)
  match res {
    Ok(v) => fail("BUG: Int overflow not detected, decoded as \{v}")
    Err(_) => ()
  }
}

///|
test "Int from_json negative overflow should error" {
  let json = @json.parse("-2147483649") // INT_MIN - 1 for 32-bit
  let res : Result[Int, _] = try? @json.from_json(json)
  match res {
    Ok(v) => fail("BUG: Int negative overflow not detected, decoded as \{v}")
    Err(_) => ()
  }
}

///|
test "UInt from_json overflow should error" {
  let json = @json.parse("4294967296") // UINT_MAX + 1 for 32-bit
  let res : Result[UInt, _] = try? @json.from_json(json)
  match res {
    Ok(v) => fail("BUG: UInt overflow not detected, decoded as \{v}")
    Err(_) => ()
  }
}

///|
test "int64 roundtrip" {
  let u = 123L.to_json()
  let v : Int64 = @json.from_json(u)
  inspect(v, content="123")
  let u = 9223372036854775807L.to_json()
  let v : Int64 = @json.from_json(u)
  inspect(v, content="9223372036854775807")
  let u = (-9223372036854775808L).to_json()
  let v : Int64 = @json.from_json(u)
  inspect(v, content="-9223372036854775808")
}

///|
test "uint64 roundtrip" {
  let u = 123UL.to_json()
  let v : UInt64 = @json.from_json(u)
  inspect(v, content="123")
  let u = 18446744073709551615UL.to_json()
  let v : UInt64 = @json.from_json(u)
  inspect(v, content="18446744073709551615")
}

///|
test "unicode" {
  let u = "\u{1F600}".to_json()
  inspect(
    u,
    content=(
      #|String("😀")
    ),
  )
  let v : Char = @json.from_json(u)
  inspect(v, content="\u{1F600}")
  let bs : Bytes = [0x3D, 0xD8, 0x00, 0xDE]
  let u = bs.to_unchecked_string().to_json()
  let v : Char = @json.from_json(u)
  inspect(v, content="\u{1F600}")
  let bs1 : Bytes = [0xD8, 0x3D, 0xDE, 0x00]
  let u = bs1.to_unchecked_string().to_json()
  let v : Result[Char, _] = try? @json.from_json(u)
  inspect(
    v,
    content=(
      #|Err(JsonDecodeError((, "Char::from_json: invalid surrogate pair")))
    ),
  )
}

///|
test "char to/from json roundtrip" {
  let u = 'a'.to_json()
  inspect(
    u,
    content=(
      #|String("a")
    ),
  )
  let v : Char = @json.from_json(u)
  inspect(v, content="a")

  // emoji char roundtrip
  let u = '😀'.to_json()
  inspect(
    u,
    content=(
      #|String("😀")
    ),
  )
  let v : Char = @json.from_json(u)
  inspect(v, content="😀")

  // jdk char roundtrip
  let u = '中'.to_json()
  inspect(
    u,
    content=(
      #|String("中")
    ),
  )
  let v : Char = @json.from_json(u)
  inspect(v, content="中")
}

///|
test "string view from json" {
  let u = "hello".to_json()
  let v : StringView = @json.from_json(u)
  inspect(v, content="hello")
}

///|
test "Bool from_json error handling" {
  let json_null = null
  let result : Result[Bool, _] = try? @json.from_json(json_null)
  inspect(
    result,
    content=(
      #|Err(JsonDecodeError((, "Bool::from_json: expected boolean")))
    ),
  )
  let json_number = Json::number(42)
  let result : Result[Bool, _] = try? @json.from_json(json_number)
  inspect(
    result,
    content=(
      #|Err(JsonDecodeError((, "Bool::from_json: expected boolean")))
    ),
  )
  let json_string = Json::string("true")
  let result : Result[Bool, _] = try? @json.from_json(json_string)
  inspect(
    result,
    content=(
      #|Err(JsonDecodeError((, "Bool::from_json: expected boolean")))
    ),
  )
}

///|
test "Int64 from_json error handling" {
  let json_number = Json::number(123)
  let result : Result[Int64, _] = try? @json.from_json(json_number)
  inspect(
    result,
    content=(
      #|Err(JsonDecodeError((, "Int64::from_json: expected number in string representation")))
    ),
  )
  let json_invalid_string = Json::string("not a number")
  let result : Result[Int64, _] = try? @json.from_json(json_invalid_string)
  inspect(
    result,
    content=(
      #|Err(JsonDecodeError((, "Int64::from_json: parsing failure invalid syntax")))
    ),
  )
}

///|
test "UInt from_json error handling" {
  let json_string = Json::string("123")
  let result : Result[UInt, _] = try? @json.from_json(json_string)
  inspect(
    result,
    content=(
      #|Err(JsonDecodeError((, "UInt::from_json: expected number")))
    ),
  )
}

///|
test "UInt64 from_json error handling" {
  let json_number = Json::number(123)
  let result : Result[UInt64, _] = try? @json.from_json(json_number)
  inspect(
    result,
    content=(
      #|Err(JsonDecodeError((, "UInt64::from_json: expected number in string representation")))
    ),
  )
  let json_invalid_string = Json::string("not a number")
  let result : Result[UInt64, _] = try? @json.from_json(json_invalid_string)
  inspect(
    result,
    content=(
      #|Err(JsonDecodeError((, "UInt64::from_json: parsing failure invalid syntax")))
    ),
  )
}

///|
test "String from_json error handling" {
  let json_number = Json::number(123)
  let result : Result[String, _] = try? @json.from_json(json_number)
  inspect(
    result,
    content=(
      #|Err(JsonDecodeError((, "String::from_json: expected string")))
    ),
  )
}

///|
test "String View from_json error handling" {
  let json_number = Json::number(123)
  let result : Result[StringView, _] = try? @json.from_json(json_number)
  inspect(
    result,
    content=(
      #|Err(JsonDecodeError((, "View::from_json: expected string")))
    ),
  )
}

///|
test "Char from_json error handling" {
  let json_number = Json::number(123)
  let result : Result[Char, _] = try? @json.from_json(json_number)
  inspect(
    result,
    content=(
      #|Err(JsonDecodeError((, "Char::from_json: expected string")))
    ),
  )
  let json_empty_string = Json::string("")
  let result : Result[Char, _] = try? @json.from_json(json_empty_string)
  inspect(
    result,
    content=(
      #|Err(JsonDecodeError((, "Char::from_json: expected single character")))
    ),
  )
  let json_long_string = Json::string("abc")
  let result : Result[Char, _] = try? @json.from_json(json_long_string)
  inspect(
    result,
    content=(
      #|Err(JsonDecodeError((, "Char::from_json: expected single character")))
    ),
  )
}

///|
test "BigInt from_json error handling" {
  let json_number = Json::number(123)
  let result : Result[BigInt, _] = try? @json.from_json(json_number)
  inspect(
    result,
    content=(
      #|Err(JsonDecodeError((, "BigInt::from_json: expected number in string representation")))
    ),
  )
}

///|
test "Array from_json error handling" {
  let json_string = Json::string("not an array")
  let result : Result[Array[Int], _] = try? @json.from_json(json_string)
  inspect(
    result,
    content=(
      #|Err(JsonDecodeError((, "Array::from_json: expected array")))
    ),
  )
}

///|
test "FixedArray from_json error handling" {
  let json_string = Json::string("not an array")
  let result : Result[FixedArray[Int], _] = try? @json.from_json(json_string)
  inspect(
    result,
    content=(
      #|Err(JsonDecodeError((, "FixedArray::from_json: expected array")))
    ),
  )
}

///|
test "Map from_json error handling" {
  let json_array = Json::array([])
  let result : Result[Map[String, Int], _] = try? @json.from_json(json_array)
  inspect(
    result,
    content=(
      #|Err(JsonDecodeError((, "Map::from_json: expected object")))
    ),
  )
}

///|
test "Option from_json error handling" {
  let json_string = Json::string("not an option")
  let result : Result[Int?, _] = try? @json.from_json(json_string)
  inspect(
    result,
    content=(
      #|Err(JsonDecodeError((, "Option::from_json: expected array or null")))
    ),
  )
}

///|
test "Result from_json error handling" {
  let json_string = Json::string("not a result")
  let result : Result[Result[Int, String], _] = try? @json.from_json(
    json_string,
  )
  inspect(
    result,
    content=(
      #|Err(JsonDecodeError((, "Result::from_json: expected object")))
    ),
  )
  let json_empty_obj = Json::object({})
  let result : Result[Result[Int, String], _] = try? @json.from_json(
    json_empty_obj,
  )
  inspect(
    result,
    content=(
      #|Err(JsonDecodeError((, "Result::from_json: expected object with one field")))
    ),
  )
  let json_invalid_obj = Json::object({ "Invalid": Json::number(1) })
  let result : Result[Result[Int, String], _] = try? @json.from_json(
    json_invalid_obj,
  )
  inspect(
    result,
    content=(
      #|Err(JsonDecodeError((, "Result::from_json: expected object with Ok or Err field")))
    ),
  )
}

///|
test "Unit from_json error handling" {
  let json_string = Json::string("not null")
  let result : Result[Unit, _] = try? @json.from_json(json_string)
  inspect(
    result,
    content=(
      #|Err(JsonDecodeError((, "Unit::from_json: expected null")))
    ),
  )
}

///|
test "Bytes from_json" {
  let bytes = b"\x00\x01abcd\"\\"
  let json = bytes.to_json()
  let result : Result[Bytes, _] = try? @json.from_json(json)
  inspect(
    result,
    content=(
      #|Ok(b"\x00\x01abcd\x22\x5c")
    ),
  )
}

///|
test "float roundtrip" {
  let u = (3.14 : Float).to_json()
  let v : Float = @json.from_json(u)
  inspect(v, content="3.140000104904175")
  let u = (0.0 : Float).to_json()
  let v : Float = @json.from_json(u)
  inspect(v, content="0")
  let u = (-1.5 : Float).to_json()
  let v : Float = @json.from_json(u)
  inspect(v, content="-1.5")
}

///|
test "float special values" {
  // Test NaN
  let u = Json::string("NaN")
  let v : Float = @json.from_json(u)
  inspect(v, content="NaN")

  // Test Infinity
  let u = Json::string("Infinity")
  let v : Float = @json.from_json(u)
  inspect(v, content="Infinity")

  // Test -Infinity
  let u = Json::string("-Infinity")
  let v : Float = @json.from_json(u)
  inspect(v, content="-Infinity")

  // Test regular number
  let u = Json::number(42.5)
  let v : Float = @json.from_json(u)
  inspect(v, content="42.5")
}

///|
test "Float from_json error handling" {
  let json_string = Json::string("not a number")
  let result : Result[Float, _] = try? @json.from_json(json_string)
  inspect(
    result,
    content=(
      #|Err(JsonDecodeError((, "Float::from_json: expected number")))
    ),
  )
  let json_array = Json::array([])
  let result : Result[Float, _] = try? @json.from_json(json_array)
  inspect(
    result,
    content=(
      #|Err(JsonDecodeError((, "Float::from_json: expected number")))
    ),
  )
  let json_object = Json::object({})
  let result : Result[Float, _] = try? @json.from_json(json_object)
  inspect(
    result,
    content=(
      #|Err(JsonDecodeError((, "Float::from_json: expected number")))
    ),
  )
  let json_null = null
  let result : Result[Float, _] = try? @json.from_json(json_null)
  inspect(
    result,
    content=(
      #|Err(JsonDecodeError((, "Float::from_json: expected number")))
    ),
  )
}

///|
test "ArrayView::from_json" {
  let u = Json::array([Json::number(1), Json::number(2), Json::number(3)])
  let v : ArrayView[Int] = @json.from_json(u)
  inspect(v, content="[1, 2, 3]")
}

///|
test "from_json special cases" {
  let nan_value : Double = @json.from_json(Json::string("NaN"))
  @json.inspect(nan_value, content="NaN")
  let inf_value : Double = @json.from_json(Json::string("Infinity"))
  @json.inspect(inf_value, content="Infinity")
  let neg_inf_value : Double = @json.from_json(Json::string("-Infinity"))
  @json.inspect(neg_inf_value, content="-Infinity")
  let array_view_result : Result[ArrayView[Int], _] = try? @json.from_json(
    Json::string("oops"),
  )
  guard array_view_result
    is Err(JsonDecodeError((_, "ArrayView::from_json: expected array"))) else {
    fail("expected ArrayView::from_json error")
  }
  let bytes_type_result : Result[Bytes, _] = try? @json.from_json(
    Json::number(1),
  )
  guard bytes_type_result
    is Err(JsonDecodeError((_, "Bytes::from_json: expected string"))) else {
    fail("expected Bytes::from_json type error")
  }
  let bytes_escape_result : Result[Bytes, _] = try? @json.from_json(
    Json::string("bad\\\\"),
  )
  guard bytes_escape_result
    is Err(JsonDecodeError((_, "Bytes::from_json: invalid escape sequence"))) else {
    fail("expected Bytes::from_json escape error")
  }
  let bytes_invalid_result : Result[Bytes, _] = try? @json.from_json(
    Json::string("\u{0}"),
  )
  guard bytes_invalid_result
    is Err(JsonDecodeError((_, "Bytes::from_json: invalid byte sequence"))) else {
    fail("expected Bytes::from_json byte error")
  }
}

///|
test "tuple size mismatch" {
  let wrong = [1].to_json()
  let res2 : Result[(Int, Int), _] = try? @json.from_json(wrong)
  guard res2 is Err(JsonDecodeError((_, "expected tuple of size 2"))) else {
    fail("expected size 2 error")
  }
  let res3 : Result[(Int, Int, Int), _] = try? @json.from_json(wrong)
  guard res3 is Err(JsonDecodeError((_, "expected tuple of size 3"))) else {
    fail("expected size 3 error")
  }
  let res4 : Result[(Int, Int, Int, Int), _] = try? @json.from_json(wrong)
  guard res4 is Err(JsonDecodeError((_, "expected tuple of size 4"))) else {
    fail("expected size 4 error")
  }
  let res5 : Result[(Int, Int, Int, Int, Int), _] = try? @json.from_json(wrong)
  guard res5 is Err(JsonDecodeError((_, "expected tuple of size 5"))) else {
    fail("expected size 5 error")
  }
  let res6 : Result[(Int, Int, Int, Int, Int, Int), _] = try? @json.from_json(
    wrong,
  )
  guard res6 is Err(JsonDecodeError((_, "expected tuple of size 6"))) else {
    fail("expected size 6 error")
  }
  let res7 : Result[(Int, Int, Int, Int, Int, Int, Int), _] = try? @json.from_json(
    wrong,
  )
  guard res7 is Err(JsonDecodeError((_, "expected tuple of size 7"))) else {
    fail("expected size 7 error")
  }
  let res8 : Result[(Int, Int, Int, Int, Int, Int, Int, Int), _] = try? @json.from_json(
    wrong,
  )
  guard res8 is Err(JsonDecodeError((_, "expected tuple of size 8"))) else {
    fail("expected size 8 error")
  }
  let res9 : Result[(Int, Int, Int, Int, Int, Int, Int, Int, Int), _] = try? @json.from_json(
    wrong,
  )
  guard res9 is Err(JsonDecodeError((_, "expected tuple of size 9"))) else {
    fail("expected size 9 error")
  }
  let res10 : Result[(Int, Int, Int, Int, Int, Int, Int, Int, Int, Int), _] = try? @json.from_json(
    wrong,
  )
  guard res10 is Err(JsonDecodeError((_, "expected tuple of size 10"))) else {
    fail("expected size 10 error")
  }
  let res11 : Result[(Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int), _] = try? @json.from_json(
    wrong,
  )
  guard res11 is Err(JsonDecodeError((_, "expected tuple of size 11"))) else {
    fail("expected size 11 error")
  }
  let res12 : Result[
    (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int),
    _,
  ] = try? @json.from_json(wrong)
  guard res12 is Err(JsonDecodeError((_, "expected tuple of size 12"))) else {
    fail("expected size 12 error")
  }
  let res13 : Result[
    (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int),
    _,
  ] = try? @json.from_json(wrong)
  guard res13 is Err(JsonDecodeError((_, "expected tuple of size 13"))) else {
    fail("expected size 13 error")
  }
  let res14 : Result[
    (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int),
    _,
  ] = try? @json.from_json(wrong)
  guard res14 is Err(JsonDecodeError((_, "expected tuple of size 14"))) else {
    fail("expected size 14 error")
  }
  let res15 : Result[
    (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int),
    _,
  ] = try? @json.from_json(wrong)
  guard res15 is Err(JsonDecodeError((_, "expected tuple of size 15"))) else {
    fail("expected size 15 error")
  }
  let res16 : Result[
    (
      Int,
      Int,
      Int,
      Int,
      Int,
      Int,
      Int,
      Int,
      Int,
      Int,
      Int,
      Int,
      Int,
      Int,
      Int,
      Int,
    ),
    _,
  ] = try? @json.from_json(wrong)
  guard res16 is Err(JsonDecodeError((_, "expected tuple of size 16"))) else {
    fail("expected size 16 error")
  }
}
