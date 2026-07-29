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
test "construct, map, and flat_map" {
  let from_size = @gen.Gen::new((size, _) => size)
  inspect(from_size.sample(size=12), content="12")
  let value = @gen.pure(20).map(x => x + 1).flat_map(x => @gen.pure(x * 2))
  inspect(value.sample(), content="42")
}

///|
test "size control" {
  let generator = @gen.sized(size => @gen.pure(size))
  inspect(generator.sample(size=9), content="9")
  inspect(generator.resize(3).sample(size=9), content="3")
}

///|
test "arbitrary generator" {
  let value : Unit = @gen.arbitrary().sample()
  inspect(value, content="()")
}

///|
test "range and choices" {
  for value in @gen.int_range(-4, 7).samples(count=64) {
    guard value >= -4 && value < 7 else {
      fail("int_range generated an out-of-range value")
    }
  }
  for value in @gen.one_of([@gen.pure(1), @gen.pure(2)]).samples(count=32) {
    guard value == 1 || value == 2 else {
      fail("one_of generated a value outside its inputs")
    }
  }
  for
    value in @gen.frequency([(1U, @gen.pure("a")), (3U, @gen.pure("b"))]).samples(
      count=32,
    ) {
    guard value == "a" || value == "b" else {
      fail("frequency generated a value outside its inputs")
    }
  }
}

///|
test "fixed-size array" {
  let values = @gen.pure(7).array_with_size(3).sample()
  inspect(values.length(), content="3")
  inspect(values.all(value => value == 7), content="true")
}
