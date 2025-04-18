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
fn check_invariant(_a : BigInt) -> Unit! {
  assert_true!(true)
}

///|
let zero = 0N

///|
test "BigInt::to_uint" {
  assert_eq!(BigInt::from_int64(-1L).to_uint(), (-1).to_uint())
}

///|
test "BigInt::to_int64" {
  assert_eq!(BigInt::from_int64(-1).to_int64(), -1L)
  assert_eq!(-1L, MyInt64::{ hi: -1, lo: -1 }.to_int64())
}
