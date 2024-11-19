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
    @double.not_a_number.trunc().reinterpret_as_uint64(),
    @double.not_a_number.reinterpret_as_uint64(),
  )
  assert_eq!(@double.infinity.trunc(), @double.infinity)
  assert_eq!(@double.neg_infinity.trunc(), @double.neg_infinity)
  assert_eq!(@double.max_value.trunc(), @double.max_value)
  assert_eq!(@double.min_value.trunc(), @double.min_value)
  assert_eq!(0.0.trunc(), 0.0)
  assert_eq!((-0.0).trunc(), -0.0)
  assert_eq!(0.001.trunc(), 0.0)
  assert_eq!(0.5.trunc(), 0.0)
  assert_eq!(0.999.trunc(), 0.0)
  assert_eq!(1.001.trunc(), 1.0)
  assert_eq!(1.5.trunc(), 1.0)
  assert_eq!(1.999.trunc(), 1.0)
  assert_eq!(2251799813685248.5.trunc(), 2251799813685248.0)
  assert_eq!(4503599627370495.5.trunc(), 4503599627370495.0)
  assert_eq!(4503599627370496.0.trunc(), 4503599627370496.0)
  assert_eq!(9007199254740992.0.trunc(), 9007199254740992.0)
  assert_eq!(16777216.0.trunc(), 16777216.0)
  assert_eq!((-0.001).trunc(), -0.0)
  assert_eq!((-0.5).trunc(), -0.0)
  assert_eq!((-0.999).trunc(), -0.0)
  assert_eq!((-1.001).trunc(), -1.0)
  assert_eq!((-1.5).trunc(), -1.0)
  assert_eq!((-1.999).trunc(), -1.0)
  assert_eq!((-2251799813685248.5).trunc(), -2251799813685248.0)
  assert_eq!((-4503599627370495.5).trunc(), -4503599627370495.0)
  assert_eq!((-4503599627370496.0).trunc(), -4503599627370496.0)
  assert_eq!((-9007199254740992.0).trunc(), -9007199254740992.0)
}

test "ceil" {
  assert_eq!(
    @double.not_a_number.ceil().reinterpret_as_uint64(),
    @double.not_a_number.reinterpret_as_uint64(),
  )
  assert_eq!(@double.infinity.ceil(), @double.infinity)
  assert_eq!(@double.neg_infinity.ceil(), @double.neg_infinity)
  assert_eq!(@double.max_value.ceil(), @double.max_value)
  assert_eq!(@double.min_value.ceil(), @double.min_value)
  assert_eq!(0.0.ceil(), 0.0)
  assert_eq!((-0.0).ceil(), -0.0)
  assert_eq!(0.001.ceil(), 1.0)
  assert_eq!(0.5.ceil(), 1.0)
  assert_eq!(0.999.ceil(), 1.0)
  assert_eq!(1.001.ceil(), 2.0)
  assert_eq!(1.5.ceil(), 2.0)
  assert_eq!(1.999.ceil(), 2.0)
  assert_eq!(2251799813685248.5.ceil(), 2251799813685249.0)
  assert_eq!(4503599627370495.5.ceil(), 4503599627370496.0)
  assert_eq!(4503599627370496.0.ceil(), 4503599627370496.0)
  assert_eq!(9007199254740992.0.ceil(), 9007199254740992.0)
  assert_eq!(16777216.0.ceil(), 16777216.0)
  assert_eq!((-0.001).ceil(), -0.0)
  assert_eq!((-0.5).ceil(), -0.0)
  assert_eq!((-0.999).ceil(), -0.0)
  assert_eq!((-1.001).ceil(), -1.0)
  assert_eq!((-1.5).ceil(), -1.0)
  assert_eq!((-1.999).ceil(), -1.0)
  assert_eq!((-2251799813685248.5).ceil(), -2251799813685248.0)
  assert_eq!((-4503599627370495.5).ceil(), -4503599627370495.0)
  assert_eq!((-4503599627370496.0).ceil(), -4503599627370496.0)
  assert_eq!((-9007199254740992.0).ceil(), -9007199254740992.0)
}

