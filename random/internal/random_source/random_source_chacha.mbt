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
/// A pseudo-random number generator built on the `chacha8rand`
/// construction used by Go's `math/rand/v2` and specified at
/// https://c2sp.org/chacha8rand. It pairs a 4-block-batched ChaCha8
/// stream with delayed key erasure.
///
/// Each `refill` runs four ChaCha8 blocks in parallel: block counters
/// `counter`, `counter + 1`, `counter + 2`, `counter + 3`, producing
/// 256 bytes (32 * `UInt64`) of output. Every fourth batch reserves the
/// tail 32 bytes as the next key, and the following `refill` installs it
/// before generating more output. Because that key erasure is delayed, a
/// memory dump can reconstruct recent buffered output, but not output
/// before the previous reseed.
///
/// This differs from a plain ChaCha8 keystream in two ways: only the key
/// rows (rows 4-11) of the state are added back into the output, and the
/// four blocks share a SIMD-friendly interleaved memory layout.
struct ChaCha8 {
  /// Generated keystream. Dual-purposed across the two phases of a
  /// refill, with a length of `BUFFER_CHUNK_NUM * 2 = 64` 32-bit words:
  ///
  /// - During `chacha_block`: a 16-row by 4-lane interleaved ChaCha state
  ///   matrix, with row `r` of lane `l` at `buffer[r * 4 + l]`.
  /// - After `chacha_block` returns: 32 consecutive little-endian
  ///   `UInt64` outputs, where output `k` lives at `buffer[k * 2]` (low)
  ///   and `buffer[k * 2 + 1]` (high). The two layouts coincide because
  ///   `16 rows * 4 lanes = 32 outputs * 2 halves = 64` words.
  buffer : FixedArray[UInt]
  /// The current ChaCha key (256 bits) as `SEED_CHUNK_NUM * 2 = 8`
  /// little-endian 32-bit words. On every reseed (every 4 refills) the
  /// final 32 bytes of the previous keystream overwrite this field: the
  /// fast-key-erasure step.
  seed : FixedArray[UInt]
  /// Index of the next `UInt64` to return, counted in 64-bit units from
  /// the start of `buffer`. `next_uint64` refills before reading when
  /// `i >= n`, so every read has `i < n <= BUFFER_CHUNK_NUM`. The mask in
  /// the buffer index is valid because `BUFFER_CHUNK_NUM` is a power of 2.
  mut i : UInt
  /// Number of `UInt64`s in `buffer` that may be returned this cycle.
  /// Normally `BUFFER_CHUNK_NUM = 32`. On the refill immediately before a
  /// reseed it drops to `BUFFER_CHUNK_NUM - SEED_CHUNK_NUM = 28`, because
  /// the trailing 4 `UInt64`s are reserved as the next key and must not
  /// be exposed as output.
  mut n : UInt
  /// ChaCha block counter for the *next* call to `chacha_block`: the
  /// counter of the first of the 4 parallel lanes. Advances by
  /// `COUNTER_INC = 4` per refill and wraps to 0 on reaching
  /// `COUNTER_MAX = 16`, which is also the reseed trigger.
  mut counter : UInt
}

///|
/// Constructs a fresh `ChaCha8` PRNG from a 32-byte key.
///
/// The seed is parsed as 8 little-endian 32-bit words. The first
/// keystream batch is produced eagerly so that the first call to
/// `next_uint64` does not pay the cost of a refill.
///
/// Aborts if `seed` is not exactly 32 bytes long.
pub fn ChaCha8::ChaCha8(seed : BytesView) -> ChaCha8 {
  if seed.length() != 32 {
    abort("seed must be 32 bytes long")
  }
  let seed = FixedArray::makei(SEED_CHUNK_NUM * 2, i => {
    match seed[i * 4:] {
      [u32le(x), ..] => x
      _ => abort("seed must be 32 bytes long")
    }
  })
  let buffer = FixedArray::make(BUFFER_CHUNK_NUM * 2, 0U)
  chacha_block(seed, buffer, 0)
  { seed, buffer, counter: 0, i: 0, n: BUFFER_CHUNK_NUM.reinterpret_as_uint() }
}

