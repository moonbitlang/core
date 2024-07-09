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
  let buf = Buffer::new()
  x.debug_write(buf)
  inspect(
    buf,
    content=
      #|42
    ,
  )!
  // This should cover the line where the debug function is called with an Int
}

test "debug function with String" {
  let s = "Hello, MoonBit!"
  let buf = Buffer::new()
  s.debug_write(buf)
  inspect(
    buf,
    content=
      #|"Hello, MoonBit!"
    ,
  )!
  // This should cover the line where the debug function is called with a String
}

test "debug function with Bool" {
  let b = true
  let buf = Buffer::new()
  b.debug_write(buf)
  inspect(
    buf,
    content=
      #|true
    ,
  )!
  // This should cover the line where the debug function is called with a Bool
}

test "debug function with Int64" {
  let i64 = 9223372036854775807L
  let buf = Buffer::new()
  i64.debug_write(buf)
  inspect(
    buf,
    content=
      #|9223372036854775807
    ,
  )!
  // This should cover the line where the debug function is called with an Int64
}

test "debug function with Bytes" {
  let bytes = Bytes::make(10)
  let buf = Buffer::new()
  bytes.debug_write(buf)
  inspect(buf, content="\x00\x00\x00\x00\x00")!
  // This should cover the line where the debug function is called with Bytes
}

test "debug function with Option[Int]" {
  let opt = Option::Some(42)
  let buf = Buffer::new()
  opt.debug_write(buf)
  inspect(
    buf,
    content=
      #|Some(42)
    ,
  )!
  // This should cover the line where the debug function is called with an Option[Int]
}

test "debug function with Result[Int, String]" {
  let res : Result[Int, String] = Result::Ok(42)
  let buf = Buffer::new()
  res.debug_write(buf)
  inspect(
    buf,
    content=
      #|Ok(42)
    ,
  )!
  // This should cover the line where the debug function is called with a Result[Int, String]
}

test "debug function with Ref[Int]" {
  let ref_int : Ref[Int] = { val: 42 }
  let buf = Buffer::new()
  ref_int.debug_write(buf)
  inspect(buf, content="{val: 42}")!
  // This should cover the line where the debug function is called with a Ref[Int]
}

test "debug function with FixedArray[Int]" {
  let arr = [1, 2, 3, 4, 5]
  let buf = Buffer::new()
  arr.debug_write(buf)
  inspect(
    buf,
    content=
      #|[1, 2, 3, 4, 5]
    ,
  )!
  // This should cover the line where the debug function is called with a FixedArray[Int]
}

test "debug function with Array[Int]" {
  let arr = [1, 2, 3, 4, 5]
  let buf = Buffer::new()
  arr.debug_write(buf)
  inspect(
    buf,
    content=
      #|[1, 2, 3, 4, 5]
    ,
  )!
  // This should cover the line where the debug function is called with an Array[Int]
}

test "debug function with ArrayView[Int]" {
  let arr = [1, 2, 3, 4, 5]
  let arrayview = arr[1:2]
  let buf = Buffer::new()
  arrayview.debug_write(buf)
  inspect(
    buf,
    content=
      #|[2]
    ,
  )!
}

test "debug function with Map[Int, String]" {
  let map = Map::new()
  map.set(1, "one")
  map.set(2, "two")
  let buf = Buffer::new()
  map.debug_write(buf)
  inspect(
    buf,
    content=
      #|(69681622,1,"one"),prev:_,next:-236984087)
      #|(-236984087,2,"two"),prev:69681622,next:_)
      #|end
    ,
  )!
  // This should cover the line where the debug function is called with a Map[Int, String]
}
