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
// the zero-step (empty) direction for every numeric type, the default
// `step_one` for Int64/Float, and a descending Float range.

///|
test "a zero step yields an empty range for every Step type" {
  inspect(@range.iter(from=(1 : Int64), to=5, step=0).count(), content="0")
  inspect(@range.iter(from=(1 : UInt), to=5, step=0).count(), content="0")
  inspect(@range.iter(from=(1 : UInt64), to=5, step=0).count(), content="0")
  inspect(@range.iter(from=(1 : Int16), to=5, step=0).count(), content="0")
  inspect(@range.iter(from=(1 : UInt16), to=5, step=0).count(), content="0")
  inspect(@range.iter(from=(1 : Byte), to=5, step=0).count(), content="0")
  inspect(
    @range.iter(from=(1.0 : Float), to=5.0, step=0.0).count(),
    content="0",
  )
  inspect(
    @range.iter(from=(1 : @bigint.BigInt), to=5, step=0).count(),
    content="0",
  )
}

///|
test "the default step is the type's natural unit step" {
  // omitting `step` uses `Step::step_one`
  @debug.assert_eq(@range.iter(from=(1 : Int64), to=4).to_array(), [1, 2, 3])
  @debug.assert_eq(@range.iter(from=(1.0 : Float), to=4.0).to_array(), [1, 2, 3])
}

///|
test "a negative step descends" {
  @debug.assert_eq(
    @range.iter(from=(5.0 : Float), to=1.0, step=-1.0).to_array(),
    [5, 4, 3, 2],
  )
  @debug.assert_eq(
    @range.iter(from=(5 : Int64), to=1, step=-1, inclusive=true).to_array(),
    [5, 4, 3, 2, 1],
  )
}
