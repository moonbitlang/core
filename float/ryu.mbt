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

// The shortest decimal digits of a `Float`: a port of `f2d` of Ryu (the
// `ryu` crate 1.0.23: `src/f2s.rs`, `src/f2s_intrinsics.rs`,
// `src/common.rs`; Ulf Adams, "Ryu: fast float-to-string conversion"),
// kept statement by statement so that the two can be compared. The result
// is the shortest decimal in the interval of the values that read back as
// the same `Float`, the one closest to the exact value; an exact tie goes
// to the even digit. `builtin/double_ryu_nonjs.mbt` is the same for
// `Double`.

///|
/// A floating decimal representing `mantissa * 10^exponent`
/// (`FloatingDecimal32`).
#valtype
priv struct FloatingDecimal32 {
  mantissa : UInt
  /// The decimal exponent's range is -45 to 38 inclusive.
  exponent : Int
}

///|
/// `FLOAT_POW5_INV_BITCOUNT` and `FLOAT_POW5_BITCOUNT`: the bit counts of
/// the double tables less the 64 bits that are not kept.
const FLOAT_POW5_BITCOUNT : Int = 61

///|
/// `e == 0 ? 1 : ceil(log_2(5^e))`. In signed arithmetic, which holds for
/// what `f2d` asks (`0 <= e <= 47`; the crate's unsigned version up to
/// 3528).
fn f2s_pow5bits(e : Int) -> Int {
  ((e * 1217359) >> 19) + 1
}

///|
/// `floor(log_10(2^e))`, for what `f2d` asks (`0 <= e <= 102`).
fn f2s_log10_pow2(e : Int) -> Int {
  (e * 78913) >> 18
}

///|
/// `floor(log_10(5^e))`, for what `f2d` asks (`0 <= e <= 151`).
fn f2s_log10_pow5(e : Int) -> Int {
  (e * 732923) >> 20
}

///|
fn f2s_multiple_of_power_of_5_32(value : UInt, p : Int) -> Bool {
  // `pow5factor_32(value) >= p`
  let mut value = value
  let mut count = 0
  while value % 5U == 0U {
    value = value / 5U
    count += 1
  }
  count >= p
}

///|
fn f2s_multiple_of_power_of_2_32(value : UInt, p : Int) -> Bool {
  (value & ((1U << p) - 1U)) == 0U
}

///|
fn f2s_mul_shift_32(m : UInt, factor : UInt64, shift : Int) -> UInt {
  let factor_lo = factor & 0xFFFFFFFFUL
  let factor_hi = factor >> 32
  let m = UInt64::extend_uint(m)
  let bits0 = m * factor_lo
  let bits1 = m * factor_hi
  let sum = (bits0 >> 32) + bits1
  (sum >> (shift - 32)).to_uint()
}

///|
fn f2s_mul_pow5_inv_div_pow2(m : UInt, q : Int, j : Int) -> UInt {
  // The inverse multipliers are defined as [2^x / 5^y] + 1; the upper 64
  // bits from the double lookup table are the correct bits for [2^x / 5^y],
  // so we have to add 1 here.
  f2s_mul_shift_32(m, f2s_pow5_inv_split_hi[q] + 1UL, j)
}

///|
fn f2s_mul_pow5_div_pow2(m : UInt, i : Int, j : Int) -> UInt {
  f2s_mul_shift_32(m, f2s_pow5_split_hi[i], j)
}