///|
/// Step applied to `counter` per refill: equals the number of ChaCha
/// blocks generated in parallel by one call to `chacha_block`.
const COUNTER_INC = 4U

///|
/// Counter value at which the generator reseeds. After
/// `COUNTER_MAX / COUNTER_INC = 4` refills, `counter` wraps back to 0 and
/// the tail of the most recent keystream becomes the new key.
const COUNTER_MAX = 16U

///|
/// Number of 64-bit outputs produced per refill. Must be a power of 2 so
/// that buffer indexing can use a bitmask (`& (BUFFER_CHUNK_NUM - 1)`)
/// instead of a division. With 4 lanes * 16 32-bit words per block / 2
/// words per `UInt64` = 32 outputs, this also matches the natural
/// capacity of `chacha_block`.
const BUFFER_CHUNK_NUM = 32

///|
/// Number of 64-bit words in the ChaCha key (256 bits = 4 * 64 bits) and,
/// equivalently, the number of `UInt64`s reserved at the end of each
/// reseed cycle to become the next key.
const SEED_CHUNK_NUM = 4

///|
/// Return the next random `UInt64`, refilling the internal buffer when needed.
pub fn ChaCha8::next_uint64(self : ChaCha8) -> UInt64 {
  let mut i = self.i
  if i >= self.n {
    self.refill()
    i = 0
  }
  self.i = i + 1
  let index = i.reinterpret_as_int() & (BUFFER_CHUNK_NUM - 1)
  let lo = self.buffer[index * 2].to_uint64()
  let hi = self.buffer[index * 2 + 1].to_uint64()
  (hi << 32) | lo
}

///|
/// Refill the internal buffer and reset the read cursor.
///
/// After refill, `self.i == 0` and `self.n` is either `BUFFER_CHUNK_NUM`
/// or `BUFFER_CHUNK_NUM - SEED_CHUNK_NUM`, so `self.i < self.n`.
///
/// On the refill that wraps `counter` from `COUNTER_MAX - COUNTER_INC`
/// back to 0, the trailing `SEED_CHUNK_NUM * 2` words of the previous
/// keystream are copied over `seed` (the fast-key-erasure reseed) before
/// the next batch is generated.
pub fn ChaCha8::refill(self : ChaCha8) -> Unit {
  self.counter += COUNTER_INC
  if self.counter == COUNTER_MAX {
    // reseed
    // 1 chunk = 64 bits = number of bits in UInt * 2
    self.buffer.blit_to(
      self.seed,
      len=SEED_CHUNK_NUM * 2,
      src_offset=(BUFFER_CHUNK_NUM - SEED_CHUNK_NUM) * 2,
    )
    self.counter = 0
  }
  chacha_block(self.seed, self.buffer, self.counter)
  self.i = 0
  self.n = if self.counter == COUNTER_MAX - COUNTER_INC {
    (BUFFER_CHUNK_NUM - SEED_CHUNK_NUM).reinterpret_as_uint()
  } else {
    BUFFER_CHUNK_NUM.reinterpret_as_uint()
  }
}

///|
/// The 4-word working set of a single ChaCha quarter-round. `#valtype`
/// keeps it unboxed so that `qr` is effectively a pure register-level
/// operation with no heap traffic.
#valtype
priv struct Quadruple(UInt, UInt, UInt, UInt)

