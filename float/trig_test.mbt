// Copyright 2025 International Digital Economy Academy
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

test "floating point trignometry" {
  // sin
  inspect!((0.0 : Float).sin(), content="0")
  inspect!((2.0 : Float).sin(), content="0.9092974066734314")
  inspect!((-5.0 : Float).sin(), content="0.9589242935180664")
  inspect!(@float.not_a_number.sin(), content="NaN")
  inspect!(@float.infinity.sin(), content="NaN")
  inspect!(@float.neg_infinity.sin(), content="NaN")

  // cos
  inspect!((0.0 : Float).cos(), content="1")
  inspect!((2.0 : Float).cos(), content="-0.416146844625473")
  inspect!((-5.0 : Float).cos(), content="0.28366219997406006") //<
  inspect!(@float.not_a_number.cos(), content="NaN")
  inspect!(@float.infinity.cos(), content="NaN")
  inspect!(@float.neg_infinity.cos(), content="NaN")

  // tan
  inspect!((0.0 : Float).tan(), content="0")
  inspect!((2.0 : Float).tan(), content="-2.185039758682251")
  inspect!((-5.0 : Float).tan(), content="3.3805150985717773")
  inspect!(@float.not_a_number.tan(), content="NaN")
  inspect!(@float.infinity.tan(), content="NaN")
  inspect!(@float.neg_infinity.tan(), content="NaN")

  // asin
  inspect!((0.0 : Float).asin(), content="0")
  inspect!((1.0 : Float).asin(), content="1.5707963705062866")
  inspect!((-1.0 : Float).asin(), content="-1.5707963705062866")
  inspect!(@float.not_a_number.asin(), content="NaN")
  inspect!(@float.infinity.asin(), content="NaN")
  inspect!(@float.neg_infinity.asin(), content="NaN")
  inspect!((0.0 : Float).acos(), content="1.5707963705062866")
  inspect!((1.0 : Float).acos(), content="0")
  inspect!((-1.0 : Float).acos(), content="3.1415927410125732") //<
  inspect!(@float.not_a_number.acos(), content="NaN")
  inspect!(@float.infinity.acos(), content="NaN")
  inspect!(@float.neg_infinity.acos(), content="NaN")

  // atan
  inspect!((0.0 : Float).atan(), content="0")
  inspect!((1.0 : Float).atan(), content="0.7853981852531433")
  inspect!((-1.0 : Float).atan(), content="-0.7853981852531433")
  inspect!(@float.not_a_number.atan(), content="NaN")
  inspect!(@float.infinity.atan(), content="1.5707963705062866")
  inspect!(@float.neg_infinity.atan(), content="-1.5707963705062866")

  // atan2
  inspect!((0.0 : Float).atan2(-1.0), content="3.1415927410125732")
  inspect!((1.0 : Float).atan2(0.0), content="1.5707963705062866")
  inspect!((1.0 : Float).atan2(1.0), content="0.7853981852531433")
  inspect!(@float.not_a_number.atan2(1.0), content="NaN")
  inspect!((1.0 : Float).atan2(not_a_number), content="NaN")
  inspect!(@float.infinity.atan2(1.0), content="1.5707963705062866")
  inspect!((1.0 : Float).atan2(infinity), content="0")
  inspect!(@float.neg_infinity.atan2(1.0), content="-1.5707963705062866")
  inspect!(
    (1.0 : Float).atan2(@float.neg_infinity),
    content="3.1415927410125732",
  )
  inspect!(@float.infinity.atan2(@float.infinity), content="0.7853981852531433")
  inspect!(
    @float.neg_infinity.atan2(@float.neg_infinity),
    content="-2.356194496154785",
  )
  inspect!(
    @float.infinity.atan2(@float.neg_infinity),
    content="2.356194496154785",
  )
  inspect!(
    @float.neg_infinity.atan2(@float.infinity),
    content="-0.7853981852531433",
  )
}
