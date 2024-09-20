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
// This is a fork of the ryu crate adjusted to comply to the ECMAScript number-to-string algorithm,

fn string_from_bytes(bytes : Bytes, from : Int, to : Int) -> String {
  let buf = Buffer::new(size_hint=bytes.length())
  for i = from; i < to; i = i + 1 {
    buf.write_char(Char::from_int(bytes[i].to_int()))
  }
  buf.to_string()
}

fn umul128(a : UInt64, b : UInt64) -> (UInt64, UInt64) {
  let aLo = a & 0xffffffff
  let aHi = a >> 32
  let bLo = b & 0xffffffff
  let bHi = b >> 32
  let x = aLo * bLo
  let y = aHi * bLo + (x >> 32)
  let z = aLo * bHi + (y & 0xffffffff)
  let w = aHi * bHi + (y >> 32) + (z >> 32)
  let lo = a * b
  let hi = w
  (lo, hi)
}

fn shiftright128(lo : UInt64, hi : UInt64, dist : Int) -> UInt64 {
  hi.lsl(64 - dist) | lo.lsr(dist)
}

fn pow5Factor(value : UInt64) -> Int {
  // We want to find the largest power of 5 that divides value.
  if value % 5UL != 0UL {
    return 0
  }
  if value % 25UL != 0UL {
    return 1
  }
  if value % 125UL != 0UL {
    return 2
  }
  if value % 625UL != 0UL {
    return 3
  }
  let mut count = 4
  let mut value = value / 625UL
  while value > 0UL {
    if value % 5UL != 0UL {
      return count
    }
    value = value / 5UL
    count = count + 1
  }
  abort("IllegalArgumentException \{value}")
}

fn multipleOfPowerOf5(value : UInt64, p : Int) -> Bool {
  pow5Factor(value) >= p
}

fn multipleOfPowerOf2(value : UInt64, p : Int) -> Bool {
  (value & (1UL.lsl(p) - 1UL)) == 0UL
}

fn mulShiftAll64(
  m : UInt64,
  mul : (UInt64, UInt64),
  j : Int,
  mmShift : Bool
) -> (UInt64, UInt64, UInt64) {
  let m = m.lsl(1)
  let (lo, tmp) = umul128(m, mul.0)
  let (lo2, hi2) = umul128(m, mul.1)
  let mid = tmp + lo2
  let hi = hi2 + (if mid < tmp { 1 } else { 0 })
  let lo2 = lo + mul.0
  let mid2 = mid + mul.1 + (if lo2 < lo { 1 } else { 0 })
  let hi2 = hi + (if mid2 < mid { 1 } else { 0 })
  let vp = shiftright128(mid2, hi2, j - 64 - 1)
  let mut vm : UInt64 = 0UL
  if mmShift {
    let lo3 = lo - mul.0
    let mid3 = mid - mul.1 - (if lo < lo3 { 1 } else { 0 })
    let hi3 = hi - (if mid < mid3 { 1 } else { 0 })
    vm = shiftright128(mid3, hi3, j - 64 - 1)
  } else {
    let lo3 : UInt64 = lo + lo
    let mid3 : UInt64 = mid + mid + (if lo3 < lo { 1 } else { 0 })
    let hi3 : UInt64 = hi + hi + (if mid3 < mid { 1 } else { 0 })
    let lo4 : UInt64 = lo3 - mul.0
    let mid4 : UInt64 = mid3 - mul.1 - (if lo3 < lo4 { 1 } else { 0 })
    let hi4 : UInt64 = hi3 - (if mid3 < mid4 { 1 } else { 0 })
    vm = shiftright128(mid4, hi4, j - 64)
  }
  let vr = shiftright128(mid, hi, j - 64 - 1)
  (vr, vp, vm)
}

let gPOW5_TABLE_SIZE = 26

let gDOUBLE_POW5_INV_SPLIT2 : Array[UInt64] = [
  1, 2305843009213693952, 5955668970331000884, 1784059615882449851, 8982663654677661702,
  1380349269358112757, 7286864317269821294, 2135987035920910082, 7005857020398200553,
  1652639921975621497, 17965325103354776697, 1278668206209430417, 8928596168509315048,
  1978643211784836272, 10075671573058298858, 1530901034580419511, 597001226353042382,
  1184477304306571148, 1527430471115325346, 1832889850782397517, 12533209867169019542,
  1418129833677084982, 5577825024675947042, 2194449627517475473, 11006974540203867551,
  1697873161311732311, 10313493231639821582, 1313665730009899186, 12701016819766672773,
  2032799256770390445,
]

