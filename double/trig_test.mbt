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

test "Inverse trigonometric functions" {
  // asin
  inspect!(0.0.asin(), content="0")
  inspect!(1.0.asin(), content="1.5707963267948966")
  inspect!((-1.0).asin(), content="-1.5707963267948966")
  inspect!(0.5.asin(), content="0.5235987755982989")
  inspect!(0.45.asin(), content="0.4667653390472964")
  inspect!(@double.not_a_number.asin(), content="NaN")
  inspect!(@double.infinity.asin(), content="NaN")
  inspect!(@double.neg_infinity.asin(), content="NaN")

  // acos
  inspect!(0.0.acos(), content="1.5707963267948966")
  inspect!(1.0.acos(), content="0")
  inspect!((-1.0).acos(), content="3.141592653589793")
  inspect!(0.5.acos(), content="1.0471975511965979")
  inspect!(0.45.acos(), content="1.1040309877476002")
  inspect!(@double.not_a_number.acos(), content="NaN")
  inspect!(@double.infinity.acos(), content="NaN")
  inspect!(@double.neg_infinity.acos(), content="NaN")

  // High accuracy test
  let vals = [
    0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 0.123, 0.234, 0.345, 0.456, 0.567,
    0.678, 0.789, 0.891, 0.912, 0.1234, -0.135, -0.246, -0.357, -0.468, -0.579, -0.681,
    -0.792, -0.893, -0.994, -0.12345,
  ]
  let asin_res = [
    0.1001674211615598, 0.2013579207903308, 0.3046926540153975, 0.41151684606748806,
    0.5235987755982989, 0.6435011087932844, 0.775397496610753, 0.9272952180016123,
    1.1197695149986342, 0.12331227519187199, 0.23618988434810217, 0.35223878509706474,
    0.47349551215005636, 0.6028592463891203, 0.745038349213386, 0.9091796699171293,
    1.0995430581994015, 1.148133721990592, 0.12371534584255098, -0.13541346246655556,
    -0.24855126213339576, -0.36505428193897027, -0.4870262796643988, -0.61750165481717,
    -0.7491273605521073, -0.9140779620461925, -1.1039675362433812, -1.4611969689632571,
    -0.12376573109305462,
  ]
  let acos_res = [
    1.4706289056333368, 1.369438406004566, 1.2661036727794992, 1.1592794807274085,
    1.0471975511965979, 0.9272952180016123, 0.7953988301841436, 0.6435011087932843,
    0.45102681179626236, 1.4474840516030247, 1.3346064424467945, 1.2185575416978318,
    1.0973008146448402, 0.9679370804057764, 0.8257579775815106, 0.6616166568777674,
    0.47125326859549527, 0.4226626048043045, 1.4470809809523457, 1.706209789261452,
    1.8193475889282924, 1.935850608733867, 2.0578226064592955, 2.1882979816120667,
    2.319923687347004, 2.4848742888410893, 2.6747638630382777, 3.031993295758154,
    1.6945620578879512,
  ]
  fn high_accuracy_test(expect : Double, actual : Double) -> Unit!Error {
    let ulp = (expect.reinterpret_as_int64() - actual.reinterpret_as_int64()).abs()
    assert_eq!(ulp <= 1, true)
  }

  for i in 0..<vals.length() {
    high_accuracy_test!(vals[i].asin(), asin_res[i])
    high_accuracy_test!(vals[i].acos(), acos_res[i])
  }
}

