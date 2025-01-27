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

///|
//Compare two Double values for equality within the allowed error range of 4.5e-9.
fn imprecise_equal(x : Double, y : Double) -> Bool {
  (x - y).abs() < 4.5e-9
}

///|
fn inaccuracy(x : Double, y : Double) -> Double {
  (x - y).abs()
}

///|
let vf = [
  4.9790119248836735e+00, 7.7388724745781045e+00, -2.7688005719200159e-01, -5.0106036182710749e+00,
  9.6362937071984173e+00, 2.9263772392439646e+00, 5.2290834314593066e+00, 2.7279399104360102e+00,
  1.8253080916808550e+00, -8.6859247685756013e+00,
]

test "atan" {
  let atan_res : FixedArray[_] = [
    1.372590262129621651920085e+00, 1.442290609645298083020664e+00, -2.7011324359471758245192595e-01,
    -1.3738077684543379452781531e+00, 1.4673921193587666049154681e+00, 1.2415173565870168649117764e+00,
    1.3818396865615168979966498e+00, 1.2194305844639670701091426e+00, 1.0696031952318783760193244e+00,
    -1.4561721938838084990898679e+00,
  ]
  inspect!(@math.atan(@double.not_a_number), content="NaN")
  inspect!(@math.atan(@double.infinity), content="1.5707963267948966")
  inspect!(@math.atan(@double.neg_infinity), content="-1.5707963267948966")
  let mut max_inaccuracy = 0.0
  for i = 0; i < vf.length(); i = i + 1 {
    inspect!(imprecise_equal(@math.atan(vf[i]), atan_res[i]), content="true")
    max_inaccuracy = @math.maximum(
      max_inaccuracy,
      inaccuracy(@math.atan(vf[i]), atan_res[i]),
    )
  }
  inspect!(max_inaccuracy, content="2.220446049250313e-16")
}

test "asin" {
  let asin_res : FixedArray[_] = [
    5.2117697218417440497416805e-01, 8.8495619865825236751471477e-01, -02.769154466281941332086016e-02,
    -5.2482360935268931351485822e-01, 1.3002662421166552333051524e+00, 2.9698415875871901741575922e-01,
    5.5025938468083370060258102e-01, 2.7629597861677201301553823e-01, 1.83559892257451475846656e-01,
    -1.0523547536021497774980928e+00,
  ]
  inspect!(@math.asin(@double.not_a_number), content="NaN")
  inspect!(@math.asin(@double.infinity), content="NaN")
  inspect!(@math.asin(@double.neg_infinity), content="NaN")
  let mut max_inaccuracy = 0.0
  for i = 0; i < vf.length(); i = i + 1 {
    inspect!(
      imprecise_equal(@math.asin(vf[i] / 10.0), asin_res[i]),
      content="true",
    )
    max_inaccuracy = @math.maximum(
      max_inaccuracy,
      inaccuracy(@math.asin(vf[i] / 10.0), asin_res[i]),
    )
  }
  inspect!(max_inaccuracy, content="2.220446049250313e-16")
}

test "acos" {
  let acos_res : FixedArray[_] = [
    1.0496193546107222142571536e+00, 6.8584012813664425171660692e-01, 1.5984878714577160325521819e+00,
    2.0956199361475859327461799e+00, 2.7053008467824138592616927e-01, 1.2738121680361776018155625e+00,
    1.0205369421140629186287407e+00, 1.2945003481781246062157835e+00, 1.3872364345374451433846657e+00,
    2.6231510803970463967294145e+00,
  ]
  inspect!(@math.acos(@double.not_a_number), content="NaN")
  inspect!(@math.acos(@double.infinity), content="NaN")
  inspect!(@math.acos(@double.neg_infinity), content="NaN")
  let mut max_inaccuracy = 0.0
  for i = 0; i < vf.length(); i = i + 1 {
    inspect!(
      imprecise_equal(@math.acos(vf[i] / 10.0), acos_res[i]),
      content="true",
    )
    max_inaccuracy = @math.maximum(
      max_inaccuracy,
      inaccuracy(@math.acos(vf[i] / 10.0), acos_res[i]),
    )
  }
  inspect!(max_inaccuracy, content="2.220446049250313e-16")
}

test "atan2" {
  let atan2_res : FixedArray[Double] = [
    1.1088291730037004444527075e+00, 9.1218183188715804018797795e-01, 1.5984772603216203736068915e+00,
    2.0352918654092086637227327e+00, 8.0391819139044720267356014e-01, 1.2861075249894661588866752e+00,
    1.0889904479131695712182587e+00, 1.3044821793397925293797357e+00, 1.3902530903455392306872261e+00,
    2.2859857424479142655411058e+00,
  ]
  let mut max_inaccuracy = 0.0
  for i = 0; i < vf.length(); i = i + 1 {
    inspect!(
      imprecise_equal(@math.atan2(10, vf[i]), atan2_res[i]),
      content="true",
    )
    max_inaccuracy = @math.maximum(
      max_inaccuracy,
      inaccuracy(@math.atan2(10, vf[i]), atan2_res[i]),
    )
  }
  inspect!(max_inaccuracy, content="4.440892098500626e-16")
}

test "tan with very small value" {
  let x = 1.0e-8 // x * x = 1.0e-16 < 1.0e-14
  inspect!(@math.tan(x), content="1e-8")
}

test "asin with value greater than 1" {
  inspect!(@math.asin(1.5), content="NaN")
}

test "atan2 with NaN" {
  let y = @double.not_a_number
  let x = 1.0
  inspect!(atan2(y, x), content="NaN")
  inspect!(atan2(1.0, @double.not_a_number), content="NaN")
}

test "atan2 with zero x" {
  inspect!(atan2(1.0, 0.0), content="1.5707963267948966")
  inspect!(atan2(-1.0, 0.0), content="-1.5707963267948966")
}

test "atan2 with zero y" {
  inspect!(atan2(0.0, 1.0), content="0")
  inspect!(atan2(0.0, -1.0), content="3.141592653589793")
  inspect!(atan2(-0.0, -1.0), content="-3.141592653589793")
}

test "atan2 with infinite y and finite x" {
  inspect!(atan2(@double.infinity, 1.0), content="1.5707963267948966")
  inspect!(atan2(-@double.infinity, 1.0), content="-1.5707963267948966")
}

test "atan2 with infinite x and finite y" {
  inspect!(@math.atan2(1.0, @double.infinity), content="0")
  inspect!(@math.atan2(1.0, @double.neg_infinity), content="3.141592653589793")
  inspect!(@math.atan2(-1.0, @double.infinity), content="0")
  inspect!(
    @math.atan2(-1.0, @double.neg_infinity),
    content="-3.141592653589793",
  )
}

test "atan2 with infinite x and infinite y" {
  inspect!(
    @math.atan2(@double.infinity, @double.infinity),
    content="0.7853981633974483",
  )
  inspect!(
    @math.atan2(@double.neg_infinity, @double.infinity),
    content="-0.7853981633974483",
  )
  inspect!(
    @math.atan2(@double.infinity, @double.neg_infinity),
    content="2.356194490192345",
  )
  inspect!(
    @math.atan2(@double.neg_infinity, @double.neg_infinity),
    content="-2.356194490192345",
  )
}