let gPOW5_INV_OFFSETS : Array[UInt] = [
  0x54544554, 0x04055545, 0x10041000, 0x00400414, 0x40010000, 0x41155555, 0x00000454,
  0x00010044, 0x40000000, 0x44000041, 0x50454450, 0x55550054, 0x51655554, 0x40004000,
  0x01000001, 0x00010500, 0x51515411, 0x05555554, 0x00000000,
]

let gDOUBLE_POW5_SPLIT2 : Array[UInt64] = [
  0, 1152921504606846976, 0, 1490116119384765625, 1032610780636961552, 1925929944387235853,
  7910200175544436838, 1244603055572228341, 16941905809032713930, 1608611746708759036,
  13024893955298202172, 2079081953128979843, 6607496772837067824, 1343575221513417750,
  17332926989895652603, 1736530273035216783, 13037379183483547984, 2244412773384604712,
  1605989338741628675, 1450417759929778918, 9630225068416591280, 1874621017369538693,
  665883850346957067, 1211445438634777304, 14931890668723713708, 1565756531257009982,
]

let gPOW5_OFFSETS : Array[Int] = [
  0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x40000000, 0x59695995, 0x55545555,
  0x56555515, 0x41150504, 0x40555410, 0x44555145, 0x44504540, 0x45555550, 0x40004000,
  0x96440440, 0x55565565, 0x54454045, 0x40154151, 0x55559155, 0x51405555, 0x00000105,
]

let gDOUBLE_POW5_TABLE : Array[UInt64] = [
  1, 5, 25, 125, 625, 3125, 15625, 78125, 390625, 1953125, 9765625, 48828125, 244140625,
  1220703125, 6103515625, 30517578125, 152587890625, 762939453125, 3814697265625,
  19073486328125, 95367431640625, 476837158203125, 2384185791015625, 11920928955078125,
  59604644775390625, 298023223876953125,
]

/// Computes 5^i in the form required by Ryū.
fn double_computePow5(i : Int) -> (UInt64, UInt64) {
  let base = i / gPOW5_TABLE_SIZE
  let base2 = base * gPOW5_TABLE_SIZE
  let offset = i - base2
  let mul0 = gDOUBLE_POW5_SPLIT2[base * 2]
  let mul1 = gDOUBLE_POW5_SPLIT2[base * 2 + 1]
  if offset == 0 {
    return (mul0, mul1)
  }
  let m : UInt64 = gDOUBLE_POW5_TABLE[offset]
  let (low1, high1) = umul128(m, mul1)
  let (low0, high0) = umul128(m, mul0)
  let sum : UInt64 = high0 + low1
  let mut high1 = high1
  if sum < high0 {
    high1 = high1 + 1UL
  }
  let delta : Int = pow5bits(i) - pow5bits(base2)
  let a = shiftright128(low0, sum, delta) +
    gPOW5_OFFSETS[i / 16].lsr((i % 16).lsl(1)).land(3).to_int64().to_uint64()
  let b = shiftright128(sum, high1, delta)
  (a, b)
}

/// Computes 5^-i in the form required by Ryū.
fn double_computeInvPow5(i : Int) -> (UInt64, UInt64) {
  let base = (i + gPOW5_TABLE_SIZE - 1) / gPOW5_TABLE_SIZE
  let base2 = base * gPOW5_TABLE_SIZE
  let offset = base2 - i
  let mul0 = gDOUBLE_POW5_INV_SPLIT2[base * 2]
  let mul1 = gDOUBLE_POW5_INV_SPLIT2[base * 2 + 1]
  if offset == 0 {
    return (mul0, mul1)
  }
  let m = gDOUBLE_POW5_TABLE[offset]
  let (low1, high1) = umul128(m, mul1)
  let (low0, high0) = umul128(m, mul0)
  let sum = high0 + low1
  let mut high1 = high1
  if sum < high0 {
    high1 = high1 + 1
  }
  let delta : Int = pow5bits(base2) - pow5bits(i)
  let a = shiftright128(low0, sum, delta) +
    1 +
    gPOW5_INV_OFFSETS[i / 16].lsr((i % 16).lsl(1)).land(3).to_uint64()
  let b = shiftright128(sum, high1, delta)
  (a, b)
}

let gDOUBLE_MANTISSA_BITS : Int = 52

let gDOUBLE_EXPONENT_BITS : Int = 11

let gDOUBLE_BIAS : Int = 1023

let gDOUBLE_POW5_INV_BITCOUNT : Int = 125

let gDOUBLE_POW5_BITCOUNT : Int = 125

