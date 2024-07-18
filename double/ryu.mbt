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

// MoonBit implementation of Ryu, https://github.com/ulfjack/ryu

fn log10Pow5(e : Int) -> Int {
  (e * 732923).lsr(20)
}

fn pow5bits(e : Int) -> Int {
  (e * 1217359).lsr(19) + 1
}

fn log10Pow2(e : Int) -> Int {
  (e * 78913).lsr(18)
}

fn string_from_bytes(bytes : Bytes, from : Int, to : Int) -> String {
  let buf = Buffer::new(size_hint=bytes.length())
  for i = from; i < to; i = i + 1 {
    buf.write_char(Char::from_int(bytes[i].to_int()))
  }
  buf.to_string()
}

fn copy_special_str(sign : Bool, exponent : Bool, mantissa : Bool) -> String {
  if mantissa {
    return "NaN"
  }
  let s = if sign { "-" } else { "" }
  if exponent {
    return s + "Infinity"
  }
  return s + "0.0"
}

fn u64_lt(x : Int64, y : Int64) -> Bool {
  x.to_uint64().compare(y.to_uint64()) == -1
}

fn umul128(a : Int64, b : Int64) -> (Int64, Int64) {
  let aLo : Int = a.to_int()
  let aHi : Int = a.lsr(32).to_int()
  let bLo : Int = b.to_int()
  let bHi : Int = b.lsr(32).to_int()
  let b00 : Int64 = (UInt64::extend_uint(aLo.to_uint()) * UInt64::extend_uint(
    bLo.to_uint(),
  )).to_int64()
  let b01 : Int64 = (UInt64::extend_uint(aLo.to_uint()) * UInt64::extend_uint(
    bHi.to_uint(),
  )).to_int64()
  let b10 : Int64 = (UInt64::extend_uint(aHi.to_uint()) * UInt64::extend_uint(
    bLo.to_uint(),
  )).to_int64()
  let b11 : Int64 = (UInt64::extend_uint(aHi.to_uint()) * UInt64::extend_uint(
    bHi.to_uint(),
  )).to_int64()
  let b00Lo : Int = b00.to_int()
  let b00Hi : Int = b00.lsr(32).to_int()
  let mid1 : Int64 = b10 + UInt64::extend_uint(b00Hi.to_uint()).to_int64()
  let mid1Lo : Int = mid1.to_int()
  let mid1Hi : Int = mid1.lsr(32).to_int()
  let mid2 : Int64 = b01 + UInt64::extend_uint(mid1Lo.to_uint()).to_int64()
  let mid2Lo : Int = mid2.to_int()
  let mid2Hi : Int = mid2.lsr(32).to_int()
  let pHi : Int64 = b11 + UInt64::extend_uint(mid1Hi.to_uint()).to_int64() + UInt64::extend_uint(
      mid2Hi.to_uint(),
    ).to_int64()
  let pLo : Int64 = UInt64::extend_uint(mid2Lo.to_uint()).to_int64().lsl(32).lor(
    UInt64::extend_uint(b00Lo.to_uint()).to_int64(),
  )
  (pLo, pHi)
}

fn shiftright128(lo : Int64, hi : Int64, dist : Int) -> Int64 {
  hi.lsl(64 - dist).lor(lo.lsr(dist))
}

fn pow5Factor(value : Int64) -> Int {
  // We want to find the largest power of 5 that divides value.
  if value % 5L != 0L {
    return 0
  }
  if value % 25L != 0L {
    return 1
  }
  if value % 125L != 0L {
    return 2
  }
  if value % 625L != 0L {
    return 3
  }
  let mut count = 4
  let mut value = value / 625L
  while value > 0L {
    if value % 5L != 0L {
      return count
    }
    value = value / 5L
    count = count + 1
  }
  abort("IllegalArgumentException \(value)")
}

fn multipleOfPowerOf5(value : Int64, p : Int) -> Bool {
  pow5Factor(value) >= p
}

fn multipleOfPowerOf2(value : Int64, p : Int) -> Bool {
  value.land(1L.lsl(p) - 1L) == 0L
}

