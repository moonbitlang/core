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
#cfg(not(target="js"))
const ALPHABET : String = "0123456789abcdefghijklmnopqrstuvwxyz"

///|
#cfg(not(target="js"))
fn unsafe_fixedarray_uint16_to_string(buffer : FixedArray[UInt16]) -> String = "%string.unsafe_from_uint16_fixedarray"

//==========================================
// Int and UInt (Non JS)
//==========================================

///|
/// Converts an unsigned 32-bit integer to hexadecimal
#cfg(not(target="js"))
fn int_to_string_hex(
  buffer : FixedArray[UInt16],
  num : UInt,
  digit_start : Int,
  total_len : Int,
) -> Unit {
  let mut offset = total_len - digit_start
  let mut n = num

  // Process 2 hex digits (1 byte) at a time
  while offset >= 2 {
    offset = offset - 2
    let byte_val = n.land(0xFFU).reinterpret_as_int()
    let hi = byte_val / 16
    let lo = byte_val % 16
    buffer.unsafe_set(
      digit_start + offset,
      ALPHABET.unsafe_charcode_at(hi).to_uint16(),
    )
    buffer.unsafe_set(
      digit_start + offset + 1,
      ALPHABET.unsafe_charcode_at(lo).to_uint16(),
    )
    n = n >> 8
  }

  // Handle remaining single hex digit
  if offset == 1 {
    let nibble = n.land(0xFU).reinterpret_as_int()
    buffer.unsafe_set(
      digit_start,
      ALPHABET.unsafe_charcode_at(nibble).to_uint16(),
    )
  }
}

///|
/// Generic radix conversion for any base 2-36
#cfg(not(target="js"))
fn int_to_string_generic(
  buffer : FixedArray[UInt16],
  num : UInt,
  digit_start : Int,
  total_len : Int,
  radix : Int,
) -> Unit {
  let mut offset = total_len - digit_start
  let mut n = num
  let base = radix.reinterpret_as_uint()
  if (radix & (radix - 1)) == 0 {
    // Power-of-two radix: use bit shifts
    let shift = radix.ctz()
    let mask = base - 1U
    while n > 0U {
      offset = offset - 1
      let digit = n.land(mask).reinterpret_as_int()
      buffer.unsafe_set(
        digit_start + offset,
        ALPHABET.unsafe_charcode_at(digit).to_uint16(),
      )
      n = n >> shift
    }
  } else {
    // General radix: use division
    while n > 0U {
      offset = offset - 1
      let q = n / base
      let digit = (n - q * base).reinterpret_as_int()
      buffer.unsafe_set(
        digit_start + offset,
        ALPHABET.unsafe_charcode_at(digit).to_uint16(),
      )
      n = q
    }
  }
}

///|
/// Converts an unsigned 32-bit integer to decimal string
#cfg(not(target="js"))
fn int_to_string_dec(
  buffer : FixedArray[UInt16],
  num : UInt,
  digit_start : Int,
  total_len : Int,
) -> Unit {
  let mut num = num
  let mut offset = total_len - digit_start

  // Process digits in groups of 4 (chunks of 10000)
  while num >= 10000U {
    let t = num / 10000U
    let r = (num % 10000U).reinterpret_as_int()
    num = t
    let d1 = r / 100
    let d2 = r % 100
    offset = offset - 4
    let d1_hi = (0x30 + d1 / 10).to_uint16()
    let d1_lo = (0x30 + d1 % 10).to_uint16()
    let d2_hi = (0x30 + d2 / 10).to_uint16()
    let d2_lo = (0x30 + d2 % 10).to_uint16()
    buffer.unsafe_set(digit_start + offset, d1_hi)
    buffer.unsafe_set(digit_start + offset + 1, d1_lo)
    buffer.unsafe_set(digit_start + offset + 2, d2_hi)
    buffer.unsafe_set(digit_start + offset + 3, d2_lo)
  }

  // Handle remaining digits (< 10000)
  let mut remaining = num.reinterpret_as_int()

  // Process pairs of digits
  while remaining >= 100 {
    let t = remaining / 100
    let d = remaining % 100
    remaining = t
    offset = offset - 2
    let d_hi = (0x30 + d / 10).to_uint16()
    let d_lo = (0x30 + d % 10).to_uint16()
    buffer.unsafe_set(digit_start + offset, d_hi)
    buffer.unsafe_set(digit_start + offset + 1, d_lo)
  }

  // Handle final 1 or 2 digits
  if remaining >= 10 {
    offset = offset - 2
    let d_hi = (0x30 + remaining / 10).to_uint16()
    let d_lo = (0x30 + remaining % 10).to_uint16()
    buffer.unsafe_set(digit_start + offset, d_hi)
    buffer.unsafe_set(digit_start + offset + 1, d_lo)
  } else {
    offset = offset - 1
    buffer.unsafe_set(digit_start + offset, (0x30 + remaining).to_uint16())
  }
}

