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

test "debug function with Int" {
  let x = 42
  debug(x)
  // This should cover the line where the debug function is called with an Int
}

test "debug function with String" {
  let s = "Hello, MoonBit!"
  debug(s)
  // This should cover the line where the debug function is called with a String
}

test "debug function with Bool" {
  let b = true
  debug(b)
  // This should cover the line where the debug function is called with a Bool
}

test "debug function with Int64" {
  let i64 = 9223372036854775807L
  debug(i64)
  // This should cover the line where the debug function is called with an Int64
}

test "debug function with Bytes" {
  let bytes = Bytes::make(10)
  debug(bytes)
  // This should cover the line where the debug function is called with Bytes
}

test "debug function with Option[Int]" {
  let opt = Option::Some(42)
  debug(opt)
  // This should cover the line where the debug function is called with an Option[Int]
}

test "debug function with Result[Int, String]" {
  let res : Result[Int, String] = Result::Ok(42)
  debug(res)
  // This should cover the line where the debug function is called with a Result[Int, String]
}

test "debug function with Ref[Int]" {
  let ref_int : Ref[Int] = { val: 42 }
  debug(ref_int)
  // This should cover the line where the debug function is called with a Ref[Int]
}

test "debug function with FixedArray[Int]" {
  let arr = [1, 2, 3, 4, 5]
  debug(arr)
  // This should cover the line where the debug function is called with a FixedArray[Int]
}

test "debug function with Array[Int]" {
  let arr = [1, 2, 3, 4, 5]
  debug(arr)
  // This should cover the line where the debug function is called with an Array[Int]
}

test "debug function with Map[Int, String]" {
  let map = Map::new()
  map.set(1, "one")
  map.set(2, "two")
  debug(map)
  // This should cover the line where the debug function is called with a Map[Int, String]
}