fn mulShiftAll64(
  m : Int64,
  mul : (Int64, Int64),
  j : Int,
  mmShift : Bool
) -> (Int64, Int64, Int64) {
  let m = m.lsl(1)
  let (lo, tmp) = umul128(m, mul.0)
  let (lo2, hi2) = umul128(m, mul.1)
  let mid = tmp + lo2
  let hi = hi2 + u64_lt(mid, tmp).to_int64()
  let lo2 = lo + mul.0
  let mid2 = mid + mul.1 + u64_lt(lo2, lo).to_int64()
  let hi2 = hi + u64_lt(mid2, mid).to_int64()
  let vp = shiftright128(mid2, hi2, j - 64 - 1)
  let mut vm : Int64 = 0L
  if mmShift {
    let lo3 = lo - mul.0
    let mid3 = mid - mul.1 - u64_lt(lo, lo3).to_int64()
    let hi3 = hi - u64_lt(mid, mid3).to_int64()
    vm = shiftright128(mid3, hi3, j - 64 - 1)
  } else {
    let lo3 : Int64 = lo + lo
    let mid3 : Int64 = mid + mid + u64_lt(lo3, lo).to_int64()
    let hi3 : Int64 = hi + hi + u64_lt(mid3, mid).to_int64()
    let lo4 : Int64 = lo3 - mul.0
    let mid4 : Int64 = mid3 - mul.1 - u64_lt(lo3, lo4).to_int64()
    let hi4 : Int64 = hi3 - u64_lt(mid3, mid4).to_int64()
    vm = shiftright128(mid4, hi4, j - 64)
  }
  let vr = shiftright128(mid, hi, j - 64 - 1)
  (vr, vp, vm)
}

let gPOW5_TABLE_SIZE = 26

let gDOUBLE_POW5_INV_SPLIT2 : Array[Int64] = [
  1L, 2305843009213693952L, 5955668970331000884L, 1784059615882449851L, 8982663654677661702L,
  1380349269358112757L, 7286864317269821294L, 2135987035920910082L, 7005857020398200553L,
  1652639921975621497L, -481418970354774919L, 1278668206209430417L, 8928596168509315048L,
  1978643211784836272L, -8371072500651252758L, 1530901034580419511L, 597001226353042382L,
  1184477304306571148L, 1527430471115325346L, 1832889850782397517L, -5913534206540532074L,
  1418129833677084982L, 5577825024675947042L, 2194449627517475473L, -7439769533505684065L,
  1697873161311732311L, -8133250842069730034L, 1313665730009899186L, -5745727253942878843L,
  2032799256770390445L,
]

let gPOW5_INV_OFFSETS : Array[Int] = [
  0x54544554, 0x04055545, 0x10041000, 0x00400414, 0x40010000, 0x41155555, 0x00000454,
  0x00010044, 0x40000000, 0x44000041, 0x50454450, 0x55550054, 0x51655554, 0x40004000,
  0x01000001, 0x00010500, 0x51515411, 0x05555554, 0x00000000,
]

let gDOUBLE_POW5_SPLIT2 : Array[Int64] = [
  0L, 1152921504606846976L, 0L, 1490116119384765625L, 1032610780636961552L, 1925929944387235853L,
  7910200175544436838L, 1244603055572228341L, -1504838264676837686L, 1608611746708759036L,
  -5421850118411349444L, 2079081953128979843L, 6607496772837067824L, 1343575221513417750L,
  -1113817083813899013L, 1736530273035216783L, -5409364890226003632L, 2244412773384604712L,
  1605989338741628675L, 1450417759929778918L, -8816519005292960336L, 1874621017369538693L,
  665883850346957067L, 1211445438634777304L, -3514853404985837908L, 1565756531257009982L,
]

let gPOW5_OFFSETS : Array[Int] = [
  0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x40000000, 0x59695995, 0x55545555,
  0x56555515, 0x41150504, 0x40555410, 0x44555145, 0x44504540, 0x45555550, 0x40004000,
  0x96440440, 0x55565565, 0x54454045, 0x40154151, 0x55559155, 0x51405555, 0x00000105,
]

