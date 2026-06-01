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
  debug_inspect(
    (j, h),
    content=(
      #|(Object({ "x": Number(3), "y": Number(4) }), { "x": 3, "y": 4 })
    ),
  )
}

///|
test {
  let u = Json::array([Json::number(1), Json::string("str")])
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(u) : Array[Int])),
    "expected Array[Int] decode failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Index(Root, index=1), "Int::from_json: expected number"))
    ),
  )
}

///|
test {
  let u = Json::object({
    "x": Json::object({ "xx": Json::number(1) }),
    "y": Json::object({ "yy": Json::string("str") }),
  })
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(u) : Map[String, Map[String, Double]])),
    "expected Map decode failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError(
      #|  (
      #|    Key(Key(Root, key="y"), key="yy"),
      #|    "Double::from_json: expected number",
      #|  ),
      #|)
    ),
  )
}

///|
test "tuple" {
  let u : Json = [1, 2]
  let v : (Int, Int) = @json.from_json(u)
  debug_inspect(v, content="(1, 2)")
  let u : Json = [1, 2, 3]
  let v : (Int, Int, Int) = @json.from_json(u)
  debug_inspect(v, content="(1, 2, 3)")
  let u : Json = [1, 2, 3, 4]
  let v : (Int, Int, Int, Int) = @json.from_json(u)
  debug_inspect(v, content="(1, 2, 3, 4)")
  let u : Json = [1, 2, 3, 4, 5]
  let v : (Int, Int, Int, Int, Int) = @json.from_json(u)
  debug_inspect(v, content="(1, 2, 3, 4, 5)")
  let u : Json = [1, 2, 3, 4, 5, 6]
  let v : (Int, Int, Int, Int, Int, Int) = @json.from_json(u)
  debug_inspect(v, content="(1, 2, 3, 4, 5, 6)")
  let u : Json = [1, 2, 3, 4, 5, 6, 7]
  let v : (Int, Int, Int, Int, Int, Int, Int) = @json.from_json(u)
  debug_inspect(v, content="(1, 2, 3, 4, 5, 6, 7)")
  let u : Json = [1, 2, 3, 4, 5, 6, 7, 8]
  let v : (Int, Int, Int, Int, Int, Int, Int, Int) = @json.from_json(u)
  debug_inspect(v, content="(1, 2, 3, 4, 5, 6, 7, 8)")
  let u : Json = [1, 2, 3, 4, 5, 6, 7, 8, 9]
  let v : (Int, Int, Int, Int, Int, Int, Int, Int, Int) = @json.from_json(u)
  debug_inspect(v, content="(1, 2, 3, 4, 5, 6, 7, 8, 9)")
  let u : Json = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  let v : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = @json.from_json(
    u,
  )
  debug_inspect(v, content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)")
  let u : Json = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
  let v : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = @json.from_json(
    u,
  )
  debug_inspect(v, content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11)")
  let u : Json = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
  let v : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = @json.from_json(
    u,
  )
  debug_inspect(v, content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)")
  let u : Json = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
  let v : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = @json.from_json(
    u,
  )
  debug_inspect(v, content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13)")
  let u : Json = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
  let v : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = @json.from_json(
    u,
  )
  debug_inspect(v, content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)")
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
  debug_inspect(
    v,
    content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)",
  )
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
  debug_inspect(
    v,
    content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16)",
  )
}

