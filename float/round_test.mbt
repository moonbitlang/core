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

test "trunc" {
  assert_eq!(
    @float.not_a_number.trunc().reinterpret_as_uint(),
    @float.not_a_number.reinterpret_as_uint(),
  )
  assert_eq!(@float.infinity.trunc(), @float.infinity)
  assert_eq!(@float.neg_infinity.trunc(), @float.neg_infinity)
  assert_eq!(@float.max_value.trunc(), @float.max_value)
  assert_eq!(@float.min_value.trunc(), @float.min_value)
  assert_eq!((0.0 : Float).trunc(), 0.0)
  assert_eq!((-0.0 : Float).trunc(), -0.0)
  assert_eq!((0.001 : Float).trunc(), 0.0)
  assert_eq!((0.5 : Float).trunc(), 0.0)
  assert_eq!((0.999 : Float).trunc(), 0.0)
  assert_eq!((1.001 : Float).trunc(), 1.0)
  assert_eq!((1.5 : Float).trunc(), 1.0)
  assert_eq!((1.999 : Float).trunc(), 1.0)
  assert_eq!((4194304.5 : Float).trunc(), 4194304.0)
  assert_eq!((8388607.5 : Float).trunc(), 8388607.0)
  assert_eq!((8388608.0 : Float).trunc(), 8388608.0)
  assert_eq!((16777216.0 : Float).trunc(), 16777216.0)
  assert_eq!((-0.001 : Float).trunc(), -0.0)
  assert_eq!((-0.5 : Float).trunc(), -0.0)
  assert_eq!((-0.999 : Float).trunc(), -0.0)
  assert_eq!((-1.001 : Float).trunc(), -1.0)
  assert_eq!((-1.5 : Float).trunc(), -1.0)
  assert_eq!((-1.999 : Float).trunc(), -1.0)
  assert_eq!((-4194304.5 : Float).trunc(), -4194304.0)
  assert_eq!((-8388607.5 : Float).trunc(), -8388607.0)
  assert_eq!((-8388608.0 : Float).trunc(), -8388608.0)
  assert_eq!((-16777216.0 : Float).trunc(), -16777216.0)
}

test "ceil" {
  assert_eq!(
    @float.not_a_number.ceil().reinterpret_as_uint(),
    @float.not_a_number.reinterpret_as_uint(),
  )
  assert_eq!(@float.infinity.ceil(), @float.infinity)
  assert_eq!(@float.neg_infinity.ceil(), @float.neg_infinity)
  assert_eq!(@float.max_value.ceil(), @float.max_value)
  assert_eq!(@float.min_value.ceil(), @float.min_value)
  assert_eq!((0.0 : Float).ceil(), 0.0)
  assert_eq!((-0.0 : Float).ceil(), -0.0)
  assert_eq!((0.001 : Float).ceil(), 1.0)
  assert_eq!((0.5 : Float).ceil(), 1.0)
  assert_eq!((0.999 : Float).ceil(), 1.0)
  assert_eq!((1.001 : Float).ceil(), 2.0)
  assert_eq!((1.5 : Float).ceil(), 2.0)
  assert_eq!((1.999 : Float).ceil(), 2.0)
  assert_eq!((4194304.5 : Float).ceil(), 4194305.0)
  assert_eq!((8388607.5 : Float).ceil(), 8388608.0)
  assert_eq!((8388608.0 : Float).ceil(), 8388608.0)
  assert_eq!((16777216.0 : Float).ceil(), 16777216.0)
  assert_eq!((-0.001 : Float).ceil(), -0.0)
  assert_eq!((-0.5 : Float).ceil(), -0.0)
  assert_eq!((-0.999 : Float).ceil(), -0.0)
  assert_eq!((-1.001 : Float).ceil(), -1.0)
  assert_eq!((-1.5 : Float).ceil(), -1.0)
  assert_eq!((-1.999 : Float).ceil(), -1.0)
  assert_eq!((-4194304.5 : Float).ceil(), -4194304.0)
  assert_eq!((-8388607.5 : Float).ceil(), -8388607.0)
  assert_eq!((-8388608.0 : Float).ceil(), -8388608.0)
  assert_eq!((-16777216.0 : Float).ceil(), -16777216.0)
}