///|
/// Calculates the number of decimal digits in a u32 value
#cfg(not(target="js"))
fn dec_count32(value : UInt) -> Int {
  // Binary search: split 1-10 digits into halves
  if value >= 100000U { // >= 10^5 means 6+ digits
    if value >= 10000000U { // >= 10^7 means 8+ digits
      if value >= 1000000000U { // >= 10^9 means 10 digits
        10
      } else if value >= 100000000U { // >= 10^8 means 9 digits
        9
      } else {
        8
      }
    } else if value >= 1000000U { // >= 10^6 means 7 digits
      7
    } else {
      6
    }
  } else if value >= 1000U { // >= 10^3 means 4+ digits
    if value >= 10000U { // >= 10^4 means 5 digits
      5
    } else {
      4
    }
  } else if value >= 100U { // >= 10^2 means 3 digits
    3
  } else if value >= 10U { // >= 10^1 means 2 digits
    2
  } else {
    1
  }
}

///|
/// Calculates the number of hex digits needed for a u32 value
#cfg(not(target="js"))
fn hex_count32(value : UInt) -> Int {
  if value == 0U {
    1
  } else {
    let leading_zeros = value.clz()
    (31 - leading_zeros) / 4 + 1
  }
}

///|
/// Calculates the number of digits needed for a u32 value in any radix
#cfg(not(target="js"))
fn radix_count32(value : UInt, radix : Int) -> Int {
  if value == 0U {
    return 1
  }
  let mut num = value
  let base = radix.reinterpret_as_uint()
  let mut count = 0
  while num > 0U {
    count = count + 1
    num = num / base
  }
  count
}

///|
/// Converts an integer to its string representation in the specified radix (base).
/// Example:
/// ```
/// inspect((255).to_string(radix=16), content="ff")
/// inspect((-255).to_string(radix=16), content="-ff")
/// ```
#cfg(not(target="js"))
pub fn Int::to_string(self : Int, radix? : Int = 10) -> String {
  // Validate radix
  if radix < 2 || radix > 36 {
    abort("radix must be between 2 and 36")
  }

  // Special case for zero
  if self == 0 {
    return "0"
  }

  // Handle negative numbers
  let is_negative = self < 0
  let num : UInt = if is_negative {
    // Negate and reinterpret as UInt
    // Works correctly for Int::min_value due to two's complement:
    // -Int::min_value wraps to itself, then reinterpreting gives 2147483648U
    (-self).reinterpret_as_uint()
  } else {
    self.reinterpret_as_uint()
  }

  // Calculate length, allocate buffer, and write digits
  let buffer = match radix {
    10 => {
      let digit_len = dec_count32(num)
      let total_len = digit_len + (if is_negative { 1 } else { 0 })
      let buffer : FixedArray[UInt16] = FixedArray::make(total_len, 0)
      let digit_start = if is_negative { 1 } else { 0 }
      int_to_string_dec(buffer, num, digit_start, total_len)
      buffer
    }
    16 => {
      let digit_len = hex_count32(num)
      let total_len = digit_len + (if is_negative { 1 } else { 0 })
      let buffer : FixedArray[UInt16] = FixedArray::make(total_len, 0)
      let digit_start = if is_negative { 1 } else { 0 }
      int_to_string_hex(buffer, num, digit_start, total_len)
      buffer
    }
    _ => {
      let digit_len = radix_count32(num, radix)
      let total_len = digit_len + (if is_negative { 1 } else { 0 })
      let buffer : FixedArray[UInt16] = FixedArray::make(total_len, 0)
      let digit_start = if is_negative { 1 } else { 0 }
      int_to_string_generic(buffer, num, digit_start, total_len, radix)
      buffer
    }
  }

  // Write minus sign if negative
  if is_negative {
    buffer.unsafe_set(0, 0x002D)
  }
  unsafe_fixedarray_uint16_to_string(buffer)
}