///|
test "tuple roundtrip" {
  let u = [1, 2]
  debug_inspect((@json.from_json(u.to_json()) : (Int, Int)), content="(1, 2)")
  let u = [1, 2, 3]
  debug_inspect(
    (@json.from_json(u.to_json()) : (Int, Int, Int)),
    content="(1, 2, 3)",
  )
  let u = [1, 2, 3, 4]
  debug_inspect(
    (@json.from_json(u.to_json()) : (Int, Int, Int, Int)),
    content="(1, 2, 3, 4)",
  )
  let u = [1, 2, 3, 4, 5]
  debug_inspect(
    (@json.from_json(u.to_json()) : (Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5)",
  )
  let u = [1, 2, 3, 4, 5, 6]
  debug_inspect(
    (@json.from_json(u.to_json()) : (Int, Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5, 6)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7]
  debug_inspect(
    (@json.from_json(u.to_json()) : (Int, Int, Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5, 6, 7)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7, 8]
  debug_inspect(
    (@json.from_json(u.to_json()) : (Int, Int, Int, Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5, 6, 7, 8)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7, 8, 9]
  debug_inspect(
    (
      @json.from_json(u.to_json()) :
      (Int, Int, Int, Int, Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5, 6, 7, 8, 9)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  debug_inspect(
    (
      @json.from_json(u.to_json()) :
      (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
  debug_inspect(
    (
      @json.from_json(u.to_json()) :
      (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
  debug_inspect(
    (
      @json.from_json(u.to_json()) :
      (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
  debug_inspect(
    (
      @json.from_json(u.to_json()) :
      (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
  debug_inspect(
    (
      @json.from_json(u.to_json()) :
      (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
  debug_inspect(
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
  debug_inspect(
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
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(u.to_json()) : (Int, Int, Int))),
    "expected tuple size error",
  )
  inspect(
    err,
    content=(
      #|JsonDecodeError((, expected tuple of size 3))
    ),
  )
  let u = ((1, 2), (3, 4))
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(ToJson::to_json(u)) : ((Int, Int), Int))),
    "expected tuple element error",
  )
  inspect(
    err,
    content=(
      #|JsonDecodeError((/1, Int::from_json: expected number))
    ),
  )
}

///|
test "fixedarray" {
  let u = ([1, 2] : FixedArray[_])
  let v : FixedArray[Int] = @json.from_json(u.to_json())
  debug_inspect(
    v,
    content=(
      #|<FixedArray: [1, 2]>
    ),
  )
  let u = (["123", "456"] : FixedArray[_])
  let v : FixedArray[String] = @json.from_json(u.to_json())
  debug_inspect(
    v,
    content=(
      #|<FixedArray: ["123", "456"]>
    ),
  )
  let u = ([(), ()] : FixedArray[Unit])
  let v : FixedArray[Unit] = @json.from_json(u.to_json())
  debug_inspect(
    v,
    content=(
      #|<FixedArray: [(), ()]>
    ),
  )
  let u = ([] : FixedArray[Unit])
  let v : FixedArray[Unit] = @json.from_json(u.to_json())
  debug_inspect(
    v,
    content=(
      #|<FixedArray: []>
    ),
  )
}

///|
test "Option" {
  let u : Json = (None : Int?).to_json()
  let v : Int? = @json.from_json(u)
  debug_inspect(v, content="None")
  let u = Some(1).to_json()
  let v : Int? = @json.from_json(u)
  debug_inspect(v, content="Some(1)")
  let nested : Json = (Some(None) : Unit??).to_json()
  let v : Unit?? = @json.from_json(nested)
  debug_inspect(v, content="Some(None)")
  let nested : Json = (Some(Some(None)) : Unit???).to_json()
  let v : Unit??? = @json.from_json(nested)
  debug_inspect(v, content="Some(Some(None))")
}

///|
test "Result" {
  let u : Json = (Ok(1) : Result[Int, String]).to_json()
  let v : Result[Int, String] = @json.from_json(u)
  debug_inspect(v, content="Ok(1)")
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
  debug_inspect(v, content="String(\"str\")")
  let u = Json::number(123)
  let v : Json = @json.from_json(u)
  debug_inspect(v, content="Number(123)")
  let u = Json::boolean(true)
  let v : Json = @json.from_json(u)
  debug_inspect(v, content="True")
  let u = Json::boolean(false)
  let v : Json = @json.from_json(u)
  debug_inspect(v, content="False")
  let u = null
  let v : Json = @json.from_json(u)
  debug_inspect(v, content="Null")
  let u = Json::array([Json::number(1), Json::string("str")])
  let v : Json = @json.from_json(u)
  debug_inspect(
    v,
    content=(
      #|Array([Number(1), String("str")])
    ),
  )
  let u = Json::object({ "x": Json::number(1) })
  let v : Json = @json.from_json(u)
  debug_inspect(
    v,
    content=(
      #|Object({ "x": Number(1) })
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
  let neg_err = expect_json_decode_error(
    () => ignore((@json.from_json(Json::number(-1)) : UInt)),
    "expected UInt overflow",
  )
  debug_inspect(
    neg_err,
    content=(
      #|JsonDecodeError((Root, "UInt::from_json: overflow"))
    ),
  )
  // overflow should error
  let ovf_err = expect_json_decode_error(
    () => ignore((@json.from_json(Json::number(4294967296)) : UInt)),
    "expected UInt overflow",
  )
  debug_inspect(
    ovf_err,
    content=(
      #|JsonDecodeError((Root, "UInt::from_json: overflow"))
    ),
  )
}

///|
test "Int from_json overflow should error" {
  let json = @json.parse("2147483648") // INT_MAX + 1 for 32-bit
  ignore(
    expect_json_decode_error(
      () => ignore((@json.from_json(json) : Int)),
      "BUG: Int overflow not detected",
    ),
  )
}

///|
test "Int from_json negative overflow should error" {
  let json = @json.parse("-2147483649") // INT_MIN - 1 for 32-bit
  ignore(
    expect_json_decode_error(
      () => ignore((@json.from_json(json) : Int)),
      "BUG: Int negative overflow not detected",
    ),
  )
}

///|
test "UInt from_json overflow should error" {
  let json = @json.parse("4294967296") // UINT_MAX + 1 for 32-bit
  ignore(
    expect_json_decode_error(
      () => ignore((@json.from_json(json) : UInt)),
      "BUG: UInt overflow not detected",
    ),
  )
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
  debug_inspect(
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
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(u) : Char)),
    "expected Char decode failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Root, "Char::from_json: invalid surrogate pair"))
    ),
  )
}

///|
test "char to/from json roundtrip" {
  let u = 'a'.to_json()
  debug_inspect(
    u,
    content=(
      #|String("a")
    ),
  )
  let v : Char = @json.from_json(u)
  inspect(v, content="a")

  // emoji char roundtrip
  let u = '😀'.to_json()
  debug_inspect(
    u,
    content=(
      #|String("😀")
    ),
  )
  let v : Char = @json.from_json(u)
  inspect(v, content="😀")

  // jdk char roundtrip
  let u = '中'.to_json()
  debug_inspect(
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
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(json_null) : Bool)),
    "expected Bool decode failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Root, "Bool::from_json: expected boolean"))
    ),
  )
  let json_number = Json::number(42)
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(json_number) : Bool)),
    "expected Bool decode failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Root, "Bool::from_json: expected boolean"))
    ),
  )
  let json_string = Json::string("true")
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(json_string) : Bool)),
    "expected Bool decode failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Root, "Bool::from_json: expected boolean"))
    ),
  )
}

///|
test "Int64 from_json error handling" {
  let json_number = Json::number(123)
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(json_number) : Int64)),
    "expected Int64 decode failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Root, "Int64::from_json: expected number in string representation"))
    ),
  )
  let json_invalid_string = Json::string("not a number")
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(json_invalid_string) : Int64)),
    "expected Int64 parse failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Root, "Int64::from_json: parsing failure invalid syntax"))
    ),
  )
}