test "floor" {
  assert_eq!(
    @double.not_a_number.floor().reinterpret_as_uint64(),
    @double.not_a_number.reinterpret_as_uint64(),
  )
  assert_eq!(@double.infinity.floor(), @double.infinity)
  assert_eq!(@double.neg_infinity.floor(), @double.neg_infinity)
  assert_eq!(@double.max_value.floor(), @double.max_value)
  assert_eq!(@double.min_value.floor(), @double.min_value)
  assert_eq!(0.0.floor(), 0.0)
  assert_eq!((-0.0).floor(), -0.0)
  assert_eq!(0.001.floor(), 0.0)
  assert_eq!(0.5.floor(), 0.0)
  assert_eq!(0.999.floor(), 0.0)
  assert_eq!(1.001.floor(), 1.0)
  assert_eq!(1.5.floor(), 1.0)
  assert_eq!(1.999.floor(), 1.0)
  assert_eq!(2251799813685248.5.floor(), 2251799813685248.0)
  assert_eq!(4503599627370495.5.floor(), 4503599627370495.0)
  assert_eq!(4503599627370496.0.floor(), 4503599627370496.0)
  assert_eq!(9007199254740992.0.floor(), 9007199254740992.0)
  assert_eq!(16777216.0.floor(), 16777216.0)
  assert_eq!((-0.001).floor(), -1.0)
  assert_eq!((-0.5).floor(), -1.0)
  assert_eq!((-0.999).floor(), -1.0)
  assert_eq!((-1.001).floor(), -2.0)
  assert_eq!((-1.5).floor(), -2.0)
  assert_eq!((-1.999).floor(), -2.0)
  assert_eq!((-2251799813685248.5).floor(), -2251799813685249.0)
  assert_eq!((-4503599627370495.5).floor(), -4503599627370496.0)
  assert_eq!((-4503599627370496.0).floor(), -4503599627370496.0)
  assert_eq!((-9007199254740992.0).floor(), -9007199254740992.0)
}

test "round" {
  assert_eq!(
    @double.not_a_number.round().reinterpret_as_uint64(),
    @double.not_a_number.reinterpret_as_uint64(),
  )
  assert_eq!(@double.infinity.round(), @double.infinity)
  assert_eq!(@double.neg_infinity.round(), @double.neg_infinity)
  assert_eq!(@double.max_value.round(), @double.max_value)
  assert_eq!(@double.min_value.round(), @double.min_value)
  assert_eq!(0.0.round(), 0.0)
  assert_eq!((-0.0).round(), -0.0)
  assert_eq!(0.001.round(), 0.0)
  assert_eq!(0.5.round(), 0.0)
  assert_eq!(0.999.round(), 1.0)
  assert_eq!(1.001.round(), 1.0)
  assert_eq!(1.5.round(), 2.0)
  assert_eq!(1.999.round(), 2.0)
  assert_eq!(2251799813685248.5.round(), 2251799813685248.0)
  assert_eq!(4503599627370495.5.round(), 4503599627370496.0)
  assert_eq!(4503599627370496.0.round(), 4503599627370496.0)
  assert_eq!(9007199254740992.0.round(), 9007199254740992.0)
  assert_eq!((-0.001).round(), -0.0)
  assert_eq!((-0.5).round(), -0.0)
  assert_eq!((-0.999).round(), -1.0)
  assert_eq!((-1.001).round(), -1.0)
  assert_eq!((-1.5).round(), -2.0)
  assert_eq!((-1.999).round(), -2.0)
  assert_eq!((-2251799813685248.5).round(), -2251799813685248.0)
  assert_eq!((-4503599627370495.5).round(), -4503599627370496.0)
  assert_eq!((-4503599627370496.0).round(), -4503599627370496.0)
  assert_eq!((-9007199254740992.0).round(), -9007199254740992.0)
}