///|
/// Converts an unsigned integer to its string representation in the specified radix (base).
#cfg(not(target="js"))
pub fn UInt::to_string(self : UInt, radix? : Int = 10) -> String {
  // Validate radix
  if radix < 2 || radix > 36 {
    abort("radix must be between 2 and 36")
  }

  // Special case for zero
  if self == 0U {
    return "0"
  }

  // Calculate length, allocate buffer, and write digits
  let buffer = match radix {
    10 => {
      let len = dec_count32(self)
      let buffer : FixedArray[UInt16] = FixedArray::make(len, 0)
      int_to_string_dec(buffer, self, 0, len)
      buffer
    }
    16 => {
      let len = hex_count32(self)
      let buffer : FixedArray[UInt16] = FixedArray::make(len, 0)
      int_to_string_hex(buffer, self, 0, len)
      buffer
    }
    _ => {
      let len = radix_count32(self, radix)
      let buffer : FixedArray[UInt16] = FixedArray::make(len, 0)
      int_to_string_generic(buffer, self, 0, len, radix)
      buffer
    }
  }
  unsafe_fixedarray_uint16_to_string(buffer)
}

//==========================================
// Int and UInt (JS)
//==========================================

///|
/// Converts an integer to its string representation in the specified radix (base).
#cfg(target="js")
pub fn Int::to_string(self : Int, radix? : Int = 10) -> String {
  int_to_string_js(self, radix)
}

///|
#cfg(target="js")
extern "js" fn int_to_string_js(i : Int, radix : Int) -> String =
  #|(x, radix) => {
  #|  return x.toString(radix);
  #|}

///|
/// Converts an unsigned integer to its string representation in the specified radix (base).
#cfg(target="js")
pub fn UInt::to_string(self : UInt, radix? : Int = 10) -> String {
  uint_to_string_js(self, radix)
}

///|
#cfg(target="js")
extern "js" fn uint_to_string_js(i : UInt, radix : Int) -> String =
  #|(x, radix) => {
  #|  return (x >>> 0).toString(radix);
  #|}

//==========================================
// Int64 and UInt64
//==========================================

