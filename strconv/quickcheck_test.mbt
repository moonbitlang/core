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

// The built-in Arbitrary instances for the integer types are bounded by the
// generator size, so they never reach interesting regions such as subnormal
// doubles or 20-digit integers. Assembling values from arbitrary bytes gives
// uniform coverage of the full 64-bit (or 32-bit) space instead.

///|
fn u64_of_bytes(
  q : ((Byte, Byte, Byte, Byte), (Byte, Byte, Byte, Byte)),
) -> UInt64 {
  let ((b7, b6, b5, b4), (b3, b2, b1, b0)) = q
  (b7.to_uint64() << 56) |
  (b6.to_uint64() << 48) |
  (b5.to_uint64() << 40) |
  (b4.to_uint64() << 32) |
  (b3.to_uint64() << 24) |
  (b2.to_uint64() << 16) |
  (b1.to_uint64() << 8) |
  b0.to_uint64()
}

///|
fn u32_of_bytes(q : (Byte, Byte, Byte, Byte)) -> UInt {
  let (b3, b2, b1, b0) = q
  (b3.to_uint() << 24) |
  (b2.to_uint() << 16) |
  (b1.to_uint() << 8) |
  b0.to_uint()
}

///|
fn insert_char(s : String, pos : Int, inserted : Char) -> String {
  let sb = StringBuilder::new()
  let mut i = 0
  for c in s {
    if i == pos {
      sb.write_char(inserted)
    }
    sb.write_char(c)
    i += 1
  }
  sb.to_string()
}

///|
/// The killer property: `Double::to_string` produces the shortest decimal
/// representation that rounds back to the value, so `parse_double` must invert
/// it *bitwise* for every double, including subnormals, extreme exponents and
/// infinities. Arbitrary bit patterns reach all of those; NaN is excluded
/// because it has many payloads and never compares equal.
#warnings("-deprecated")
test "quickcheck: parse_double inverts to_string for arbitrary bit patterns" {
  @quickcheck.check(
    (q : ((Byte, Byte, Byte, Byte), (Byte, Byte, Byte, Byte))) => {
      let d = u64_of_bytes(q).reinterpret_as_double()
      let s = d.to_string()
      let parsed = @strconv.parse_double(s)
      if parsed.reinterpret_as_int64() == d.reinterpret_as_int64() {
        true
      } else {
        // `Double::to_string` follows the ECMAScript number-to-string
        // algorithm on every backend, and that algorithm renders negative
        // zero as "0", so the sign bit cannot survive the trip through the
        // string. Parsing that "0" must still yield exactly +0.0. Every
        // other double must round-trip bit-for-bit.
        d.reinterpret_as_int64() == -0x8000000000000000L &&
        s == "0" &&
        parsed.reinterpret_as_int64() == 0L
      }
    },
    filter=q => !u64_of_bytes(q).reinterpret_as_double().is_nan(),
    count=500,
  )
}

///|
/// Same round-trip on uniformly distributed doubles in [0, 1]: dense mantissas
/// with small exponents exercise the fast path a bit-pattern generator rarely
/// hits.
#warnings("-deprecated")
test "quickcheck: parse_double inverts to_string for uniform doubles" {
  @quickcheck.check(
    (d : Double) => {
      @strconv.parse_double(d.to_string()).reinterpret_as_int64() ==
      d.reinterpret_as_int64()
    },
    count=500,
  )
}

///|
/// Decimal round-trip over the full signed/unsigned 64-bit range, and
/// agreement with `to_double`: parsing the exact decimal string of an integer
/// must give the same correctly-rounded double as converting the integer
/// directly (19-20 significant digits exercise the slow path).
#warnings("-deprecated")
test "quickcheck: 64-bit integers round-trip through decimal strings" {
  @quickcheck.check(
    (q : ((Byte, Byte, Byte, Byte), (Byte, Byte, Byte, Byte))) => {
      let u = u64_of_bytes(q)
      let n = u.reinterpret_as_int64()
      @strconv.parse_uint64(u.to_string()) == u &&
      @strconv.parse_int64(n.to_string()) == n &&
      @strconv.parse_int64(n.to_string(), base=10) == n &&
      @strconv.parse_double(u.to_string()) == u.to_double() &&
      @strconv.parse_double(n.to_string()) == n.to_double()
    },
    count=500,
  )
}

///|
/// Radix round-trip: formatting in any base 2..=36 and parsing with the same
/// explicit base is the identity, for both signed and unsigned 64-bit values.
#warnings("-deprecated")
test "quickcheck: radix formatting and parsing are inverse in every base" {
  @quickcheck.check(
    (input : (((Byte, Byte, Byte, Byte), (Byte, Byte, Byte, Byte)), UInt)) => {
      let (q, r) = input
      let base = 2 + (r % 35).reinterpret_as_int()
      let u = u64_of_bytes(q)
      let n = u.reinterpret_as_int64()
      @strconv.parse_uint64(u.to_string(radix=base), base~) == u &&
      @strconv.parse_int64(n.to_string(radix=base), base~) == n
    },
    count=500,
  )
}

