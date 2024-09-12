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

/// Trait for types that can be randomly generated
pub trait Arbitrary {
  // `arbitrary` function takes a random number generator and a number that 
  // determines the size of the generated value as arguments, and returns a
  // randomly generated value of certain type.
  arbitrary(Int, @splitmix.RandomState) -> Self
}

pub impl Arbitrary for Unit with arbitrary(_i, _rs) { () }

pub impl Arbitrary for Bool with arbitrary(_i, rs) { rs.next_double() < 0.5 }

pub impl Arbitrary for UInt with arbitrary(size, rs) {
  if size == 0 {
    0
  } else {
    rs.next_uint() % size.reinterpret_as_uint()
  }
}

pub impl Arbitrary for Int with arbitrary(size, rs) {
  if size == 0 {
    0
  } else {
    rs.next_int() % size
  }
}

pub impl Arbitrary for Int64 with arbitrary(size, rs) {
  if size == 0 {
    0
  } else {
    rs.next_int64() % size.to_int64()
  }
}

pub impl Arbitrary for Double with arbitrary(_i, rs) { rs.next_double() }

pub impl Arbitrary for UInt64 with arbitrary(size, rs) {
  if size == 0 {
    0
  } else {
    rs.next_uint64() % size.reinterpret_as_uint().to_uint64()
  }
}

pub fn gen[T : Arbitrary](~size? : Int, ~state? : @splitmix.RandomState) -> T {
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
