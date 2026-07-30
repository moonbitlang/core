// Copyright 2020 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the repository NOTICE file.
//
// Adapted to MoonBit from Go 1.26.2's internal/strconv/atofeisel.go.

///|
#valtype
priv struct EiselProduct {
  lo : UInt64
  hi : UInt64
}

///|
fn eisel_umul128(a : UInt64, b : UInt64) -> EiselProduct {
  let a_lo = a & 0xffffffffUL
  let a_hi = a >> 32
  let b_lo = b & 0xffffffffUL
  let b_hi = b >> 32
  let x = a_lo * b_lo
  let y = a_hi * b_lo + (x >> 32)
  let z = a_lo * b_hi + (y & 0xffffffffUL)
  let hi = a_hi * b_hi + (y >> 32) + (z >> 32)
  { lo: a * b, hi }
}

///|
fn eisel_mul_log2_10(exponent : Int) -> Int {
  // floor(exponent * log2(10)) for -500 <= exponent <= 500.
  (exponent * 108853) >> 15
}

///|
/// Attempts Eisel-Lemire conversion of `mantissa * 10^exponent`.
///
/// A NaN result is a private failure sentinel. The algorithm deliberately
/// rejects values whose correct rounding cannot be certified; callers must
/// retain an exact Decimal fallback for those inputs.
#doc(hidden)
pub fn try_eisel_lemire64(
  mantissa : UInt64,
  exponent : Int64,
  negative : Bool,
) -> Double {
  if mantissa == 0UL {
    return if negative {
      0x8000000000000000UL.reinterpret_as_double()
    } else {
      0.0
    }
  }
  if exponent < EISEL_LEMIRE_POW10_MIN.to_int64() ||
    exponent > EISEL_LEMIRE_POW10_MAX.to_int64() {
    return @double.not_a_number
  }
  let exponent = exponent.to_int()
  let table_index = (exponent - EISEL_LEMIRE_POW10_MIN) * 2
  let pow_hi = eisel_lemire_pow10_table[table_index]
  let pow_lo = eisel_lemire_pow10_table[table_index + 1]
  let pow_exp2 = 1 + eisel_mul_log2_10(exponent)

  // Normalize the decimal mantissa so its most significant bit is set.
  let leading_zeros = mantissa.clz()
  let normalized = mantissa << leading_zeros
  let mut result_exp2 = pow_exp2 + 63 + 1023 - leading_zeros

  let product = eisel_umul128(normalized, pow_hi)
  let mut product_hi = product.hi
  let mut product_lo = product.lo

  // Use the low limb of the cached power when the first product does not
  // contain enough information to determine the rounded result.
  if (product_hi & 0x1ffUL) == 0x1ffUL && product_lo + normalized < normalized {
    let wider = eisel_umul128(normalized, pow_lo)
    let mut merged_hi = product_hi
    let merged_lo = product_lo + wider.hi
    if merged_lo < product_lo {
      merged_hi += 1UL
    }
    if (merged_hi & 0x1ffUL) == 0x1ffUL &&
      merged_lo + 1UL == 0UL &&
      wider.lo + normalized < normalized {
      return @double.not_a_number
    }
    product_hi = merged_hi
    product_lo = merged_lo
  }

  // Keep 54 significant bits, then round down to the binary64 precision.
  let top_bit = (product_hi >> 63).to_int()
  let mut result_mantissa = product_hi >> (top_bit + 9)
  result_exp2 -= 1 - top_bit

  // An exact halfway case needs the Decimal fallback to resolve ties safely.
  if product_lo == 0UL &&
    (product_hi & 0x1ffUL) == 0UL &&
    (result_mantissa & 3UL) == 1UL {
    return @double.not_a_number
  }

  result_mantissa += result_mantissa & 1UL
  result_mantissa = result_mantissa >> 1
  if result_mantissa >> 53 > 0UL {
    result_mantissa = result_mantissa >> 1
    result_exp2 += 1
  }

  // Subnormal, overflow, and special-value boundaries remain on the exact
  // fallback path.
  if result_exp2 <= 0 || result_exp2 >= 0x7ff {
    return @double.not_a_number
  }
  let exponent_bits = UInt64::extend_uint(result_exp2.reinterpret_as_uint()) <<
    52
  let mut result_bits = exponent_bits | (result_mantissa & 0x000fffffffffffffUL)
  if negative {
    result_bits = result_bits | 0x8000000000000000UL
  }
  result_bits.reinterpret_as_double()
}