///|
/// Calculates the number of decimal digits in a u64 value
#cfg(not(target="js"))
fn dec_count64(value : UInt64) -> Int {
  // Binary search: split 1-20 digits into halves
  if value >= 10000000000UL { // >= 10^10 means 11+ digits
    if value >= 100000000000000UL { // >= 10^14 means 15+ digits
      if value >= 10000000000000000UL { // >= 10^16 means 17+ digits
        if value >= 1000000000000000000UL { // >= 10^18 means 19+ digits
          if value >= 10000000000000000000UL { // >= 10^19 means 20 digits
            20
          } else {
            19
          }
        } else if value >= 100000000000000000UL { // >= 10^17 means 18 digits
          18
        } else {
          17
        }
      } else if value >= 1000000000000000UL { // >= 10^15 means 16 digits
        16
      } else {
        15
      }
    } else if value >= 1000000000000UL { // >= 10^12 means 13+ digits
      if value >= 10000000000000UL { // >= 10^13 means 14 digits
        14
      } else {
        13
      }
    } else if value >= 100000000000UL { // >= 10^11 means 12 digits
      12
    } else {
      11
    }
  } else if value >= 100000UL { // >= 10^5 means 6+ digits
    if value >= 10000000UL { // >= 10^7 means 8+ digits
      if value >= 1000000000UL { // >= 10^9 means 10 digits
        10
      } else if value >= 100000000UL { // >= 10^8 means 9 digits
        9
      } else {
        8
      }
    } else if value >= 1000000UL { // >= 10^6 means 7 digits
      7
    } else {
      6
    }
  } else if value >= 1000UL { // >= 10^3 means 4+ digits
    if value >= 10000UL { // >= 10^4 means 5 digits
      5
    } else {
      4
    }
  } else if value >= 100UL { // >= 10^2 means 3 digits
    3
  } else if value >= 10UL { // >= 10^1 means 2 digits
    2
  } else {
    1
  }
}

///|
/// Calculates the number of hex digits needed for a u64 value
#cfg(not(target="js"))
fn hex_count64(value : UInt64) -> Int {
  if value == 0UL {
    1
  } else {
    let leading_zeros = value.clz()
    (63 - leading_zeros) / 4 + 1
  }
}

///|
/// Calculates the number of digits needed for a u64 value in any radix
#cfg(not(target="js"))
fn radix_count64(value : UInt64, radix : Int) -> Int {
  if value == 0UL {
    return 1
  }
  let mut num = value
  let base = radix.to_uint64()
  let mut count = 0
  while num > 0UL {
    count = count + 1
    num = num / base
  }
  count
}

///|
/// Converts an unsigned 64-bit integer to hexadecimal
#cfg(not(target="js"))
fn int64_to_string_hex(
  buffer : FixedArray[UInt16],
  num : UInt64,
  digit_start : Int,
  total_len : Int,
) -> Unit {
  let mut offset = total_len - digit_start
  let mut n = num

  // Process 2 hex digits (1 byte) at a time
  while offset >= 2 {
    offset = offset - 2
    let byte_val = n.land(0xFFUL).to_int()
    let hi = byte_val / 16
    let lo = byte_val % 16
    buffer.unsafe_set(
      digit_start + offset,
      ALPHABET.unsafe_charcode_at(hi).to_uint16(),
    )
    buffer.unsafe_set(
      digit_start + offset + 1,
      ALPHABET.unsafe_charcode_at(lo).to_uint16(),
    )
    n = n >> 8
  }

  // Handle remaining single hex digit
  if offset == 1 {
    let nibble = n.land(0xFUL).to_int()
    buffer.unsafe_set(
      digit_start,
      ALPHABET.unsafe_charcode_at(nibble).to_uint16(),
    )
  }
}

///|
/// Generic radix conversion for any base 2-36 (64-bit)
#cfg(not(target="js"))
fn int64_to_string_generic(
  buffer : FixedArray[UInt16],
  num : UInt64,
  digit_start : Int,
  total_len : Int,
  radix : Int,
) -> Unit {
  let mut offset = total_len - digit_start
  let mut n = num
  let base = radix.to_uint64()
  if (radix & (radix - 1)) == 0 {
    // Power-of-two radix: use bit shifts
    let shift = radix.ctz()
    let mask = base - 1UL
    while n > 0UL {
      offset = offset - 1
      let digit = n.land(mask).to_int()
      buffer.unsafe_set(
        digit_start + offset,
        ALPHABET.unsafe_charcode_at(digit).to_uint16(),
      )
      n = n >> shift
    }
  } else {
    // General radix: use division
    while n > 0UL {
      offset = offset - 1
      let q = n / base
      let digit = (n - q * base).to_int()
      buffer.unsafe_set(
        digit_start + offset,
        ALPHABET.unsafe_charcode_at(digit).to_uint16(),
      )
      n = q
    }
  }
}

