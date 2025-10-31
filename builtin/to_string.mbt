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

///|
const ALPHABET : String = "0123456789abcdefghijklmnopqrstuvwxyz"

///|
pub fn Int64::to_string(self : Int64, radix? : Int = 10) -> String {
  let buf = StringBuilder::new(size_hint=Int64::output_size_hint(radix~))
  self.output(buf, radix~)
  buf.to_string()
}

///|
pub impl Show for Int64 with to_string(self) {
  self.to_string(radix=10)
}

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
  if value < 100000U {
    if value < 100U {
      1 + (if value >= 10U { 1 } else { 0 })
    } else {
      3 +
      (if value >= 10000U { 1 } else { 0 }) +
      (if value >= 1000U { 1 } else { 0 })
    }
  } else if value < 10000000U {
    6 + (if value >= 1000000U { 1 } else { 0 })
  } else {
    8 +
    (if value >= 1000000000U { 1 } else { 0 }) +
    (if value >= 100000000U { 1 } else { 0 })
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
  unsafe_fixedarray_to_string(buffer)
}

///|
#cfg(not(any(target="js", target="wasm-gc")))
fn unsafe_fixedarray_to_string(buffer : FixedArray[UInt16]) -> String = "%identity"

///|
#cfg(target="wasm-gc")
fn unsafe_fixedarray_to_string(buffer : FixedArray[UInt16]) -> String {
  let sb = StringBuilder::new(size_hint=buffer.length() * 2)
  for u in buffer {
    sb.write_char(u.to_int().unsafe_to_char())
  }
  sb.to_string()
}

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
pub impl Show for Int with to_string(self) {
  self.to_string(radix=10)
}

///|
pub fn UInt::to_string(self : UInt, radix? : Int = 10) -> String {
  let buf = StringBuilder::new(size_hint=UInt::output_size_hint(radix~))
  self.output(buf, radix~)
  buf.to_string()
}

///|
pub impl Show for UInt with to_string(self) {
  self.to_string(radix=10)
}

///|
test "UInt::to_string" {
  inspect(0U, content="0")
  inspect(17U, content="17")
  inspect(4294967295U, content="4294967295")
}

///|
pub fn UInt64::to_string(self : UInt64, radix? : Int = 10) -> String {
  let buf = StringBuilder::new(size_hint=UInt64::output_size_hint(radix~))
  self.output(buf, radix~)
  buf.to_string()
}

///|
pub impl Show for UInt64 with to_string(self) {
  self.to_string(radix=10)
}

///|
pub fn Int16::to_string(self : Int16, radix? : Int = 10) -> String {
  self.to_int().to_string(radix~)
}

///|
pub impl Show for Int16 with to_string(self) {
  self.to_string(radix=10)
}

///|
pub fn UInt16::to_string(self : UInt16, radix? : Int = 10) -> String {
  self.to_int().to_string(radix~)
}

///|
pub impl Show for UInt16 with to_string(self) {
  self.to_string(radix=10)
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
test "to_string with radix" {
  // Binary
  inspect((0).to_string(radix=2), content="0")
  inspect((1).to_string(radix=2), content="1")
  inspect((2).to_string(radix=2), content="10")
  inspect((255).to_string(radix=2), content="11111111")
  inspect((-255).to_string(radix=2), content="-11111111")

  // Octal
  inspect((0).to_string(radix=8), content="0")
  inspect((8).to_string(radix=8), content="10")
  inspect((64).to_string(radix=8), content="100")
  inspect((-64).to_string(radix=8), content="-100")

  // Decimal
  inspect((0).to_string(radix=10), content="0")
  inspect((123).to_string(radix=10), content="123")
  inspect((-123).to_string(radix=10), content="-123")
  inspect(
    0x7fff_ffff_ffff_ffffL.to_string(radix=10),
    content="9223372036854775807",
  )
  inspect(
    0x8000_0000_0000_0000L.to_string(radix=10),
    content="-9223372036854775808",
  )

  // Hexadecimal
  inspect((0).to_string(radix=16), content="0")
  inspect((0x11).to_string(radix=16), content="11")
  inspect((0x15ef).to_string(radix=16), content="15ef")
  inspect((-0xabcd).to_string(radix=16), content="-abcd")
  inspect(
    (1.0 : Float).reinterpret_as_int().to_string(radix=16),
    content="3f800000",
  )

  // UInt
  inspect(0U.to_string(radix=16), content="0")
  inspect(0x1AU.to_string(radix=16), content="1a")
  inspect(0xabcdU.to_string(radix=16), content="abcd")
  inspect(
    (-2.0 : Float).reinterpret_as_uint().to_string(radix=16),
    content="c0000000",
  )
  inspect((-1).reinterpret_as_uint().to_string(radix=16), content="ffffffff")

  // Int64
  inspect(0L.to_string(radix=16), content="0")
  inspect(0x2fL.to_string(radix=16), content="2f")
  inspect(0xf0aeL.to_string(radix=16), content="f0ae")
  inspect((-0x1234eacbL).to_string(radix=16), content="-1234eacb")
  inspect(
    1.0.reinterpret_as_uint64().to_string(radix=16),
    content="3ff0000000000000",
  )
  inspect(0b101L.to_string(radix=2), content="101")
  inspect(0o17L.to_string(radix=8), content="17")

  // UInt64
  inspect(0UL.to_string(radix=16), content="0")
  inspect(0x11UL.to_string(radix=16), content="11")
  inspect(0x12bdUL.to_string(radix=16), content="12bd")
  inspect(
    (-1L).reinterpret_as_uint64().to_string(radix=16),
    content="ffffffffffffffff",
  )
  inspect(
    2.0.reinterpret_as_uint64().to_string(radix=16),
    content="4000000000000000",
  )
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