///|
/// Runs four parallel ChaCha8 blocks into `buf`, using `seed` as the key
/// and `(counter, counter + 1, counter + 2, counter + 3)` as the four
/// block counters.
///
/// State is laid out in interleaved SIMD form: row `r` of lane `l` lives
/// at `buf[r * 4 + l]`. The outer `for i in 0..<4` loop walks the lanes;
/// holding all 16 state words in locals `b0..b15` across the inner
/// `for _ in 0..<4` double-round loop lets the backend keep them in
/// registers for the entire permutation.
///
/// After 4 double-rounds (= 8 rounds) of column + diagonal quarter
/// rounds, only the key rows (rows 4-11) are added back into the
/// output; the constant and counter/nonce rows are written directly.
/// This is intentional per the `chacha8rand` spec and is what makes the
/// output differ from a plain ChaCha8 keystream.
fn chacha_block(
  seed : FixedArray[UInt],
  buf : FixedArray[UInt],
  counter : UInt,
) -> Unit {
  fn qr(t : Quadruple) -> Quadruple {
    let Quadruple(a, b, c, d) = t
    let a = a + b
    let d = d ^ a
    let d = (d << 16) | (d >> 16)
    let c = c + d
    let b = b ^ c
    let b = (b << 12) | (b >> 20)
    let a = a + b
    let d = d ^ a
    let d = (d << 8) | (d >> 24)
    let c = c + d
    let b = b ^ c
    let b = (b << 7) | (b >> 25)
    Quadruple(a, b, c, d)
  }

  setup(seed, buf, counter)
  for i in 0..<4 {
    let mut b0 = buf[0 * 4 + i]
    let mut b1 = buf[1 * 4 + i]
    let mut b2 = buf[2 * 4 + i]
    let mut b3 = buf[3 * 4 + i]
    let mut b4 = buf[4 * 4 + i]
    let mut b5 = buf[5 * 4 + i]
    let mut b6 = buf[6 * 4 + i]
    let mut b7 = buf[7 * 4 + i]
    let mut b8 = buf[8 * 4 + i]
    let mut b9 = buf[9 * 4 + i]
    let mut b10 = buf[10 * 4 + i]
    let mut b11 = buf[11 * 4 + i]
    let mut b12 = buf[12 * 4 + i]
    let mut b13 = buf[13 * 4 + i]
    let mut b14 = buf[14 * 4 + i]
    let mut b15 = buf[15 * 4 + i]
    for _ in 0..<4 {
      let Quadruple(tb1_0, tb1_1, tb1_2, tb1_3) = qr(Quadruple(b0, b4, b8, b12))
      b0 = tb1_0
      b4 = tb1_1
      b8 = tb1_2
      b12 = tb1_3
      let Quadruple(tb2_0, tb2_1, tb2_2, tb2_3) = qr(Quadruple(b1, b5, b9, b13))
      b1 = tb2_0
      b5 = tb2_1
      b9 = tb2_2
      b13 = tb2_3
      let Quadruple(tb3_0, tb3_1, tb3_2, tb3_3) = qr(
        Quadruple(b2, b6, b10, b14),
      )
      b2 = tb3_0
      b6 = tb3_1
      b10 = tb3_2
      b14 = tb3_3
      let Quadruple(tb4_0, tb4_1, tb4_2, tb4_3) = qr(
        Quadruple(b3, b7, b11, b15),
      )
      b3 = tb4_0
      b7 = tb4_1
      b11 = tb4_2
      b15 = tb4_3
      let Quadruple(tb5_0, tb5_1, tb5_2, tb5_3) = qr(
        Quadruple(b0, b5, b10, b15),
      )
      b0 = tb5_0
      b5 = tb5_1
      b10 = tb5_2
      b15 = tb5_3
      let Quadruple(tb6_0, tb6_1, tb6_2, tb6_3) = qr(
        Quadruple(b1, b6, b11, b12),
      )
      b1 = tb6_0
      b6 = tb6_1
      b11 = tb6_2
      b12 = tb6_3
      let Quadruple(tb7_0, tb7_1, tb7_2, tb7_3) = qr(Quadruple(b2, b7, b8, b13))
      b2 = tb7_0
      b7 = tb7_1
      b8 = tb7_2
      b13 = tb7_3
      let Quadruple(tb8_0, tb8_1, tb8_2, tb8_3) = qr(Quadruple(b3, b4, b9, b14))
      b3 = tb8_0
      b4 = tb8_1
      b9 = tb8_2
      b14 = tb8_3
    }
    buf[0 * 4 + i] = b0
    buf[1 * 4 + i] = b1
    buf[2 * 4 + i] = b2
    buf[3 * 4 + i] = b3
    buf[4 * 4 + i] += b4
    buf[5 * 4 + i] += b5
    buf[6 * 4 + i] += b6
    buf[7 * 4 + i] += b7
    buf[8 * 4 + i] += b8
    buf[9 * 4 + i] += b9
    buf[10 * 4 + i] += b10
    buf[11 * 4 + i] += b11
    buf[12 * 4 + i] = b12
    buf[13 * 4 + i] = b13
    buf[14 * 4 + i] = b14
    buf[15 * 4 + i] = b15
  }
}

