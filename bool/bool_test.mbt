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
test "Bool hash function" {
  inspect(Hasher::new(seed=0)..combine(true).finalize(), content="-205818221")
  inspect(Hasher::new(seed=0)..combine(false).finalize(), content="148298089")
}

///|
test "Bool hash function with struct" {
  struct TestHash {
    flag : Bool
    x : Int
  } derive(Hash, Eq, Show)
  // type MyInt Int derive(Show) this does not work
  // let m : Map[TestHash, Char] = {}
  let m = {}
  m[{ flag: true, x: 1 }] = '3'
  m[{ flag: false, x: 1 }] = '3'
  inspect(m, content="{{flag: true, x: 1}: '3', {flag: false, x: 1}: '3'}")
}

///|
test "bool convert" {
  inspect(true.to_int(), content="1")
  inspect(false.to_int(), content="0")
  inspect(true.to_int64(), content="1")
  inspect(false.to_int64(), content="0")
  inspect(true.to_uint(), content="1")
  inspect(false.to_uint(), content="0")
  inspect(true.to_uint64(), content="1")
  inspect(false.to_uint64(), content="0")
  inspect(true.to_uint16(), content="1")
  inspect(false.to_uint16(), content="0")
  inspect(true.to_int16(), content="1")
  inspect(false.to_int16(), content="0")
}
