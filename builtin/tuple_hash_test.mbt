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
let seed = 0x533D

///|
fn h() -> Hasher {
  Hasher::new(seed~)
}

///|
test "hash_combine for 2-tuple" {
  assert_eq(
    h()..combine(1)..combine("hello").finalize(),
    h()..combine((1, "hello")).finalize(),
  )
}

///|
test "hash_combine for 3-tuple" {
  assert_eq(
    h()..combine(1)..combine("hello")..combine(3.14).finalize(),
    h()..combine((1, "hello", 3.14)).finalize(),
  )
}

///|
test "hash_combine for 4-tuple" {
  assert_eq(
    h()..combine(1)..combine("hello")..combine(3.14)..combine(15).finalize(),
    h()..combine((1, "hello", 3.14, 15)).finalize(),
  )
}

///|
test "hash_combine for 5-tuple" {
  assert_eq(
    h()
    ..combine(1)
    ..combine("hello")
    ..combine(3.14)
    ..combine(15)
    ..combine('a')
    .finalize(),
    h()..combine((1, "hello", 3.14, 15, 'a')).finalize(),
  )
}

///|
test "hash_combine for 6-tuple" {
  assert_eq(
    h()
    ..combine(1)
    ..combine("hello")
    ..combine(3.14)
    ..combine(15)
    ..combine('a')
    ..combine(0x12345678UL)
    .finalize(),
    h()..combine((1, "hello", 3.14, 15, 'a', 0x12345678UL)).finalize(),
  )
}

///|
test "hash_combine for 7-tuple" {
  assert_eq(
    h()
    ..combine(1)
    ..combine("hello")
    ..combine(3.14)
    ..combine(15)
    ..combine('a')
    ..combine(0x12345678UL)
    ..combine(b's')
    .finalize(),
    h()..combine((1, "hello", 3.14, 15, 'a', 0x12345678UL, b's')).finalize(),
  )
}