test "atan" {
  // atan
  inspect!(0.0.atan(), content="0")
  inspect!(1.0.atan(), content="0.7853981633974483")
  inspect!((-1.0).atan(), content="-0.7853981633974483")
  inspect!(0.5.atan(), content="0.4636476090008061")
  inspect!(0.45.atan(), content="0.4228539261329407")
  inspect!(31415926535897.1234.atan(), content="1.5707963267948648")
  inspect!(-27182818284590.5678.atan(), content="-1.57079632679486")
  inspect!(@double.not_a_number.atan(), content="NaN")
  inspect!(@double.infinity.atan(), content="1.5707963267948966")
  inspect!(@double.neg_infinity.atan(), content="-1.5707963267948966")
  let vals = [
    1.1, 3.3, 4.4, 5.5, 11.22, 33.44, 55.66, 77.88, 99.99, -1.0, -2.1, -3.21, -4.321,
    -5.4321, -6.54321, -7.654321, -8.7654321, -9.87654321, -10.987654321, 123456789.1,
    234567891.2, 345678912.3, 456789123.4, 567891234.5, 678912345.6, 789123456.7,
    891234567.8, 912345678.9, 123456789.01, -135792468.1, -357924681.3, -57924681.5,
    -7924681.7, -924681.9, -24681.01, -4681.23,
  ]
  let atan_res = [
    0.8329812666744317, 1.2765617616837088, 1.3473197256542635, 1.3909428270024184,
    1.4819046422200983, 1.540900929944898, 1.552832035997718, 1.5579567653163433,
    1.5607956601082313, -0.7853981633974483, -1.1263771168937977, -1.2687986121971189,
    -1.343372193641761, -1.3887437506630411, -1.4191396270967231, -1.440886936094721,
    -1.457202937285794, -1.4698902043265738, -1.4800351327361252, 1.5707963186948966,
    1.5707963225317385, 1.5707963239020386, 1.5707963246057026, 1.570796325033996,
    1.5707963253219523, 1.5707963255276678, 1.5707963256728577, 1.5707963256988209,
    1.5707963186948966, -1.570796319430718, -1.5707963240010128, -1.5707963095310986,
    -1.5707962006068632, -1.5707952453419127, -1.570755809814455, -1.5705827077279444,
  ]
  fn high_accuracy_test(expect : Double, actual : Double) -> Unit!Error {
    let ulp = (expect.reinterpret_as_int64() - actual.reinterpret_as_int64()).abs()
    assert_eq!(ulp <= 1, true)
  }

  for i in 0..<vals.length() {
    high_accuracy_test!(vals[i].atan(), atan_res[i])
  }
}

test "atan2" {
  // atan2
  inspect!(0.0.atan2(-1.0), content="3.141592653589793")
  inspect!(1.0.atan2(0.0), content="1.5707963267948966")
  inspect!(1.0.atan2(1.0), content="0.7853981633974483")
  inspect!(not_a_number.atan2(1.0), content="NaN")
  inspect!(1.0.atan2(not_a_number), content="NaN")
  inspect!(infinity.atan2(1.0), content="1.5707963267948966")
  inspect!(1.0.atan2(infinity), content="0")
  inspect!(neg_infinity.atan2(1.0), content="-1.5707963267948966")
  inspect!(1.0.atan2(neg_infinity), content="3.141592653589793")
  inspect!(infinity.atan2(infinity), content="0.7853981633974483")
  inspect!(neg_infinity.atan2(neg_infinity), content="-2.356194490192345")
  inspect!(infinity.atan2(neg_infinity), content="2.356194490192345")
  inspect!(neg_infinity.atan2(infinity), content="-0.7853981633974483")

  // High accuracy test
  let vals = [0.12, 0.34, 0.56, 0.78, 0.9785]
  let atan2_res = [
    0.7853981633974483, 0.3392926144540446, 0.2110933332227465, 0.15264932839526515,
    0.12202736915798754, 1.231503712340852, 0.7853981633974483, 0.5456550545269917,
    0.4110645473898644, 0.33441969792485843, 1.35970299357215, 1.025141272267905,
    0.7853981633974483, 0.6226707887570673, 0.5198062164665054, 1.4181469983996315,
    1.1597317794050321, 0.9481255380378293, 0.7853981633974483, 0.6729936741108642,
    1.4487689576369092, 1.2363766288700382, 1.0509901103283912, 0.8978026526840324,
    0.7853981633974483,
  ]
  fn high_accuracy_test(expect : Double, actual : Double) -> Unit!Error {
    let ulp = (expect.reinterpret_as_int64() - actual.reinterpret_as_int64()).abs()
    assert_eq!(ulp <= 1, true)
  }

  let mut idx = 0
  for y in vals {
    for x in vals {
      high_accuracy_test!(y.atan2(x), atan2_res[idx])
      idx = idx + 1
    }
  }
}
