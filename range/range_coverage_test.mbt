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

// Black-box tests covering the `Step` instances the existing suite misses:
// the zero-step (empty) direction for the types not already exercised
// (Int64/UInt/UInt64/Int16/UInt16/Byte/Float/BigInt — Int and Double are
// covered elsewhere), the default `step_one` for Int64/Float, and a
// descending Float range.

///|
test "a zero step yields an empty range for the remaining Step types" {
  inspect(@range.iter(start=Int64(1), end=5, step=0).count(), content="0")
  inspect(@range.iter(start=UInt(1), end=5, step=0).count(), content="0")
  inspect(@range.iter(start=UInt64(1), end=5, step=0).count(), content="0")
  inspect(@range.iter(start=Int16(1), end=5, step=0).count(), content="0")
  inspect(@range.iter(start=UInt16(1), end=5, step=0).count(), content="0")
  inspect(@range.iter(start=Byte(1), end=5, step=0).count(), content="0")
  inspect(@range.iter(start=Float(1.0), end=5.0, step=0.0).count(), content="0")
  inspect(
    @range.iter(start=(1 : @bigint.BigInt), end=5, step=0).count(),
    content="0",
  )
}

///|
test "the default step is the type's natural unit step" {
  // omitting `step` uses `Step::step_one`
  @debug.assert_eq(@range.iter(start=Int64(1), end=4).to_array(), [1, 2, 3])
  @debug.assert_eq(@range.iter(start=Float(1.0), end=4.0).to_array(), [1, 2, 3])
}

///|
test "a negative step descends" {
  @debug.assert_eq(
    @range.iter(start=Float(5.0), end=1.0, step=-1.0).to_array(),
    [5, 4, 3, 2],
  )
  @debug.assert_eq(
    @range.iter(start=Int64(5), end=1, step=-1, inclusive=true).to_array(),
    [5, 4, 3, 2, 1],
  )
}
