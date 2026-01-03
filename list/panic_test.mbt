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
test "last None" {
  assert_eq(@list.empty().last(), (None : Unit?))
}

///|
test "panic nth_exn" {
  @list.empty().unsafe_nth(0)
}

///|
test "panic @list.exn with empty list" {
  @list.empty().unsafe_head()
}

///|
test "panic @list.unsafe_maximum with empty list" {
  inspect((@list.empty() : @list.List[Int]).unsafe_maximum())
}

///|
test "panic @list.unsafe_minimum with empty list" {
  inspect((@list.empty() : @list.List[Int]).unsafe_minimum())
}

///|
test "unsafe_head with non-empty list" {
  // Test the non-panic path of unsafe_head to cover line 407
  let list = @list.from_array([1, 2, 3])
  inspect(list.unsafe_head(), content="1")
}

///|
test "panic unsafe_last with empty list" {
  // Test the panic path of unsafe_last to cover line 469
  @list.empty().unsafe_last()
}