let gDOUBLE_POW5_TABLE : Array[Int64] = [
  1L, 5L, 25L, 125L, 625L, 3125L, 15625L, 78125L, 390625L, 1953125L, 9765625L, 48828125L,
  244140625L, 1220703125L, 6103515625L, 30517578125L, 152587890625L, 762939453125L,
  3814697265625L, 19073486328125L, 95367431640625L, 476837158203125L, 2384185791015625L,
  11920928955078125L, 59604644775390625L, 298023223876953125L,
]

fn double_computePow5(i : Int) -> (Int64, Int64) {
  let base : Int = i / gPOW5_TABLE_SIZE
  let base2 : Int = base * gPOW5_TABLE_SIZE
  let offset : Int = i - base2
  let mul0 = gDOUBLE_POW5_SPLIT2[base * 2]
  let mul1 = gDOUBLE_POW5_SPLIT2[base * 2 + 1]
  if offset == 0 {
    return (mul0, mul1)
  }
  let m : Int64 = gDOUBLE_POW5_TABLE[offset]
  let (low1, high1) = umul128(m, mul1)
  let (low0, high0) = umul128(m, mul0)
  let sum : Int64 = high0 + low1
  let mut high1 = high1
  if u64_lt(sum, high0) {
    high1 = high1 + 1L
  }
  let delta : Int = pow5bits(i) - pow5bits(base2)
  let a = shiftright128(low0, sum, delta) + gPOW5_OFFSETS[i / 16].lsr(
      (i % 16).lsl(1),
    ).land(3).to_int64()
  let b = shiftright128(sum, high1, delta)
  (a, b)
}

fn double_computeInvPow5(i : Int) -> (Int64, Int64) {
  let base : Int = (i + gPOW5_TABLE_SIZE - 1) / gPOW5_TABLE_SIZE
  let base2 : Int = base * gPOW5_TABLE_SIZE
  let offset : Int = base2 - i
  let mul0 = gDOUBLE_POW5_INV_SPLIT2[base * 2]
  let mul1 = gDOUBLE_POW5_INV_SPLIT2[base * 2 + 1]
  if offset == 0 {
    return (mul0, mul1)
  }
  let m : Int64 = gDOUBLE_POW5_TABLE[offset]
  let (low1, high1) = umul128(m, mul1)
  let (low0, high0) = umul128(m, mul0)
  let sum = high0 + low1
  let mut high1 = high1
  if u64_lt(sum, high0) {
    high1 = high1 + 1L
  }
  let delta : Int = pow5bits(base2) - pow5bits(i)
  let a = shiftright128(low0, sum, delta) + 1L + gPOW5_INV_OFFSETS[i / 16].lsr(
      (i % 16).lsl(1),
    ).land(3).to_int64()
  let b = shiftright128(sum, high1, delta)
  (a, b)
}

let gDOUBLE_MANTISSA_BITS : Int = 52

let gDOUBLE_EXPONENT_BITS : Int = 11

let gDOUBLE_BIAS : Int = 1023

let gDOUBLE_POW5_INV_BITCOUNT : Int = 125

let gDOUBLE_POW5_BITCOUNT : Int = 125

fn assert(b : Bool, msg : String) -> Unit {
  if not(b) {
    abort("assert failed: \(msg)\n")
  }
}

fn decimalLength17(v : Int64) -> Int {
  // This is slightly faster than a loop.
  // The average output length is 16.38 digits, so we check high-to-low.
  // Function precondition: v is not an 18, 19, or 20-digit number.
  // (17 digits are sufficient for round-tripping.)
  assert(v < 100000000000000000L, "v < 100000000000000000L")
  if v >= 10000000000000000L {
    return 17
  }
  if v >= 1000000000000000L {
    return 16
  }
  if v >= 100000000000000L {
    return 15
  }
  if v >= 10000000000000L {
    return 14
  }
  if v >= 1000000000000L {
    return 13
  }
  if v >= 100000000000L {
    return 12
  }
  if v >= 10000000000L {
    return 11
  }
  if v >= 1000000000L {
    return 10
  }
  if v >= 100000000L {
    return 9
  }
  if v >= 10000000L {
    return 8
  }
  if v >= 1000000L {
    return 7
  }
  if v >= 100000L {
    return 6
  }
  if v >= 10000L {
    return 5
  }
  if v >= 1000L {
    return 4
  }
  if v >= 100L {
    return 3
  }
  if v >= 10L {
    return 2
  }
  return 1
}

