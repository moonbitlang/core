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
test "tuple2 default" {
  let t : (Int, Bool) = Default::default()
  inspect(t, content="(0, false)")
}

///|
test "tuple3 default" {
  let t : (Int, Bool, Int) = Default::default()
  inspect(t, content="(0, false, 0)")
}

///|
test "tuple4 default" {
  let t : (Int, Bool, Int, Int) = Default::default()
  inspect(t, content="(0, false, 0, 0)")
}

///|
test "tuple5 default" {
  let t : (Int, Bool, Int, Int, Int) = Default::default()
  inspect(t, content="(0, false, 0, 0, 0)")
}

///|
test "tuple6 default" {
  let t : (Int, Int, Int, Int, Int, Int) = Default::default()
  inspect(t, content="(0, 0, 0, 0, 0, 0)")
}

///|
test "tuple7 default" {
  let t : (Int, Int, Int, Int, Int, Int, Int) = Default::default()
  inspect(t, content="(0, 0, 0, 0, 0, 0, 0)")
}

///|
test "tuple8 default" {
  let t : (Int, Int, Int, Int, Int, Int, Int, Int) = Default::default()
  inspect(t, content="(0, 0, 0, 0, 0, 0, 0, 0)")
}

///|
test "tuple9 default" {
  let t : (Int, Int, Int, Int, Int, Int, Int, Int, Int) = Default::default()
  inspect(t, content="(0, 0, 0, 0, 0, 0, 0, 0, 0)")
}

///|
test "tuple10 default" {
  let t : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = Default::default()
  inspect(t, content="(0, 0, 0, 0, 0, 0, 0, 0, 0, 0)")
}

///|
test "tuple11 default" {
  let t : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = Default::default()
  inspect(t, content="(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)")
}

///|
test "tuple12 default" {
  let t : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = Default::default()
  inspect(t, content="(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)")
}

///|
test "tuple13 default" {
  let t : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = Default::default()
  inspect(t, content="(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)")
}

///|
test "tuple14 default" {
  let t : (Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) = Default::default()
  inspect(t, content="(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)")
}

///|
test "tuple15 default" {
  let t : (
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
  ) = Default::default()
  inspect(t, content="(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)")
}

///|
test "tuple16 default" {
  let t : (
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
  ) = Default::default()
  inspect(t, content="(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)")
}
