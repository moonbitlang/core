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

test "trigonometric functions" {
  // sin
  inspect!(0.0.sin(), content="0")
  inspect!(1.570796326794897.sin(), content="1") // pi / 2
  inspect!(2.0.sin(), content="0.9092974268256817")
  inspect!(-5.0.sin(), content="0.9589242746631385")
  inspect!(31415926535897.9323846.sin(), content="0.0012091232715481885")
  inspect!(@double.not_a_number.sin(), content="NaN")
  inspect!(@double.infinity.sin(), content="NaN")
  inspect!(@double.neg_infinity.sin(), content="NaN")

  // cos
  inspect!(0.0.cos(), content="1")
  inspect!(2.5.cos(), content="-0.8011436155469337")
  inspect!((-3.141592653589793).cos(), content="-1") // -pi
  inspect!((-5.0).cos(), content="0.28366218546322625")
  inspect!(31415926535897.9323846.cos(), content="0.9999992690101899")
  inspect!(@double.not_a_number.cos(), content="NaN")
  inspect!(@double.infinity.cos(), content="NaN")
  inspect!(@double.neg_infinity.cos(), content="NaN")

  // tan
  inspect!(0.0.tan(), content="0")
  inspect!(0.7853981633974483.tan(), content="0.9999999999999999")
  inspect!(4.0.tan(), content="1.1578212823495777")
  inspect!(5.0.tan(), content="-3.380515006246586")
  inspect!(31415926535897.9323846.tan(), content="0.0012091241554056254")
  inspect!(@double.not_a_number.tan(), content="NaN")
  inspect!(@double.infinity.tan(), content="NaN")
  inspect!(@double.neg_infinity.tan(), content="NaN")

  // Consistency Test
  let vals = [
    1.1, 3.3, 4.4, 5.5, 11.22, 33.44, 55.66, 77.88, 99.99, -1.0, -2.1, -3.21, -4.321,
    -5.4321, -6.54321, -7.654321, -8.7654321, -9.87654321, -10.987654321, 123456789.1,
    234567891.2, 345678912.3, 456789123.4, 567891234.5, 678912345.6, 789123456.7,
    891234567.8, 912345678.9, 123456789.01,
  ]

  // Results get from JavaScript V8
  let sin_res = [
    0.8912073600614354, -0.1577456941432482, -0.9516020738895161, -0.7055403255703919,
    -0.9749220735246146, 0.8990168278954119, -0.7762325332088996, 0.612971751458885,
    -0.5149633680424761, -0.8414709848078965, -0.8632093666488737, 0.06835400612104778,
    0.9243800935781268, 0.7519962469828865, -0.2571044147079568, -0.9801339430243416,
    -0.6125999559240065, 0.43655436914142864, 0.999968637228749, 0.9991709051289052,
    0.7065650094118109, -0.6621352221182213, -0.36973782493802004, 0.6337066920505413,
    -0.990764758712146, -0.8321035463409452, -0.4831904888511182, -0.6152185206743059,
    0.9914678206150951,
  ]
  let cos_res = [
    0.4535961214255773, -0.9874797699088649, -0.30733286997841935, 0.70866977429126,
    0.22254651323816765, -0.43791408193945003, 0.6304467101889696, -0.7901048233705619,
    0.8572121846861191, 0.5403023058681398, -0.5048461045998576, -0.9976611297666176,
    -0.38147272850951436, 0.6591673873331824, 0.966383629795993, 0.19833671806187747,
    -0.7903931262364985, -0.8996778772335848, -0.007919883766735825, 0.040712434757508714,
    -0.7076481381837216, -0.7493843790942362, 0.9291361260924591, 0.7735734150359359,
    -0.13559200896093865, 0.5546203099119456, 0.8755152491440783, -0.7883566273072857,
    0.13035168078990628,
  ]
  let tan_res = [
    1.9647596572486523, 0.15974574766003222, 3.0963237806497457, -0.995584052213885,
    -4.380756451040238, -2.052952542457217, -1.2312421028832592, -0.7758106688223559,
    -0.6007420067541824, -1.5574077246549023, 1.7098465429045073, -0.06851425206576686,
    -2.4231878834166034, 1.1408274460077057, -0.2660479821685643, -4.941767478065043,
    0.775057291857959, -0.48523408231820436, -126.26051930568741, 24.542155512932695,
    -0.9984693964225064, 0.883572223534375, -0.3979371962351479, 0.8191939895208301,
    7.306955375206259, -1.500312072006621, -0.5518927161160188, 0.7803809841437486,
    7.606099243270125,
  ]
  fn high_accuracy_test(expect : Double, actual : Double) -> Unit!Error {
    assert_eq!((expect - actual).abs() < 1.0e-14, true)
  }

  for i in 0..<vals.length() {
    high_accuracy_test!(vals[i].sin(), sin_res[i])
    high_accuracy_test!(vals[i].cos(), cos_res[i])
    high_accuracy_test!(vals[i].tan(), tan_res[i])
  }
}
