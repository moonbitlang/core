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

struct ChaCha8 {
  state : State
}

fn ChaCha8::new(seed : Bytes) -> ChaCha8 {
  let c = { state: State::new() }
  c.state.init(seed)
  c
}

priv struct State {
  mut buffer : FixedArray[UInt64] // size=[32]
  mut seed : FixedArray[UInt64] // size=[4]
  mut i : UInt
  mut n : UInt
  mut c : UInt
}

fn State::new() -> State {
  {
    buffer: FixedArray::make(32, 0UL),
    seed: FixedArray::make(4, 0UL),
    i: 0U,
    n: 0U,
    c: 0U,
  }
}

let ctrInc = 4U

let ctrMax = 16U

let chunk = 32U

let chachaReseed = 4

fn State::next(self : State) -> (UInt64, Bool) {
  let i = self.i
  if i >= self.n {
    return (0, false)
  }
  self.i = i + 1
  (self.buffer[i.to_int() & 31], true)
}

fn bytesToUInt64(b : Bytes) -> UInt64 {
  let mut result = 0UL
  for i = 0; i < 8; i = i + 1 {
    result = result | (b[i].to_int64().to_uint64() << (i * 8))
  }
  result
}

test "bytesToUInt64" {
  let bytes = Bytes::new(8)
  for i = 0; i < 2; i = i + 1 {
    bytes[i] = i.to_byte()
  }
  inspect!(bytesToUInt64(bytes), content="256")
}

/// [seed] must be 32 bytes long.
/// @alert unsafe "Panic if seed is not 32 bytes long"
fn State::init(self : State, seed : Bytes) -> Unit {
  if seed.length() != 32 {
    abort("seed must be 32 bytes long")
  }
  let seed0 = Bytes::new(8)
  let seed1 = Bytes::new(8)
  let seed2 = Bytes::new(8)
  let seed3 = Bytes::new(8)
  for i = 0; i < 8; i = i + 1 {
    seed0[i] = seed[i]
    seed1[i] = seed[8 + i]
    seed2[i] = seed[16 + i]
    seed3[i] = seed[24 + i]
  }
  let arr = FixedArray::make(4, 0UL)
  arr[0] = bytesToUInt64(seed0)
  arr[1] = bytesToUInt64(seed1)
  arr[2] = bytesToUInt64(seed2)
  arr[3] = bytesToUInt64(seed3)
  self.init64(arr)
}

fn State::init64(self : State, seed : FixedArray[UInt64]) -> Unit {
  self.seed = seed
  // convert FixedArray[UInt64] size=[32] to FixedArray[FixedArray[UInt]] size=[16][4]
  let buffer = FixedArray::makei(16, fn(_i) { FixedArray::make(4, 0U) })
  // split u64 to 2 u32 and store in buffer to meet the function signature
  for i = 0; i < 16; i = i + 1 {
    let hi = self.buffer[i * 2]
    let lo = self.buffer[i * 2 + 1]
    buffer[i][0] = hi.lsr(32).to_uint()
    buffer[i][1] = hi.to_uint()
    buffer[i][2] = lo.lsr(32).to_uint()
    buffer[i][3] = lo.to_uint()
  }
  // [buffer] is changed in chacha_block
  chacha_block(self.seed, buffer, 0)
  // concat 2 u32 to u64 and store in self.buffer
  for i = 0; i < 16; i = i + 1 {
    for j = 0; j < 4; j = j + 2 {
      let lo = buffer[i][j]
      let hi = buffer[i][j + 1]
      let u64 : UInt64 = (hi.to_uint64() << 32) | lo.to_uint64()
      self.buffer[i * 2 + j / 2] = u64
    }
  }
  self.c = 0
  self.i = 0
  self.n = chunk
}