///|
/// The shortest decimal of the finite, non-zero `f32` with the mantissa and
/// exponent fields `ieee_mantissa` and `ieee_exponent` (`f2d`).
fn f2d(ieee_mantissa : UInt, ieee_exponent : UInt) -> FloatingDecimal32 {
  // We subtract 2 so that the bounds computation has 2 additional bits.
  let e2 = if ieee_exponent == 0U {
    1 - 127 - 23 - 2
  } else {
    ieee_exponent.reinterpret_as_int() - 127 - 23 - 2
  }
  let m2 = if ieee_exponent == 0U {
    ieee_mantissa
  } else {
    (1U << 23) | ieee_mantissa
  }
  let even = (m2 & 1U) == 0U
  let accept_bounds = even

  // Step 2: Determine the interval of valid decimal representations.
  let mv = 4U * m2
  let mp = 4U * m2 + 2U
  let mm_shift : UInt = if ieee_mantissa != 0U || ieee_exponent <= 1U {
    1U
  } else {
    0U
  }
  let mm = 4U * m2 - 1U - mm_shift

  // Step 3: Convert to a decimal power base using 64-bit arithmetic.
  let mut vr = 0U
  let mut vp = 0U
  let mut vm = 0U
  let mut e10 = 0
  let mut vm_is_trailing_zeros = false
  let mut vr_is_trailing_zeros = false
  let mut last_removed_digit = 0U
  if e2 >= 0 {
    let q = f2s_log10_pow2(e2)
    e10 = q
    let k = FLOAT_POW5_BITCOUNT + f2s_pow5bits(q) - 1
    let i = -e2 + q + k
    vr = f2s_mul_pow5_inv_div_pow2(mv, q, i)
    vp = f2s_mul_pow5_inv_div_pow2(mp, q, i)
    vm = f2s_mul_pow5_inv_div_pow2(mm, q, i)
    if q != 0 && (vp - 1U) / 10U <= vm / 10U {
      // We need to know one removed digit even if we are not going to loop
      // below. We could use q = X - 1 above, except that would require 33
      // bits for the result, and we've found that 32-bit arithmetic is
      // faster even on 64-bit machines.
      let l = FLOAT_POW5_BITCOUNT + f2s_pow5bits(q - 1) - 1
      last_removed_digit = f2s_mul_pow5_inv_div_pow2(mv, q - 1, -e2 + q - 1 + l) %
        10U
    }
    if q <= 9 {
      // The largest power of 5 that fits in 24 bits is 5^10, but q <= 9
      // seems to be safe as well. Only one of mp, mv, and mm can be a
      // multiple of 5, if any.
      if mv % 5U == 0U {
        vr_is_trailing_zeros = f2s_multiple_of_power_of_5_32(mv, q)
      } else if accept_bounds {
        vm_is_trailing_zeros = f2s_multiple_of_power_of_5_32(mm, q)
      } else if f2s_multiple_of_power_of_5_32(mp, q) {
        vp = vp - 1U
      }
    }
  } else {
    let q = f2s_log10_pow5(-e2)
    e10 = q + e2
    let i = -e2 - q
    let k = f2s_pow5bits(i) - FLOAT_POW5_BITCOUNT
    let mut j = q - k
    vr = f2s_mul_pow5_div_pow2(mv, i, j)
    vp = f2s_mul_pow5_div_pow2(mp, i, j)
    vm = f2s_mul_pow5_div_pow2(mm, i, j)
    if q != 0 && (vp - 1U) / 10U <= vm / 10U {
      j = q - 1 - (f2s_pow5bits(i + 1) - FLOAT_POW5_BITCOUNT)
      last_removed_digit = f2s_mul_pow5_div_pow2(mv, i + 1, j) % 10U
    }
    if q <= 1 {
      // {vr,vp,vm} is trailing zeros if {mv,mp,mm} has at least q trailing 0
      // bits. mv = 4 * m2, so it always has at least two trailing 0 bits.
      vr_is_trailing_zeros = true
      if accept_bounds {
        // mm = mv - 1 - mm_shift, so it has 1 trailing 0 bit iff
        // mm_shift == 1.
        vm_is_trailing_zeros = mm_shift == 1U
      } else {
        // mp = mv + 2, so it always has at least one trailing 0 bit.
        vp = vp - 1U
      }
    } else if q < 31 {
      vr_is_trailing_zeros = f2s_multiple_of_power_of_2_32(mv, q - 1)
    }
  }

  // Step 4: Find the shortest decimal representation in the interval of
  // valid representations.
  let mut removed = 0
  let output = if vm_is_trailing_zeros || vr_is_trailing_zeros {
    // General case, which happens rarely (~4.0%).
    while vp / 10U > vm / 10U {
      vm_is_trailing_zeros = vm_is_trailing_zeros && vm - vm / 10U * 10U == 0U
      vr_is_trailing_zeros = vr_is_trailing_zeros && last_removed_digit == 0U
      last_removed_digit = vr % 10U
      vr = vr / 10U
      vp = vp / 10U
      vm = vm / 10U
      removed += 1
    }
    if vm_is_trailing_zeros {
      while vm % 10U == 0U {
        vr_is_trailing_zeros = vr_is_trailing_zeros && last_removed_digit == 0U
        last_removed_digit = vr % 10U
        vr = vr / 10U
        vm = vm / 10U
        removed += 1
      }
    }
    if vr_is_trailing_zeros && last_removed_digit == 5U && vr % 2U == 0U {
      // Round even if the exact number is .....50..0.
      last_removed_digit = 4U
    }
    // We need to take vr + 1 if vr is outside bounds or we need to round
    // up.
    if (vr == vm && (!accept_bounds || !vm_is_trailing_zeros)) ||
      last_removed_digit >= 5U {
      vr + 1U
    } else {
      vr
    }
  } else {
    // Specialized for the common case (~96.0%).
    while vp / 10U > vm / 10U {
      last_removed_digit = vr % 10U
      vr = vr / 10U
      vp = vp / 10U
      vm = vm / 10U
      removed += 1
    }
    // We need to take vr + 1 if vr is outside bounds or we need to round
    // up.
    if vr == vm || last_removed_digit >= 5U {
      vr + 1U
    } else {
      vr
    }
  }
  { mantissa: output, exponent: e10 + removed, }
}

