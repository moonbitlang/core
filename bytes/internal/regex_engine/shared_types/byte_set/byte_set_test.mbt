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
test "ranges cross word boundaries" {
  let set = @byte_set.ByteSet::char_range(60, 130) +
    @byte_set.ByteSet::char(255)
  @test.assert_eq(set.intervals().to_array(), [(60, 130), (255, 255)])
  assert_true(set.contains(63) && set.contains(64) && set.contains(128))
  assert_true(!set.contains(59) && !set.contains(131) && !set.contains(256))
  assert_true(!set.contains(-1))
}

///|
test "set operations" {
  let a = @byte_set.ByteSet::char_range('a', 'z')
  let vowels = @byte_set.ByteSet::char('a') +
    @byte_set.ByteSet::char('e') +
    @byte_set.ByteSet::char('o')
  @test.assert_eq((a - vowels).intervals().to_array(), [
    (98, 100),
    (102, 110),
    (112, 122),
  ])
  @test.assert_eq(
    (a & @byte_set.ByteSet::char_range(0, 'c')).intervals().to_array(),
    [(97, 99)],
  )
  let full = @byte_set.ByteSet::full()
  assert_true((full - full).is_empty())
  @test.assert_eq((full - a + a).intervals().to_array(), [(0, 255)])
  assert_true(@byte_set.ByteSet::char_range(10, 5).is_empty())
  @test.assert_eq(
    @byte_set.ByteSet::char_range(-5, 300).intervals().to_array(),
    [(0, 255)],
  )
}

///|
test "offset_by" {
  let upper = @byte_set.ByteSet::char_range('A', 'C').offset_by(c => c + 32)
  @test.assert_eq(upper.intervals().to_array(), [(97, 99)])
  @test.assert_eq(
    @byte_set.ByteSet::char(250).offset_by(c => c + 10).intervals().to_array(),
    [],
  )
}

///|
test "bounds far outside the bytes" {
  // Found in review: `char(-2147483648)` used to overflow into bits.
  let min = -2147483648
  let max = 2147483647
  assert_true(@byte_set.ByteSet::char(min).is_empty())
  assert_true(@byte_set.ByteSet::char(max).is_empty())
  assert_true(@byte_set.ByteSet::char_range(min, -1).is_empty())
  assert_true(@byte_set.ByteSet::char_range(256, max).is_empty())
  @test.assert_eq(
    @byte_set.ByteSet::char_range(min, max).intervals().to_array(),
    [(0, 255)],
  )
  assert_true(@byte_set.ByteSet::char(0).offset_by(_ => min).is_empty())
}
