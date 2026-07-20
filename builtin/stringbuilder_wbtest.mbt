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
#cfg(not(target="js"))
test "StringBuilder::reset reuses an unshared buffer" {
  let builder = StringBuilder(size_hint=64)
  let backing = builder.data
  builder.write_string("hello")
  let first = builder.to_string()
  builder.reset()
  builder.write_string("bye")
  assert_true(first == "hello")
  assert_true(backing[0] == ('b' : UInt16))
  assert_true(backing[1] == ('y' : UInt16))
  assert_true(backing[2] == ('e' : UInt16))
}
