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
test "write_iter with trailing" {
  let builder = StringBuilder::new()
  let logger : &Logger = builder
  let arr : Array[Int] = [1, 2]
  logger.write_iter(arr.iter(), prefix="[", suffix="]", sep=",", trailing=true)
  inspect(builder.to_string(), content="[1,2,]")
}

///|
test "hash_data" {
  struct Data {
    x : Array[Int]
    y : FixedArray[Int]
  } derive(Hash, Eq, Show)
  let data = Data::{ x: [1, 2, 3], y: [4, 5, 6] }
  let map = {}
  map[data] = 1
  inspect(map, content="{{x: [1, 2, 3], y: [4, 5, 6]}: 1}")
}

///|
struct TestLogger {
  mut output : String
}

///|
struct Pair {
  left : Int
  right : Int
} derive(Eq, Show)

///|
struct Wrapper {
  value : Int
}

///|
impl Eq for Wrapper with equal(self, other) {
  self.value == other.value
}

///|
impl Logger for TestLogger with write_view(self, value) {
  self.output = self.output + value.to_string()
}

///|
test "Eq helpers" {
  inspect(Eq::not_equal(1, 2), content="true")
  inspect(Eq::equal(3, 3), content="true")
  let a : Pair = Pair::{ left: 1, right: 2 }
  let b : Pair = Pair::{ left: 1, right: 3 }
  inspect(Eq::not_equal(a, b), content="true")
}

///|
#warnings("-deprecated")
test "Eq op_equal default" {
  let a = Wrapper::{ value: 1 }
  let b = Wrapper::{ value: 2 }
  inspect(Eq::op_equal(a, b), content="false")
}

///|
test "Logger defaults" {
  let logger = TestLogger::{ output: "" }
  logger.write_string("hi")
  logger.write_char('!')
  inspect(logger.output, content="hi!")
}
