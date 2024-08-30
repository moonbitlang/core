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

type MyBigInt BigInt

impl Show for MyBigInt with output(self, logger) {
  logger.write_string(
    "{limbs : \{self.0.limbs}, sign : \{self.0.sign}, len : \{self.0.len} }",
  )
}

test "debug_string" {
  let buf = Buffer::new()
  let v : Array[MyBigInt] = [0, 1, 2, 3, 4, -0, -1, -2, -3]
  for i in v {
    buf.write_object(i)
    buf.write_string("\n")
  }
  inspect!(
    buf,
    content=
      #|{limbs : [0, 0], sign : Positive, len : 1 }
      #|{limbs : [1, 0], sign : Positive, len : 1 }
      #|{limbs : [2, 0], sign : Positive, len : 1 }
      #|{limbs : [3, 0], sign : Positive, len : 1 }
      #|{limbs : [4, 0], sign : Positive, len : 1 }
      #|{limbs : [0, 0], sign : Positive, len : 1 }
      #|{limbs : [1, 0], sign : Negative, len : 1 }
      #|{limbs : [2, 0], sign : Negative, len : 1 }
      #|{limbs : [3, 0], sign : Negative, len : 1 }
      #|
    ,
  )
}

fn check_len(a : BigInt) -> Unit! {
  if a.is_zero() {
    return ()
  }
  assert_eq!(a.limbs[a.len - 1] != 0, true)
  for i = a.len; i < a.limbs.length(); i = i + 1 {
    assert_eq!(a.limbs[i], 0)
  }
}

test "trivial property" {
  let a = BigInt::from_int64(0L)
  let b = -a
  assert_eq!(a, b)
  let a = BigInt::from_int(65537)
  let b = BigInt::from_int64(65537)
  assert_eq!(a, b)
  let a = BigInt::from_int(65537)
  let b = BigInt::from_int(65536)
  inspect!(a / b, content="1")
}

