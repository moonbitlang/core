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
/// Trait for types that can be randomly generated
pub(open) trait Arbitrary {
  // `arbitrary` function takes a random number generator and a number that 
  // determines the size of the generated value as arguments, and returns a
  // randomly generated value of certain type.
  arbitrary(Int, @splitmix.RandomState) -> Self
}

///|
pub impl Arbitrary for Unit with arbitrary(_i, _rs) { () }

///|
pub impl Arbitrary for Bool with arbitrary(_i, rs) { rs.next_double() < 0.5 }

///|
pub impl Arbitrary for Int with arbitrary(size, rs) {
  if size == 0 {
    0
  } else {
    rs.next_int() % size
  }
}

///|
pub impl Arbitrary for UInt with arbitrary(size, rs) {
  if size == 0 {
    0
  } else {
    rs.next_uint() % size.reinterpret_as_uint()
  }
}

///|
fn unsafe_to_bytes(bytes : FixedArray[Byte]) -> Bytes = "%identity"

///|
pub impl Arbitrary for Byte with arbitrary(_i, rs) { rs.next_uint().to_byte() }

///|
pub impl Arbitrary for Bytes with arbitrary(size, rs) {
  if size == 0 {
    Bytes::new(0)
  } else {
    let sz = rs.next_positive_int() % size
    let result = FixedArray::make(sz, Byte::default())
    for i = 0; i < sz; i = i + 1 {
      result[i] = Byte::arbitrary(size, rs)
    }
    unsafe_to_bytes(result)
  }
}

///|
pub impl Arbitrary for Int64 with arbitrary(size, rs) {
  if size == 0 {
    0
  } else {
    rs.next_int64() % size.to_int64()
  }
}

///|
pub impl Arbitrary for UInt64 with arbitrary(size, rs) {
  if size == 0 {
    0
  } else {
    rs.next_uint64() % size.to_uint64()
  }
}

///|
pub impl Arbitrary for Float with arbitrary(_i, rs) { rs.next_float() }

///|
pub impl Arbitrary for Double with arbitrary(_i, rs) { rs.next_double() }

///|
pub impl Arbitrary for Char with arbitrary(_i, rs) {
  // Choose only ASCII characters
  rs.next_uint() % 128 |> UInt::reinterpret_as_int |> Char::from_int
}

///|
pub impl Arbitrary for String with arbitrary(size, rs) {
  let len = if size == 0 { 0 } else { rs.next_positive_int() % size }
  let mut s = ""
  for i = 0; i < len; i = i + 1 {
    s = s + Char::arbitrary(i, rs).to_string()
  }
  s
}

///|
pub impl Arbitrary for BigInt with arbitrary(size, rs) {
  if size == 0 {
    0
  } else {
    rs.next_int64() |> BigInt::from_int64
  }
}

///|
pub impl[X : Arbitrary] Arbitrary for Iter[X] with arbitrary(size, rs) {
  let len = if size == 0 { 0 } else { rs.next_positive_int() % size }
  Iter::new(fn(yield_) {
    for i = 0; i < len; i = i + 1 {
      if yield_(X::arbitrary(i, rs)) == IterEnd {
        break IterEnd
      }
    } else {
      IterContinue
    }
  })
}

test "iter arbitrary" {
  let samples : Array[Iter[Int]] = samples(20)
  inspect!("[0, 0, 0, 1, 2, -2]", content="[0, 0, 0, 1, 2, -2]")
  inspect!(samples[1:5], content="[[], [0], [0], [0]]")
  // inspect!(samples[9], content="[0, 0, 0, 1, 2, -2]") (Cause infinite loop?)
  inspect!(samples[10], content="[0, 0, 0]")
}

///|
pub fn gen[T : Arbitrary](size? : Int, state? : @splitmix.RandomState) -> T {
  let size = match size {
    None => 0
    Some(x) => x
  }
  let state = match state {
    None => @splitmix.RandomState::default()
    Some(x) => x
  }
  Arbitrary::arbitrary(size, state)
}