///|
test "UInt from_json error handling" {
  let json_string = Json::string("123")
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(json_string) : UInt)),
    "expected UInt decode failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Root, "UInt::from_json: expected number"))
    ),
  )
}

///|
test "UInt64 from_json error handling" {
  let json_number = Json::number(123)
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(json_number) : UInt64)),
    "expected UInt64 decode failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Root, "UInt64::from_json: expected number in string representation"))
    ),
  )
  let json_invalid_string = Json::string("not a number")
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(json_invalid_string) : UInt64)),
    "expected UInt64 parse failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Root, "UInt64::from_json: parsing failure invalid syntax"))
    ),
  )
}

///|
test "String from_json error handling" {
  let json_number = Json::number(123)
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(json_number) : String)),
    "expected String decode failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Root, "String::from_json: expected string"))
    ),
  )
}

///|
test "String View from_json error handling" {
  let json_number = Json::number(123)
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(json_number) : StringView)),
    "expected StringView decode failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Root, "View::from_json: expected string"))
    ),
  )
}

///|
test "Char from_json error handling" {
  let json_number = Json::number(123)
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(json_number) : Char)),
    "expected Char decode failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Root, "Char::from_json: expected string"))
    ),
  )
  let json_empty_string = Json::string("")
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(json_empty_string) : Char)),
    "expected Char decode failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Root, "Char::from_json: expected single character"))
    ),
  )
  let json_long_string = Json::string("abc")
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(json_long_string) : Char)),
    "expected Char decode failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Root, "Char::from_json: expected single character"))
    ),
  )
}

///|
test "BigInt from_json error handling" {
  let json_number = Json::number(123)
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(json_number) : BigInt)),
    "expected BigInt decode failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Root, "BigInt::from_json: expected number in string representation"))
    ),
  )
}

///|
test "Array from_json error handling" {
  let json_string = Json::string("not an array")
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(json_string) : Array[Int])),
    "expected Array decode failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Root, "Array::from_json: expected array"))
    ),
  )
}

///|
test "FixedArray from_json error handling" {
  let json_string = Json::string("not an array")
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(json_string) : FixedArray[Int])),
    "expected FixedArray decode failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Root, "FixedArray::from_json: expected array"))
    ),
  )
}

