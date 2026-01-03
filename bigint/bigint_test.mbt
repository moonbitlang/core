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

///|
test "neg" {
  let a = @bigint.BigInt::from_int64(123456789012345678L)
  let b = -a
  inspect(b.to_string(), content="-123456789012345678")
  let a = @bigint.BigInt::from_string(
    "123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let b = -a
  inspect(
    b.to_string(),
    content="-123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let a = @bigint.BigInt::from_string(
    "-123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let b = -a
  inspect(
    b.to_string(),
    content="123456789012345678123456789012345678123456789012345678123456789012345678",
  )
}

///|
test "bit_length zero" {
  let zero = 0N
  inspect(zero.bit_length(), content="0")
}

///|
test "add" {
  let a = @bigint.BigInt::from_int64(123456789012345678L)
  let b = @bigint.BigInt::from_int64(987654321098765432L)
  let c = a + b
  inspect(c.to_string(), content="1111111110111111110")
  let a = @bigint.BigInt::from_string("123456789012345678123456789012345678")
  let b = @bigint.BigInt::from_string(
    "9876543210987654329876543210987654321241243",
  )
  let c = a + b
  inspect(c.to_string(), content="9876543334444443342222221334444443333586921")
  let a = @bigint.BigInt::from_string(
    "-345678987654356798765467898765456789098764567890987655678",
  )
  let b = @bigint.BigInt::from_string("76678908909876567890987656789098789")
  let c = a + b
  inspect(
    c.to_string(),
    content="-345678987654356798765391219856546912530873580234198556889",
  )
  let a = @bigint.BigInt::from_string(
    "-123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let b = @bigint.BigInt::from_string(
    "-5467890987656789098765678909876789098767098767890987657890987689",
  )
  let c = a + b
  inspect(
    c.to_string(),
    content="-123456794480236665780245887778024588000245887779444446014444446903333367",
  )
  let a = @bigint.BigInt::from_string(
    "123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let b = @bigint.BigInt::from_string(
    "-5467890987656789098765678909876789098767098767890987657890987689",
  )
  let c = a + b
  inspect(
    c.to_string(),
    content="123456783544454690466667690246666768246667690245246910232469131121357989",
  )
  let a = @bigint.BigInt::from_string(
    "123456789012345678123456789012345678123456789",
  )
  let b = @bigint.BigInt::from_string(
    "98765432109876543298765432109876543298765432112341241213125125",
  )
  let c = a + b
  let d = b + a
  inspect(
    c.to_string(),
    content="98765432109876543422222221122222221422222221124686919336581914",
  )
  inspect(
    d.to_string(),
    content="98765432109876543422222221122222221422222221124686919336581914",
  )
  let a = @bigint.BigInt::from_string("1")
  let b = @bigint.BigInt::from_string("1")
  let c = a + b
  inspect(c.to_string(), content="2")

  // case where a < b
  let a = @bigint.BigInt::from_int64(123456789012345678)
  let b = @bigint.BigInt::from_int64(876543210987654321)
  inspect(a + b, content="999999999999999999")
  let a = @bigint.BigInt::from_string(
    "123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let b = @bigint.BigInt::from_string(
    "876543210987654321876543210987654321876543210987654321876543210987654321",
  )
  inspect(
    a + b,
    content="999999999999999999999999999999999999999999999999999999999999999999999999",
  )
  inspect(-1N + 1N, content="0")
  inspect(1N + -1N, content="0")
  inspect(-11N + 11N, content="0")
  inspect(11N + -11N, content="0")
}

///|
test "sub" {
  let a = @bigint.BigInt::from_int64(987654321098765432L)
  let b = @bigint.BigInt::from_int64(123456789012345678L)
  let c = a - b
  inspect(c.to_string(), content="864197532086419754")
  let c = b - a
  inspect(c.to_string(), content="-864197532086419754")
  let a = @bigint.BigInt::from_string("987654321098765432987654321098765432")
  let b = @bigint.BigInt::from_string("123456789012345678123456789012345678")
  let c = a - b
  inspect(c.to_string(), content="864197532086419754864197532086419754")
  let c = b - a
  inspect(c.to_string(), content="-864197532086419754864197532086419754")
  let a = @bigint.BigInt::from_string("-123456789012345678123456789012345678")
  let b = @bigint.BigInt::from_string("-987654321098765432987654321098765432")
  let c = a - b
  inspect(c.to_string(), content="864197532086419754864197532086419754")
  let c = b - a
  inspect(c.to_string(), content="-864197532086419754864197532086419754")
  let a = @bigint.BigInt::from_string("123456789012345678123456789012345678233")
  let b = @bigint.BigInt::from_string("-987654321098765432987654321098765432")
  let c = a - b
  inspect(c.to_string(), content="124444443333444443556444443333444443665")
  let a = @bigint.BigInt::from_string(
    "-123456789012345678123456789012345678233",
  )
  let b = @bigint.BigInt::from_string("987654321098765432987654321098765432")
  let c = a - b
  inspect(c.to_string(), content="-124444443333444443556444443333444443665")
  let a = @bigint.BigInt::from_string("123456789012345678123456789012345678233")
  let b = @bigint.BigInt::from_string("987")
  let c = a - b
  inspect(c.to_string(), content="123456789012345678123456789012345677246")

  // case where a < b
  let a = @bigint.BigInt::from_int64(123456789012345678)
  let b = @bigint.BigInt::from_int64(876543210987654321)
  inspect(a - b, content="-753086421975308643")
  let a = @bigint.BigInt::from_string(
    "123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let b = @bigint.BigInt::from_string(
    "876543210987654321876543210987654321876543210987654321876543210987654321",
  )
  inspect(
    a - b,
    content="-753086421975308643753086421975308643753086421975308643753086421975308643",
  )
}

///|
test "mul" {
  let a = @bigint.BigInt::from_int64(987654321098765432L)
  let b = @bigint.BigInt::from_int64(123456789012345678L)
  let c = a * b
  inspect(c.to_string(), content="121932631137021794322511812221002896")
  let b = @bigint.BigInt::from_int(0)
  let c = a * b
  inspect(c.to_string(), content="0")
  let a = @bigint.BigInt::from_string("987654321098765432987654321098765432")
  let b = @bigint.BigInt::from_string("123456789012345678123456789012345678")
  let c = a * b
  inspect(
    c.to_string(),
    content="121932631137021794566377074495046484766956255579027586322511812221002896",
  )
  let a = @bigint.BigInt::from_string(
    "-123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let b = @bigint.BigInt::from_string(
    "5467890987656789098765678909876789098767098767890987657890987689",
  )
  let c = a * b
  inspect(
    c.to_string(),
    content="-675048264005650638331575538351330675368295268968297112032725993817064025468035871811413387811508597465733350774788866848766914110358142",
  )
  let a = @bigint.BigInt::from_string(
    "123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let b = @bigint.BigInt::from_string(
    "123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let c = a * b
  inspect(
    c.to_string(),
    content="15241578753238836558451457271757357101661335790275877644871214308794398188081092827312918731290971345831439274500849864349959817710728382868480360920606901387000904130485419905521447340363938424041990550242456942562533760120975461083076969999493979603620179878012498124163389756531016644691358056296296328691358056296296328691358056296296328691358056296296328691358056296296328691358056296296328691358056296296328691358056296296328676116477543057492132906599024538971589696720506020451046486841987501930503276963468983409960067084950464889416857206431946368873647327913427848330437449394909327787227570876390807244017692357872286700807813839353766157597935320835245614388056802316725071178178283798204527968299765279684",
  )
  let a = @bigint.BigInt::from_string(
    "123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let b = @bigint.BigInt::from_string(
    "1234567890123456781234567890123456781234567890123456712345678901234567812345678901234567812345678901234567123456789012345678123456789012345678123456789012345671234567890123456781234567890123456781234567890123456778123456789012345678123456789012345677812345678901234567812345678901234567",
  )
  let c = a * b
  inspect(
    c.to_string(),
    content="152415787532388365584514572717573571016613357902758767943911109891785022264898961743637076585886813595489045858864333485751589068742852004272132278621370522791825008396569425417257107181754610622689205966939795827737216965321140148280426843839658668785227943677793100839548931529644952793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793580330296296378793427914508763990427995815723578805222563716938393620025636419186404593771315431334552741716994443482700889747721465962810627204511587444292106661301708925773586968571933726870961536473148541685756104374363356500551056363364975156230513153486456637710008352386618503277954031398766651426",
  )

  // cases where a < b
  let a = @bigint.BigInt::from_int64(123456789012345678)
  let b = @bigint.BigInt::from_int64(876543210987654321)
  inspect(a * b, content="108215210259106841348574911222374638")
  let a = @bigint.BigInt::from_string(
    "123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let b = @bigint.BigInt::from_string(
    "876543210987654321876543210987654321876543210987654321876543210987654321",
  )
  inspect(
    a * b,
    content="108215210259106841565005331740588321021795453222069800478585574703551279718945275666819076262155154185337596805365032703856117348574911222374638",
  )
}

///|
test "div" {
  let a = @bigint.BigInt::from_int64(987654321098765432L)
  let b = @bigint.BigInt::from_int64(123456789012345678L)
  let c = a / b
  inspect(c.to_string(), content="8")
  let c = a % b
  inspect(c.to_string(), content="9000000008")
  let a = @bigint.BigInt::from_string("987654321098765432987654321098765432")
  let b = @bigint.BigInt::from_string("123456789012345678123456789012345678")
  let c = a / b
  inspect(c.to_string(), content="8")
  let c = a % b
  inspect(c.to_string(), content="9000000008000000009000000008")
  let a = @bigint.BigInt::from_string(
    "-123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let b = @bigint.BigInt::from_string(
    "-5467890987656789098765678909876789098767098767890987657890987689",
  )
  let c = a / b
  inspect(c.to_string(), content="22578502")
  let c = a % b
  inspect(
    c.to_string(),
    content="-1411754890143397710214334775703365651947321477507789807694283800",
  )
  let a = @bigint.BigInt::from_string(
    "12421645375698213532453474567345623538756734578959876125298763582362",
  )
  let b = @bigint.BigInt::from_string(
    "-5467890987656789098765678909876789098767098767890987657890987689",
  )
  let c = a / b
  inspect(c.to_string(), content="-2271")
  let c = a % b
  inspect(
    c.to_string(),
    content="4064942729645489156617763015435495456653277079443154228330540643",
  )
  let a = @bigint.BigInt::from_string(
    "559480073748030317374803031737502937374948313029373748143063751326169",
  )
  let b = @bigint.BigInt::from_string(
    "5467890987656789098765678909876789098767098767890987657890987689",
  )
  let c = a / b
  inspect(c.to_string(), content="102321")
  let c = a % b
  inspect(c.to_string(), content="0")
  let c = b / a
  inspect(c.to_string(), content="0")
  let a = @bigint.BigInt::from_string(
    "-123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let b = @bigint.BigInt::from_string(
    "98765432109876543298765432109876543298765432112341241213125125",
  )
  let c = a / b
  inspect(c.to_string(), content="-1249999988")
  let c = a % b
  inspect(
    c.to_string(),
    content="-60185184318518518460185184318518518457104311955145277319847178",
  )
  let b = @bigint.BigInt::from_string(
    "123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let c = a / b
  inspect(c.to_string(), content="-1")
  let c = a % b
  inspect(c.to_string(), content="0")
  let b = @bigint.BigInt::from_int(42)
  let c = a / b
  inspect(
    c.to_string(),
    content="-2939447357436801860082304500293944717225161643151087574368018786008230",
  )
  let c = a % b
  inspect(c.to_string(), content="-18")
  let a = @bigint.BigInt::from_string(
    "192840512535448761530339373212972361809285001825938158026158292411480026580386667968523131569543343891463401449181505398836",
  )
  let b = @bigint.BigInt::from_string(
    "53114991887765067119604462397623222751521283658033792",
  )
  let c = a / b
  inspect(
    c.to_string(),
    content="3630623025283172274355511610456320508397929760764978568884844414130904",
  )
  let a = @bigint.BigInt::from_string("65535232222222222222222222222")
  let b = @bigint.BigInt::from_string("1")
  let c = a / b
  inspect(c.to_string(), content="65535232222222222222222222222")
  let c = a % b
  inspect(c.to_string(), content="0")

  // case where a < b
  let a = @bigint.BigInt::from_int64(123456789012345678)
  let b = @bigint.BigInt::from_int64(876543210987654321)
  inspect(a / b, content="0")
  inspect(a % b, content="123456789012345678")
  let a = @bigint.BigInt::from_string(
    "123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let b = @bigint.BigInt::from_string(
    "876543210987654321876543210987654321876543210987654321876543210987654321",
  )
  inspect(a / b, content="0")
  inspect(
    a % b,
    content="123456789012345678123456789012345678123456789012345678123456789012345678",
  )
}

///|
test "shl" {
  let a = @bigint.BigInt::from_int64(1234567890123456789)
  let b = a << 1
  inspect(b.to_string(), content="2469135780246913578")
  let c = a << 64
  inspect(c.to_string(), content="22773757910726981402256170801141121024")
  let a = 0N
  let b = a << 1
  inspect(b.to_string(), content="0")
}

///|
test "shr" {
  let a = @bigint.BigInt::from_int64(1234567890123456789L)
  let b = a >> 1
  inspect(b.to_string(), content="617283945061728394")
  let c = a >> 64
  inspect(c.to_string(), content="0")
  let a = @bigint.BigInt::from_int64(-1234567890123456789L)
  let b = a >> 1
  inspect(b.to_string(), content="-617283945061728395")
  let c = a >> 64
  inspect(c.to_string(), content="-1")
  assert_eq(
    @bigint.BigInt::from_int64(0b1111_1111L) >> 4,
    @bigint.BigInt::from_int64(0b1111L),
  )
  assert_eq(
    @bigint.BigInt::from_int64(0b1111_1111L) >> 24,
    @bigint.BigInt::from_int64(0),
  )
  assert_eq(
    @bigint.BigInt::from_int64(0b1111_1111L) >> 44,
    @bigint.BigInt::from_int64(0),
  )
}

///|
test "decimal_string" {
  let a = @bigint.BigInt::from_string("0")
  inspect(a.to_string(), content="0")
  let a = @bigint.BigInt::from_string("123")
  inspect(a.to_string(), content="123")
  assert_eq(a, @bigint.BigInt::from_int64(123L))
  let a = @bigint.BigInt::from_string("1234567890123456789")
  inspect(a.to_string(), content="1234567890123456789")
  let b = @bigint.BigInt::from_string("-1234567890")
  inspect(b.to_string(), content="-1234567890")
  assert_eq(a, @bigint.BigInt::from_int64(1234567890123456789L))
  let str = "12345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812"
  let a = @bigint.BigInt::from_string(str)
  inspect(a.to_string(), content=str)
  let a = @bigint.BigInt::from_int64(1234567890123456789L)
  inspect(a.to_string(), content="1234567890123456789")
  let b = @bigint.BigInt::from_int64(-1234567890L)
  inspect(b.to_string(), content="-1234567890")
}

///|
test "from_int" {
  let a = @bigint.BigInt::from_int(1234567899)
  inspect(a.to_string(), content="1234567899")
  let b = @bigint.BigInt::from_int(-1234567890)
  inspect(b.to_string(), content="-1234567890")
}

///|
test "compare" {
  let a = @bigint.BigInt::from_int64(1234567890123456789L)
  let b = @bigint.BigInt::from_int64(-1234567890123456789L)
  inspect(a.compare(b), content="1")
  inspect(b.compare(a), content="-1")
  let a = -a
  let b = @bigint.BigInt::from_int64(-1234567890123456788L)
  assert_true(a.compare(b) < 0)
  assert_true(b.compare(a) > 0)
  let a = @bigint.BigInt::from_int64(-1234567890123456789L)
  let b = @bigint.BigInt::from_int64(-1234569L)
  assert_true(a.compare(b) < 0)
  assert_true(b.compare(a) > 0)
}

///|
test "from_hex" {
  // Check zero
  let a = @bigint.BigInt::from_hex("0")
  inspect(a.to_string(), content="0")

  // Test positive number
  let a = @bigint.BigInt::from_hex("1")
  inspect(a.to_string(), content="1")

  // Test negative number
  let a = @bigint.BigInt::from_hex("-F")
  inspect(a.to_string(), content="-15")
  let a = @bigint.BigInt::from_hex("-a")
  inspect(a.to_string(), content="-10")

  // Test large positive number
  let a = @bigint.BigInt::from_hex("112210F47DE98115")
  inspect(a.to_string(), content="1234567890123456789")

  // Test very large positive number
  let a = @bigint.BigInt::from_hex(
    "123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  inspect(
    a.to_string(),
    content="35365207917649046390549507392234216535182073572857507984542859337680634154115797374584",
  )
  let a = @bigint.BigInt::from_hex(
    "11E3444DC1F35F057AD2CBC2791737468140A426FAC3CBA7AF8C92A8F34E",
  )
  inspect(
    a.to_string(),
    content="123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let a = @bigint.BigInt::from_hex(
    "805146F2F58580962A0A2E6134BC75E25AD97AE3D09CD34BA4F629AB8911F3F5CB8573A62EDD16B0D46775A415F545A75518DA3439914D9CAA26449067D85E704E8FCF9B29182485B41F952616BACDFDDF52B413B524D0EB743E8264A9C6AE32D12C3D20C5B81189060F4AC5D216713D503A69644EA8E4EA220A720C41F6B3D18BED65B4238318E6B0A41D8540D756865EC92DF40E8D365A230F17DF1D0A440BC6A557CD46D00B10D74C0E75500B2ADB3A0336223F9285B78CD04F485E417E1DB562B9EFCF79433209E6D6E2F43A484E471DE4F1F5AE38E08E7DAEB644C2C0A22697DD6D29BE0B40FF50DB575FEF02FA5525953C7C198B4A3600BA8CE1F917852A4B957151189F09DCDFCB79963E7D850127858A97855B94870ACCBE8203E73FE79791EE6EA1B1282A0CEAC54D6F6B7CD6C7B8D8092E949FF0A84",
  )
  inspect(
    a.to_string(),
    content="12345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812",
  )

  // Test very large negative number
  let a = @bigint.BigInt::from_hex(
    "-123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  inspect(
    a.to_string(),
    content="-35365207917649046390549507392234216535182073572857507984542859337680634154115797374584",
  )
}

///|
test "to_hex" {
  // Check zero
  let a = @bigint.BigInt::from_hex("00")
  inspect(a.to_hex(), content="0")

  // Test negative number
  let a = @bigint.BigInt::from_hex("-F")
  inspect(a.to_hex(), content="-F")

  // Test positive number
  let a = @bigint.BigInt::from_hex("F")
  inspect(a.to_hex(), content="F")

  // Test positive number with leading zero
  let a = @bigint.BigInt::from_hex("10")
  inspect(a.to_hex(), content="10")

  // Test large positive number
  let a = @bigint.BigInt::from_hex("01234567890123456789")
  inspect(a.to_hex(), content="1234567890123456789")

  // Check padding
  let a = @bigint.BigInt::from_hex("100000")
  inspect(a.to_string(), content="1048576")
  inspect(a.to_hex(), content="100000")

  // Test very large positive number
  let a = @bigint.BigInt::from_string(
    "123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  inspect(
    a.to_hex(),
    content="11E3444DC1F35F057AD2CBC2791737468140A426FAC3CBA7AF8C92A8F34E",
  )
  let a = @bigint.BigInt::from_string(
    "35365207917649046390549507392234216535182073572857507984542859337680634154115797374584",
  )
  inspect(
    a.to_hex(),
    content="123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let str = "12345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812345678901234567812"
  let a = @bigint.BigInt::from_string(str)
  inspect(
    a.to_hex(),
    content="805146F2F58580962A0A2E6134BC75E25AD97AE3D09CD34BA4F629AB8911F3F5CB8573A62EDD16B0D46775A415F545A75518DA3439914D9CAA26449067D85E704E8FCF9B29182485B41F952616BACDFDDF52B413B524D0EB743E8264A9C6AE32D12C3D20C5B81189060F4AC5D216713D503A69644EA8E4EA220A720C41F6B3D18BED65B4238318E6B0A41D8540D756865EC92DF40E8D365A230F17DF1D0A440BC6A557CD46D00B10D74C0E75500B2ADB3A0336223F9285B78CD04F485E417E1DB562B9EFCF79433209E6D6E2F43A484E471DE4F1F5AE38E08E7DAEB644C2C0A22697DD6D29BE0B40FF50DB575FEF02FA5525953C7C198B4A3600BA8CE1F917852A4B957151189F09DCDFCB79963E7D850127858A97855B94870ACCBE8203E73FE79791EE6EA1B1282A0CEAC54D6F6B7CD6C7B8D8092E949FF0A84",
  )
  inspect(
    a.to_hex(uppercase=false),
    content="805146f2f58580962a0a2e6134bc75e25ad97ae3d09cd34ba4f629ab8911f3f5cb8573a62edd16b0d46775a415f545a75518da3439914d9caa26449067d85e704e8fcf9b29182485b41f952616bacdfddf52b413b524d0eb743e8264a9c6ae32d12c3d20c5b81189060f4ac5d216713d503a69644ea8e4ea220a720c41f6b3d18bed65b4238318e6b0a41d8540d756865ec92df40e8d365a230f17df1d0a440bc6a557cd46d00b10d74c0e75500b2adb3a0336223f9285b78cd04f485e417e1db562b9efcf79433209e6d6e2f43a484e471de4f1f5ae38e08e7daeb644c2c0a22697dd6d29be0b40ff50db575fef02fa5525953c7c198b4a3600ba8ce1f917852a4b957151189f09dcdfcb79963e7d850127858a97855b94870accbe8203e73fe79791ee6ea1b1282a0ceac54d6f6b7cd6c7b8d8092e949ff0a84",
  )

  // Test very large negative number
  let a = @bigint.BigInt::from_string(
    "-123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  inspect(
    a.to_hex(),
    content="-11E3444DC1F35F057AD2CBC2791737468140A426FAC3CBA7AF8C92A8F34E",
  )
  inspect(
    a.to_hex(uppercase=false),
    content="-11e3444dc1f35f057ad2cbc2791737468140a426fac3cba7af8c92a8f34e",
  )
}

///|
test "pow" {
  let x = 2N.pow(5664N).to_hex()
  assert_eq(x.get_char(0).unwrap(), '1')
  assert_eq(x[1:], String::make(5664 / 4, '0')[:])
}

///|
test "land_1" {
  let a = @bigint.BigInt::from_string("-10")
  let b = @bigint.BigInt::from_string("11")
  inspect(a & b, content="2")
}

///|
test "land_2" {
  let a = @bigint.BigInt::from_string("-10")
  let b = @bigint.BigInt::from_hex("fffffffffffffff") // 15 'f' chars
  inspect(a & b, content="1152921504606846966")
}

///|
test "land_3" {
  let a = @bigint.BigInt::from_hex("ffffffffffffffff") // 16 'f' chars
  let b = @bigint.BigInt::from_string("-10")
  inspect(a & b, content="18446744073709551606")
}

///|
test "land_4" {
  let a = @bigint.BigInt::from_string("0")
  let b = @bigint.BigInt::from_string("-10")
  inspect(a & b, content="0")
}

///|
test "land_5" {
  let a = @bigint.BigInt::from_hex("ffffffffffffffff")
  let b = @bigint.BigInt::from_hex("ffffffffffffffff")
  inspect(a & b, content="18446744073709551615")
}

///|
test "lor_1" {
  let a = @bigint.BigInt::from_string("-10")
  let b = @bigint.BigInt::from_string("11")
  inspect(a | b, content="-1")
}

///|
test "lor_2" {
  let a = @bigint.BigInt::from_string("-10")
  let b = @bigint.BigInt::from_hex("fffffffffffffff") // 15 'f' chars
  inspect(a | b, content="-1")
}

///|
test "lor_3" {
  let a = @bigint.BigInt::from_hex("ffffffffffffffff") // 16 'f' chars
  let b = @bigint.BigInt::from_string("-10")
  inspect(a | b, content="-1")
}

///|
test "lor_4" {
  let a = @bigint.BigInt::from_string("0")
  let b = @bigint.BigInt::from_string("-10")
  inspect(a | b, content="-10")
}

///|
test "lor_5" {
  let a = @bigint.BigInt::from_hex("ffffffffffffffff")
  let b = @bigint.BigInt::from_string("0")
  inspect(a | b, content="18446744073709551615")
}

///|
test "lxor_1" {
  let a = @bigint.BigInt::from_string("-10")
  let b = @bigint.BigInt::from_string("11")
  inspect(a ^ b, content="-3")
}

///|
test "lxor_2" {
  let a = @bigint.BigInt::from_string("-10")
  let b = @bigint.BigInt::from_hex("fffffffffffffff") // 15 'f' chars
  inspect(a ^ b, content="-1152921504606846967")
}

///|
test "lxor_3" {
  let a = @bigint.BigInt::from_hex("ffffffffffffffff") // 16 'f' chars
  let b = @bigint.BigInt::from_string("-10")
  inspect(a ^ b, content="-18446744073709551607")
}

///|
test "lxor_4" {
  let a = @bigint.BigInt::from_string("0")
  let b = @bigint.BigInt::from_string("-10")
  inspect(a ^ b, content="-10")
}

///|
test "lxor_5" {
  let a = @bigint.BigInt::from_string("0")
  let b = @bigint.BigInt::from_hex("ffffffffffffffff")
  inspect(a ^ b, content="18446744073709551615")
}

///|
test "to_int" {
  let a = @bigint.BigInt::from_int(1234567899)
  inspect(a.to_int(), content="1234567899")
  let b = @bigint.BigInt::from_int(-1234567890)
  inspect(b.to_int(), content="-1234567890")
  let max = 2N.pow(32) - 1
  inspect(max.to_int(), content="-1")
  inspect((max + 1).to_int(), content="0")
}

///|
test "to_uint" {
  let a = @bigint.BigInt::from_uint(1234567899)
  inspect(a.to_uint(), content="1234567899")
  let b = @bigint.BigInt::from_int(-1234567890)
  inspect(b.to_uint(), content="3060399406")
  let max = 2N.pow(32) - 1
  inspect(max.to_uint(), content="4294967295")
  inspect((max + 1).to_uint(), content="0")
}

///|
test "to_int64" {
  let a = @bigint.BigInt::from_int64(1234567890123456789L)
  inspect(a.to_int64(), content="1234567890123456789")
  let b = @bigint.BigInt::from_int64(-1234567890123456789L)
  inspect(b.to_int64(), content="-1234567890123456789")
  let max = 2N.pow(63) - 1
  inspect(max.to_int64(), content="9223372036854775807")
  inspect((max + 1).to_int64(), content="-9223372036854775808")
}

///|
test "to_uint64" {
  let a = @bigint.BigInt::from_uint64(1234567890123456789UL)
  inspect(a.to_uint64(), content="1234567890123456789")
  let b = @bigint.BigInt::from_int64(-1234567890123456789L)
  inspect(b.to_uint64(), content="17212176183586094827")
  let max = 2N.pow(64) - 1
  inspect(max.to_uint64(), content="18446744073709551615")
  inspect((max + 1).to_uint64(), content="0")
}

///|
test "equal_int" {
  assert_true(@bigint.BigInt::equal_int(1N, 1))
  assert_true(@bigint.BigInt::equal_int(-1N, -1))
  assert_false(@bigint.BigInt::equal_int(1N, -1))
  assert_false(@bigint.BigInt::equal_int(-1N, 1))
  assert_true(@bigint.BigInt::equal_int(0N, 0))
  assert_false(@bigint.BigInt::equal_int(0N, 1))
  assert_false(@bigint.BigInt::equal_int(1N, 0))

  // Test with max/min int values
  assert_true(@bigint.BigInt::equal_int(2147483647N, 2147483647))
  assert_true(@bigint.BigInt::equal_int(-2147483648N, -2147483648))
  assert_false(@bigint.BigInt::equal_int(2147483647N, -2147483648))
  assert_false(@bigint.BigInt::equal_int(-2147483648N, 2147483647))

  // Test with large BigInt that doesn't fit in int
  let large = 2N.pow(32)
  assert_false(@bigint.BigInt::equal_int(large, 0))
  assert_false(@bigint.BigInt::equal_int(large, 1))
  assert_false(@bigint.BigInt::equal_int(large, -1))

  // Test with negative large BigInt
  let neg_large = -2N.pow(32)
  assert_false(@bigint.BigInt::equal_int(neg_large, 0))
  assert_false(@bigint.BigInt::equal_int(neg_large, 1))
  assert_false(@bigint.BigInt::equal_int(neg_large, -1))
}

///|
test "equal_int64" {
  assert_true(@bigint.BigInt::equal_int64(1N, 1L))
  assert_true(@bigint.BigInt::equal_int64(-1N, -1L))
  assert_false(@bigint.BigInt::equal_int64(1N, -1L))
  assert_false(@bigint.BigInt::equal_int64(-1N, 1L))
  assert_true(@bigint.BigInt::equal_int64(0N, 0L))
  assert_false(@bigint.BigInt::equal_int64(0N, 1L))
  assert_false(@bigint.BigInt::equal_int64(1N, 0L))

  // Test with max/min int64 values
  assert_true(
    @bigint.BigInt::equal_int64(9223372036854775807N, 9223372036854775807L),
  )
  assert_true(
    @bigint.BigInt::equal_int64(-9223372036854775808N, -9223372036854775808L),
  )
  assert_false(
    @bigint.BigInt::equal_int64(9223372036854775807N, -9223372036854775808L),
  )
  assert_false(
    @bigint.BigInt::equal_int64(-9223372036854775808N, 9223372036854775807L),
  )

  // Test with large values that fit in int64
  assert_true(
    @bigint.BigInt::equal_int64(1234567890123456789N, 1234567890123456789L),
  )
  assert_true(
    @bigint.BigInt::equal_int64(-1234567890123456789N, -1234567890123456789L),
  )
  assert_false(
    @bigint.BigInt::equal_int64(1234567890123456789N, -1234567890123456789L),
  )
  assert_false(
    @bigint.BigInt::equal_int64(-1234567890123456789N, 1234567890123456789L),
  )

  // Test with BigInt that doesn't fit in int64
  let large = 2N.pow(64)
  assert_false(@bigint.BigInt::equal_int64(large, 0L))
  assert_false(@bigint.BigInt::equal_int64(large, 1L))
  assert_false(@bigint.BigInt::equal_int64(large, -1L))
  assert_false(@bigint.BigInt::equal_int64(large, 9223372036854775807L))
  assert_false(@bigint.BigInt::equal_int64(large, -9223372036854775808L))

  // Test with negative large BigInt that doesn't fit in int64
  let neg_large = -2N.pow(64)
  assert_false(@bigint.BigInt::equal_int64(neg_large, 0L))
  assert_false(@bigint.BigInt::equal_int64(neg_large, 1L))
  assert_false(@bigint.BigInt::equal_int64(neg_large, -1L))
  assert_false(@bigint.BigInt::equal_int64(neg_large, 9223372036854775807L))
  assert_false(@bigint.BigInt::equal_int64(neg_large, -9223372036854775808L))

  // Test edge cases around int64 boundaries
  let max_plus_one = 9223372036854775808N // 2^63
  let min_minus_one = -9223372036854775809N // -2^63 - 1
  assert_false(@bigint.BigInt::equal_int64(max_plus_one, 9223372036854775807L))
  assert_false(
    @bigint.BigInt::equal_int64(min_minus_one, -9223372036854775808L),
  )

  // Test with powers of 2
  assert_true(@bigint.BigInt::equal_int64(2N.pow(32), 4294967296L))
  assert_true(@bigint.BigInt::equal_int64(2N.pow(62), 4611686018427387904L))
  assert_false(@bigint.BigInt::equal_int64(2N.pow(63), 9223372036854775807L)) // This would overflow
}

///|
test "compare_int" {
  // Test with zero
  assert_eq(@bigint.BigInt::compare_int(0N, 0), 0)
  assert_eq(@bigint.BigInt::compare_int(0N, 1), -1)
  assert_eq(@bigint.BigInt::compare_int(0N, -1), 1)

  // Test with positive values
  assert_eq(@bigint.BigInt::compare_int(1N, 1), 0)
  assert_eq(@bigint.BigInt::compare_int(1N, 0), 1)
  assert_eq(@bigint.BigInt::compare_int(1N, 2), -1)
  assert_eq(@bigint.BigInt::compare_int(42N, 42), 0)
  assert_eq(@bigint.BigInt::compare_int(100N, 50), 1)
  assert_eq(@bigint.BigInt::compare_int(25N, 100), -1)

  // Test with negative values
  assert_eq(@bigint.BigInt::compare_int(-1N, -1), 0)
  assert_eq(@bigint.BigInt::compare_int(-1N, 0), -1)
  assert_eq(@bigint.BigInt::compare_int(-1N, 1), -1)
  assert_eq(@bigint.BigInt::compare_int(-42N, -42), 0)
  assert_eq(@bigint.BigInt::compare_int(-25N, -100), 1)
  assert_eq(@bigint.BigInt::compare_int(-100N, -50), -1)

  // Test with mixed signs
  assert_eq(@bigint.BigInt::compare_int(1N, -1), 1)
  assert_eq(@bigint.BigInt::compare_int(-1N, 1), -1)
  assert_eq(@bigint.BigInt::compare_int(100N, -50), 1)
  assert_eq(@bigint.BigInt::compare_int(-100N, 50), -1)

  // Test with Int boundary values
  assert_eq(@bigint.BigInt::compare_int(2147483647N, 2147483647), 0) // Int.max_value
  assert_eq(@bigint.BigInt::compare_int(-2147483648N, -2147483648), 0) // Int.min_value
  assert_eq(@bigint.BigInt::compare_int(2147483647N, 2147483646), 1)
  assert_eq(@bigint.BigInt::compare_int(2147483646N, 2147483647), -1)
  assert_eq(@bigint.BigInt::compare_int(-2147483648N, -2147483647), -1)
  assert_eq(@bigint.BigInt::compare_int(-2147483647N, -2147483648), 1)

  // Test with BigInt that doesn't fit in Int
  let large = 2147483648N // Int.max_value + 1
  assert_eq(@bigint.BigInt::compare_int(large, 2147483647), 1)
  assert_eq(@bigint.BigInt::compare_int(large, -2147483648), 1)
  assert_eq(@bigint.BigInt::compare_int(large, 0), 1)
  let neg_large = -2147483649N // Int.min_value - 1
  assert_eq(@bigint.BigInt::compare_int(neg_large, -2147483648), -1)
  assert_eq(@bigint.BigInt::compare_int(neg_large, 2147483647), -1)
  assert_eq(@bigint.BigInt::compare_int(neg_large, 0), -1)

  // Test with very large BigInt values
  let very_large = @bigint.BigInt::from_string("123456789012345678901234567890")
  assert_eq(@bigint.BigInt::compare_int(very_large, 2147483647), 1)
  assert_eq(@bigint.BigInt::compare_int(very_large, -2147483648), 1)
  assert_eq(@bigint.BigInt::compare_int(very_large, 0), 1)
  let very_neg_large = @bigint.BigInt::from_string(
    "-123456789012345678901234567890",
  )
  assert_eq(@bigint.BigInt::compare_int(very_neg_large, 2147483647), -1)
  assert_eq(@bigint.BigInt::compare_int(very_neg_large, -2147483648), -1)
  assert_eq(@bigint.BigInt::compare_int(very_neg_large, 0), -1)

  // Test with powers of 2
  assert_eq(@bigint.BigInt::compare_int(2N.pow(10), 1024), 0)
  assert_eq(@bigint.BigInt::compare_int(2N.pow(20), 1048576), 0)
  assert_eq(@bigint.BigInt::compare_int(2N.pow(30), 1073741824), 0)
  assert_eq(@bigint.BigInt::compare_int(2N.pow(31), 2147483647), 1) // 2^31 > Int.max_value
}

///|
test "compare_int64" {
  // Test with zero
  assert_eq(@bigint.BigInt::compare_int64(0N, 0L), 0)
  assert_eq(@bigint.BigInt::compare_int64(0N, 1L), -1)
  assert_eq(@bigint.BigInt::compare_int64(0N, -1L), 1)

  // Test with positive values
  assert_eq(@bigint.BigInt::compare_int64(1N, 1L), 0)
  assert_eq(@bigint.BigInt::compare_int64(42N, 42L), 0)
  assert_eq(@bigint.BigInt::compare_int64(100N, 50L), 1)
  assert_eq(@bigint.BigInt::compare_int64(25N, 100L), -1)

  // Test with negative values
  assert_eq(@bigint.BigInt::compare_int64(-1N, -1L), 0)
  assert_eq(@bigint.BigInt::compare_int64(-1N, 0L), -1)
  assert_eq(@bigint.BigInt::compare_int64(-1N, 1L), -1)
  assert_eq(@bigint.BigInt::compare_int64(-42N, -42L), 0)
  assert_eq(@bigint.BigInt::compare_int64(-25N, -100L), 1)
  assert_eq(@bigint.BigInt::compare_int64(-100N, -50L), -1)

  // Test with mixed signs
  assert_eq(@bigint.BigInt::compare_int64(1N, -1L), 1)
  assert_eq(@bigint.BigInt::compare_int64(-1N, 1L), -1)
  assert_eq(@bigint.BigInt::compare_int64(100N, -50L), 1)
  assert_eq(@bigint.BigInt::compare_int64(-100N, 50L), -1)

  // Test with Int64 boundary values
  assert_eq(
    @bigint.BigInt::compare_int64(9223372036854775807N, 9223372036854775807L),
    0,
  ) // Int64.max_value
  assert_eq(
    @bigint.BigInt::compare_int64(-9223372036854775808N, -9223372036854775808L),
    0,
  ) // Int64.min_value
  assert_eq(
    @bigint.BigInt::compare_int64(9223372036854775807N, 9223372036854775806L),
    1,
  )
  assert_eq(
    @bigint.BigInt::compare_int64(9223372036854775806N, 9223372036854775807L),
    -1,
  )
  assert_eq(
    @bigint.BigInt::compare_int64(-9223372036854775808N, -9223372036854775807L),
    -1,
  )
  assert_eq(
    @bigint.BigInt::compare_int64(-9223372036854775807N, -9223372036854775808L),
    1,
  )

  // Test with BigInt that doesn't fit in Int64
  let large = @bigint.BigInt::from_string("9223372036854775808") // Int64.max_value + 1
  assert_eq(@bigint.BigInt::compare_int64(large, 9223372036854775807L), 1)
  assert_eq(@bigint.BigInt::compare_int64(large, -9223372036854775808L), 1)
  assert_eq(@bigint.BigInt::compare_int64(large, 0L), 1)
  let neg_large = @bigint.BigInt::from_string("-9223372036854775809") // Int64.min_value - 1
  assert_eq(@bigint.BigInt::compare_int64(neg_large, -9223372036854775808L), -1)
  assert_eq(@bigint.BigInt::compare_int64(neg_large, 9223372036854775807L), -1)
  assert_eq(@bigint.BigInt::compare_int64(neg_large, 0L), -1)

  // Test with very large BigInt values
  let very_large = @bigint.BigInt::from_string("123456789012345678901234567890")
  assert_eq(@bigint.BigInt::compare_int64(very_large, 9223372036854775807L), 1)
  assert_eq(@bigint.BigInt::compare_int64(very_large, -9223372036854775808L), 1)
  assert_eq(@bigint.BigInt::compare_int64(very_large, 0L), 1)
  let very_neg_large = @bigint.BigInt::from_string(
    "-123456789012345678901234567890",
  )
  assert_eq(
    @bigint.BigInt::compare_int64(very_neg_large, 9223372036854775807L),
    -1,
  )
  assert_eq(
    @bigint.BigInt::compare_int64(very_neg_large, -9223372036854775808L),
    -1,
  )
  assert_eq(@bigint.BigInt::compare_int64(very_neg_large, 0L), -1)

  // Test with powers of 2
  assert_eq(@bigint.BigInt::compare_int64(2N.pow(10), 1024L), 0)
  assert_eq(@bigint.BigInt::compare_int64(2N.pow(20), 1048576L), 0)
  assert_eq(@bigint.BigInt::compare_int64(2N.pow(30), 1073741824L), 0)
  assert_eq(@bigint.BigInt::compare_int64(2N.pow(40), 1099511627776L), 0)
  assert_eq(@bigint.BigInt::compare_int64(2N.pow(50), 1125899906842624L), 0)
  assert_eq(@bigint.BigInt::compare_int64(2N.pow(60), 1152921504606846976L), 0)
  assert_eq(@bigint.BigInt::compare_int64(2N.pow(62), 4611686018427387904L), 0)
  assert_eq(@bigint.BigInt::compare_int64(2N.pow(63), 9223372036854775807L), 1) // 2^63 > Int64.max_value

  // Test with values around 32-bit boundaries (to ensure 64-bit handling)
  let val_32bit = 4294967296N // 2^32
  assert_eq(@bigint.BigInt::compare_int64(val_32bit, 4294967296L), 0)
  assert_eq(@bigint.BigInt::compare_int64(val_32bit, 4294967295L), 1)
  assert_eq(@bigint.BigInt::compare_int64(val_32bit, 4294967297L), -1)
  let neg_val_32bit = -4294967296N // -2^32
  assert_eq(@bigint.BigInt::compare_int64(neg_val_32bit, -4294967296L), 0)
  assert_eq(@bigint.BigInt::compare_int64(neg_val_32bit, -4294967295L), -1)
  assert_eq(@bigint.BigInt::compare_int64(neg_val_32bit, -4294967297L), 1)
}

///|
test "@bigint.BigInt::hash" {
  // Test zero
  inspect(Hasher::new(seed=0)..combine(0N).finalize(), content="-813420232")
  assert_eq(0N.hash(), (-0N).hash())

  // Positive and negative of same magnitude should have different hashes
  assert_not_eq(1N.hash(), (-1N).hash())

  // Test small positive numbers
  inspect(Hasher::new(seed=0)..combine(42N).finalize(), content="2103260413")

  // Test small negative numbers
  inspect(Hasher::new(seed=0)..combine(-42N).finalize(), content="-504604139")

  // Test larger numbers
  let large = 123456789N
  inspect(Hasher::new(seed=0)..combine(large).finalize(), content="275171670")
  inspect(Hasher::new(seed=0)..combine(-large).finalize(), content="-200902609")

  // Test very large numbers (multi-limb)
  let very_large = 12345678901234567890123456789N
  inspect(
    Hasher::new(seed=0)..combine(very_large).finalize(),
    content="2115080653",
  )
  inspect(
    Hasher::new(seed=0)..combine(-very_large).finalize(),
    content="-1781872667",
  )

  // Test that equal BigInts have equal hashes
  let a = 987654321098765432N
  let b = @bigint.BigInt::from_string("00987654321098765432")
  inspect(Hasher::new(seed=0)..combine(a).finalize(), content="-1950963429")
  inspect(Hasher::new(seed=0)..combine(b).finalize(), content="-1950963429")

  // Test that different BigInts have different hashes (usually)
  let c = a + 1N
  inspect(Hasher::new(seed=0)..combine(c).finalize(), content="-959383658")
}

///|
test "@bigint.BigInt::hash consistency" {
  // Test that hash is consistent across multiple calls
  let big = 999888777666555444333222111N
  let hash1 = big.hash()
  let hash2 = big.hash()
  let hash3 = big.hash()
  assert_eq(hash1, hash2)
  assert_eq(hash1, hash3)

  // Test with negative number
  let neg_big = -big
  let neg_hash1 = neg_big.hash()
  let neg_hash2 = neg_big.hash()
  assert_eq(neg_hash1, neg_hash2)
  assert_not_eq(hash1, neg_hash1)
}

///|
test "default" {
  let a = @bigint.BigInt::default()
  assert_eq(a, 0N)
}

///|
test "BigInt bit ops and arbitrary" {
  let rs = @splitmix.new(seed=1)
  let _ = @bigint.BigInt::arbitrary(1, rs)
  let small = @bigint.BigInt::from_int(1)
  let big = @bigint.BigInt::from_string("123456789012345678901234567891")
  inspect(small.land(big).to_string(), content="1")
  inspect(small.lor(big).to_string(), content="123456789012345678901234567891")
  inspect(small.lxor(big).to_string(), content="123456789012345678901234567890")
}

///|
test "BigInt bit_length negative multi-limb" {
  let neg = @bigint.BigInt::from_string("-4294967297")
  inspect(neg.bit_length() > 0, content="true")
}

///|
test "BigInt bit_length zero" {
  inspect(@bigint.BigInt::from_int(0).bit_length(), content="0")
}
