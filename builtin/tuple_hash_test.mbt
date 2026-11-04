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
  Hasher(seed~)
}

///|
test "hash_combine for 2-tuple" {
  let h1 = h()
  h1.combine(1)
  h1.combine("hello")
  let h2 = h()
  h2.combine((1, "hello"))
  @test.assert_eq(h1.finalize(), h2.finalize())
}

///|
test "hash_combine for 3-tuple" {
  let h1 = h()
  h1.combine(1)
  h1.combine("hello")
  h1.combine(3.14)
  let h2 = h()
  h2.combine((1, "hello", 3.14))
  @test.assert_eq(h1.finalize(), h2.finalize())
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
  @test.assert_eq(h1.finalize(), h2.finalize())
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
  @test.assert_eq(h1.finalize(), h2.finalize())
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
  @test.assert_eq(h1.finalize(), h2.finalize())
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
  @test.assert_eq(h1.finalize(), h2.finalize())
}

///|
test "hash_combine for 8-tuple" {
  let h1 = h()
  h1.combine(1)
  h1.combine("hello")
  h1.combine(3.14)
  h1.combine(15)
  h1.combine('a')
  h1.combine(0x12345678UL)
  h1.combine(b's')
  h1.combine(true)
  let h2 = h()
  h2.combine((1, "hello", 3.14, 15, 'a', 0x12345678UL, b's', true))
  @test.assert_eq(h1.finalize(), h2.finalize())
}

///|
test "hash_combine for 9-tuple" {
  let h1 = h()
  h1.combine(1)
  h1.combine("hello")
  h1.combine(3.14)
  h1.combine(15)
  h1.combine('a')
  h1.combine(0x12345678UL)
  h1.combine(b's')
  h1.combine(true)
  h1.combine(-7L)
  let h2 = h()
  h2.combine((1, "hello", 3.14, 15, 'a', 0x12345678UL, b's', true, -7L))
  @test.assert_eq(h1.finalize(), h2.finalize())
}

///|
test "hash_combine for 10-tuple" {
  let h1 = h()
  h1.combine(1)
  h1.combine("hello")
  h1.combine(3.14)
  h1.combine(15)
  h1.combine('a')
  h1.combine(0x12345678UL)
  h1.combine(b's')
  h1.combine(true)
  h1.combine(-7L)
  h1.combine(2.5F)
  let h2 = h()
  h2.combine((1, "hello", 3.14, 15, 'a', 0x12345678UL, b's', true, -7L, 2.5F))
  @test.assert_eq(h1.finalize(), h2.finalize())
}

///|
test "hash_combine for 11-tuple" {
  let h1 = h()
  h1.combine(1)
  h1.combine("hello")
  h1.combine(3.14)
  h1.combine(15)
  h1.combine('a')
  h1.combine(0x12345678UL)
  h1.combine(b's')
  h1.combine(true)
  h1.combine(-7L)
  h1.combine(2.5F)
  h1.combine(42U)
  let h2 = h()
  h2.combine(
    (1, "hello", 3.14, 15, 'a', 0x12345678UL, b's', true, -7L, 2.5F, 42U),
  )
  @test.assert_eq(h1.finalize(), h2.finalize())
}

///|
test "hash_combine for 12-tuple" {
  let h1 = h()
  h1.combine(1)
  h1.combine("hello")
  h1.combine(3.14)
  h1.combine(15)
  h1.combine('a')
  h1.combine(0x12345678UL)
  h1.combine(b's')
  h1.combine(true)
  h1.combine(-7L)
  h1.combine(2.5F)
  h1.combine(42U)
  h1.combine("world")
  let h2 = h()
  h2.combine(
    (
      1, "hello", 3.14, 15, 'a', 0x12345678UL, b's', true, -7L, 2.5F, 42U, "world",
    ),
  )
  @test.assert_eq(h1.finalize(), h2.finalize())
}

///|
test "hash_combine for 13-tuple" {
  let h1 = h()
  h1.combine(1)
  h1.combine("hello")
  h1.combine(3.14)
  h1.combine(15)
  h1.combine('a')
  h1.combine(0x12345678UL)
  h1.combine(b's')
  h1.combine(true)
  h1.combine(-7L)
  h1.combine(2.5F)
  h1.combine(42U)
  h1.combine("world")
  h1.combine('z')
  let h2 = h()
  h2.combine(
    (
      1, "hello", 3.14, 15, 'a', 0x12345678UL, b's', true, -7L, 2.5F, 42U, "world",
      'z',
    ),
  )
  @test.assert_eq(h1.finalize(), h2.finalize())
}

