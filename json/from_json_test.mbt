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

///|
/// FIXME: remove later, workaround formatter bug
fn temp() -> Unit {
  ()
}

///|
typealias TestX = Map[String, Int]

///|
test {
  let _ = temp()
  let u = { "x": 3, "y": 4 }
  let j = u.to_json()
  let h : TestX = @json.from_json!(j)
  inspect!(
    (j, h),
    content=
      #|(Object({"x": Number(3), "y": Number(4)}), {"x": 3, "y": 4})
    ,
  )
}

///|
test {
  let u = Json::Array([Json::Number(1), Json::String("str")])
  let v : Result[Array[Int], _] = @json.from_json?(u)
  inspect!(
    v,
    content=
      #|Err(JsonDecodeError(($[1], "Int::from_json: expected number")))
    ,
  )
}

///|
test {
  let u = Json::Object({
    "x": Json::Object({ "xx": Json::Number(1) }),
    "y": Json::Object({ "yy": Json::String("str") }),
  })
  let v : Result[Map[String, Map[String, Double]], _] = @json.from_json?(u)
  inspect!(
    v,
    content=
      #|Err(JsonDecodeError(($.y.yy, "Double::from_json: expected number")))
    ,
  )
}

///|
test "tuple" {
  let u : Json = [1, 2]
  let v : (Int, Int) = @json.from_json!(u)
  inspect!(v, content="(1, 2)")
  let u : Json = [1, 2, 3]
  let v : (Int, Int, Int) = @json.from_json!(u)
  inspect!(v, content="(1, 2, 3)")
  let u : Json = [1, 2, 3, 4]
  let v : (Int, Int, Int, Int) = @json.from_json!(u)
  inspect!(v, content="(1, 2, 3, 4)")
  let u : Json = [1, 2, 3, 4, 5]
  let v : (Int, Int, Int, Int, Int) = @json.from_json!(u)
  inspect!(v, content="(1, 2, 3, 4, 5)")
  let u : Json = [1, 2, 3, 4, 5, 6]
  let v : (Int, Int, Int, Int, Int, Int) = @json.from_json!(u)
  inspect!(v, content="(1, 2, 3, 4, 5, 6)")
  let u : Json = [1, 2, 3, 4, 5, 6, 7]
  let v : (Int, Int, Int, Int, Int, Int, Int) = @json.from_json!(u)
  inspect!(v, content="(1, 2, 3, 4, 5, 6, 7)")
  let u : Json = [1, 2, 3, 4, 5, 6, 7, 8]
  let v : (Int, Int, Int, Int, Int, Int, Int, Int) = @json.from_json!(u)
  inspect!(v, content="(1, 2, 3, 4, 5, 6, 7, 8)")
  let u : Json = [1, 2, 3, 4, 5, 6, 7, 8, 9]
  let v : (Int, Int, Int, Int, Int, Int, Int, Int, Int) = @json.from_json!(u)
  inspect!(v, content="(1, 2, 3, 4, 5, 6, 7, 8, 9)")
  let u : Json = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  let v : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = @json.from_json!(
    u,
  )
  inspect!(v, content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)")
  let u : Json = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
  let v : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = @json.from_json!(
    u,
  )
  inspect!(v, content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11)")
  let u : Json = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
  let v : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = @json.from_json!(
    u,
  )
  inspect!(v, content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)")
  let u : Json = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
  let v : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = @json.from_json!(
    u,
  )
  inspect!(v, content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13)")
  let u : Json = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
  let v : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = @json.from_json!(
    u,
  )
  inspect!(v, content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)")
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
  ) = @json.from_json!(u)
  inspect!(v, content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)")
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
  ) = @json.from_json!(u)
  inspect!(v, content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16)")
}