fn decimal_length17(v : UInt64) -> Int {
  // This is slightly faster than a loop.
  // The average output length is 16.38 digits, so we check high-to-low.
  // Function precondition: v is not an 18, 19, or 20-digit number.
  // (17 digits are sufficient for round-tripping.)
  if v >= 10000000000000000 {
    return 17
  }
  if v >= 1000000000000000 {
    return 16
  }
  if v >= 100000000000000 {
    return 15
  }
  if v >= 10000000000000 {
    return 14
  }
  if v >= 1000000000000 {
    return 13
  }
  if v >= 100000000000 {
    return 12
  }
  if v >= 10000000000 {
    return 11
  }
  if v >= 1000000000 {
    return 10
  }
  if v >= 100000000 {
    return 9
  }
  if v >= 10000000 {
    return 8
  }
  if v >= 1000000 {
    return 7
  }
  if v >= 100000 {
    return 6
  }
  if v >= 10000 {
    return 5
  }
  if v >= 1000 {
    return 4
  }
  if v >= 100 {
    return 3
  }
  if v >= 10 {
    return 2
  }
  return 1
}

// A floating decimal representing m * 10^e.
priv struct FloatingDecimal64 {
  mantissa : UInt64
  // Decimal exponent's range is -324 to 308
  // inclusive, and can fit in a short if needed.
  exponent : Int
}

fn d2d(ieeeMantissa : UInt64, ieeeExponent : UInt) -> FloatingDecimal64 {
  let mut e2 : Int = 0
  let mut m2 : UInt64 = 0
  if ieeeExponent == 0 {
    // Denormal number - no implicit leading 1, and the exponent is 1, not 0.
    e2 = 1 - gDOUBLE_BIAS - gDOUBLE_MANTISSA_BITS - 2
    m2 = ieeeMantissa
  } else {
    // Add implicit leading 1.
    e2 = ieeeExponent.reinterpret_as_int() -
      gDOUBLE_BIAS -
      gDOUBLE_MANTISSA_BITS -
      2
    m2 = 1UL.lsl(gDOUBLE_MANTISSA_BITS) | ieeeMantissa
  }
  let even = (m2 & 1UL) == 0UL
  let mv = 4UL *

    // Step 2: Determine the interval of valid decimal representations.
    m2
  // Implicit bool -> int conversion. True is 1, false is 0.
  let mmShift = ieeeMantissa != 0UL || ieeeExponent <= 1
  // We would compute mp and mm like this:
  // uint64_t mp = 4 * m2 + 2;
  // uint64_t mm = mv - 1 - mmShift;

  // Step 3: Convert to a decimal power base using 128-bit arithmetic.
  let mut vr = 0UL
  let mut vp = 0UL
  let mut vm = 0UL
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
      let mvMod5 : Int = mv.to_int() - 5 * (mv / 5UL).to_int()
      if mvMod5 == 0 {
        vrIsTrailingZeros = multipleOfPowerOf5(mv, q)
      } else if even {
        // Same as min(e2 + (~mm & 1), pow5Factor(mm)) >= q
        // <=> e2 + (~mm & 1) >= q && pow5Factor(mm) >= q
        // <=> true && pow5Factor(mm) >= q, since e2 >= q.
        vmIsTrailingZeros = multipleOfPowerOf5(
          mv - 1UL - mmShift.to_int64().to_uint64(),
          q,
        )
      } else {
        vp = vp - multipleOfPowerOf5(mv + 2UL, q).to_int64().to_uint64()
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
      if even {
        vmIsTrailingZeros = mmShift.to_int() == 1
      } else {
        vp = vp - 1
      }
    } else if q < 63 {
      vrIsTrailingZeros = multipleOfPowerOf2(mv, q)
    }
  }

  // Step 4: Find the shortest decimal representation in the interval of valid representations.
  let mut removed : Int = 0
  let mut lastRemovedDigit : Int = 0
  let mut output : UInt64 = 0UL
  // On average, we remove ~2 digits.
  if vmIsTrailingZeros || vrIsTrailingZeros {
    // General case, which happens rarely (~0.7%).
    while true {
      let vpDiv10 = vp / 10
      let vmDiv10 = vm / 10
      if vpDiv10 <= vmDiv10 {
        break
      }
      let vmMod10 : Int = vm.to_int() - 10 * vmDiv10.to_int()
      let vrDiv10 = vr / 10
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
        let vmDiv10 = vm / 10
        let vmMod10 : Int = vm.to_int() - 10 * vmDiv10.to_int()
        if vmMod10 != 0 {
          break
        }
        let vpDiv10 = vp / 10
        let vrDiv10 = vr / 10
        let vrMod10 : Int = vr.to_int() - 10 * vrDiv10.to_int()
        vrIsTrailingZeros = vrIsTrailingZeros && lastRemovedDigit == 0
        lastRemovedDigit = vrMod10
        vr = vrDiv10
        vp = vpDiv10
        vm = vmDiv10
        removed = removed + 1
      }
    }
    if vrIsTrailingZeros && lastRemovedDigit == 5 && vr % 2 == 0 {
      lastRemovedDigit = 4
    }
    output = vr +
      ((vr == vm && (not(even) || not(vmIsTrailingZeros))) ||
      lastRemovedDigit >= 5)
      .to_int64()
      .to_uint64()
  } else {
    // Specialized for the common case (~99.3%). Percentages below are relative to this.
    let mut roundUp = false
    let vpDiv100 = vp / 100
    let vmDiv100 = vm / 100
    if vpDiv100 > vmDiv100 {
      let vrDiv100 = vr / 100
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
      let vpDiv10 = vp / 10
      let vmDiv10 = vm / 10
      if vpDiv10 <= vmDiv10 {
        break
      }
      let vrDiv10 = vr / 10
      let vrMod10 : Int = vr.to_int() - 10 * vrDiv10.to_int()
      roundUp = vrMod10 >= 5
      vr = vrDiv10
      vp = vpDiv10
      vm = vmDiv10
      removed = removed + 1
    }
    output = vr + (vr == vm || roundUp).to_int64().to_uint64()
  }
  let exp : Int = e10 + removed
  let fd : FloatingDecimal64 = { mantissa: output, exponent: exp }
  fd
}

