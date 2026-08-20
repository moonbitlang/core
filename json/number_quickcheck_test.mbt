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

// Property tests for JSON number parsing.
//
// `lex_number_end` routes a literal to one of several conversions —
// safe-integer, Clinger, Eisel-Lemire, or the exact strconv fallback —
// based purely on the literal's shape. Different spellings of the same
// value therefore take different routes, which yields the property that
// pins them all together: every spelling must parse to the same double,
// bit for bit. Padding the fraction with zeros pushes the significant-digit
// count past the 19 the fast routes tolerate, forcing the exact fallback
// and turning it into the oracle for the fast ones.

///|
fn number_value_bits(text : String) -> UInt64? {
  let json = @json.parse(text) catch { _ => return None }
  guard json is Number(value, ..) else { return None }
  Some(value.reinterpret_as_uint64())
}

///|
test "quickcheck: json number value is independent of its spelling" {
  @quickcheck.check(
    (input : (UInt64, Int, Int, Bool)) => {
      let (raw, shift_code, exp_code, negative) = input
      // The shift spreads mantissas across every magnitude; exponents
      // overshoot the double range on both sides so the overflow and
      // underflow fallbacks are exercised too.
      let mantissa = raw >> wrap_index(shift_code, 64)
      let exponent = wrap_index(exp_code, 723) - 361
      let sign = if negative { "-" } else { "" }
      let digits = mantissa.to_string()
      let plain = "\{sign}\{digits}e\{exponent}"
      // Fraction zeros leave the value unchanged but push the significant
      // digit count past 19, forcing the exact fallback.
      let padded = "\{sign}\{digits}.\{String::make(21, '0')}e\{exponent}"
      // The decimal point moved behind the first digit, with the exponent
      // compensating — the same value split differently between mantissa
      // and exponent by the scanner.
      let len = digits.length()
      let pointed = if len == 1 {
        "\{sign}\{digits}.0e\{exponent}"
      } else {
        "\{sign}\{digits[0:1]}.\{digits[1:len]}e\{exponent + len - 1}"
      }
      match
        (
          number_value_bits(plain),
          number_value_bits(padded),
          number_value_bits(pointed),
        ) {
        (Some(a), Some(b), Some(c)) => a == b && b == c
        _ => false
      }
    },
    count=10000,
  )
}