///|
test "Map from_json error handling" {
  let json_array = Json::array([])
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(json_array) : Map[String, Int])),
    "expected Map decode failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Root, "Map::from_json: expected object"))
    ),
  )
}

///|
test "Option from_json error handling" {
  let json_string = Json::string("not an option")
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(json_string) : Int?)),
    "expected Option decode failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Root, "Option::from_json: expected array or null"))
    ),
  )
}

///|
test "Result from_json error handling" {
  let json_string = Json::string("not a result")
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(json_string) : Result[Int, String])),
    "expected Result decode failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Root, "Result::from_json: expected object"))
    ),
  )
  let json_empty_obj = Json::object({})
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(json_empty_obj) : Result[Int, String])),
    "expected Result decode failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Root, "Result::from_json: expected object with one field"))
    ),
  )
  let json_invalid_obj = Json::object({ "Invalid": Json::number(1) })
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(json_invalid_obj) : Result[Int, String])),
    "expected Result decode failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Root, "Result::from_json: expected object with Ok or Err field"))
    ),
  )
}

///|
test "Unit from_json error handling" {
  let json_string = Json::string("not null")
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(json_string) : Unit)),
    "expected Unit decode failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Root, "Unit::from_json: expected null"))
    ),
  )
}

///|
test "Bytes from_json" {
  let bytes = b"\x00\x01abcd\"\\"
  let json = bytes.to_json()
  let bytes : Bytes = @json.from_json(json)
  debug_inspect(
    bytes,
    content=(
      #|<Bytes: [0x00, 0x01, 0x61, 0x62, 0x63, 0x64, 0x22, 0x5c]>
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
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(json_string) : Float)),
    "expected Float decode failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Root, "Float::from_json: expected number"))
    ),
  )
  let json_array = Json::array([])
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(json_array) : Float)),
    "expected Float decode failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Root, "Float::from_json: expected number"))
    ),
  )
  let json_object = Json::object({})
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(json_object) : Float)),
    "expected Float decode failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Root, "Float::from_json: expected number"))
    ),
  )
  let json_null = null
  let err = expect_json_decode_error(
    () => ignore((@json.from_json(json_null) : Float)),
    "expected Float decode failure",
  )
  debug_inspect(
    err,
    content=(
      #|JsonDecodeError((Root, "Float::from_json: expected number"))
    ),
  )
}

///|
test "ArrayView::from_json" {
  let u = Json::array([Json::number(1), Json::number(2), Json::number(3)])
  let v : ArrayView[Int] = @json.from_json(u)
  debug_inspect(
    v,
    content=(
      #|<ArrayView: [1, 2, 3]>
    ),
  )
}

///|
test "from_json special cases" {
  let nan_value : Double = @json.from_json(Json::string("NaN"))
  @json.json_inspect(nan_value, content="NaN")
  let inf_value : Double = @json.from_json(Json::string("Infinity"))
  @json.json_inspect(inf_value, content="Infinity")
  let neg_inf_value : Double = @json.from_json(Json::string("-Infinity"))
  @json.json_inspect(neg_inf_value, content="-Infinity")
  let array_view_err = expect_json_decode_error(
    () => ignore((@json.from_json(Json::string("oops")) : ArrayView[Int])),
    "expected ArrayView::from_json error",
  )
  guard array_view_err
    is JsonDecodeError((_, "ArrayView::from_json: expected array")) else {
    fail("expected ArrayView::from_json error")
  }
  let bytes_type_err = expect_json_decode_error(
    () => ignore((@json.from_json(Json::number(1)) : Bytes)),
    "expected Bytes::from_json type error",
  )
  guard bytes_type_err
    is JsonDecodeError((_, "Bytes::from_json: expected string")) else {
    fail("expected Bytes::from_json type error")
  }
  let bytes_escape_err = expect_json_decode_error(
    () => ignore((@json.from_json(Json::string("bad\\\\")) : Bytes)),
    "expected Bytes::from_json escape error",
  )
  guard bytes_escape_err
    is JsonDecodeError((_, "Bytes::from_json: invalid escape sequence")) else {
    fail("expected Bytes::from_json escape error")
  }
  let bytes_invalid_err = expect_json_decode_error(
    () => ignore((@json.from_json(Json::string("\u{0}")) : Bytes)),
    "expected Bytes::from_json byte error",
  )
  guard bytes_invalid_err
    is JsonDecodeError((_, "Bytes::from_json: invalid byte sequence")) else {
    fail("expected Bytes::from_json byte error")
  }
}