// A floating decimal representing m * 10^e.
priv struct FloatingDecimal64 {
  mantissa : Int64
  // Decimal exponent's range is -324 to 308
  // inclusive, and can fit in a short if needed.
  exponent : Int
}

fn to_string(self : FloatingDecimal64) -> String {
  let m = self.mantissa
  let e = self.exponent
  "{ mantissa: \(m), exponent: \(e) }"
}

fn d2d(ieeeMantissa : Int64, ieeeExponent : Int) -> FloatingDecimal64 {
  let mut e2 : Int = 0
  let mut m2 : Int64 = 0L
  if ieeeExponent == 0 {
    e2 = 1 - gDOUBLE_BIAS - gDOUBLE_MANTISSA_BITS - 2
    m2 = ieeeMantissa
  } else {
    e2 = ieeeExponent - gDOUBLE_BIAS - gDOUBLE_MANTISSA_BITS - 2
    m2 = 1L.lsl(gDOUBLE_MANTISSA_BITS).lor(ieeeMantissa)
  }
  let even = m2.land(1L) == 0L
  let acceptBounds = even

  // Step 2: Determine the interval of valid decimal representations.
  let mv = 4L * m2
  // Implicit bool -> int conversion. True is 1, false is 0.
  let mmShift = ieeeMantissa != 0L || ieeeExponent <= 1
  // We would compute mp and mm like this:
  // uint64_t mp = 4 * m2 + 2;
  // uint64_t mm = mv - 1 - mmShift;

  // Step 3: Convert to a decimal power base using 128-bit arithmetic.
  let mut vr : Int64 = 0L
  let mut vp : Int64 = 0L
  let mut vm : Int64 = 0L
  let mut e10 : Int = 0
  let mut vmIsTrailingZeros = false
  let mut vrIsTrailingZeros = false
  if e2 >= 0 {
    // I tried special-casing q == 0, but there was no effect on performance.
    // This expression is slightly faster than max(0, log10Pow2(e2) - 1).
    let q : Int = log10Pow2(e2) - (e2 > 3).to_int()
    e10 = q
    let k = gDOUBLE_POW5_INV_BITCOUNT + pow5bits(q) - 1
    let i = -e2 + q + k
    let pow5 = double_computeInvPow5(q)
    let vs = mulShiftAll64(m2, pow5, i, mmShift)
    vr = vs.0
    vp = vs.1
    vm = vs.2
    if q <= 21 {
      // This should use q <= 22, but I think 21 is also safe. Smaller values
      // may still be safe, but it's more difficult to reason about them.
      // Only one of mp, mv, and mm can be a multiple of 5, if any.
      let mvMod5 : Int = mv.to_int() - 5 * (mv / 5L).to_int()
      if mvMod5 == 0 {
        vrIsTrailingZeros = multipleOfPowerOf5(mv, q)
      } else if acceptBounds {
        // Same as min(e2 + (~mm & 1), pow5Factor(mm)) >= q
        // <=> e2 + (~mm & 1) >= q && pow5Factor(mm) >= q
        // <=> true && pow5Factor(mm) >= q, since e2 >= q.
        vmIsTrailingZeros = multipleOfPowerOf5(mv - 1L - mmShift.to_int64(), q)
      } else {
        vp = vp - multipleOfPowerOf5(mv + 2L, q).to_int64()
      }
    }
  } else {
    // This expression is slightly faster than max(0, log10Pow5(-e2) - 1).
    let q : Int = log10Pow5(-e2) - (-e2 > 1).to_int()
    e10 = q + e2
    let i : Int = -e2 - q
    let k = pow5bits(i) - gDOUBLE_POW5_BITCOUNT
    let j = q - k
    let pow5 = double_computePow5(i)
    let vs = mulShiftAll64(m2, pow5, j, mmShift)
    vr = vs.0
    vp = vs.1
    vm = vs.2
    if q <= 1 {
      // {vr,vp,vm} is trailing zeros if {mv,mp,mm} has at least q trailing 0 bits.
      // mv = 4 * m2, so it always has at least two trailing 0 bits.
      vrIsTrailingZeros = true
      if acceptBounds {
        vmIsTrailingZeros = mmShift.to_int() == 1
      } else {
        vp = vp - 1L
      }
    } else if q < 63 {
      vrIsTrailingZeros = multipleOfPowerOf2(mv, q)
    }
  }

  // Step 4: Find the shortest decimal representation in the interval of valid representations.
  let mut removed : Int = 0
  let mut lastRemovedDigit : Int = 0
  let mut output : Int64 = 0L
  // On average, we remove ~2 digits.
  if vmIsTrailingZeros || vrIsTrailingZeros {
    // General case, which happens rarely (~0.7%).
    while true {
      let vpDiv10 : Int64 = vp / 10L
      let vmDiv10 : Int64 = vm / 10L
      if vpDiv10 <= vmDiv10 {
        break
      }
      let vmMod10 : Int = vm.to_int() - 10 * vmDiv10.to_int()
      let vrDiv10 : Int64 = vr / 10L
      let vrMod10 : Int = vr.to_int() - 10 * vrDiv10.to_int()
      vmIsTrailingZeros = vmIsTrailingZeros && vmMod10 == 0
      vrIsTrailingZeros = vrIsTrailingZeros && lastRemovedDigit == 0
      lastRemovedDigit = vrMod10
      vr = vrDiv10
      vp = vpDiv10
      vm = vmDiv10
      removed = removed + 1
    }
    if vmIsTrailingZeros {
      while true {
        let vmDiv10 : Int64 = vm / 10L
        let vmMod10 : Int = vm.to_int() - 10 * vmDiv10.to_int()
        if vmMod10 != 0 {
          break
        }
        let vpDiv10 : Int64 = vp / 10L
        let vrDiv10 : Int64 = vr / 10L
        let vrMod10 : Int = vr.to_int() - 10 * vrDiv10.to_int()
        vrIsTrailingZeros = vrIsTrailingZeros && lastRemovedDigit == 0
        lastRemovedDigit = vrMod10
        vr = vrDiv10
        vp = vpDiv10
        vm = vmDiv10
        removed = removed + 1
      }
    }
    if vrIsTrailingZeros && lastRemovedDigit == 5 && vr % 2L == 0L {
      lastRemovedDigit = 4
    }
    output = vr + ((vr == vm && (not(acceptBounds) || not(vmIsTrailingZeros))) ||
      lastRemovedDigit >= 5).to_int64()
  } else {
    // Specialized for the common case (~99.3%). Percentages below are relative to this.
    let mut roundUp = false
    let vpDiv100 : Int64 = vp / 100L
    let vmDiv100 : Int64 = vm / 100L
    if vpDiv100 > vmDiv100 {
      let vrDiv100 : Int64 = vr / 100L
      let vrMod100 : Int = vr.to_int() - 100 * vrDiv100.to_int()
      roundUp = vrMod100 >= 50
      vr = vrDiv100
      vp = vpDiv100
      vm = vmDiv100
      removed = removed + 2
    }
    // Loop iterations below (approximately), without optimization above:
    // 0: 0.03%, 1: 13.8%, 2: 70.6%, 3: 14.0%, 4: 1.40%, 5: 0.14%, 6+: 0.02%
    // Loop iterations below (approximately), with optimization above:
    // 0: 70.6%, 1: 27.8%, 2: 1.40%, 3: 0.14%, 4+: 0.02%
    while true {
      let vpDiv10 : Int64 = vp / 10L
      let vmDiv10 : Int64 = vm / 10L
      if vpDiv10 <= vmDiv10 {
        break
      }
      let vrDiv10 : Int64 = vr / 10L
      let vrMod10 : Int = vr.to_int() - 10 * vrDiv10.to_int()
      roundUp = vrMod10 >= 5
      vr = vrDiv10
      vp = vpDiv10
      vm = vmDiv10
      removed = removed + 1
    }
    output = vr + (vr == vm || roundUp).to_int64()
  }
  let exp : Int = e10 + removed
  let fd = { mantissa: output, exponent: exp }
  fd
}

