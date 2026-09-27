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
/// Compares two `V128` values for bitwise equality across both 64-bit words.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub impl Eq for V128 with fn equal(self : V128, other : V128) -> Bool {
  v128_lo(self) == v128_lo(other) && v128_hi(self) == v128_hi(other)
}

///|
/// Compares two `V128` values for bitwise inequality across both 64-bit words.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub impl Eq for V128 with fn not_equal(self : V128, other : V128) -> Bool {
  v128_lo(self) != v128_lo(other) || v128_hi(self) != v128_hi(other)
}

///|
fn u64_hex_to(logger : &Logger, value : UInt64) -> Unit {
  let digits = value.to_string(radix=16)
  logger <+ "0x"
  for _ in digits.length()..<16 {
    logger.write_char('0')
  }
  logger.write_string(digits)
}

///|
/// Prints the two 64-bit words in zero-padded hex so every byte lane is
/// visible; lane 0 is the lowest byte of the first word.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub impl Show for V128 with fn output(self : V128, logger) {
  logger <+
    "V128(\{cb => u64_hex_to(cb, v128_lo(self))}, \{cb => u64_hex_to(cb, v128_hi(self))})"
}