///|
test "tuple size mismatch" {
  let wrong = [1].to_json()
  let err2 = expect_json_decode_error(
    () => ignore((@json.from_json(wrong) : (Int, Int))),
    "expected size 2 error",
  )
  guard err2 is JsonDecodeError((_, "expected tuple of size 2")) else {
    fail("expected size 2 error")
  }
  let err3 = expect_json_decode_error(
    () => ignore((@json.from_json(wrong) : (Int, Int, Int))),
    "expected size 3 error",
  )
  guard err3 is JsonDecodeError((_, "expected tuple of size 3")) else {
    fail("expected size 3 error")
  }
  let err4 = expect_json_decode_error(
    () => ignore((@json.from_json(wrong) : (Int, Int, Int, Int))),
    "expected size 4 error",
  )
  guard err4 is JsonDecodeError((_, "expected tuple of size 4")) else {
    fail("expected size 4 error")
  }
  let err5 = expect_json_decode_error(
    () => ignore((@json.from_json(wrong) : (Int, Int, Int, Int, Int))),
    "expected size 5 error",
  )
  guard err5 is JsonDecodeError((_, "expected tuple of size 5")) else {
    fail("expected size 5 error")
  }
  let err6 = expect_json_decode_error(
    () => ignore((@json.from_json(wrong) : (Int, Int, Int, Int, Int, Int))),
    "expected size 6 error",
  )
  guard err6 is JsonDecodeError((_, "expected tuple of size 6")) else {
    fail("expected size 6 error")
  }
  let err7 = expect_json_decode_error(
    () => ignore((@json.from_json(wrong) : (Int, Int, Int, Int, Int, Int, Int))),
    "expected size 7 error",
  )
  guard err7 is JsonDecodeError((_, "expected tuple of size 7")) else {
    fail("expected size 7 error")
  }
  let err8 = expect_json_decode_error(
    () => {
      ignore(
        (@json.from_json(wrong) : (Int, Int, Int, Int, Int, Int, Int, Int)),
      )
    },
    "expected size 8 error",
  )
  guard err8 is JsonDecodeError((_, "expected tuple of size 8")) else {
    fail("expected size 8 error")
  }
  let err9 = expect_json_decode_error(
    () => {
      let _ : (Int, Int, Int, Int, Int, Int, Int, Int, Int) = @json.from_json(
        wrong,
      )
      ()
    },
    "expected size 9 error",
  )
  guard err9 is JsonDecodeError((_, "expected tuple of size 9")) else {
    fail("expected size 9 error")
  }
  let err10 = expect_json_decode_error(
    () => {
      let _ : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = @json.from_json(
        wrong,
      )
      ()
    },
    "expected size 10 error",
  )
  guard err10 is JsonDecodeError((_, "expected tuple of size 10")) else {
    fail("expected size 10 error")
  }
  let err11 = expect_json_decode_error(
    () => {
      let _ : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = @json.from_json(
        wrong,
      )
      ()
    },
    "expected size 11 error",
  )
  guard err11 is JsonDecodeError((_, "expected tuple of size 11")) else {
    fail("expected size 11 error")
  }
  let err12 = expect_json_decode_error(
    () => {
      let _ : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = @json.from_json(
        wrong,
      )
      ()
    },
    "expected size 12 error",
  )
  guard err12 is JsonDecodeError((_, "expected tuple of size 12")) else {
    fail("expected size 12 error")
  }
  let err13 = expect_json_decode_error(
    () => {
      let _ : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = @json.from_json(
        wrong,
      )
      ()
    },
    "expected size 13 error",
  )
  guard err13 is JsonDecodeError((_, "expected tuple of size 13")) else {
    fail("expected size 13 error")
  }
  let err14 = expect_json_decode_error(
    () => {
      let _ : (
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
      ) = @json.from_json(wrong)
      ()
    },
    "expected size 14 error",
  )
  guard err14 is JsonDecodeError((_, "expected tuple of size 14")) else {
    fail("expected size 14 error")
  }
  let err15 = expect_json_decode_error(
    () => {
      let _ : (
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
      ) = @json.from_json(wrong)
      ()
    },
    "expected size 15 error",
  )
  guard err15 is JsonDecodeError((_, "expected tuple of size 15")) else {
    fail("expected size 15 error")
  }
  let err16 = expect_json_decode_error(
    () => {
      let _ : (
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
      ) = @json.from_json(wrong)
      ()
    },
    "expected size 16 error",
  )
  guard err16 is JsonDecodeError((_, "expected tuple of size 16")) else {
    fail("expected size 16 error")
  }
}