///|
/// 32-bit round-trip, an explicit leading '+', and agreement between the
/// integer and floating-point parsers on the same string (exact: every Int
/// fits in a double).
#warnings("-deprecated")
test "quickcheck: 32-bit integers round-trip and parsers agree" {
  @quickcheck.check(
    (q : (Byte, Byte, Byte, Byte)) => {
      let u = u32_of_bytes(q)
      let n = u.reinterpret_as_int()
      let s = n.to_string()
      @strconv.parse_int(s) == n &&
      @strconv.parse_uint(u.to_string()) == u &&
      @strconv.parse_int64(s) == n.to_int64() &&
      @strconv.parse_double(s) == n.to_double() &&
      (n < 0 || @strconv.parse_int("+" + s) == n)
    },
    count=500,
  )
}

///|
/// Underscores between digits are documented as pure readability sugar: they
/// must not change the parsed value, for integers and doubles alike.
#warnings("-deprecated")
test "quickcheck: an underscore between digits never changes the value" {
  @quickcheck.check(
    (input : (((Byte, Byte, Byte, Byte), (Byte, Byte, Byte, Byte)), UInt)) => {
      let (q, pos_seed) = input
      let u = u64_of_bytes(q)
      let s = u.to_string()
      guard s.length() >= 2 else { return true }
      // Any interior position sits between two digits.
      let pos = 1 +
        (pos_seed % (s.length() - 1).reinterpret_as_uint()).reinterpret_as_int()
      let with_underscore = insert_char(s, pos, '_')
      @strconv.parse_uint64(with_underscore) == u &&
      @strconv.parse_double(with_underscore) == u.to_double()
    },
    count=300,
  )
}

///|
/// The grammar accepts no decoration: a stray character that is not a digit,
/// letter, sign, dot or underscore — including whitespace — must make parsing
/// fail whether it is prepended or appended.
#warnings("-deprecated")
test "quickcheck: a stray non-numeric character is rejected" {
  @quickcheck.check(
    (input : (Int, Char)) => {
      let (n, c) = input
      let s = n.to_string()
      (try? @strconv.parse_int("\{c}\{s}")) is Err(_) &&
      (try? @strconv.parse_int("\{s}\{c}")) is Err(_) &&
      (try? @strconv.parse_double("\{c}\{s}")) is Err(_) &&
      (try? @strconv.parse_double("\{s}\{c}")) is Err(_)
    },
    filter=input => {
      !(input.1 is ('0'..='9' | 'a'..='z' | 'A'..='Z' | '_' | '+' | '-' | '.'))
    },
    count=300,
  )
}

///|
/// Small-grammar fuzz: every string of the shape
/// `[-]digits[.digits][e[-]digits]` must either parse — and then the parsed
/// value's own rendering must reparse to the same bits (a fixed point) — or
/// fail with a range error, which is only legitimate for a genuinely huge
/// exponent (overflow past Double::max_value; underflow flushes to zero
/// silently and never errors).
#warnings("-deprecated")
test "quickcheck: structured numeric strings parse to a printing fixed point" {
  @quickcheck.check(
    (parts : (UInt, UInt, Int, (Bool, Bool, Bool))) => {
      let (int_part, frac_part, e, (neg, with_frac, with_exp)) = parts
      let exp = e * 4
      let sb = StringBuilder::new()
      if neg {
        sb.write_char('-')
      }
      sb.write_string(int_part.to_string())
      if with_frac {
        sb.write_char('.')
        sb.write_string(frac_part.to_string())
      }
      if with_exp {
        sb.write_char('e')
        sb.write_string(exp.to_string())
      }
      let s = sb.to_string()
      match (try? @strconv.parse_double(s)) {
        Ok(p) => {
          let reparsed = @strconv.parse_double(p.to_string())
          if p.reinterpret_as_int64() == -0x8000000000000000L {
            // "-0" parses to -0.0, but the ECMAScript-style to_string renders
            // negative zero as "0", so one reparse lands on +0.0.
            reparsed.reinterpret_as_int64() == 0L
          } else {
            reparsed.reinterpret_as_int64() == p.reinterpret_as_int64()
          }
        }
        Err(_) => with_exp && exp > 250
      }
    },
    count=500,
  )
}

///|
/// Booleans round-trip too.
#warnings("-deprecated")
test "quickcheck: parse_bool inverts to_string" {
  @quickcheck.check((b : Bool) => @strconv.parse_bool(b.to_string()) == b)
}