///|
test "hash_combine for 14-tuple" {
  let h1 = h()
  h1.combine(1)
  h1.combine("hello")
  h1.combine(3.14)
  h1.combine(15)
  h1.combine('a')
  h1.combine(0x12345678UL)
  h1.combine(b's')
  h1.combine(true)
  h1.combine(-7L)
  h1.combine(2.5F)
  h1.combine(42U)
  h1.combine("world")
  h1.combine('z')
  h1.combine(0xFFFF_FFFF_FFFF_FFFFUL)
  let h2 = h()
  h2.combine(
    (
      1, "hello", 3.14, 15, 'a', 0x12345678UL, b's', true, -7L, 2.5F, 42U, "world",
      'z', 0xFFFF_FFFF_FFFF_FFFFUL,
    ),
  )
  @test.assert_eq(h1.finalize(), h2.finalize())
}

///|
test "hash_combine for 15-tuple" {
  let h1 = h()
  h1.combine(1)
  h1.combine("hello")
  h1.combine(3.14)
  h1.combine(15)
  h1.combine('a')
  h1.combine(0x12345678UL)
  h1.combine(b's')
  h1.combine(true)
  h1.combine(-7L)
  h1.combine(2.5F)
  h1.combine(42U)
  h1.combine("world")
  h1.combine('z')
  h1.combine(0xFFFF_FFFF_FFFF_FFFFUL)
  h1.combine(false)
  let h2 = h()
  h2.combine(
    (
      1, "hello", 3.14, 15, 'a', 0x12345678UL, b's', true, -7L, 2.5F, 42U, "world",
      'z', 0xFFFF_FFFF_FFFF_FFFFUL, false,
    ),
  )
  @test.assert_eq(h1.finalize(), h2.finalize())
}

///|
test "hash_combine for 16-tuple" {
  let h1 = h()
  h1.combine(1)
  h1.combine("hello")
  h1.combine(3.14)
  h1.combine(15)
  h1.combine('a')
  h1.combine(0x12345678UL)
  h1.combine(b's')
  h1.combine(true)
  h1.combine(-7L)
  h1.combine(2.5F)
  h1.combine(42U)
  h1.combine("world")
  h1.combine('z')
  h1.combine(0xFFFF_FFFF_FFFF_FFFFUL)
  h1.combine(false)
  h1.combine(-1)
  let h2 = h()
  h2.combine(
    (
      1, "hello", 3.14, 15, 'a', 0x12345678UL, b's', true, -7L, 2.5F, 42U, "world",
      'z', 0xFFFF_FFFF_FFFF_FFFFUL, false, -1,
    ),
  )
  @test.assert_eq(h1.finalize(), h2.finalize())
}

///|
test "hash method on tuples of arity 8 to 16" {
  let t8 = (1, 2, 3, 4, 5, 6, 7, 8)
  @test.assert_eq(t8.hash(), Hash::hash(t8))
  assert_true(t8.hash() != (1, 2, 3, 4, 5, 6, 8, 7).hash())
  let t16 = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16)
  @test.assert_eq(t16.hash(), Hash::hash(t16))
  assert_true(
    t16.hash() != (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 17).hash(),
  )
}

///|
test "tuples of arity 8 to 16 as map keys" {
  let m : Map[
    (Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32),
    String,
  ] = Map([])
  m[(1, 2, 3, 4, 5, 6, 7, 8, 9)] = "a"
  m[(9, 8, 7, 6, 5, 4, 3, 2, 1)] = "b"
  m[(1, 2, 3, 4, 5, 6, 7, 8, 9)] = "c"
  inspect(m.length(), content="2")
  @test.assert_eq(m.get((1, 2, 3, 4, 5, 6, 7, 8, 9)), Some("c"))
  @test.assert_eq(m.get((9, 8, 7, 6, 5, 4, 3, 2, 1)), Some("b"))
  @test.assert_eq(m.get((1, 2, 3, 4, 5, 6, 7, 8, 0)), None)
}
