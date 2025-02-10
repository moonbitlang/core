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
struct Hello[A, B] {
  fieldA : A
  fieldB : B
  data : Map[String, A]
} derive(ToJson, FromJson, Show, Eq)

///|
test {
  let v = Hello::{ fieldA: 3, fieldB: 2, data: { "a": 3 } }
  let vj = v.to_json()
  let v0 : Hello[Int, Int] = @json.from_json!(vj)
  inspect!(
    v0,
    content=
      #|{fieldA: 3, fieldB: 2, data: {"a": 3}}
    ,
  )
  assert_eq!(v0, v)
}

///|
// struct Hello2 [A, B] {
//   fieldA : A
//   fieldB : B
//   data : Map[B, A]
// }derive(ToJson)
// Should the deriver generate constraints that [B: Show]
struct Hello3[A, B] {
  fieldAX : A
  fieldB : B
  data : Map[Int, A]
} derive(ToJson)

///|
test {
  let h = Hello::{ fieldA: 1, fieldB: "hello", data: { "a": 1, "b": 2 } }
  let j = h.to_json()
  inspect!(
    j,
    content=
      #|Object({"fieldA": Number(1), "fieldB": String("hello"), "data": Object({"a": Number(1), "b": Number(2)})})
    ,
  )
  let h3 = Hello3::{ fieldAX: 1, fieldB: "hello", data: { 1: 1, 2: 2 } }
  let j3 = h3.to_json()
  inspect!(
    j3,
    content=
      #|Object({"fieldAX": Number(1), "fieldB": String("hello"), "data": Object({"1": Number(1), "2": Number(2)})})
    ,
  )
}