fn State::refill(self : State) -> Unit {
  self.c = self.c + ctrInc
  if self.c == ctrMax {
    // reseed
    let len = self.buffer.length()
    self.seed[0] = self.buffer[len - chachaReseed + 0]
    self.seed[1] = self.buffer[len - chachaReseed + 1]
    self.seed[2] = self.buffer[len - chachaReseed + 2]
    self.seed[3] = self.buffer[len - chachaReseed + 3]
    self.c = 0
  }
  // convert FixedArray[UInt64] size=[32] to FixedArray[FixedArray[UInt]] size=[16][4]
  let buffer = FixedArray::makei(16, fn(_i) { FixedArray::make(4, 0U) })
  // split u64 to 2 u32 and store in buffer to meet the function signature
  for i = 0; i < 16; i = i + 1 {
    let hi = self.buffer[i * 2]
    let lo = self.buffer[i * 2 + 1]
    buffer[i][0] = hi.lsr(32).to_uint()
    buffer[i][1] = hi.to_uint()
    buffer[i][2] = lo.lsr(32).to_uint()
    buffer[i][3] = lo.to_uint()
  }
  chacha_block(self.seed, buffer, self.c)
  // concat 2 u32 to u64 and store in self.buffer
  for i = 0; i < 16; i = i + 1 {
    for j = 0; j < 4; j = j + 2 {
      let lo = buffer[i][j]
      let hi = buffer[i][j + 1]
      let u64 : UInt64 = (hi.to_uint64() << 32) | lo.to_uint64()
      self.buffer[i * 2 + j / 2] = u64
    }
  }
  self.i = 0
  self.n = self.buffer.length().to_uint()
  if self.c == ctrMax - ctrInc {
    self.n = (self.buffer.length() - chachaReseed).to_uint()
  }
}

fn State::reseed(self : State) -> Unit {
  let seed = FixedArray::make(4, 0UL)
  for i = 0; i < 4; i = i + 1 {
    for {
      let x = self.next()
      if x.1 {
        seed[i] = x.0
        break
      }
      self.refill()
    }
  }
  self.init64(seed)
}

fn chacha_block(
  seed : FixedArray[UInt64],
  buf : FixedArray[FixedArray[UInt]],
  counter : UInt
) -> Unit {
  fn qr(t : (UInt, UInt, UInt, UInt)) -> (UInt, UInt, UInt, UInt) {
    let a = t.0
    let b = t.1
    let c = t.2
    let d = t.3
    let a = a + b
    let d = d ^ a
    let d = (d << 16) | d.lsr(16)
    let c = c + d
    let b = b ^ c
    let b = (b << 12) | b.lsr(20)
    let a = a + b
    let d = d ^ a
    let d = (d << 8) | d.lsr(24)
    let c = c + d
    let b = b ^ c
    let b = (b << 7) | b.lsr(25)
    return (a, b, c, d)
  }

  setup(seed, buf, counter)
  for i = 0; i < buf[0].length(); i = i + 1 {
    let mut b0 = buf[0][i]
    let mut b1 = buf[1][i]
    let mut b2 = buf[2][i]
    let mut b3 = buf[3][i]
    let mut b4 = buf[4][i]
    let mut b5 = buf[5][i]
    let mut b6 = buf[6][i]
    let mut b7 = buf[7][i]
    let mut b8 = buf[8][i]
    let mut b9 = buf[9][i]
    let mut b10 = buf[10][i]
    let mut b11 = buf[11][i]
    let mut b12 = buf[12][i]
    let mut b13 = buf[13][i]
    let mut b14 = buf[14][i]
    let mut b15 = buf[15][i]
    for round = 0; round < 4; round = round + 1 {
      let tb1 = qr((b0, b4, b8, b12))
      b0 = tb1.0
      b4 = tb1.1
      b8 = tb1.2
      b12 = tb1.3
      let tb2 = qr((b1, b5, b9, b13))
      b1 = tb2.0
      b5 = tb2.1
      b9 = tb2.2
      b13 = tb2.3
      let tb3 = qr((b2, b6, b10, b14))
      b2 = tb3.0
      b6 = tb3.1
      b10 = tb3.2
      b14 = tb3.3
      let tb4 = qr((b3, b7, b11, b15))
      b3 = tb4.0
      b7 = tb4.1
      b11 = tb4.2
      b15 = tb4.3
      let tb5 = qr((b0, b5, b10, b15))
      b0 = tb5.0
      b5 = tb5.1
      b10 = tb5.2
      b15 = tb5.3
      let tb6 = qr((b1, b6, b11, b12))
      b1 = tb6.0
      b6 = tb6.1
      b11 = tb6.2
      b12 = tb6.3
      let tb7 = qr((b2, b7, b8, b13))
      b2 = tb7.0
      b7 = tb7.1
      b8 = tb7.2
      b13 = tb7.3
      let tb8 = qr((b3, b4, b9, b14))
      b3 = tb8.0
      b4 = tb8.1
      b9 = tb8.2
      b14 = tb8.3
    }
    buf[0][i] = b0
    buf[1][i] = b1
    buf[2][i] = b2
    buf[3][i] = b3
    buf[4][i] = buf[4][i] + b4
    buf[5][i] = buf[5][i] + b5
    buf[6][i] = buf[6][i] + b6
    buf[7][i] = buf[7][i] + b7
    buf[8][i] = buf[8][i] + b8
    buf[9][i] = buf[9][i] + b9
    buf[10][i] = buf[10][i] + b10
    buf[11][i] = buf[11][i] + b11
    buf[12][i] = b12
    buf[13][i] = b13
    buf[14][i] = b14
    buf[15][i] = b15
  }
}

