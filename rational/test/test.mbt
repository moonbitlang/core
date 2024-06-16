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

test "new" {
  // 1/2
  let a = @rational.new(1L, 2L)
  inspect(a, content="Some(1/2)")?

  // 1/0
  let a = @rational.new(1L, 0L)
  inspect(a, content="None")?
}

test "addition" {
  let a = @rational.new(1L, 2L).unwrap()
  let b = @rational.new(1L, 3L).unwrap()
  let result = a + b
  inspect(result, content="5/6")?
}

test "subtraction" {
  let a = @rational.new(3L, 4L).unwrap()
  let b = @rational.new(1L, 4L).unwrap()
  let result = a - b
  inspect(result, content="1/2")?
}

test "multiplication" {
  let a = @rational.new(2L, 3L).unwrap()
  let b = @rational.new(3L, 4L).unwrap()
  let result = a * b
  inspect(result, content="1/2")?
}

test "division" {
  let a = @rational.new(1L, 2L).unwrap()
  let b = @rational.new(3L, 4L).unwrap()
  let result = a / b
  inspect(result, content="2/3")?
}