fn to_chars(v : FloatingDecimal64, sign : Bool) -> String {
  // Step 5: Print the decimal representation.
  let result = Bytes::new(24)
  let mut index : Int = 0
  if sign {
    result[index] = '-'.to_int().to_byte()
    index = index + 1
  }
  let mut output : Int64 = v.mantissa
  let olength : Int = decimalLength17(output)
  let mut exp : Int = v.exponent + olength - 1
  let scientificNotation = not(exp >= -3 && exp < 7)
  if scientificNotation {
    // Print the decimal digits.
    for i = 0; i < olength - 1; i = i + 1 {
      let c = output % 10L
      output = output / 10L
      result[index + olength - i] = ('0'.to_int() + c.to_int()).to_byte()
    }
    result[index] = ('0'.to_int() + output.to_int() % 10).to_byte()

    // Always print point
    result[index + 1] = '.'.to_int().to_byte()
    index = index + olength + 1
    if olength == 1 {
      result[index] = '0'.to_int().to_byte()
      index = index + 1
    }

    // Print the exponent.
    result[index] = 'e'.to_int().to_byte()
    index = index + 1
    if exp < 0 {
      result[index] = '-'.to_int().to_byte()
      index = index + 1
      exp = -exp
    }
    if exp >= 100 {
      let a = exp / 100
      let b = exp / 10 % 10
      let c = exp % 10
      result[index + 0] = ('0'.to_int() + a).to_byte()
      result[index + 1] = ('0'.to_int() + b).to_byte()
      result[index + 2] = ('0'.to_int() + c).to_byte()
      index = index + 3
    } else if exp >= 10 {
      let a = exp / 10
      let b = exp % 10
      result[index + 0] = ('0'.to_int() + a).to_byte()
      result[index + 1] = ('0'.to_int() + b).to_byte()
      index = index + 2
    } else {
      result[index] = ('0'.to_int() + exp).to_byte()
      index = index + 1
    }
    string_from_bytes(result, 0, index)
  } else {
    if exp < 0 {
      // Decimal dot is before any of the digits.
      result[index] = '0'.to_int().to_byte()
      index = index + 1
      result[index] = '.'.to_int().to_byte()
      index = index + 1
      for i = -1; i > exp; i = i - 1 {
        result[index] = '0'.to_int().to_byte()
        index = index + 1
      }
      let current = index
      for i = 0; i < olength; i = i + 1 {
        result[current + olength - i - 1] = ('0'.to_int() + (output % 10L).to_int()).to_byte()
        output = output / 10L
        index = index + 1
      }
    } else if exp + 1 >= olength {
      // Decimal dot is after any of the digits.
      for i = 0; i < olength; i = i + 1 {
        result[index + olength - i - 1] = ('0'.to_int() + (output % 10L).to_int()).to_byte()
        output = output / 10L
      }
      index = index + olength
      for i = olength; i < exp + 1; i = i + 1 {
        result[index] = '0'.to_int().to_byte()
        index = index + 1
      }
      result[index] = '.'.to_int().to_byte()
      index = index + 1
      result[index] = '0'.to_int().to_byte()
      index = index + 1
    } else {
      // Decimal dot is somewhere between the digits.
      let mut current = index + 1
      for i = 0; i < olength; i = i + 1 {
        if olength - i - 1 == exp {
          result[current + olength - i - 1] = '.'.to_int().to_byte()
          current = current - 1
        }
        result[current + olength - i - 1] = ('0'.to_int() + (output % 10L).to_int()).to_byte()
        output = output / 10L
      }
      index = index + olength + 1
    }
    return string_from_bytes(result, 0, index)
  }
}