fn setup(
  seed : FixedArray[UInt64],
  b32 : FixedArray[FixedArray[UInt]],
  counter : UInt
) -> Unit {
  b32[0][0] = 0x61707865
  b32[0][1] = 0x61707865
  b32[0][2] = 0x61707865
  b32[0][3] = 0x61707865
  b32[1][0] = 0x3320646e
  b32[1][1] = 0x3320646e
  b32[1][2] = 0x3320646e
  b32[1][3] = 0x3320646e
  b32[2][0] = 0x79622d32
  b32[2][1] = 0x79622d32
  b32[2][2] = 0x79622d32
  b32[2][3] = 0x79622d32
  b32[3][0] = 0x6b206574
  b32[3][1] = 0x6b206574
  b32[3][2] = 0x6b206574
  b32[3][3] = 0x6b206574
  b32[4][0] = seed[0].to_uint()
  b32[4][1] = seed[0].to_uint()
  b32[4][2] = seed[0].to_uint()
  b32[4][3] = seed[0].to_uint()
  b32[5][0] = seed[0].lsr(32).to_uint()
  b32[5][1] = seed[0].lsr(32).to_uint()
  b32[5][2] = seed[0].lsr(32).to_uint()
  b32[5][3] = seed[0].lsr(32).to_uint()
  b32[6][0] = seed[1].to_uint()
  b32[6][1] = seed[1].to_uint()
  b32[6][2] = seed[1].to_uint()
  b32[6][3] = seed[1].to_uint()
  b32[7][0] = seed[1].lsr(32).to_uint()
  b32[7][1] = seed[1].lsr(32).to_uint()
  b32[7][2] = seed[1].lsr(32).to_uint()
  b32[7][3] = seed[1].lsr(32).to_uint()
  b32[8][0] = seed[2].to_uint()
  b32[8][1] = seed[2].to_uint()
  b32[8][2] = seed[2].to_uint()
  b32[8][3] = seed[2].to_uint()
  b32[9][0] = seed[2].lsr(32).to_uint()
  b32[9][1] = seed[2].lsr(32).to_uint()
  b32[9][2] = seed[2].lsr(32).to_uint()
  b32[9][3] = seed[2].lsr(32).to_uint()
  b32[10][0] = seed[3].to_uint()
  b32[10][1] = seed[3].to_uint()
  b32[10][2] = seed[3].to_uint()
  b32[10][3] = seed[3].to_uint()
  b32[11][0] = seed[3].lsr(32).to_uint()
  b32[11][1] = seed[3].lsr(32).to_uint()
  b32[11][2] = seed[3].lsr(32).to_uint()
  b32[11][3] = seed[3].lsr(32).to_uint()
  b32[12][0] = counter + 0
  b32[12][1] = counter + 1
  b32[12][2] = counter + 2
  b32[12][3] = counter + 3
  b32[13][0] = 0
  b32[13][1] = 0
  b32[13][2] = 0
  b32[13][3] = 0
  b32[14][0] = 0
  b32[14][1] = 0
  b32[14][2] = 0
  b32[14][3] = 0
  b32[15][0] = 0
  b32[15][1] = 0
  b32[15][2] = 0
  b32[15][3] = 0
}