///|
test "tuple roundtrip" {
  let u = [1, 2]
  inspect!((@json.from_json!(u.to_json()) : (Int, Int)), content="(1, 2)")
  let u = [1, 2, 3]
  inspect!(
    (@json.from_json!(u.to_json()) : (Int, Int, Int)),
    content="(1, 2, 3)",
  )
  let u = [1, 2, 3, 4]
  inspect!(
    (@json.from_json!(u.to_json()) : (Int, Int, Int, Int)),
    content="(1, 2, 3, 4)",
  )
  let u = [1, 2, 3, 4, 5]
  inspect!(
    (@json.from_json!(u.to_json()) : (Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5)",
  )
  let u = [1, 2, 3, 4, 5, 6]
  inspect!(
    (@json.from_json!(u.to_json()) : (Int, Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5, 6)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7]
  inspect!(
    (@json.from_json!(u.to_json()) : (Int, Int, Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5, 6, 7)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7, 8]
  inspect!(
    (@json.from_json!(u.to_json()) : (Int, Int, Int, Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5, 6, 7, 8)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7, 8, 9]
  inspect!(
    (
      @json.from_json!(u.to_json()) :
      (Int, Int, Int, Int, Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5, 6, 7, 8, 9)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  inspect!(
    (
      @json.from_json!(u.to_json()) :
      (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
  inspect!(
    (
      @json.from_json!(u.to_json()) :
      (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
  inspect!(
    (
      @json.from_json!(u.to_json()) :
      (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
  inspect!(
    (
      @json.from_json!(u.to_json()) :
      (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
  inspect!(
    (
      @json.from_json!(u.to_json()) :
      (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int)),
    content="(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)",
  )
  let u = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
  inspect!(
    (
      @json.from_json!(u.to_json()) :
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
  inspect!(
    (
      @json.from_json!(u.to_json()) :
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
  let v : Result[(Int, Int, Int), _] = @json.from_json?(u.to_json())
  inspect!(
    v,
    content=
      #|Err(JsonDecodeError(($, "expected tuple of size 3")))
    ,
  )
  let u = ((1, 2), (3, 4))
  let v : Result[((Int, Int), Int), _] = @json.from_json?(ToJson::to_json(u))
  inspect!(
    v,
    content=
      #|Err(JsonDecodeError(($[1], "Int::from_json: expected number")))
    ,
  )
}

///|
test "fixedarray" {
  let u = ([1, 2] : FixedArray[_])
  let v : FixedArray[Int] = @json.from_json!(u.to_json())
  inspect!(v, content="[1, 2]")
  let u = (["123", "456"] : FixedArray[_])
  let v : FixedArray[String] = @json.from_json!(u.to_json())
  inspect!(
    v,
    content=
      #|["123", "456"]
    ,
  )
  let u = ([(), ()] : FixedArray[Unit])
  let v : FixedArray[Unit] = @json.from_json!(u.to_json())
  inspect!(v, content="[(), ()]")
  let u = ([] : FixedArray[Unit])
  let v : Result[FixedArray[Unit], _] = @json.from_json?(u.to_json())
  inspect!(v, content="Ok([])")
}

///|
test "Option" {
  let u : Json = (None : Int?).to_json()
  let v : Int? = @json.from_json!(u)
  inspect!(v, content="None")
  let u = Some(1).to_json()
  let v : Int? = @json.from_json!(u)
  inspect!(v, content="Some(1)")
  let nested : Json = (Some(None) : Unit??).to_json()
  let v : Unit?? = @json.from_json!(nested)
  inspect!(v, content="Some(None)")
  let nested : Json = (Some(Some(None)) : Unit???).to_json()
  let v : Unit??? = @json.from_json!(nested)
  inspect!(v, content="Some(Some(None))")
}

///|
test "Result" {
  let u : Json = (Ok(1) : Result[Int, String]).to_json()
  let v : Result[Int, String] = @json.from_json!(u)
  inspect!(v, content="Ok(1)")
  let u = (Err("error") : Result[Int, String]).to_json()
  let v : Result[Int, String] = @json.from_json!(u)
  inspect!(v, content="Err(\"error\")")
}

///|
test "Unit" {
  let u = ().to_json()
  let v : Unit = @json.from_json!(u)
  inspect!(v, content="()")
}

///|
test "bigint" {
  let u = BigInt::from_string("10238490123489120893478175871203124819").to_json()
  let v : BigInt = @json.from_json!(u)
  inspect!(v, content="10238490123489120893478175871203124819")
}

///|
test "jsonvalue" {
  let u = Json::String("str")
  let v : Json = @json.from_json!(u)
  inspect!(v, content="String(\"str\")")
  let u = Json::Number(123)
  let v : Json = @json.from_json!(u)
  inspect!(v, content="Number(123)")
  let u = Json::True
  let v : Json = @json.from_json!(u)
  inspect!(v, content="True")
  let u = Json::False
  let v : Json = @json.from_json!(u)
  inspect!(v, content="False")
  let u = Json::Null
  let v : Json = @json.from_json!(u)
  inspect!(v, content="Null")
  let u = Json::Array([Json::Number(1), Json::String("str")])
  let v : Json = @json.from_json!(u)
  inspect!(
    v,
    content=
      #|Array([Number(1), String("str")])
    ,
  )
  let u = Json::Object({ "x": Json::Number(1) })
  let v : Json = @json.from_json!(u)
  inspect!(
    v,
    content=
      #|Object({"x": Number(1)})
    ,
  )
}

///|
test "bool roundtrip" {
  let u = true.to_json()
  let v : Bool = @json.from_json!(u)
  inspect!(v, content="true")
  let u = false.to_json()
  let v : Bool = @json.from_json!(u)
  inspect!(v, content="false")
}

///|
test "int roundtrip" {
  let u = (123).to_json()
  let v : Int = @json.from_json!(u)
  inspect!(v, content="123")
  let u = (-123).to_json()
  let v : Int = @json.from_json!(u)
  inspect!(v, content="-123")
}

///|
test "uint roundtrip" {
  let u = 123U.to_json()
  let v : UInt = @json.from_json!(u)
  inspect!(v, content="123")
  let u = 4294967295U.to_json()
  let v : UInt = @json.from_json!(u)
  inspect!(v, content="4294967295")
}

///|
test "uint" {
  let v : UInt = @json.from_json!(Number(4294967295))
  inspect!(v, content="4294967295")
  let v : UInt = @json.from_json!(Number(-1))
  inspect!(v, content="0")
  let v : UInt = @json.from_json!(Number(4294967296))
  inspect!(v, content="4294967295")
}

///|
test "int64 roundtrip" {
  let u = 123L.to_json()
  let v : Int64 = @json.from_json!(u)
  inspect!(v, content="123")
  let u = 9223372036854775807L.to_json()
  let v : Int64 = @json.from_json!(u)
  inspect!(v, content="9223372036854775807")
  let u = (-9223372036854775808L).to_json()
  let v : Int64 = @json.from_json!(u)
  inspect!(v, content="-9223372036854775808")
}

///|
test "uint64 roundtrip" {
  let u = 123UL.to_json()
  let v : UInt64 = @json.from_json!(u)
  inspect!(v, content="123")
  let u = 18446744073709551615UL.to_json()
  let v : UInt64 = @json.from_json!(u)
  inspect!(v, content="18446744073709551615")
}

///|
test "unicode" {
  let u = "\u{1F600}".to_json()
  inspect!(
    u,
    content=
      #|String("😀")
    ,
  )
  let v : Char = @json.from_json!(u)
  inspect!(v, content="\u{1F600}")
  let bs : Bytes = [0x3D, 0xD8, 0x00, 0xDE]
  let u = bs.to_unchecked_string().to_json()
  let v : Char = @json.from_json!(u)
  inspect!(v, content="\u{1F600}")
  let bs1 : Bytes = [0xD8, 0x3D, 0xDE, 0x00]
  let u = bs1.to_unchecked_string().to_json()
  let v : Result[Char, _] = @json.from_json?(u)
  inspect!(
    v,
    content=
      #|Err(JsonDecodeError(($, "Char::from_json: invalid surrogate pair")))
    ,
  )
}

///|
test "char to/from json roundtrip" {
  let u = 'a'.to_json()
  inspect!(
    u,
    content=
      #|String("a")
    ,
  )
  let v : Char = @json.from_json!(u)
  inspect!(v, content="a")

  // emoji char roundtrip
  let u = '😀'.to_json()
  inspect!(
    u,
    content=
      #|String("😀")
    ,
  )
  let v : Char = @json.from_json!(u)
  inspect!(v, content="😀")

  // jdk char roundtrip
  let u = '中'.to_json()
  inspect!(
    u,
    content=
      #|String("中")
    ,
  )
  let v : Char = @json.from_json!(u)
  inspect!(v, content="中")
}

///|
test "string view from json" {
  let u = "hello".to_json()
  let v : @string.View = @json.from_json!(u)
  inspect!(v, content="hello")
}