fn d2d_small_int(
  ieeeMantissa : Int64,
  ieeeExponent : Int
) -> FloatingDecimal64? {
  let m2 : Int64 = 1L.lsl(gDOUBLE_MANTISSA_BITS).lor(ieeeMantissa)
  let e2 : Int = ieeeExponent - gDOUBLE_BIAS - gDOUBLE_MANTISSA_BITS
  if e2 > 0 {
    return None
  }
  if e2 < -52 {
    return None
  }
  let mask : Int64 = 1L.lsl(-e2) - 1L
  let fraction : Int64 = m2.land(mask)
  if fraction != 0L {
    return None
  }
  Some({ mantissa: m2.lsr(-e2), exponent: 0 })
}

fn ryu_to_string(self : Double) -> String {
  // Step 1: Decode the floating-point number, and unify normalized and subnormal cases.
  let bits : Int64 = self.reinterpret_as_i64()

  // Decode bits into sign, mantissa, and exponent.
  let ieeeSign = bits.lsr(gDOUBLE_MANTISSA_BITS + gDOUBLE_EXPONENT_BITS).land(
      1L,
    ) != 0L
  let ieeeMantissa : Int64 = bits.land(1L.lsl(gDOUBLE_MANTISSA_BITS) - 1L)
  let ieeeExponent : Int = bits.lsr(gDOUBLE_MANTISSA_BITS).land(
    1L.lsl(gDOUBLE_EXPONENT_BITS) - 1L,
  ).to_int()
  if ieeeExponent == (1).lsl(gDOUBLE_EXPONENT_BITS) - 1 || (ieeeExponent == 0 &&
  ieeeMantissa == 0L) {
    return copy_special_str(ieeeSign, ieeeExponent != 0, ieeeMantissa != 0L)
  }
  let mut v : FloatingDecimal64 = { mantissa: 0L, exponent: 0 }
  let small = d2d_small_int(ieeeMantissa, ieeeExponent)
  match small {
    Some(f) => {
      let mut x = f
      while true {
        let q : Int64 = x.mantissa / 10L
        let r = x.mantissa.to_int() - 10 * q.to_int()
        if r != 0 {
          break
        }
        x = { mantissa: q, exponent: x.exponent + 1 }
      }
      v = x
    }
    None => v = d2d(ieeeMantissa, ieeeExponent)
  }
  to_chars(v, ieeeSign)
}

