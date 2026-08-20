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

// Property tests for the Eisel-Lemire fast path.
//
// `try_eisel_lemire64` is free to reject any input, but every value it
// accepts must be the correctly rounded double — bit for bit what the
// arbitrary-precision Decimal conversion produces. The oracle reaches that
// exact path through the public parser: appending 21 mantissa zeros (with
// the exponent compensating) pushes the digit count past the 19 the fast
// paths tolerate, so `parse_double` is forced onto the Decimal slow path.

///|
fn eisel_lemire_is_exact(
  mantissa : UInt64,
  exponent : Int,
  negative : Bool,
) -> Bool {
  let fast = @strconv.try_eisel_lemire64(
    mantissa,
    exponent.to_int64(),
    negative,
  )
  if fast.is_nan() {
    // Rejection is always allowed: those inputs stay on the exact fallback.
    return true
  }
  let sign = if negative { "-" } else { "" }
  let padded = "\{sign}\{mantissa}\{repeat_char('0', 21)}e\{exponent - 21}"
  parsed(padded) is Some(exact) && same_double(fast, exact)
}

///|
/// Whatever the fast path accepts must match the exact conversion.
test "quickcheck: accepted Eisel-Lemire values are correctly rounded" {
  @quickcheck.check(
    (input : (UInt64, Int, Int, Bool)) => {
      let (raw, shift_code, exp_code, negative) = input
      // The shift spreads mantissas across every magnitude, including the
      // small values a uniform UInt64 almost never produces.
      let mantissa = raw >> wrap_index(shift_code, 64)
      // Exponents overshoot the table range (-348..=347) on both sides so
      // the bounds check is exercised alongside the conversion.
      let exponent = wrap_index(exp_code, 723) - 361
      eisel_lemire_is_exact(mantissa, exponent, negative)
    },
    count=20000,
  )
}

///|
/// Mantissas next to powers of two sit on binade boundaries, where rounding
/// carries into the next exponent and halfway cases cluster; the ambiguity
/// rejection has to fire exactly there.
test "quickcheck: Eisel-Lemire stays exact near binade boundaries" {
  @quickcheck.check(
    (input : (Int, Int, Int, Bool)) => {
      let (bit_code, delta_code, exp_code, negative) = input
      let base = 1UL << wrap_index(bit_code, 64)
      let delta = (wrap_index(delta_code, 9) - 4).to_int64()
      // Wrapping addition is fine: any UInt64 is a valid mantissa.
      let mantissa = base + delta.reinterpret_as_uint64()
      let exponent = wrap_index(exp_code, 723) - 361
      eisel_lemire_is_exact(mantissa, exponent, negative)
    },
    count=20000,
  )
}