///|
/// Initializes the interleaved 16-by-4 state matrix in `b32` from the key
/// and block counter, ready for `chacha_block` to permute.
///
/// All four lanes share the same constants (rows 0-3), the same key (rows
/// 4-11), and zero nonce (rows 13-15); only the block counter in row 12
/// differs across lanes, taking values `counter, counter + 1,
/// counter + 2, counter + 3`.
///
/// Rows 0-3 hold the four 32-bit words of the ASCII string
/// `"expand 32-byte k"` (`"expa" / "nd 3" / "2-by" / "te k"` in
/// little-endian): the standard ChaCha sigma constants.
fn setup(
  seed : FixedArray[UInt],
  b32 : FixedArray[UInt],
  counter : UInt,
) -> Unit {
  b32[0 * 4 + 0] = 0x61707865
  b32[0 * 4 + 1] = 0x61707865
  b32[0 * 4 + 2] = 0x61707865
  b32[0 * 4 + 3] = 0x61707865
  b32[1 * 4 + 0] = 0x3320646e
  b32[1 * 4 + 1] = 0x3320646e
  b32[1 * 4 + 2] = 0x3320646e
  b32[1 * 4 + 3] = 0x3320646e
  b32[2 * 4 + 0] = 0x79622d32
  b32[2 * 4 + 1] = 0x79622d32
  b32[2 * 4 + 2] = 0x79622d32
  b32[2 * 4 + 3] = 0x79622d32
  b32[3 * 4 + 0] = 0x6b206574
  b32[3 * 4 + 1] = 0x6b206574
  b32[3 * 4 + 2] = 0x6b206574
  b32[3 * 4 + 3] = 0x6b206574
  b32[4 * 4 + 0] = seed[0]
  b32[4 * 4 + 1] = seed[0]
  b32[4 * 4 + 2] = seed[0]
  b32[4 * 4 + 3] = seed[0]
  b32[5 * 4 + 0] = seed[1]
  b32[5 * 4 + 1] = seed[1]
  b32[5 * 4 + 2] = seed[1]
  b32[5 * 4 + 3] = seed[1]
  b32[6 * 4 + 0] = seed[2]
  b32[6 * 4 + 1] = seed[2]
  b32[6 * 4 + 2] = seed[2]
  b32[6 * 4 + 3] = seed[2]
  b32[7 * 4 + 0] = seed[3]
  b32[7 * 4 + 1] = seed[3]
  b32[7 * 4 + 2] = seed[3]
  b32[7 * 4 + 3] = seed[3]
  b32[8 * 4 + 0] = seed[4]
  b32[8 * 4 + 1] = seed[4]
  b32[8 * 4 + 2] = seed[4]
  b32[8 * 4 + 3] = seed[4]
  b32[9 * 4 + 0] = seed[5]
  b32[9 * 4 + 1] = seed[5]
  b32[9 * 4 + 2] = seed[5]
  b32[9 * 4 + 3] = seed[5]
  b32[10 * 4 + 0] = seed[6]
  b32[10 * 4 + 1] = seed[6]
  b32[10 * 4 + 2] = seed[6]
  b32[10 * 4 + 3] = seed[6]
  b32[11 * 4 + 0] = seed[7]
  b32[11 * 4 + 1] = seed[7]
  b32[11 * 4 + 2] = seed[7]
  b32[11 * 4 + 3] = seed[7]
  // from counter to counter + (COUNTER_INC - 1)
  b32[12 * 4 + 0] = counter + 0
  b32[12 * 4 + 1] = counter + 1
  b32[12 * 4 + 2] = counter + 2
  b32[12 * 4 + 3] = counter + 3
  b32[13 * 4 + 0] = 0
  b32[13 * 4 + 1] = 0
  b32[13 * 4 + 2] = 0
  b32[13 * 4 + 3] = 0
  b32[14 * 4 + 0] = 0
  b32[14 * 4 + 1] = 0
  b32[14 * 4 + 2] = 0
  b32[14 * 4 + 3] = 0
  b32[15 * 4 + 0] = 0
  b32[15 * 4 + 1] = 0
  b32[15 * 4 + 2] = 0
  b32[15 * 4 + 3] = 0
}

