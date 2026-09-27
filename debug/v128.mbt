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
fn v128_lo(value : V128) -> UInt64 = "%v128.lo"

///|
fn v128_hi(value : V128) -> UInt64 = "%v128.hi"

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
fn u64_hex(value : UInt64) -> String {
  let buf = StringBuilder()
  u64_hex_to(buf, value)
  buf.to_string()
}

///|
/// Shows the two 64-bit words in the same zero-padded hex form as `Show`.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub impl Debug for V128 with fn to_repr(self) {
  Repr::opaque_(
    "V128",
    Repr::tuple([
      Repr::literal(u64_hex(v128_lo(self))),
      Repr::literal(u64_hex(v128_hi(self))),
    ]),
  )
}
