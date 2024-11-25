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

///|
trait FromString {
  from_string(String) -> Self
}

///|
type MyInt Int derive(Show)

///|
// _ allow in names
impl FromString for MyInt with from_string(_s) { 0 }

///|
type MyString String derive(Show)

///|
impl FromString for MyString with from_string(_s) { "" }

///|
fn need_int(_x : MyInt) -> Unit {

}

///|
fn need_string(_x : MyString) -> Unit {

}

test {
  let u0 : MyString = FromString::from_string("")
  let u1 : MyInt = FromString::from_string("")
  inspect!(
    (u0, u1),
    content=
      #|(MyString(""), MyInt(0))
    ,
  )
  need_int(FromString::from_string(""))
  need_string(FromString::from_string(""))
  let z = FromString::from_string("")
  need_int(z)
  // let z0 = FromString::from_string("")
  // ...
}