fn to_chars(v : FloatingDecimal64, sign : Bool) -> String {
  // Step 5: Print the decimal representation.
  let result = Bytes::new(25)
  let mut index : Int = 0
  if sign {
    result[index] = b'-'
    index += 1
  }
  let mut output = v.mantissa
  let olength = decimal_length17(output)
  let mut exp : Int = v.exponent + olength - 1
  let scientificNotation = not(exp >= -6 && exp < 21)
  if scientificNotation {
    // Print the decimal digits.
    for i = 0; i < olength - 1; i = i + 1 {
      let c = output % 10
      output /= 10
      // 48 is ASCII '0', the same applies below.
      result[index + olength - i] = (48 + c.to_int()).to_byte()
    }
    result[index] = (48 + output.to_int() % 10).to_byte()
    if olength > 1 {
      result[index + 1] = b'.'
    } else {
      // If there are no decimals, suppress .0
      index -= 1
    }
    index += olength + 1

    // Print the exponent.
    result[index] = b'e'
    index += 1
    if exp < 0 {
      result[index] = b'-'
      index += 1
      exp = -exp
    } else {
      result[index] = b'+'
      index += 1
    }
    if exp >= 100 {
      let a = exp / 100
      let b = exp / 10 % 10
      let c = exp % 10
      result[index + 0] = (48 + a).to_byte()
      result[index + 1] = (48 + b).to_byte()
      result[index + 2] = (48 + c).to_byte()
      index += 3
    } else if exp >= 10 {
      let a = exp / 10
      let b = exp % 10
      result[index + 0] = (48 + a).to_byte()
      result[index + 1] = (48 + b).to_byte()
      index += 2
    } else {
      result[index] = (48 + exp).to_byte()
      index += 1
    }
    string_from_bytes(result, 0, index)
  } else {
    // Otherwise follow the ECMAScript spec.
    if exp < 0 {
      // Decimal dot is before any of the digits.
      result[index] = b'0'
      index += 1
      result[index] = b'.'
      index += 1
      for i = -1; i > exp; i = i - 1 {
        result[index] = b'0'
        index += 1
      }
      let current = index
      for i = 0; i < olength; i = i + 1 {
        result[current + olength - i - 1] = (48 + (output % 10).to_int()).to_byte()
        output /= 10
        index += 1
      }
    } else if exp + 1 >= olength {
      // Decimal dot is after any of the digits.
      for i = 0; i < olength; i = i + 1 {
        result[index + olength - i - 1] = (48 + (output % 10).to_int()).to_byte()
        output /= 10
      }
      index += olength
      for i = olength; i < exp + 1; i = i + 1 {
        result[index] = b'0'
        index += 1
      }
    } else {
      // Decimal dot is somewhere between the digits.
      let mut current = index + 1
      for i = 0; i < olength; i = i + 1 {
        if olength - i - 1 == exp {
          result[current + olength - i - 1] = b'.'
          current -= 1
        }
        result[current + olength - i - 1] = (48 + (output % 10).to_int()).to_byte()
        output /= 10
      }
      index += olength + 1
    }
    return string_from_bytes(result, 0, index)
  }
}