///|
/// Converts an unsigned 64-bit integer to decimal string
#cfg(not(target="js"))
fn int64_to_string_dec(
  buffer : FixedArray[UInt16],
  num : UInt64,
  digit_start : Int,
  total_len : Int,
) -> Unit {
  let mut num = num
  let mut offset = total_len - digit_start

  // Process digits in groups of 4 (chunks of 10000)
  while num >= 10000UL {
    let t = num / 10000UL
    let r = (num % 10000UL).to_int()
    num = t
    let d1 = r / 100
    let d2 = r % 100
    offset = offset - 4
    let d1_hi = (0x30 + d1 / 10).to_uint16()
    let d1_lo = (0x30 + d1 % 10).to_uint16()
    let d2_hi = (0x30 + d2 / 10).to_uint16()
    let d2_lo = (0x30 + d2 % 10).to_uint16()
    buffer.unsafe_set(digit_start + offset, d1_hi)
    buffer.unsafe_set(digit_start + offset + 1, d1_lo)
    buffer.unsafe_set(digit_start + offset + 2, d2_hi)
    buffer.unsafe_set(digit_start + offset + 3, d2_lo)
  }

  // Handle remaining digits (< 10000)
  let mut remaining = num.to_int()

  // Process pairs of digits
  while remaining >= 100 {
    let t = remaining / 100
    let d = remaining % 100
    remaining = t
    offset = offset - 2
    let d_hi = (0x30 + d / 10).to_uint16()
    let d_lo = (0x30 + d % 10).to_uint16()
    buffer.unsafe_set(digit_start + offset, d_hi)
    buffer.unsafe_set(digit_start + offset + 1, d_lo)
  }

  // Handle final 1 or 2 digits
  if remaining >= 10 {
    offset = offset - 2
    let d_hi = (0x30 + remaining / 10).to_uint16()
    let d_lo = (0x30 + remaining % 10).to_uint16()
    buffer.unsafe_set(digit_start + offset, d_hi)
    buffer.unsafe_set(digit_start + offset + 1, d_lo)
  } else {
    offset = offset - 1
    buffer.unsafe_set(digit_start + offset, (0x30 + remaining).to_uint16())
  }
}

///|
/// Converts a 64-bit integer to its string representation in the specified radix (base).
#cfg(not(target="js"))
pub fn Int64::to_string(self : Int64, radix? : Int = 10) -> String {
  // Validate radix
  if radix < 2 || radix > 36 {
    abort("radix must be between 2 and 36")
  }

  // Special case for zero
  if self == 0L {
    return "0"
  }

  // Handle negative numbers
  let is_negative = self < 0L
  let num : UInt64 = if is_negative {
    // Negate and reinterpret as UInt64
    // Works correctly for Int64::min_value due to two's complement
    (-self).reinterpret_as_uint64()
  } else {
    self.reinterpret_as_uint64()
  }

  // Calculate length, allocate buffer, and write digits
  let buffer = match radix {
    10 => {
      let digit_len = dec_count64(num)
      let total_len = digit_len + (if is_negative { 1 } else { 0 })
      let buffer : FixedArray[UInt16] = FixedArray::make(total_len, 0)
      let digit_start = if is_negative { 1 } else { 0 }
      int64_to_string_dec(buffer, num, digit_start, total_len)
      buffer
    }
    16 => {
      let digit_len = hex_count64(num)
      let total_len = digit_len + (if is_negative { 1 } else { 0 })
      let buffer : FixedArray[UInt16] = FixedArray::make(total_len, 0)
      let digit_start = if is_negative { 1 } else { 0 }
      int64_to_string_hex(buffer, num, digit_start, total_len)
      buffer
    }
    _ => {
      let digit_len = radix_count64(num, radix)
      let total_len = digit_len + (if is_negative { 1 } else { 0 })
      let buffer : FixedArray[UInt16] = FixedArray::make(total_len, 0)
      let digit_start = if is_negative { 1 } else { 0 }
      int64_to_string_generic(buffer, num, digit_start, total_len, radix)
      buffer
    }
  }

  // Write minus sign if negative
  if is_negative {
    buffer.unsafe_set(0, 0x002D)
  }
  unsafe_fixedarray_uint16_to_string(buffer)
}