fn string_to_bytes(s : String) -> Bytes {
  let bytes = Bytes::new(s.length())
  for i = 0; i < s.length(); i = i + 1 {
    bytes[i] = s[i].to_int().to_byte()
  }
  bytes
}

test "output" {
  let s = State::new()
  let seed_string = "ABCDEFGHIJKLMNOPQRSTUVWXYZ123456"
  let seed = string_to_bytes(seed_string)
  let res = Array::new(capacity=372)
  s.init(seed)
  fn uint64(s : State) -> UInt64 {
    for {
      let x = s.next()
      if x.1 {
        return x.0
      }
      s.refill()
    }
  }

  for i = 0; i < 372; i = i + 1 {
    let x = uint64(s)
    res.push(x)
  }
  let expected = [
    13219109469176600229UL, 1252193259764759612UL, 10098646897834928252UL, 9142445797040479446UL,
    14963947397558572717UL, 1011356013395962489UL, 4360278772332321598UL, 11266561239126549327UL,
    16103107970030431910UL, 3951155890335085418UL, 17217491508779737119UL, 620366957612729398UL,
    15701003340574544488UL, 16946962128229337786UL, 5734710318278665825UL, 14107018073513584172UL,
    10514695901183618686UL, 8668570317698669510UL, 6644195231047269920UL, 5695522258251995816UL,
    18173674537264966642UL, 6561080880156464316UL, 7896566770606135777UL, 17198961315715285235UL,
    3258233649777561765UL, 4039019003980269744UL, 17199080872890330697UL, 17597083911441838460UL,
    9541597232904836516UL, 10269632480771352091UL, 1791309313159652499UL, 1121290688170442051UL,
    14767415290099658880UL, 18264015867885335344UL, 10795746865526236211UL, 7814966709161082135UL,
    5056082071174014306UL, 6606687772221963370UL, 902460967827941768UL, 15247644503822243389UL,
    13837920613503741631UL, 6215820458297045417UL, 2701601382099612372UL, 8049443921449462014UL,
    12580932726856406240UL, 5068579462968063859UL, 2054759765710618254UL, 8060325759976441792UL,
    3952703220727229276UL, 11868554197401451959UL, 5611917470950228677UL, 14826085289999852455UL,
    18131733951999902497UL, 6983040833037131399UL, 15098965934858340182UL, 7162487557317849930UL,
    389612597396113390UL, 5480468948381420210UL, 14924541494497045954UL, 438038016380948435UL,
    15107526033745383085UL, 3577988464916041960UL, 12379376873809997548UL, 4629939204773816090UL,
    4382836348202044776UL, 15911307370497934714UL, 16912525941835256446UL, 1749399752872286892UL,
    17865934552210109010UL, 6342441227090084049UL, 6679300346758746971UL, 16633103117551110662UL,
    369926567391976152UL, 3270154504052173416UL, 12351442307584366520UL, 14053856752323452444UL,
    5700095014850418212UL, 18134114469714363192UL, 11060594460025237009UL, 1231359220627153402UL,
    562452272787830041UL, 2978775404523127572UL, 4722226048622717816UL, 6253931703231703629UL,
    9215422719337958629UL, 3873253580645818250UL, 1288530853271360801UL, 11001669669030575221UL,
    15088099745414120440UL, 10121311161118028787UL, 2646319338087045047UL, 8736474933647836016UL,
    10270419548610515257UL, 4775977266197392933UL, 5858955664787759631UL, 15884112255303985129UL,
    1570402559843208890UL, 14683984304255533684UL, 4590793746421620769UL, 15088822470495597798UL,
    430063278371467896UL, 17951554591419905623UL, 871816740556950425UL, 17903421440867820178UL,
    13750571273678813240UL, 17408919480923799904UL, 14550467517685344003UL, 17801022151644150006UL,
    15135601085914355452UL, 3483086720686978374UL, 9411102566564534151UL, 1565275101947305404UL,
    18195171881473325257UL, 3771067494878101692UL, 7443114766343082856UL, 1311911009840065015UL,
    1031414546975514137UL, 16727931877057143004UL, 420176525623228030UL, 16779254430513255833UL,
    2085321528439172864UL, 14769502908867070793UL, 3476754806476653326UL, 9663999206884821105UL,
    6864012991572870279UL, 2719468417766812445UL, 13735767778024137757UL, 7331676388138190150UL,
    15110277136215905228UL, 118894811326561078UL, 6308935423749160781UL, 1857610629058673910UL,
    15843686394045370811UL, 10951543581626859443UL, 3587431610669043023UL, 670469650389812154UL,
    476209600999700306UL, 6589566024609793738UL, 8281611217869782149UL, 15129277549214352190UL,
    13446421929377692845UL, 17071158676955966275UL, 7349330903428905191UL, 3277698994734830674UL,
    14731635658592643043UL, 5477400073429632652UL, 67518392538487036UL, 11035168000757098093UL,
    9797693702590129641UL, 14649582299731326424UL, 15236666389149272153UL, 16511980240231261314UL,
    2249833951459307500UL, 13214955418772830438UL, 329963039908253864UL, 8574511220958401562UL,
    4538345089129965474UL, 16353802882881726632UL, 8935276449126753317UL, 13532443277699696063UL,
    8669346374187395779UL, 17810417737921607796UL, 3904677225590828551UL, 10264576476552345822UL,
    3042606770072189440UL, 12878478126980245939UL, 17862138228081367377UL, 16992359172961651842UL,
    17034107108697981338UL, 12909026467335450156UL, 2470441546010339704UL, 3634699771143106326UL,
    366960336551226348UL, 5510841956427041079UL, 15461212383052875073UL, 16433279593065139848UL,
    4486890193637877972UL, 14360905330534596440UL, 4449385520993789019UL, 3743094329222006520UL,
    2212668117926313829UL, 4681723502265844963UL, 13296513799272088946UL, 2343616111600662093UL,
    14717171566066041529UL, 11738831003851491807UL, 15851419960104864784UL, 8132762647638440149UL,
    3464418631265929631UL, 340027485718840165UL, 8395791638092059350UL, 3109485649064359417UL,
    10944349985020042736UL, 6522608726689095595UL, 17803052569896648610UL, 2064238649661354599UL,
    4092763376312896325UL, 15988266335744638521UL, 16848187183754420180UL, 199841868197609864UL,
    17491157950173501157UL, 12533485177359032661UL, 6254686503080376974UL, 5499127381395659705UL,
    10487847042307388775UL, 12368654789669906974UL, 2361938659724380109UL, 8148818964487342298UL,
    12717021730603072605UL, 15728257831000719154UL, 15823591063810279774UL, 6928887951986678348UL,
    17959062744186568888UL, 16016655507227678734UL, 14898526437837544110UL, 16974466848830908932UL,
    15320157178342639871UL, 8261903640164714632UL, 14435417271854760UL, 9182672404209601003UL,
    5994285655773158181UL, 15654703508405219038UL, 16079243345868226083UL, 10784497444694088416UL,
    4442318623009455690UL, 7578904045792755239UL, 4660917127407640248UL, 1338871040102977572UL,
    7923968833761895669UL, 16874906449763725362UL, 6867431507591727612UL, 6311558572587278442UL,
    11133241125491102835UL, 11738312930013082355UL, 11475845091361842759UL, 1643869946623606078UL,
    10415771985971144045UL, 16177299554619494974UL, 539570561320537202UL, 14686903393511273001UL,
    4445884513647149105UL, 5098090666552700373UL, 15054419504752089185UL, 3474469100259604016UL,
    6290470378995655110UL, 12581245818984890955UL, 12787308417917333104UL, 15615073174539148765UL,
    12984984669203863910UL, 5985056152809872019UL, 11524779172526084917UL, 12665285781050723551UL,
    17258307941988319274UL, 1228317169172941352UL, 11160397433235040502UL, 9071341095814202162UL,
    16466220084500004578UL, 17881879368693790694UL, 11823018491644357805UL, 16578188432210840351UL,
    9406010430949605407UL, 11905115929048085077UL, 9944213925190004442UL, 7029678422186467496UL,
    11401152387492259905UL, 10919895159361451251UL, 8495109194203518959UL, 16018667729961568082UL,
    167446916071967039UL, 5832416432401633017UL, 2555624166217836526UL, 4693948454793001376UL,
    15027938303073958689UL, 3816085682362256244UL, 3185235675206645589UL, 14811052307061536715UL,
    16390566561388972206UL, 16262619695511054469UL, 18052593823409859051UL, 3945540604022845918UL,
    15826009464703323776UL, 7719326347171925540UL, 9769778031520080067UL, 421859423473436660UL,
    13367093898566883586UL, 6779889834239319169UL, 609582038820777224UL, 8614685872506396309UL,
    4322299411370527537UL, 12846241946314463225UL, 7603764924892388925UL, 14478986206635481787UL,
    12755177540574038518UL, 6194314060039108547UL, 7432498317049243916UL, 13744344095303706494UL,
    4564573594452194471UL, 15206391374377392170UL, 14985029622013689232UL, 14328768324291300885UL,
    10654090591156151429UL, 7338671807663089189UL, 16334907285225846266UL, 7423398075744368270UL,
    13908293662617472937UL, 17175512688958868014UL, 7864028190390018941UL, 13126986956610526127UL,
    7926473773501694475UL, 1941817884837167576UL, 15856689629067382306UL, 11177334980354607906UL,
    7146885710676518584UL, 15983324774902192370UL, 17386093453964105449UL, 4150817240659351930UL,
    7715942048190956297UL, 7276773301104081815UL, 13271959532491042945UL, 1194118668544183835UL,
    17605071903565571062UL, 8948583740938417863UL, 3864418170274807074UL, 3699237212540510096UL,
    14714003198217388528UL, 14269453830925281739UL, 8957047989018367339UL, 12402048382093370001UL,
    11758047802384768757UL, 7093460309329455699UL, 384408371497488372UL, 1458858056370266940UL,
    15774153359596962328UL, 5577985376535770293UL, 3965786813088619889UL, 17835800480481320920UL,
    32994991092960231UL, 17146972595756459521UL, 12264557860820767038UL, 13718959782553074566UL,
    1372337231943282583UL, 15958043944784669526UL, 17520298198669188203UL, 3031291504644241637UL,
    6514984797562383624UL, 4345071177348538448UL, 3359260195018829989UL, 2607793539626362761UL,
    16792663172613334423UL, 9898393582456908268UL, 2786478731415243607UL, 12029113901756054096UL,
    3691479334576095829UL, 11929280456476427793UL, 18327972477027512052UL, 254886074006853656UL,
    2927328918014182935UL, 4439939690082200099UL, 5969478689443458641UL, 14369317615642310767UL,
    17764732325494572140UL, 10115938472474762880UL, 369466901724782737UL, 2269989694701338999UL,
    1231466417883291608UL, 4918841702239877720UL, 13883670878602349637UL, 11470126477371023265UL,
    17128636052794644986UL, 205335811880395712UL, 12443170494233065292UL, 15986026963143729439UL,
  ]
  assert_eq!(res, expected)
}
