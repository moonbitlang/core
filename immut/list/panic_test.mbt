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

test "panic last" {
  @list.Nil.last()
}

test "panic nth_exn" {
  @list.Nil.unsafe_nth(0)
}

test "panic @list.exn with empty list" {
  @list.Nil.unsafe_head()
}

test "panic @list.unsafe_maximum with empty list" {
  inspect!((@list.Nil : @list.T[Int]).unsafe_maximum())
}

test "panic @list.unsafe_minimum with empty list" {
  inspect!((@list.Nil : @list.T[Int]).unsafe_minimum())
}
