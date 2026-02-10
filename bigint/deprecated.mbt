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
/// Arithmetic right shift for bigint values.
///
/// Deprecated: use the infix operator `>>` instead.
///
/// Example:
///
/// ```mbt check
/// test {
///   let x = @bigint.BigInt::from_int(16)
///   inspect((x >> 2).to_int(), content="4")
/// }
/// ```
#deprecated("Use infix bitwise operator `>>` instead")
#coverage.skip
pub fn BigInt::asr(self : BigInt, n : Int) -> BigInt {
  self >> n
}

///|
/// Left shift a bigint
/// The sign of the result is the same as the sign of the input.
/// Only the absolute value is shifted.
///
#deprecated("Use infix bitwise operator `<<` instead")
#coverage.skip
pub fn BigInt::shl(self : BigInt, n : Int) -> BigInt {
  self << n
}

///|
/// Left shift a bigint
/// The sign of the result is the same as the sign of the input.
/// Only the absolute value is shifted.
///
#deprecated("Use infix bitwise operator `<<` instead")
#coverage.skip
pub fn BigInt::lsl(self : BigInt, n : Int) -> BigInt {
  self << n
}

///|
/// Right shift a bigint
/// The sign of the result is the same as the sign of the input.
/// Only the absolute value is shifted.
///
#deprecated("Use infix bitwise operator `>>` instead")
#coverage.skip
pub fn BigInt::shr(self : BigInt, n : Int) -> BigInt {
  self >> n
}

///|
/// Deprecated: use `to_string(radix=16)` instead.
#deprecated("Use `to_string(radix=16)` instead")
#coverage.skip
#cfg(not(target="js"))
pub fn BigInt::to_hex(self : BigInt, uppercase? : Bool = true) -> String {
  if self.is_zero() {
    return "0"
  }
  // WARN: this implementation assumes that `radix_bit_len` is a multiple of 4.
  let digits_per_limb = radix_bit_len / 4
  let buf = if self.sign is Negative {
    let builder = StringBuilder::new(size_hint=self.len * digits_per_limb + 2)
    builder.write_char('-')
    builder
  } else {
    StringBuilder::new(size_hint=self.len * digits_per_limb)
  }
  for i = self.len - 1; i >= 0; i = i - 1 { // TODO: reverse iteration would be a bit faster.
    // split the limb into 4-bit chunks
    let mut x = self.limbs[i]
    let digits = FixedArray::make(digits_per_limb, '0')
    let mut idx = 0
    while x > 0 {
      let y = x % 16
      x /= 16
      digits[idx] = if y < 10 {
        (y.reinterpret_as_int() + '0'.to_int()).unsafe_to_char()
      } else if uppercase {
        (y.reinterpret_as_int() - 10 + 'A'.to_int()).unsafe_to_char()
      } else {
        (y.reinterpret_as_int() - 10 + 'a'.to_int()).unsafe_to_char()
      }
      idx += 1
    }
    if i != self.len - 1 {
      idx = digits_per_limb
    }
    for j in 0..<idx {
      buf.write_char(digits[idx - 1 - j])
    }
  }
  buf.to_string()
}

///|
/// Deprecated: use `to_string(radix=16)` instead.
#deprecated("Use `to_string(radix=16)` instead")
#coverage.skip
#cfg(target="js")
pub extern "js" fn BigInt::to_hex(
  self : BigInt,
  uppercase? : Bool = true,
) -> String =
  #|(x, uppercase) => {
  #|  const r = x.toString(16);
  #|  return uppercase ? r.toUpperCase() : r;
  #|}

///|
/// Deprecated: use `from_string(radix=16)` instead.
#deprecated("Use `from_string(radix=16)` instead")
#coverage.skip
#cfg(not(target="js"))
pub fn BigInt::from_hex(input : String) -> BigInt {
  // WARN: this implementation assumes that `radix_bit_len` is a multiple of 4.
  fn char_from_hex(x : Int) -> UInt {
    (match x {
      '0'..='9' => x - '0'
      'A'..='F' => x + (10 - 'A')
      'a'..='f' => x + (10 - 'a')
      _ => abort("invalid character")
    }).reinterpret_as_uint()
  }

  let len = input.length()
  if len == 0 {
    abort("empty string")
  }
  let (sign, number_len) = if input.unsafe_get(0) == '-' {
    (Negative, len - 1)
  } else {
    (Positive, len)
  }
  let nb_char = radix_bit_len / 4 // number of char per limb
  let quotient = number_len / nb_char
  let mod = number_len % nb_char
  let mut b_len = if mod == 0 { quotient } else { quotient + 1 }
  let b = FixedArray::make(b_len, 0U)
  if mod != 0 {
    let start = len - quotient * nb_char - mod
    for i in 0..<mod {
      b[b_len - 1] = (b[b_len - 1] << 4) |
        char_from_hex(input.unsafe_get(start + i).to_int())
    }
  }
  for i in 0..<quotient {
    let start = len - (i + 1) * nb_char
    for j in 0..<nb_char {
      b[i] = (b[i] << 4) | char_from_hex(input.unsafe_get(start + j).to_int())
    }
  }
  while b[b_len - 1] == 0 && b_len > 1 {
    b_len -= 1
  }
  let sign = if b_len == 1 && b[0] == 0 { Positive } else { sign }
  { limbs: b, sign, len: b_len }
}

///|
/// Deprecated: use `from_string(radix=16)` instead.
#deprecated("Use `from_string(radix=16)` instead")
#coverage.skip
#cfg(target="js")
pub extern "js" fn BigInt::from_hex(str : String) -> BigInt =
  #|(x) => x.startsWith('-') ? -BigInt(`0x${x.slice(1)}`) : BigInt(`0x${x}`)