test "neg" {
  let a = BigInt::from_int64(123456789012345678L)
  let b = -a
  inspect!(b.to_string(), content="-123456789012345678")
  check_len!(b)
  let a = from_string(
    "123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let b = -a
  inspect!(
    b.to_string(),
    content="-123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  check_len!(b)
  let a = from_string(
    "-123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let b = -a
  inspect!(
    b.to_string(),
    content="123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  check_len!(b)
}

test "add" {
  let a = BigInt::from_int64(123456789012345678L)
  let b = BigInt::from_int64(987654321098765432L)
  let c = a + b
  inspect!(c.to_string(), content="1111111110111111110")
  check_len!(c)
  let a = from_string("123456789012345678123456789012345678")
  let b = from_string("9876543210987654329876543210987654321241243")
  let c = a + b
  check_len!(c)
  inspect!(c.to_string(), content="9876543334444443342222221334444443333586921")
  let a = from_string(
    "-345678987654356798765467898765456789098764567890987655678",
  )
  let b = from_string("76678908909876567890987656789098789")
  let c = a + b
  check_len!(c)
  inspect!(
    c.to_string(),
    content="-345678987654356798765391219856546912530873580234198556889",
  )
  let a = from_string(
    "-123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let b = from_string(
    "-5467890987656789098765678909876789098767098767890987657890987689",
  )
  let c = a + b
  check_len!(c)
  inspect!(
    c.to_string(),
    content="-123456794480236665780245887778024588000245887779444446014444446903333367",
  )
  let a = from_string(
    "123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let b = from_string(
    "-5467890987656789098765678909876789098767098767890987657890987689",
  )
  let c = a + b
  check_len!(c)
  inspect!(
    c.to_string(),
    content="123456783544454690466667690246666768246667690245246910232469131121357989",
  )
  let a = from_string("123456789012345678123456789012345678123456789")
  let b = from_string(
    "98765432109876543298765432109876543298765432112341241213125125",
  )
  let c = a + b
  let d = b + a
  check_len!(c)
  inspect!(
    c.to_string(),
    content="98765432109876543422222221122222221422222221124686919336581914",
  )
  check_len!(d)
  inspect!(
    d.to_string(),
    content="98765432109876543422222221122222221422222221124686919336581914",
  )
  let a = from_string("1")
  let b = from_string("1")
  let c = a + b
  check_len!(c)
  inspect!(c.to_string(), content="2")
}

test "sub" {
  let a = BigInt::from_int64(987654321098765432L)
  let b = BigInt::from_int64(123456789012345678L)
  let c = a - b
  check_len!(c)
  inspect!(c.to_string(), content="864197532086419754")
  let c = b - a
  check_len!(c)
  inspect!(c.to_string(), content="-864197532086419754")
  let a = BigInt::from_string("987654321098765432987654321098765432")
  let b = BigInt::from_string("123456789012345678123456789012345678")
  let c = a - b
  check_len!(c)
  inspect!(c.to_string(), content="864197532086419754864197532086419754")
  let c = b - a
  check_len!(c)
  inspect!(c.to_string(), content="-864197532086419754864197532086419754")
  let a = BigInt::from_string("-123456789012345678123456789012345678")
  let b = BigInt::from_string("-987654321098765432987654321098765432")
  let c = a - b
  check_len!(c)
  inspect!(c.to_string(), content="864197532086419754864197532086419754")
  let c = b - a
  check_len!(c)
  inspect!(c.to_string(), content="-864197532086419754864197532086419754")
  let a = BigInt::from_string("123456789012345678123456789012345678233")
  let b = BigInt::from_string("-987654321098765432987654321098765432")
  let c = a - b
  check_len!(c)
  inspect!(c.to_string(), content="124444443333444443556444443333444443665")
  let a = BigInt::from_string("-123456789012345678123456789012345678233")
  let b = BigInt::from_string("987654321098765432987654321098765432")
  let c = a - b
  check_len!(c)
  inspect!(c.to_string(), content="-124444443333444443556444443333444443665")
  let a = BigInt::from_string("123456789012345678123456789012345678233")
  let b = BigInt::from_string("987")
  let c = a - b
  check_len!(c)
  inspect!(c.to_string(), content="123456789012345678123456789012345677246")
}

test "mul" {
  let a = BigInt::from_int64(987654321098765432L)
  let b = BigInt::from_int64(123456789012345678L)
  let c = a * b
  check_len!(c)
  inspect!(c.to_string(), content="121932631137021794322511812221002896")
  let b = BigInt::from_int(0)
  let c = a * b
  check_len!(c)
  inspect!(c.to_string(), content="0")
  let a = from_string("987654321098765432987654321098765432")
  let b = from_string("123456789012345678123456789012345678")
  let c = a * b
  check_len!(c)
  inspect!(
    c.to_string(),
    content="121932631137021794566377074495046484766956255579027586322511812221002896",
  )
  let a = from_string(
    "-123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let b = from_string(
    "5467890987656789098765678909876789098767098767890987657890987689",
  )
  let c = a * b
  check_len!(c)
  inspect!(
    c.to_string(),
    content="-675048264005650638331575538351330675368295268968297112032725993817064025468035871811413387811508597465733350774788866848766914110358142",
  )
  let a = from_string(
    "123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let b = from_string(
    "123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let c = a * b
  check_len!(c)
  inspect!(
    c.to_string(),
    content="15241578753238836558451457271757357101661335790275877644871214308794398188081092827312918731290971345831439274500849864349959817710728382868480360920606901387000904130485419905521447340363938424041990550242456942562533760120975461083076969999493979603620179878012498124163389756531016644691358056296296328691358056296296328691358056296296328691358056296296328691358056296296328691358056296296328691358056296296328691358056296296328676116477543057492132906599024538971589696720506020451046486841987501930503276963468983409960067084950464889416857206431946368873647327913427848330437449394909327787227570876390807244017692357872286700807813839353766157597935320835245614388056802316725071178178283798204527968299765279684",
  )
  let a = from_string(
    "123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let b = from_string(
    "1234567890123456781234567890123456781234567890123456712345678901234567812345678901234567812345678901234567123456789012345678123456789012345678123456789012345671234567890123456781234567890123456781234567890123456778123456789012345678123456789012345677812345678901234567812345678901234567",
  )
  let c = a * b
  check_len!(c)
  inspect!(
    c.to_string(),
    content="152415787532388365584514572717573571016613357902758767943911109891785022264898961743637076585886813595489045858864333485751589068742852004272132278621370522791825008396569425417257107181754610622689205966939795827737216965321140148280426843839658668785227943677793100839548931529644952793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793427914508763990427995815723578805222563716938393620025636419186404593771315431334552741716994443482700889747721465962810627204511587444292106661301708925773586968571933726870961536473148541685756104374363356500551056363364975156230513153486456637710008352386618503277954031398766651426",
  )
}

test "div" {
  let a = BigInt::from_int64(987654321098765432L)
  let b = BigInt::from_int64(123456789012345678L)
  let c = a / b
  check_len!(c)
  inspect!(c.to_string(), content="8")
  let c = a % b
  check_len!(c)
  inspect!(c.to_string(), content="9000000008")
  let a = BigInt::from_string("987654321098765432987654321098765432")
  let b = BigInt::from_string("123456789012345678123456789012345678")
  let c = a / b
  check_len!(c)
  inspect!(c.to_string(), content="8")
  let c = a % b
  check_len!(c)
  inspect!(c.to_string(), content="9000000008000000009000000008")
  let a = BigInt::from_string(
    "-123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let b = BigInt::from_string(
    "-5467890987656789098765678909876789098767098767890987657890987689",
  )
  let c = a / b
  check_len!(c)
  inspect!(c.to_string(), content="22578502")
  let c = a % b
  check_len!(c)
  inspect!(
    c.to_string(),
    content="-1411754890143397710214334775703365651947321477507789807694283800",
  )
  let a = from_string(
    "12421645375698213532453474567345623538756734578959876125298763582362",
  )
  let b = from_string(
    "-5467890987656789098765678909876789098767098767890987657890987689",
  )
  let c = a / b
  check_len!(c)
  inspect!(c.to_string(), content="-2271")
  let c = a % b
  check_len!(c)
  inspect!(
    c.to_string(),
    content="4064942729645489156617763015435495456653277079443154228330540643",
  )
  let a = from_string(
    "559480073748030317374803031737502937374948313029373748143063751326169",
  )
  let b = from_string(
    "5467890987656789098765678909876789098767098767890987657890987689",
  )
  let c = a / b
  check_len!(c)
  inspect!(c.to_string(), content="102321")
  let c = a % b
  check_len!(c)
  inspect!(c.to_string(), content="0")
  let c = b / a
  check_len!(c)
  inspect!(c.to_string(), content="0")
  let a = from_string(
    "-123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let b = from_string(
    "98765432109876543298765432109876543298765432112341241213125125",
  )
  let c = a / b
  check_len!(c)
  inspect!(c.to_string(), content="-1249999988")
  let c = a % b
  check_len!(c)
  inspect!(
    c.to_string(),
    content="-60185184318518518460185184318518518457104311955145277319847178",
  )
  let b = from_string(
    "123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let c = a / b
  check_len!(c)
  inspect!(c.to_string(), content="-1")
  let c = a % b
  check_len!(c)
  inspect!(c.to_string(), content="0")
  let b = BigInt::from_int(42)
  let c = a / b
  check_len!(c)
  inspect!(
    c.to_string(),
    content="-2939447357436801860082304500293944717225161643151087574368018786008230",
  )
  let c = a % b
  check_len!(c)
  inspect!(c.to_string(), content="-18")
  let a = BigInt::from_int64(1L << 17)
  let b = BigInt::from_int(3)
  let c = a / b
  check_len!(c)
  inspect!(c.to_string(), content="43690")
  let c = a % b
  check_len!(c)
  inspect!(c.to_string(), content="2")
  let a = from_string(
    "192840512535448761530339373212972361809285001825938158026158292411480026580386667968523131569543343891463401449181505398836",
  )
  let b = from_string("53114991887765067119604462397623222751521283658033792")
  let c = a / b
  check_len!(c)
  inspect!(
    c.to_string(),
    content="3630623025283172274355511610456320508397929760764978568884844414130904",
  )
  let a = from_string("65535232222222222222222222222")
  let b = from_string("1")
  let c = a / b
  check_len!(c)
  inspect!(c.to_string(), content="65535232222222222222222222222")
  let c = a % b
  check_len!(c)
  inspect!(c.to_string(), content="0")
}

test "shl" {
  let a = BigInt::from_int64(1234567890123456789)
  let b = a << 1
  check_len!(b)
  inspect!(b.to_string(), content="2469135780246913578")
  let c = a << 64
  check_len!(c)
  inspect!(c.to_string(), content="22773757910726981402256170801141121024")
  let a = 0N
  let b = a << 1
  check_len!(b)
  inspect!(b.to_string(), content="0")
}

test "shr" {
  let a = BigInt::from_int64(1234567890123456789L)
  let b = a.shr(1)
  check_len!(b)
  inspect!(b.to_string(), content="617283945061728394")
  let c = a.shr(64)
  check_len!(c)
  inspect!(c.to_string(), content="0")
  let a = BigInt::from_int64((radix * radix / 2).to_int64())
  let b = a.shr(radix_bit_len * 2)
  check_len!(b)
  inspect!(b.to_string(), content="0")
}

test "decimal_string" {
  let a = BigInt::from_string("0")
  check_len!(a)
  inspect!(a.to_string(), content="0")
  let a = BigInt::from_string("123")
  check_len!(a)
  inspect!(a.to_string(), content="123")
  assert_eq!(a, BigInt::from_int64(123L))
  let a = from_string("1234567890123456789")
  check_len!(a)
  inspect!(a.to_string(), content="1234567890123456789")
  let b = from_string("-1234567890")
  check_len!(b)
  inspect!(b.to_string(), content="-1234567890")
  assert_eq!(a, BigInt::from_int64(1234567890123456789L))
  let str = "12345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812"
  let a = from_string(str)
  check_len!(a)
  inspect!(a.to_string(), content=str)
  let a = BigInt::from_int64(1234567890123456789L)
  check_len!(a)
  inspect!(a.to_string(), content="1234567890123456789")
  let b = BigInt::from_int64(-1234567890L)
  check_len!(b)
  inspect!(b.to_string(), content="-1234567890")
}

test "from_int" {
  let a = BigInt::from_int(1234567899)
  check_len!(a)
  inspect!(a.to_string(), content="1234567899")
  let b = BigInt::from_int(-1234567890)
  check_len!(b)
  inspect!(b.to_string(), content="-1234567890")
}

test "compare" {
  let a = BigInt::from_int64(1234567890123456789L)
  let b = BigInt::from_int64(-1234567890123456789L)
  inspect!(a.compare(b), content="1")
  inspect!(b.compare(a), content="-1")
  let a = -a
  let b = BigInt::from_int64(-1234567890123456788L)
  assert_eq!(a.compare(b) < 0, true)
  assert_eq!(b.compare(a) > 0, true)
  let a = BigInt::from_int64(-1234567890123456789L)
  let b = BigInt::from_int64(-1234569L)
  assert_eq!(a.compare(b) < 0, true)
  assert_eq!(b.compare(a) > 0, true)
}

test "from_hex" {
  // Check zero
  let a = from_hex("0")
  check_len!(a)
  inspect!(a.to_string(), content="0")

  // Test positive number
  let a = from_hex("1")
  check_len!(a)
  inspect!(a.to_string(), content="1")

  // Test negative number
  let a = from_hex("-F")
  check_len!(a)
  inspect!(a.to_string(), content="-15")
  let a = from_hex("-a")
  check_len!(a)
  inspect!(a.to_string(), content="-10")

  // Test large positive number
  let a = from_hex("112210F47DE98115")
  check_len!(a)
  inspect!(a.to_string(), content="1234567890123456789")

  // Test very large positive number
  let a = from_hex(
    "123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  check_len!(a)
  inspect!(
    a.to_string(),
    content="35365207917649046390549507392234216535182073572857507984542859337680634154115797374584",
  )
  let a = from_hex(
    "11E3444DC1F35F057AD2CBC2791737468140A426FAC3CBA7AF8C92A8F34E",
  )
  check_len!(a)
  inspect!(
    a.to_string(),
    content="123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let a = from_hex(
    "805146F2F58580962A0A2E6134BC75E25AD97AE3D09CD34BA4F629AB8911F3F5CB8573A62EDD16B0D46775A415F545A75518DA3439914D9CAA26449067D85E704E8FCF9B29182485B41F952616BACDFDDF52B413B524D0EB743E8264A9C6AE32D12C3D20C5B81189060F4AC5D216713D503A69644EA8E4EA220A720C41F6B3D18BED65B4238318E6B0A41D8540D756865EC92DF40E8D365A230F17DF1D0A440BC6A557CD46D00B10D74C0E75500B2ADB3A0336223F9285B78CD04F485E417E1DB562B9EFCF79433209E6D6E2F43A484E471DE4F1F5AE38E08E7DAEB644C2C0A22697DD6D29BE0B40FF50DB575FEF02FA5525953C7C198B4A3600BA8CE1F917852A4B957151189F09DCDFCB79963E7D850127858A97855B94870ACCBE8203E73FE79791EE6EA1B1282A0CEAC54D6F6B7CD6C7B8D8092E949FF0A84",
  )
  check_len!(a)
  inspect!(
    a.to_string(),
    content="12345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812",
  )

  // Test very large negative number
  let a = from_hex(
    "-123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  check_len!(a)
  inspect!(
    a.to_string(),
    content="-35365207917649046390549507392234216535182073572857507984542859337680634154115797374584",
  )
}

test "to_hex" {
  // Check zero
  let a = from_hex("00")
  check_len!(a)
  inspect!(a.to_hex(), content="0")

  // Test negative number
  let a = from_hex("-F")
  check_len!(a)
  inspect!(a.to_hex(), content="-F")

  // Test positive number
  let a = from_hex("F")
  check_len!(a)
  inspect!(a.to_hex(), content="F")

  // Test positive number with leading zero
  let a = from_hex("10")
  check_len!(a)
  inspect!(a.to_hex(), content="10")

  // Test large positive number
  let a = from_hex("01234567890123456789")
  check_len!(a)
  inspect!(a.to_hex(), content="1234567890123456789")

  // Check padding
  let a = from_hex("100000")
  check_len!(a)
  inspect!(a.to_string(), content="1048576")
  inspect!(a.to_hex(), content="100000")

  // Test very large positive number
  let a = from_string(
    "123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  check_len!(a)
  inspect!(
    a.to_hex(),
    content="11E3444DC1F35F057AD2CBC2791737468140A426FAC3CBA7AF8C92A8F34E",
  )
  let a = from_string(
    "35365207917649046390549507392234216535182073572857507984542859337680634154115797374584",
  )
  check_len!(a)
  inspect!(
    a.to_hex(),
    content="123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let str = "12345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812"
  let a = from_string(str)
  check_len!(a)
  inspect!(
    a.to_hex(),
    content="805146F2F58580962A0A2E6134BC75E25AD97AE3D09CD34BA4F629AB8911F3F5CB8573A62EDD16B0D46775A415F545A75518DA3439914D9CAA26449067D85E704E8FCF9B29182485B41F952616BACDFDDF52B413B524D0EB743E8264A9C6AE32D12C3D20C5B81189060F4AC5D216713D503A69644EA8E4EA220A720C41F6B3D18BED65B4238318E6B0A41D8540D756865EC92DF40E8D365A230F17DF1D0A440BC6A557CD46D00B10D74C0E75500B2ADB3A0336223F9285B78CD04F485E417E1DB562B9EFCF79433209E6D6E2F43A484E471DE4F1F5AE38E08E7DAEB644C2C0A22697DD6D29BE0B40FF50DB575FEF02FA5525953C7C198B4A3600BA8CE1F917852A4B957151189F09DCDFCB79963E7D850127858A97855B94870ACCBE8203E73FE79791EE6EA1B1282A0CEAC54D6F6B7CD6C7B8D8092E949FF0A84",
  )

  // Test very large negative number
  let a = from_string(
    "-123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  check_len!(a)
  inspect!(
    a.to_hex(),
    content="-11E3444DC1F35F057AD2CBC2791737468140A426FAC3CBA7AF8C92A8F34E",
  )
}

test "from_octets" {
  // Check zero
  let a = from_octets(b"\x00")
  check_len!(a)
  assert_eq!(a, 0)
  let a = from_octets(b"\x00", signum=-1)
  check_len!(a)
  assert_eq!(a, 0)
  let a = from_octets(b"\x00", signum=0)
  check_len!(a)
  assert_eq!(a, 0)

  // Test positive number
  let a = from_octets(b"\x01")
  check_len!(a)
  assert_eq!(a, 0x01)

  // Test negative number
  let a = from_octets(b"\x0F", signum=-1)
  check_len!(a)
  assert_eq!(a, -0x0F)
  let a = from_octets(b"\x0a", signum=-1)
  check_len!(a)
  assert_eq!(a, -0x0A)

  // Test large positive number
  let a = from_octets(b"\x11\x22\x10\xF4\x7D\xE9\x81\x15")
  check_len!(a)
  assert_eq!(a, 0x112210F47DE98115)
  assert_eq!(a, 1234567890123456789)

  // Test very large positive number
  let a = from_octets(
    b"\x12\x34\x56\x78\x90\x12\x34\x56\x78\x12\x34\x56\x78\x90\x12\x34\x56\x78\x12\x34\x56\x78\x90\x12\x34\x56\x78\x12\x34\x56\x78\x90\x12\x34\x56\x78",
  )
  check_len!(a)
  assert_eq!(
    a, 0x123456789012345678123456789012345678123456789012345678123456789012345678,
  )
  assert_eq!(
    a, 35365207917649046390549507392234216535182073572857507984542859337680634154115797374584,
  )
  let a = from_octets(
    b"\x11\xE3\x44\x4D\xC1\xF3\x5F\x05\x7A\xD2\xCB\xC2\x79\x17\x37\x46\x81\x40\xA4\x26\xFA\xC3\xCB\xA7\xAF\x8C\x92\xA8\xF3\x4E",
  )
  check_len!(a)
  assert_eq!(a, 0x11E3444DC1F35F057AD2CBC2791737468140A426FAC3CBA7AF8C92A8F34E)
  assert_eq!(
    a, 123456789012345678123456789012345678123456789012345678123456789012345678,
  )
  let a = from_octets(
    b"\x08\x05\x14\x6F\x2F\x58\x58\x09\x62\xA0\xA2\xE6\x13\x4B\xC7\x5E\x25\xAD\x97\xAE\x3D\x09\xCD\x34\xBA\x4F\x62\x9A\xB8\x91\x1F\x3F\x5C\xB8\x57\x3A\x62\xED\xD1\x6B\x0D\x46\x77\x5A\x41\x5F\x54\x5A\x75\x51\x8D\xA3\x43\x99\x14\xD9\xCA\xA2\x64\x49\x06\x7D\x85\xE7\x04\xE8\xFC\xF9\xB2\x91\x82\x48\x5B\x41\xF9\x52\x61\x6B\xAC\xDF\xDD\xF5\x2B\x41\x3B\x52\x4D\x0E\xB7\x43\xE8\x26\x4A\x9C\x6A\xE3\x2D\x12\xC3\xD2\x0C\x5B\x81\x18\x90\x60\xF4\xAC\x5D\x21\x67\x13\xD5\x03\xA6\x96\x44\xEA\x8E\x4E\xA2\x20\xA7\x20\xC4\x1F\x6B\x3D\x18\xBE\xD6\x5B\x42\x38\x31\x8E\x6B\x0A\x41\xD8\x54\x0D\x75\x68\x65\xEC\x92\xDF\x40\xE8\xD3\x65\xA2\x30\xF1\x7D\xF1\xD0\xA4\x40\xBC\x6A\x55\x7C\xD4\x6D\x00\xB1\x0D\x74\xC0\xE7\x55\x00\xB2\xAD\xB3\xA0\x33\x62\x23\xF9\x28\x5B\x78\xCD\x04\xF4\x85\xE4\x17\xE1\xDB\x56\x2B\x9E\xFC\xF7\x94\x33\x20\x9E\x6D\x6E\x2F\x43\xA4\x84\xE4\x71\xDE\x4F\x1F\x5A\xE3\x8E\x08\xE7\xDA\xEB\x64\x4C\x2C\x0A\x22\x69\x7D\xD6\xD2\x9B\xE0\xB4\x0F\xF5\x0D\xB5\x75\xFE\xF0\x2F\xA5\x52\x59\x53\xC7\xC1\x98\xB4\xA3\x60\x0B\xA8\xCE\x1F\x91\x78\x52\xA4\xB9\x57\x15\x11\x89\xF0\x9D\xCD\xFC\xB7\x99\x63\xE7\xD8\x50\x12\x78\x58\xA9\x78\x55\xB9\x48\x70\xAC\xCB\xE8\x20\x3E\x73\xFE\x79\x79\x1E\xE6\xEA\x1B\x12\x82\xA0\xCE\xAC\x54\xD6\xF6\xB7\xCD\x6C\x7B\x8D\x80\x92\xE9\x49\xFF\x0A\x84",
  )
  check_len!(a)
  assert_eq!(
    a, 0x805146F2F58580962A0A2E6134BC75E25AD97AE3D09CD34BA4F629AB8911F3F5CB8573A62EDD16B0D46775A415F545A75518DA3439914D9CAA26449067D85E704E8FCF9B29182485B41F952616BACDFDDF52B413B524D0EB743E8264A9C6AE32D12C3D20C5B81189060F4AC5D216713D503A69644EA8E4EA220A720C41F6B3D18BED65B4238318E6B0A41D8540D756865EC92DF40E8D365A230F17DF1D0A440BC6A557CD46D00B10D74C0E75500B2ADB3A0336223F9285B78CD04F485E417E1DB562B9EFCF79433209E6D6E2F43A484E471DE4F1F5AE38E08E7DAEB644C2C0A22697DD6D29BE0B40FF50DB575FEF02FA5525953C7C198B4A3600BA8CE1F917852A4B957151189F09DCDFCB79963E7D850127858A97855B94870ACCBE8203E73FE79791EE6EA1B1282A0CEAC54D6F6B7CD6C7B8D8092E949FF0A84,
  )
  assert_eq!(
    a, 12345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812,
  )

  // Test very large negative number
  let a = from_octets(
    b"\x12\x34\x56\x78\x90\x12\x34\x56\x78\x12\x34\x56\x78\x90\x12\x34\x56\x78\x12\x34\x56\x78\x90\x12\x34\x56\x78\x12\x34\x56\x78\x90\x12\x34\x56\x78",
    signum=-1,
  )
  check_len!(a)
  assert_eq!(
    a, -0x123456789012345678123456789012345678123456789012345678123456789012345678,
  )
  assert_eq!(
    a, -35365207917649046390549507392234216535182073572857507984542859337680634154115797374584,
  )
  let a = from_octets(
    b"\x00\xd2\x68\x67\xc5\x72\x75\x22\xf2\xca\xe8\x27\x3d\x05\x6f\xee\x02\x3a\xca\xb0\x9a\x23\x43\xcb\xc0\x1b\x29\xbf\x29\x95\xaa\x34\x02\x78\x7b\xd6\x71\x95\x47\x85\x44\xc2\x00\x73\x28\xec\x92\x41\xd1\x5e\x15\xce\x74\xdd\x0f\x23\x7c\x5e\xf2\x43\x0a\xf7\xe2\x89\xb0\x00\xe6\xe1\xf4\x8c\x84\x7b\x1f\x9e\x28\x0b\x3d\xc8\xdb\xcc\xe1\xa6\xdf\x92\x6e\xa0\xbd\x96\xec\x0d\x72\x19\xc0\x16\xd8\x0e\xf0\xb4\x3a\x14\x82\xab\x38\x6c\xe8\xc9\xef\xc6\xa3\x04\xef\x15\xcf\x8c\x89\xea\x6d\x3e\x05\xdc\x5f\x39\xd7\xdb\xcf\x78\xad\x00\x86\x51\x29\x76\x35\x96\x8f\xbc\x86\x9a\x18\x5c\xa9\x34\xef\xfc\x94\x08\x3a\xdd\xed\xe6\x59\xe9\xa0\x07\xcd\xa2\x1a\x17\x51\xf8\x3c\x70\xc8\xbc\x43\x65\x1e\x78\x28\x6d\x23\xc0\x43\x5f\xf4\x9f\x5b\xb1\x3f\x81\x7d\xf0\xfd\x8c\x37\x3f\xd5\x58\x55\xf9\x20\x5d\xdf\x74\x95\x89\xe1\x57\xbc\xc0\x35\x82\xea\x7b\xb1\x33\x9f\x47\x69\x93\xd0\x84\x48\x31\x88\xea\x47\x67\x9a\xfa\x25\x29\x37\xc4\x2c\xff\x96\x72\xcc\x6a\x68\x56\x0f\xa0\x18\x48\xff\x65\x68\xf3\xfd\x41\x74\x67\x1b\x2f\xef\x76\x54\xbf\xcb\xe5\x7f\x24\xb6\x38\xc7",
  )
  check_len!(a)
  let a = from_octets(b"\x00\x00\x00\x00")
  check_len!(a)
  assert_eq!(a, 0)
}

test "to_octets" {
  // Check zero
  let a = 0x00N
  check_len!(a)
  inspect!(
    a.to_octets(),
    content=
      #|b"\x00"
    ,
  )

  // Test positive number
  let a = 0x0FN
  check_len!(a)
  inspect!(
    a.to_octets(),
    content=
      #|b"\x0f"
    ,
  )

  // Test positive number with leading zero
  let a = 0x10N
  check_len!(a)
  inspect!(
    a.to_octets(),
    content=
      #|b"\x10"
    ,
  )

  // Test large positive number
  let a = 0x01234567890123456789N
  check_len!(a)
  inspect!(
    a.to_octets(),
    content=
      #|b"\x01\x23\x45\x67\x89\x01\x23\x45\x67\x89"
    ,
  )

  // Check padding
  let a = 0x100000N
  check_len!(a)
  inspect!(
    a.to_octets(),
    content=
      #|b"\x10\x00\x00"
    ,
  )

  // Test very large positive number
  let a = 0x11E3444DC1F35F057AD2CBC2791737468140A426FAC3CBA7AF8C92A8F34EN
  check_len!(a)
  inspect!(
    a.to_octets(),
    content=
      #|b"\x11\xe3\x44\x4d\xc1\xf3\x5f\x05\x7a\xd2\xcb\xc2\x79\x17\x37\x46\x81\x40\xa4\x26\xfa\xc3\xcb\xa7\xaf\x8c\x92\xa8\xf3\x4e"
    ,
  )
  let a = 0x123456789012345678123456789012345678123456789012345678123456789012345678N
  check_len!(a)
  inspect!(
    a.to_octets(),
    content=
      #|b"\x12\x34\x56\x78\x90\x12\x34\x56\x78\x12\x34\x56\x78\x90\x12\x34\x56\x78\x12\x34\x56\x78\x90\x12\x34\x56\x78\x12\x34\x56\x78\x90\x12\x34\x56\x78"
    ,
  )
  let a = 0x805146F2F58580962A0A2E6134BC75E25AD97AE3D09CD34BA4F629AB8911F3F5CB8573A62EDD16B0D46775A415F545A75518DA3439914D9CAA26449067D85E704E8FCF9B29182485B41F952616BACDFDDF52B413B524D0EB743E8264A9C6AE32D12C3D20C5B81189060F4AC5D216713D503A69644EA8E4EA220A720C41F6B3D18BED65B4238318E6B0A41D8540D756865EC92DF40E8D365A230F17DF1D0A440BC6A557CD46D00B10D74C0E75500B2ADB3A0336223F9285B78CD04F485E417E1DB562B9EFCF79433209E6D6E2F43A484E471DE4F1F5AE38E08E7DAEB644C2C0A22697DD6D29BE0B40FF50DB575FEF02FA5525953C7C198B4A3600BA8CE1F917852A4B957151189F09DCDFCB79963E7D850127858A97855B94870ACCBE8203E73FE79791EE6EA1B1282A0CEAC54D6F6B7CD6C7B8D8092E949FF0A84N
  check_len!(a)
  inspect!(
    a.to_octets(),
    content=
      #|b"\x08\x05\x14\x6f\x2f\x58\x58\x09\x62\xa0\xa2\xe6\x13\x4b\xc7\x5e\x25\xad\x97\xae\x3d\x09\xcd\x34\xba\x4f\x62\x9a\xb8\x91\x1f\x3f\x5c\xb8\x57\x3a\x62\xed\xd1\x6b\x0d\x46\x77\x5a\x41\x5f\x54\x5a\x75\x51\x8d\xa3\x43\x99\x14\xd9\xca\xa2\x64\x49\x06\x7d\x85\xe7\x04\xe8\xfc\xf9\xb2\x91\x82\x48\x5b\x41\xf9\x52\x61\x6b\xac\xdf\xdd\xf5\x2b\x41\x3b\x52\x4d\x0e\xb7\x43\xe8\x26\x4a\x9c\x6a\xe3\x2d\x12\xc3\xd2\x0c\x5b\x81\x18\x90\x60\xf4\xac\x5d\x21\x67\x13\xd5\x03\xa6\x96\x44\xea\x8e\x4e\xa2\x20\xa7\x20\xc4\x1f\x6b\x3d\x18\xbe\xd6\x5b\x42\x38\x31\x8e\x6b\x0a\x41\xd8\x54\x0d\x75\x68\x65\xec\x92\xdf\x40\xe8\xd3\x65\xa2\x30\xf1\x7d\xf1\xd0\xa4\x40\xbc\x6a\x55\x7c\xd4\x6d\x00\xb1\x0d\x74\xc0\xe7\x55\x00\xb2\xad\xb3\xa0\x33\x62\x23\xf9\x28\x5b\x78\xcd\x04\xf4\x85\xe4\x17\xe1\xdb\x56\x2b\x9e\xfc\xf7\x94\x33\x20\x9e\x6d\x6e\x2f\x43\xa4\x84\xe4\x71\xde\x4f\x1f\x5a\xe3\x8e\x08\xe7\xda\xeb\x64\x4c\x2c\x0a\x22\x69\x7d\xd6\xd2\x9b\xe0\xb4\x0f\xf5\x0d\xb5\x75\xfe\xf0\x2f\xa5\x52\x59\x53\xc7\xc1\x98\xb4\xa3\x60\x0b\xa8\xce\x1f\x91\x78\x52\xa4\xb9\x57\x15\x11\x89\xf0\x9d\xcd\xfc\xb7\x99\x63\xe7\xd8\x50\x12\x78\x58\xa9\x78\x55\xb9\x48\x70\xac\xcb\xe8\x20\x3e\x73\xfe\x79\x79\x1e\xe6\xea\x1b\x12\x82\xa0\xce\xac\x54\xd6\xf6\xb7\xcd\x6c\x7b\x8d\x80\x92\xe9\x49\xff\x0a\x84"
    ,
  )
}

test "to_octets with padding" {
  // corner case of zero
  let a = zero
  inspect!(
    a.to_octets(length=4),
    content=
      #|b"\x00\x00\x00\x00"
    ,
  )
  // some random number
  let a = 0x10000N
  check_len!(a)
  inspect!(
    a.to_octets(),
    content=
      #|b"\x01\x00\x00"
    ,
  )
  inspect!(
    a.to_octets(length=4),
    content=
      #|b"\x00\x01\x00\x00"
    ,
  )
}

test "op_add coverage for max(self_len, other_len)" {
  let a = BigInt::from_int(123456789)
  let b = BigInt::from_int(987654321)
  let result = a + b
  inspect!(a.len, content="1")
  inspect!(b.len, content="1")
  inspect!(result.len, content="1")
}

test "op_sub coverage for max(self_len, other_len)" {
  let a = BigInt::from_int(987654321)
  let b = BigInt::from_int(123456789)
  let result = a - b
  inspect!(a.len, content="1")
  inspect!(b.len, content="1")
  inspect!(result.len, content="1")
}

test "pow" {
  inspect!(4N.pow(13N, modulus=497N), content="445")
  inspect!(65N.pow(17, modulus=3233), content="2790")
  inspect!(2790N.pow(413, modulus=3233), content="65")
}

test "panic op_div coverage for division by zero" {
  let a = BigInt::from_int(123456789)
  let b = BigInt::from_int(0)
  a / b |> ignore
}

test "panic op_mod coverage for modulo by zero" {
  let a = BigInt::from_int(123456789)
  let b = BigInt::from_int(0)
  a % b |> ignore
}

test "panic shl coverage for negative shift" {
  let a = BigInt::from_int(123456789)
  a.shl(-1) |> ignore
}

test "panic shr coverage for negative shift" {
  let a = BigInt::from_int(123456789)
  a.shr(-1) |> ignore
}

test "panic from_string coverage for empty string" {
  from_string("") |> ignore
}

test "panic from_string coverage for invalid character" {
  from_string("123a56789") |> ignore
}

test "panic from_hex coverage for empty string" {
  from_hex("") |> ignore
}

test "panic from_hex coverage for invalid character" {
  from_hex("123g56789") |> ignore
}

test "panic pow coverage for negative exponent" {
  4N.pow(-13N, modulus=497N) |> ignore
}

test "panic pow coverage for zero modulus" {
  4N.pow(13N, modulus=0N) |> ignore
}

test "panic to_octets coverage for negative length" {
  123456789N.to_octets(length=-1) |> ignore
}

test "panic to_octets coverage for zero length" {
  123456789N.to_octets(length=0) |> ignore
}

test "panic to_octets coverage for negative number than required" {
  (-123456789N).to_octets() |> ignore
}

test "panic from_octets coverage for empty octets" {
  from_octets(b"") |> ignore
}
