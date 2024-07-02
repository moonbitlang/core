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

let pi = 0x3.243F6A8885A308CA8A54

//Compare two Double values for equality within the allowed error range of 4.5e-9.
fn imprecise_equal(x : Double, y : Double) -> Bool {
  (x - y).abs() < 4.5e-9
}

let vf = [
  4.9790119248836735e+00, 7.7388724745781045e+00, -2.7688005719200159e-01, -5.0106036182710749e+00,
  9.6362937071984173e+00, 2.9263772392439646e+00, 5.2290834314593066e+00, 2.7279399104360102e+00,
  1.8253080916808550e+00, -8.6859247685756013e+00,
]

test "sin" {
  let sin_res : FixedArray[_] = [
    -9.6466616586009283766724726e-01, 9.9338225271646545763467022e-01, -2.7335587039794393342449301e-01,
    9.5586257685042792878173752e-01, -2.099421066779969164496634e-01, 2.135578780799860532750616e-01,
    -8.694568971167362743327708e-01, 4.019566681155577786649878e-01, 9.6778633541687993721617774e-01,
    -6.734405869050344734943028e-01,
  ]
  let sin_res_large : FixedArray[_] = [
    -9.646661658548936063912e-01, 9.933822527198506903752e-01, -2.7335587036246899796e-01,
    9.55862576853689321268e-01, -2.099421066862688873691e-01, 2.13557878070308981163e-01,
    -8.694568970959221300497e-01, 4.01956668098863248917e-01, 9.67786335404528727927e-01,
    -6.7344058693131973066e-01,
  ]
  inspect(@math.sin(Double::nan()), content="NaN")!
  inspect(@math.sin(Double::inf(1)), content="Infinity")!
  inspect(@math.sin(Double::inf(-1)), content="-Infinity")!
  for i = 0; i < vf.length(); i = i + 1 {
    inspect(imprecise_equal(@math.sin(vf[i]), sin_res[i]), content="true")!
    inspect(
      imprecise_equal(@math.sin(100000.0 * pi + vf[i]), sin_res_large[i]),
      content="true",
    )!
  }
}

test "cos" {
  let cos_res : FixedArray[_] = [
    2.634752140995199110787593e-01, 1.148551260848219865642039e-01, 9.6191297325640768154550453e-01,
    2.938141150061714816890637e-01, -9.777138189897924126294461e-01, -9.7693041344303219127199518e-01,
    4.940088096948647263961162e-01, -9.1565869021018925545016502e-01, -2.517729313893103197176091e-01,
    -7.39241351595676573201918e-01,
  ]
  let cos_res_large : FixedArray[_] = [
    2.634752141185559426744e-01, 1.14855126055543100712e-01, 9.61912973266488928113e-01,
    2.9381411499556122552e-01, -9.777138189880161924641e-01, -9.76930413445147608049e-01,
    4.940088097314976789841e-01, -9.15658690217517835002e-01, -2.51772931436786954751e-01,
    -7.3924135157173099849e-01,
  ]
  inspect(@math.cos(Double::nan()), content="NaN")!
  inspect(@math.cos(Double::inf(1)), content="Infinity")!
  inspect(@math.cos(Double::inf(-1)), content="-Infinity")!
  for i = 0; i < vf.length(); i = i + 1 {
    inspect(imprecise_equal(@math.cos(vf[i]), cos_res[i]), content="true")!
    inspect(
      imprecise_equal(@math.cos(100000.0 * pi + vf[i]), cos_res_large[i]),
      content="true",
    )!
  }
}

test "tan" {
  let tan_res : FixedArray[_] = [
    -3.661316565040227801781974e+00, 8.64900232648597589369854e+00, -2.8417941955033612725238097e-01,
    3.253290185974728640827156e+00, 2.147275640380293804770778e-01, -2.18600910711067004921551e-01,
    -1.760002817872367935518928e+00, -4.389808914752818126249079e-01, -3.843885560201130679995041e+00,
    9.10988793377685105753416e-01,
  ]
  let tan_res_large : FixedArray[_] = [
    -3.66131656475596512705e+00, 8.6490023287202547927e+00, -2.841794195104782406e-01,
    3.2532901861033120983e+00, 2.14727564046880001365e-01, -2.18600910700688062874e-01,
    -1.760002817699722747043e+00, -4.38980891453536115952e-01, -3.84388555942723509071e+00,
    9.1098879344275101051e-01,
  ]
  inspect(@math.tan(Double::nan()), content="NaN")!
  inspect(@math.tan(Double::inf(1)), content="Infinity")!
  inspect(@math.tan(Double::inf(-1)), content="-Infinity")!
  for i = 0; i < vf.length(); i = i + 1 {
    inspect(imprecise_equal(@math.tan(vf[i]), tan_res[i]), content="true")!
    inspect(
      imprecise_equal(@math.tan(100000.0 * pi + vf[i]), tan_res_large[i]),
      content="true",
    )!
  }
}

test "atan" {
  let atan_res : FixedArray[_] = [
    1.372590262129621651920085e+00, 1.442290609645298083020664e+00, -2.7011324359471758245192595e-01,
    -1.3738077684543379452781531e+00, 1.4673921193587666049154681e+00, 1.2415173565870168649117764e+00,
    1.3818396865615168979966498e+00, 1.2194305844639670701091426e+00, 1.0696031952318783760193244e+00,
    -1.4561721938838084990898679e+00,
  ]
  inspect(@math.atan(Double::nan()), content="NaN")!
  inspect(@math.atan(Double::inf(1)), content="Infinity")!
  inspect(@math.atan(Double::inf(-1)), content="-Infinity")!
  for i = 0; i < vf.length(); i = i + 1 {
    inspect(imprecise_equal(@math.atan(vf[i]), atan_res[i]), content="true")!
  }
}

test "asin" {
  let asin_res : FixedArray[_] = [
    5.2117697218417440497416805e-01, 8.8495619865825236751471477e-01, -02.769154466281941332086016e-02,
    -5.2482360935268931351485822e-01, 1.3002662421166552333051524e+00, 2.9698415875871901741575922e-01,
    5.5025938468083370060258102e-01, 2.7629597861677201301553823e-01, 1.83559892257451475846656e-01,
    -1.0523547536021497774980928e+00,
  ]
  inspect(@math.asin(Double::nan()), content="NaN")!
  inspect(@math.asin(Double::inf(1)), content="Infinity")!
  inspect(@math.asin(Double::inf(-1)), content="-Infinity")!
  for i = 0; i < vf.length(); i = i + 1 {
    inspect(
      imprecise_equal(@math.asin(vf[i] / 10.0), asin_res[i]),
      content="true",
    )!
  }
}

test "acos" {
  let acos_res : FixedArray[_] = [
    1.0496193546107222142571536e+00, 6.8584012813664425171660692e-01, 1.5984878714577160325521819e+00,
    2.0956199361475859327461799e+00, 2.7053008467824138592616927e-01, 1.2738121680361776018155625e+00,
    1.0205369421140629186287407e+00, 1.2945003481781246062157835e+00, 1.3872364345374451433846657e+00,
    2.6231510803970463967294145e+00,
  ]
  inspect(@math.acos(Double::nan()), content="NaN")!
  inspect(@math.acos(Double::inf(1)), content="Infinity")!
  inspect(@math.acos(Double::inf(-1)), content="-Infinity")!
  for i = 0; i < vf.length(); i = i + 1 {
    inspect(
      imprecise_equal(@math.acos(vf[i] / 10.0), acos_res[i]),
      content="true",
    )!
  }
}
