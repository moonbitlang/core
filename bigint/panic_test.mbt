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
test "panic division by zero" {
  let a = BigInt::from_int(10)
  let b = BigInt::from_int(0)
  (a / b) |> ignore
}

///|
test "panic modulo by zero" {
  let a = BigInt::from_int(10)
  let b = BigInt::from_int(0)
  (a % b) |> ignore
}

///|
test "panic negative shift left" {
  let a = BigInt::from_int(10)
  (a << -1) |> ignore
}

///|
test "panic negative shift right" {
  let a = BigInt::from_int(10)
  (a >> -1) |> ignore
}

///|
test "panic from_string empty" {
  BigInt::from_string("") |> ignore
}