/// @intrinsic %f64.to_string
pub fn to_string(self : Double) -> String {
  ryu_to_string(self)
}

pub fn debug_write(self : Double, buf : Buffer) -> Unit {
  buf.write_string(self.to_string())
}

test "double/ryu.mbt:205" {
  let m = 123456789L
  let mul0 = 987654321L
  let (_, high0) = umul128(m, mul0)
  let low1 = 111111111L
  let high1 = 222222222L
  let sum : Int64 = high0 + low1
  let mut high1 = high1
  if u64_lt(sum, high0) {
    high1 = high1 + 1L
  }
  @test.eq(high1, 222222222L)!
}

test "double/ryu.mbt:230" {
  let m = 123456789L
  let mul0 = 987654321L
  let (_, high0) = umul128(m, mul0)
  let low1 = 111111111L
  let high1 = 222222222L
  let sum = high0 + low1
  let mut high1 = high1
  if u64_lt(sum, high0) {
    high1 = high1 + 1L
  }
  @test.eq(high1, 222222222L)!
}

test "double/ryu.mbt:252" {
  @test.eq(gDOUBLE_POW5_BITCOUNT, 125)!
}

test "double/ryu.mbt:205" {
  let m = 123456789L
  let mul0 = 987654321L
  let (_, high0) = umul128(m, mul0)
  let low1 = 111111111L
  let high1 = 222222222L
  let sum : Int64 = high0 + low1
  let mut high1 = high1
  if u64_lt(sum, high0) {
    high1 = high1 + 1L
  }
  @test.eq(high1, 222222222L)!
}

test "double/ryu.mbt:230" {
  let m = 123456789L
  let mul0 = 987654321L
  let (_, high0) = umul128(m, mul0)
  let low1 = 111111111L
  let high1 = 222222222L
  let sum = high0 + low1
  let mut high1 = high1
  if u64_lt(sum, high0) {
    high1 = high1 + 1L
  }
  @test.eq(high1, 222222222L)!
}

test "double/ryu.mbt:252" {
  @test.eq(gDOUBLE_POW5_BITCOUNT, 125)!
}