fn d2d_small_int(
  ieeeMantissa : UInt64,
  ieeeExponent : Int
) -> FloatingDecimal64? {
  let m2 : UInt64 = 1UL.lsl(gDOUBLE_MANTISSA_BITS) | ieeeMantissa
  let e2 : Int = ieeeExponent - gDOUBLE_BIAS - gDOUBLE_MANTISSA_BITS
  if e2 > 0 {
    return None
  }
  if e2 < -52 {
    return None
  }
  let mask : UInt64 = 1UL.lsl(-e2) - 1UL
  let fraction : UInt64 = m2 & mask
  if fraction != 0UL {
    return None
  }
  Some({ mantissa: m2.lsr(-e2), exponent: 0 })
}

/// TODO: ryu_to_logger[T:Logger](Double/Float, T) -> Unit
pub fn ryu_to_string(val : Double) -> String {
  if val == 0.0 {
    return "0"
  }
  // Step 1: Decode the floating-point number, and unify normalized and subnormal cases.
  let bits : UInt64 = val.reinterpret_as_u64()

  // Decode bits into sign, mantissa, and exponent.
  let ieeeSign = (bits.lsr(gDOUBLE_MANTISSA_BITS + gDOUBLE_EXPONENT_BITS) & 1UL) !=
    0UL
  let ieeeMantissa : UInt64 = bits & (1UL.lsl(gDOUBLE_MANTISSA_BITS) - 1UL)
  let ieeeExponent : Int = bits
    .lsr(gDOUBLE_MANTISSA_BITS)
    .land(1UL.lsl(gDOUBLE_EXPONENT_BITS) - 1UL)
    .to_int()
  if ieeeExponent == (1).lsl(gDOUBLE_EXPONENT_BITS) - 1 ||
    (ieeeExponent == 0 && ieeeMantissa == 0UL) {
    return copy_special_str(ieeeSign, ieeeExponent != 0, ieeeMantissa != 0UL)
  }
  let mut v : FloatingDecimal64 = { mantissa: 0UL, exponent: 0 }
  let small = d2d_small_int(ieeeMantissa, ieeeExponent)
  match small {
    Some(f) => {
      let mut x = f
      while true {
        let q : UInt64 = x.mantissa / 10
        let r = x.mantissa - 10UL * q
        if r != 0 {
          break
        }
        x = { mantissa: q, exponent: x.exponent + 1 }
      }
      v = x
    }
    None => v = d2d(ieeeMantissa, ieeeExponent.reinterpret_as_uint())
  }
  to_chars(v, ieeeSign)
}

test "double/ryu.mbt:205" {
  let m = 123456789UL
  let mul0 = 987654321UL
  let (_, high0) = umul128(m, mul0)
  let low1 = 111111111UL
  let high1 = 222222222UL
  let sum = high0 + low1
  let mut high1 = high1
  if sum < high0 {
    high1 = high1 + 1
  }
  assert_eq!(high1, 222222222)
}

test "double/ryu.mbt:230" {
  let m = 123456789UL
  let mul0 = 987654321UL
  let (_, high0) = umul128(m, mul0)
  let low1 = 111111111UL
  let high1 = 222222222UL
  let sum = high0 + low1
  let mut high1 = high1
  if sum < high0 {
    high1 = high1 + 1UL
  }
  assert_eq!(high1, 222222222UL)
}

test "double/ryu.mbt:252" {
  assert_eq!(gDOUBLE_POW5_BITCOUNT, 125)
}

test "double/ryu.mbt:205" {
  let m = 123456789UL
  let mul0 = 987654321UL
  let (_, high0) = umul128(m, mul0)
  let low1 = 111111111UL
  let high1 = 222222222UL
  let sum = high0 + low1
  let mut high1 = high1
  if sum < high0 {
    high1 = high1 + 1UL
  }
  assert_eq!(high1, 222222222UL)
}

test "double/ryu.mbt:230" {
  let m = 123456789UL
  let mul0 = 987654321UL
  let (_, high0) = umul128(m, mul0)
  let low1 = 111111111UL
  let high1 = 222222222UL
  let sum = high0 + low1
  let mut high1 = high1
  if sum < high0 {
    high1 = high1 + 1UL
  }
  assert_eq!(high1, 222222222UL)
}

test "double/ryu.mbt:252" {
  assert_eq!(gDOUBLE_POW5_BITCOUNT, 125)
}
