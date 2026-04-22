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
test "tail push across multiple blocks" {
  let mut values : @vector.Vector[Int] = @vector.new()
  for i in 0..<100 {
    values = values.push(i)
  }
  assert_true(values.length() == 100)
  assert_true(values[0] == 0)
  assert_true(values[31] == 31)
  assert_true(values[32] == 32)
  assert_true(values[99] == 99)
  assert_true(values.to_array() == Array::makei(100, i => i))
}

///|
test "tail set in prefix and tail" {
  let values = @vector.from_iter((0).until(40))
  let updated = values.set(5, 500).set(35, 3500)
  let expected = Array::makei(40, i => i)
  expected[5] = 500
  expected[35] = 3500
  assert_true(updated[5] == 500)
  assert_true(updated[35] == 3500)
  assert_true(updated.to_array() == expected)
}

///|
test "tail equality across different internal layouts" {
  let direct = @vector.from_iter((0).until(40))
  let via_concat = @vector.from_iter((0).until(20)).concat(
    @vector.from_iter((20).until(40)),
  )
  assert_true(direct == via_concat)
  assert_true(direct.to_array() == via_concat.to_array())
}

///|
test "tail push after concat result" {
  let base = @vector.from_iter((0).until(20)).concat(
    @vector.from_iter((20).until(40)),
  )
  let pushed = base.push(40).push(41)
  assert_true(pushed.to_array() == Array::makei(42, i => i))
}

///|
test "tail fold rev_fold and map stay consistent" {
  let values = @vector.from_iter((0).until(40))
  let doubled = values.map(x => x * 2)
  assert_true(doubled[0] == 0)
  assert_true(doubled[39] == 78)
  assert_true(values.fold((acc, x) => acc + x, init=0) == 780)
  assert_true(values.rev_fold((acc, x) => acc + x, init=0) == 780)
}

///|
test "peek reads the tail tip" {
  let values = @vector.from_iter((0).until(40))
  assert_true(values.peek() == Some(39))
  let empty : @vector.Vector[Int] = @vector.new()
  assert_true(empty.peek() == None)
}

///|
test "pop shrinks tail and promotes previous leaf when needed" {
  let values = @vector.from_iter((0).until(40))
  assert_true(values.pop().unwrap().to_array() == Array::makei(39, i => i))

  let boundary = @vector.from_iter((0).until(33))
  let popped = boundary.pop().unwrap()
  assert_true(popped.length() == 32)
  assert_true(popped.to_array() == Array::makei(32, i => i))
}