test "floor" {
  assert_eq!(
    @float.not_a_number.floor().reinterpret_as_uint(),
    @float.not_a_number.reinterpret_as_uint(),
  )
  assert_eq!(@float.infinity.floor(), @float.infinity)
  assert_eq!(@float.neg_infinity.floor(), @float.neg_infinity)
  assert_eq!(@float.max_value.floor(), @float.max_value)
  assert_eq!(@float.min_value.floor(), @float.min_value)
  assert_eq!((0.0 : Float).floor(), 0.0)
  assert_eq!((-0.0 : Float).floor(), -0.0)
  assert_eq!((0.001 : Float).floor(), 0.0)
  assert_eq!((0.5 : Float).floor(), 0.0)
  assert_eq!((0.999 : Float).floor(), 0.0)
  assert_eq!((1.001 : Float).floor(), 1.0)
  assert_eq!((1.5 : Float).floor(), 1.0)
  assert_eq!((1.999 : Float).floor(), 1.0)
  assert_eq!((4194304.5 : Float).floor(), 4194304.0)
  assert_eq!((8388607.5 : Float).floor(), 8388607.0)
  assert_eq!((8388608.0 : Float).floor(), 8388608.0)
  assert_eq!((16777216.0 : Float).floor(), 16777216.0)
  assert_eq!((-0.001 : Float).floor(), -1.0)
  assert_eq!((-0.5 : Float).floor(), -1.0)
  assert_eq!((-0.999 : Float).floor(), -1.0)
  assert_eq!((-1.001 : Float).floor(), -2.0)
  assert_eq!((-1.5 : Float).floor(), -2.0)
  assert_eq!((-1.999 : Float).floor(), -2.0)
  assert_eq!((-4194304.5 : Float).floor(), -4194305.0)
  assert_eq!((-8388607.5 : Float).floor(), -8388608.0)
  assert_eq!((-8388608.0 : Float).floor(), -8388608.0)
  assert_eq!((-16777216.0 : Float).floor(), -16777216.0)
}

test "round" {
  assert_eq!(
    @float.not_a_number.round().reinterpret_as_uint(),
    @float.not_a_number.reinterpret_as_uint(),
  )
  assert_eq!(@float.infinity.round(), @float.infinity)
  assert_eq!(@float.neg_infinity.round(), @float.neg_infinity)
  assert_eq!(@float.max_value.round(), @float.max_value)
  assert_eq!(@float.min_value.round(), @float.min_value)
  assert_eq!((0.0 : Float).round(), 0.0)
  assert_eq!((-0.0 : Float).round(), -0.0)
  assert_eq!((0.001 : Float).round(), 0.0)
  assert_eq!((0.5 : Float).round(), 0.0)
  assert_eq!((0.999 : Float).round(), 1.0)
  assert_eq!((1.001 : Float).round(), 1.0)
  assert_eq!((1.5 : Float).round(), 2.0)
  assert_eq!((1.999 : Float).round(), 2.0)
  assert_eq!((4194304.5 : Float).round(), 4194304.0)
  assert_eq!((8388607.5 : Float).round(), 8388608.0)
  assert_eq!((8388608.0 : Float).round(), 8388608.0)
  assert_eq!((16777216.0 : Float).round(), 16777216.0)
  assert_eq!((-0.001 : Float).round(), -0.0)
  assert_eq!((-0.5 : Float).round(), -0.0)
  assert_eq!((-0.999 : Float).round(), -1.0)
  assert_eq!((-1.001 : Float).round(), -1.0)
  assert_eq!((-1.5 : Float).round(), -2.0)
  assert_eq!((-1.999 : Float).round(), -2.0)
  assert_eq!((-4194304.5 : Float).round(), -4194304.0)
  assert_eq!((-8388607.5 : Float).round(), -8388608.0)
  assert_eq!((-8388608.0 : Float).round(), -8388608.0)
  assert_eq!((-16777216.0 : Float).round(), -16777216.0)
}
