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

test "panic unwrap should panic on None" {
  let none : Int? = None
  none.unwrap() |> ignore
}

test "unwrap should return value on Some" {
  let some : Int? = Some(42)
  @test.eq(some.unwrap(), 42)!
}

test "Option::default should return None" {
  let x : Int? = Option::default()
  @test.eq(x, None)!
}

test "Option::default should return None for String" {
  let x : String? = Option::default()
  @test.eq(x, None)!
}

test "Option::default should return None for Bool" {
  let x : Bool? = Option::default()
  @test.eq(x, None)!
}