///|
/// The upper 64 bits of `DOUBLE_POW5_INV_SPLIT[q]` (`d2s_full_table.rs`) for
/// `q` in `0..=30`, the range of `f32`.
let f2s_pow5_inv_split_hi : ReadOnlyArray[UInt64] = [
  0x2000000000000000UL, 0x1999999999999999UL, 0x147AE147AE147AE1UL, 0x10624DD2F1A9FBE7UL,
  0x1A36E2EB1C432CA5UL, 0x14F8B588E368F084UL, 0x10C6F7A0B5ED8D36UL, 0x1AD7F29ABCAF4857UL,
  0x15798EE2308C39DFUL, 0x112E0BE826D694B2UL, 0x1B7CDFD9D7BDBAB7UL, 0x15FD7FE17964955FUL,
  0x119799812DEA1119UL, 0x1C25C268497681C2UL, 0x16849B86A12B9B01UL, 0x1203AF9EE756159BUL,
  0x1CD2B297D889BC2BUL, 0x170EF54646D49689UL, 0x12725DD1D243ABA0UL, 0x1D83C94FB6D2AC34UL,
  0x179CA10C9242235DUL, 0x12E3B40A0E9B4F7DUL, 0x1E392010175EE596UL, 0x182DB34012B25144UL,
  0x1357C299A88EA76AUL, 0x1EF2D0F5DA7DD8AAUL, 0x18C240C4AECB13BBUL, 0x13CE9A36F23C0FC9UL,
  0x1FB0F6BE50601941UL, 0x195A5EFEA6B34767UL, 0x14484BFEEBC29F86UL,
]

///|
/// The upper 64 bits of `DOUBLE_POW5_SPLIT[i]` (`d2s_full_table.rs`) for `i`
/// in `0..=47`, the range of `f32`.
let f2s_pow5_split_hi : ReadOnlyArray[UInt64] = [
  0x1000000000000000UL, 0x1400000000000000UL, 0x1900000000000000UL, 0x1F40000000000000UL,
  0x1388000000000000UL, 0x186A000000000000UL, 0x1E84800000000000UL, 0x1312D00000000000UL,
  0x17D7840000000000UL, 0x1DCD650000000000UL, 0x12A05F2000000000UL, 0x174876E800000000UL,
  0x1D1A94A200000000UL, 0x12309CE540000000UL, 0x16BCC41E90000000UL, 0x1C6BF52634000000UL,
  0x11C37937E0800000UL, 0x16345785D8A00000UL, 0x1BC16D674EC80000UL, 0x1158E460913D0000UL,
  0x15AF1D78B58C4000UL, 0x1B1AE4D6E2EF5000UL, 0x10F0CF064DD59200UL, 0x152D02C7E14AF680UL,
  0x1A784379D99DB420UL, 0x108B2A2C28029094UL, 0x14ADF4B7320334B9UL, 0x19D971E4FE8401E7UL,
  0x1027E72F1F128130UL, 0x1431E0FAE6D7217CUL, 0x193E5939A08CE9DBUL, 0x1F8DEF8808B02452UL,
  0x13B8B5B5056E16B3UL, 0x18A6E32246C99C60UL, 0x1ED09BEAD87C0378UL, 0x13426172C74D822BUL,
  0x1812F9CF7920E2B6UL, 0x1E17B84357691B64UL, 0x12CED32A16A1B11EUL, 0x178287F49C4A1D66UL,
  0x1D6329F1C35CA4BFUL, 0x125DFA371A19E6F7UL, 0x16F578C4E0A060B5UL, 0x1CB2D6F618C878E3UL,
  0x11EFC659CF7D4B8DUL, 0x166BB7F0435C9E71UL, 0x1C06A5EC5433C60DUL, 0x118427B3B4A05BC8UL,
]