///|
/// Converts an unsigned 64-bit integer to its string representation in the specified radix (base).
#cfg(not(target="js"))
pub fn UInt64::to_string(self : UInt64, radix? : Int = 10) -> String {
  // Validate radix
  if radix < 2 || radix > 36 {
    abort("radix must be between 2 and 36")
  }

  // Special case for zero
  if self == 0UL {
    return "0"
  }

  // Calculate length, allocate buffer, and write digits
  let buffer = match radix {
    10 => {
      let len = dec_count64(self)
      let buffer : FixedArray[UInt16] = FixedArray::make(len, 0)
      int64_to_string_dec(buffer, self, 0, len)
      buffer
    }
    16 => {
      let len = hex_count64(self)
      let buffer : FixedArray[UInt16] = FixedArray::make(len, 0)
      int64_to_string_hex(buffer, self, 0, len)
      buffer
    }
    _ => {
      let len = radix_count64(self, radix)
      let buffer : FixedArray[UInt16] = FixedArray::make(len, 0)
      int64_to_string_generic(buffer, self, 0, len, radix)
      buffer
    }
  }
  unsafe_fixedarray_uint16_to_string(buffer)
}

///|
/// Converts a 64-bit integer to its string representation in the specified radix (base).
#cfg(target="js")
pub fn Int64::to_string(self : Int64, radix? : Int = 10) -> String {
  int64_to_string_js(self, radix)
}

///|
#cfg(target="js")
extern "js" fn int64_to_string_js(num : Int64, radix : Int) -> String =
  #|(num, radix) => {
  #|  let val = (BigInt(num.hi >>> 0) << 32n) | BigInt(num.lo >>> 0);
  #|  if (val & (1n << 63n)) {
  #|    val = val - (1n << 64n);
  #|  }
  #|  return val.toString(radix);
  #|}

///|
/// Converts an unsigned 64-bit integer to its string representation in the specified radix (base).
#cfg(target="js")
pub fn UInt64::to_string(self : UInt64, radix? : Int = 10) -> String {
  uint64_to_string_js(self, radix)
}

///|
#cfg(target="js")
extern "js" fn uint64_to_string_js(num : UInt64, radix : Int) -> String =
  #|(num, radix) => {
  #|  return (BigInt(num.hi >>> 0) << 32n | BigInt(num.lo >>> 0)).toString(radix);
  #|}

//==========================================
// Int16 and UInt16
//==========================================

///|
pub fn UInt16::to_string(self : UInt16, radix? : Int = 10) -> String {
  self.to_int().to_string(radix~)
}

//==========================================
// Test cases
//==========================================

///|
test "UInt::to_string" {
  inspect(0U, content="0")
  inspect(17U, content="17")
  inspect(4294967295U, content="4294967295")
}

///|
test "to_string" {
  assert_eq((0x100).to_string(), "256")
  assert_eq("\{0x100}", "256")
  assert_eq(0x200U.to_string(), "512")
  assert_eq("\{0x200U}", "512")
  assert_eq(0x300L.to_string(), "768")
  assert_eq("\{0x300L}", "768")
  assert_eq(0x400UL.to_string(), "1024")
  assert_eq("\{0x400UL}", "1024")
}

///|
test "panic to_string_by_radix/illegal_radix" {
  ignore((1).to_string(radix=1))
  ignore((1).to_string(radix=37))
  ignore(1L.to_string(radix=0))
  ignore(1L.to_string(radix=42))
  ignore(1U.to_string(radix=-1))
  ignore(1U.to_string(radix=73))
  ignore(1UL.to_string(radix=-100))
  ignore(1UL.to_string(radix=100))
}