///|
test "BUFFER_CHUNK_NUM is power of 2" {
  @test.assert_eq(BUFFER_CHUNK_NUM.clz() + BUFFER_CHUNK_NUM.ctz(), 31)
}

///|
fn chacha8_values_at(seed : BytesView, positions : Array[Int]) -> Array[UInt64] {
  let s = ChaCha8(seed)
  let values = [
    for _ in 0..<=positions[positions.length() - 1] => s.next_uint64()
  ]
  [
    for position in positions => values[position]
  ]
}

///|
test "boundary conformance samples" {
  let positions = [
    0, 1, 31, 32, 33, 95, 96, 123, 124, 125, 247, 248, 249, 371, 372,
  ]
  // Generated from an independent C2SP-style ChaCha8Rand reference. The
  // selected indices cover starts, 32-value refill boundaries, the 124-value
  // reseed iteration boundary, and the first value after three reseeds.
  @test.assert_eq(chacha8_values_at(Bytes::make(32, b'\x00'), positions), [
    12432809566553409497UL, 7766219816435805978UL, 125952780581614778UL, 11456203247299035011UL,
    11766211380141310478UL, 6247410371955873534UL, 3688096476295560216UL, 8184198519316962464UL,
    10179668788428909817UL, 5258471208527403019UL, 7420841827674394489UL, 10937539205284161074UL,
    7354588099337910803UL, 1988377183516050978UL, 14819101479397601098UL,
  ])
  @test.assert_eq(
    chacha8_values_at(Bytes::makei(32, i => i.to_byte()), positions),
    [
      12537355132343524571UL, 11147319424196738781UL, 10643391562797985389UL, 3312211745067898083UL,
      9018521450285820678UL, 4858190046463179352UL, 990490856749627748UL, 7053860951501379351UL,
      7333627332515303615UL, 13837653776835850180UL, 2865794351678725456UL, 5128231522832781158UL,
      5308840319225627323UL, 16534914931032675201UL, 9337503077864249277UL,
    ],
  )
  @test.assert_eq(
    chacha8_values_at(Bytes::makei(32, i => (31 - i).to_byte()), positions),
    [
      13207452830590730783UL, 5009552866163029026UL, 10502404787336730197UL, 9712881148437595521UL,
      16401154181191732095UL, 16593913030854572746UL, 14562847379601139255UL, 7882510831935376133UL,
      7240113522724531080UL, 1369140773094178244UL, 12544778259996841346UL, 17662407199021422433UL,
      8595294092888404219UL, 3588698780051976674UL, 13209002768099367735UL,
    ],
  )
}

///|
test "output" {
  let s = ChaCha8(b"ABCDEFGHIJKLMNOPQRSTUVWXYZ123456")
  // C2SP's sample output is the first 2976 bytes of ChaCha8Rand output,
  // interpreted here as 372 little-endian UInt64 values. That spans three
  // 992-byte iterations and exercises both refill and reseed transitions.
  let res = [ for _ in 0..<372 => s.next_uint64() ]
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
  @test.assert_eq(res, expected)
}
