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
  let h1 = h()
  h1.combine(1)
  h1.combine("hello")
  let h2 = h()
  h2.combine((1, "hello"))
  assert_eq(h1.finalize(), h2.finalize())
}

///|
test "hash_combine for 3-tuple" {
  let h1 = h()
  h1.combine(1)
  h1.combine("hello")
  h1.combine(3.14)
  let h2 = h()
  h2.combine((1, "hello", 3.14))
  assert_eq(h1.finalize(), h2.finalize())
}

///|
test "hash_combine for 4-tuple" {
  let h1 = h()
  h1.combine(1)
  h1.combine("hello")
  h1.combine(3.14)
  h1.combine(15)
  let h2 = h()
  h2.combine((1, "hello", 3.14, 15))
  assert_eq(h1.finalize(), h2.finalize())
}

///|
test "hash_combine for 5-tuple" {
  let h1 = h()
  h1.combine(1)
  h1.combine("hello")
  h1.combine(3.14)
  h1.combine(15)
  h1.combine('a')
  let h2 = h()
  h2.combine((1, "hello", 3.14, 15, 'a'))
  assert_eq(h1.finalize(), h2.finalize())
}

///|
test "hash_combine for 6-tuple" {
  let h1 = h()
  h1.combine(1)
  h1.combine("hello")
  h1.combine(3.14)
  h1.combine(15)
  h1.combine('a')
  h1.combine(0x12345678UL)
  let h2 = h()
  h2.combine((1, "hello", 3.14, 15, 'a', 0x12345678UL))
  assert_eq(h1.finalize(), h2.finalize())
}

///|
test "hash_combine for 7-tuple" {
  let h1 = h()
  h1.combine(1)
  h1.combine("hello")
  h1.combine(3.14)
  h1.combine(15)
  h1.combine('a')
  h1.combine(0x12345678UL)
  h1.combine(b's')
  let h2 = h()
  h2.combine((1, "hello", 3.14, 15, 'a', 0x12345678UL, b's'))
  assert_eq(h1.finalize(), h2.finalize())
}
