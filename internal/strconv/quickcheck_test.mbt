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

// Specification tests for the integer parsers.
//
// The oracle below is written from the documented grammar, not from the
// implementation: sign, optional base prefix, digits separated by single
// underscores, every digit below the base, and a magnitude that fits the
// target type. Accumulation is done in `UInt64` with an exact
// `acc > (limit - d) / base` overflow test, so the oracle's notion of "out
// of range" does not depend on the same threshold arithmetic the
// implementation uses.
//
// The inputs are short strings over an alphabet chosen to sit on the
// grammar's boundaries — digits either side of every base, letters either
// side of 'f' and 'z', both cases, the prefix letters, underscore, both
// signs, and two characters that are never valid.

///|
let alphabet : Array[Char] = [
  '0', '1', '7', '8', '9', 'a', 'f', 'g', 'z', 'A', 'F', 'Z', '_', '+', '-', 'x',
  'X', 'o', 'O', 'b', 'B', ' ', '.',
]

///|
/// Bases worth trying: 0 (infer), every base with a prefix, the two
/// endpoints of the valid range, a couple of ordinary ones, and three
/// invalid ones.
let bases : Array[Int] = [0, 2, 8, 10, 16, 36, 3, 7, 35, 1, 37, -1]

///|
fn wrap_index(value : Int, modulus : Int) -> Int {
  let r = value % modulus
  if r < 0 {
    r + modulus
  } else {
    r
  }
}

///|
fn make_text(codes : ArrayView[Int]) -> String {
  String::from_array(
    Array::makei(codes.length(), i => {
      alphabet[wrap_index(codes[i], alphabet.length())]
    }),
  )
}

///|
/// The digit value of `c` in base 36, or `None` if it is not a digit.
fn digit_value(c : Char) -> Int? {
  let n = c.to_int()
  if n >= '0' && n <= '9' {
    Some(n - '0')
  } else if n >= 'a' && n <= 'z' {
    Some(n - 'a' + 10)
  } else if n >= 'A' && n <= 'Z' {
    Some(n - 'A' + 10)
  } else {
    None
  }
}

///|
/// The base a prefix introduces, if `chars[i..]` starts with one.
fn prefix_base(chars : ArrayView[Char], i : Int) -> Int? {
  if i + 1 >= chars.length() || chars[i] != '0' {
    return None
  }
  match chars[i + 1] {
    'x' | 'X' => Some(16)
    'o' | 'O' => Some(8)
    'b' | 'B' => Some(2)
    _ => None
  }
}

///|
/// Shared front end: validates the base, consumes a sign if `signed`, and
/// consumes a base prefix when it agrees with `base`. Returns the sign, the
/// effective base, the index of the first digit, and whether an underscore
/// may lead the digits (only just after a prefix).
fn scan_prefix(
  chars : ArrayView[Char],
  base : Int,
  signed : Bool,
) -> (Bool, Int, Int, Bool)? {
  guard base == 0 || (base >= 2 && base <= 36) else { return None }
  guard chars.length() > 0 else { return None }
  let mut i = 0
  let mut neg = false
  if chars[0] is ('+' | '-') {
    guard signed else { return None }
    neg = chars[0] == '-'
    i = 1
  }
  match prefix_base(chars, i) {
    Some(p) if base == 0 || base == p => Some((neg, p, i + 2, true))
    _ => Some((neg, if base == 0 { 10 } else { base }, i, false))
  }
}

///|
/// The digits of `chars[start..]` in `base`, or `None` if the digit/underscore
/// grammar is violated. `lead_underscore` says whether a single underscore may
/// come first (it may, exactly when a prefix was just consumed).
fn scan_digits(
  chars : ArrayView[Char],
  start : Int,
  base : Int,
  lead_underscore : Bool,
) -> Array[Int]? {
  let digits = []
  let mut underscore_ok = lead_underscore
  let mut after_underscore = false
  for i in start..<chars.length() {
    if chars[i] == '_' {
      guard underscore_ok else { return None }
      underscore_ok = false
      after_underscore = true
    } else {
      guard digit_value(chars[i]) is Some(d) && d < base else { return None }
      digits.push(d)
      underscore_ok = true
      after_underscore = false
    }
  }
  // A trailing underscore, or no digit at all, is not a number.
  guard !after_underscore && digits.length() > 0 else { return None }
  Some(digits)
}

///|
/// Folds `digits` in `base`, or `None` if the magnitude exceeds `limit`.
/// Exact: `acc * base + d <= limit` iff `acc <= (limit - d) / base`.
fn fold_digits(digits : ArrayView[Int], base : Int, limit : UInt64) -> UInt64? {
  let b = base.to_uint64()
  let mut acc = 0UL
  for d in digits {
    let dv = d.to_uint64()
    guard acc <= (limit - dv) / b else { return None }
    acc = acc * b + dv
  }
  Some(acc)
}

///|
/// Reference `parse_int64`. `None` means "must be rejected".
fn oracle_int64(text : String, base : Int) -> Int64? {
  let chars = text.to_array()[:]
  guard scan_prefix(chars, base, true) is Some((neg, eff, start, lead)) else {
    return None
  }
  guard scan_digits(chars, start, eff, lead) is Some(digits) else {
    return None
  }
  // Two's complement: the negative range reaches one further than the
  // positive one.
  let limit = if neg { 0x8000000000000000UL } else { 0x7fffffffffffffffUL }
  guard fold_digits(digits, eff, limit) is Some(magnitude) else { return None }
  let v = magnitude.reinterpret_as_int64()
  Some(if neg { 0L - v } else { v })
}

///|
/// Reference `parse_uint64`. Signs are not part of the grammar here.
fn oracle_uint64(text : String, base : Int) -> UInt64? {
  let chars = text.to_array()[:]
  guard scan_prefix(chars, base, false) is Some((_, eff, start, lead)) else {
    return None
  }
  guard scan_digits(chars, start, eff, lead) is Some(digits) else {
    return None
  }
  fold_digits(digits, eff, 0xffffffffffffffffUL)
}

///|
fn actual_int64(text : String, base : Int) -> Int64? {
  Some(@strconv.parse_int64(text, base~)) catch {
    _ => None
  }
}

///|
fn actual_int(text : String, base : Int) -> Int? {
  Some(@strconv.parse_int(text, base~)) catch {
    _ => None
  }
}

///|
fn actual_uint64(text : String, base : Int) -> UInt64? {
  Some(@strconv.parse_uint64(text, base~)) catch {
    _ => None
  }
}

///|
fn actual_uint(text : String, base : Int) -> UInt? {
  Some(@strconv.parse_uint(text, base~)) catch {
    _ => None
  }
}

// =====================================================================
// Well-formed numerals, biased at the type boundaries.
//
// Random text is good at the grammar but almost never long enough to
// overflow: `Int64` needs 19 decimal digits. These properties render a
// magnitude in the target base instead — with every combination of sign,
// prefix, and interior underscores the grammar allows — and bias the
// magnitude towards the values where a threshold is off by one.
// =====================================================================

///|
/// Magnitudes where an overflow check can be wrong by one.
let boundaries : Array[UInt64] = [
  0, 1, 0x7ffffffe, 0x7fffffff, 0x80000000, 0x80000001, 0xfffffffe, 0xffffffff, 0x100000000,
  0x7ffffffffffffffe, 0x7fffffffffffffff, 0x8000000000000000, 0x8000000000000001,
  0xfffffffffffffffe, 0xffffffffffffffff,
]

///|
/// `choice` either keeps the generated magnitude or swaps in a boundary,
/// so a run covers both the bulk of the space and its edges.
fn pick_magnitude(raw : UInt64, choice : Int) -> UInt64 {
  if choice % 2 == 0 {
    boundaries[wrap_index(choice / 2, boundaries.length())]
  } else {
    raw
  }
}

///|
/// Renders `magnitude` in `base`. `flags` selects the sign, whether a base
/// prefix is emitted (only where one exists and agrees), the digit case,
/// and which gaps between digits get an underscore.
fn render(magnitude : UInt64, base : Int, flags : Int) -> String {
  let digits = []
  let b = base.to_uint64()
  let mut n = magnitude
  if n == 0 {
    digits.push(0)
  }
  while n > 0 {
    digits.push((n % b).to_int())
    n = n / b
  }
  digits.rev_in_place()
  let upper = flags / 2 % 2 == 0
  let out = StringBuilder::new()
  match flags % 4 {
    1 => out.write_char('+')
    2 => out.write_char('-')
    _ => ()
  }
  if flags / 4 % 2 == 0 {
    match base {
      16 => out.write_string("0x")
      8 => out.write_string("0o")
      2 => out.write_string("0b")
      _ => ()
    }
  }
  for i, d in digits {
    // An underscore may sit between any two digits; the bit pattern of
    // `flags` decides which gaps take one.
    if i > 0 && flags / 8 / (1 << (i % 20)) % 2 == 1 {
      out.write_char('_')
    }
    let c = if d < 10 {
      (d + '0').unsafe_to_char()
    } else if upper {
      (d - 10 + 'A').unsafe_to_char()
    } else {
      (d - 10 + 'a').unsafe_to_char()
    }
    out.write_char(c)
  }
  out.to_string()
}

///|
test "quickcheck: signed numerals at the type boundaries" {
  @quickcheck.check(
    (input : (UInt64, Int, Int, Int)) => {
      let (raw, choice, base_code, flags) = input
      let base = bases[wrap_index(base_code, bases.length())]
      let render_base = if base is (2..=36) { base } else { 10 }
      let text = render(pick_magnitude(raw, choice), render_base, flags)
      actual_int64(text, base) == oracle_int64(text, base) &&
      actual_int(text, base) ==
      (match oracle_int64(text, base) {
        Some(v) if v >= -2147483648L && v <= 2147483647L => Some(v.to_int())
        _ => None
      })
    },
    count=20000,
  )
}

///|
test "quickcheck: unsigned numerals at the type boundaries" {
  @quickcheck.check(
    (input : (UInt64, Int, Int, Int)) => {
      let (raw, choice, base_code, flags) = input
      let base = bases[wrap_index(base_code, bases.length())]
      let render_base = if base is (2..=36) { base } else { 10 }
      let text = render(pick_magnitude(raw, choice), render_base, flags)
      actual_uint64(text, base) == oracle_uint64(text, base) &&
      actual_uint(text, base) ==
      (match oracle_uint64(text, base) {
        Some(v) if v <= 0xffffffffUL => Some(v.to_uint())
        _ => None
      })
    },
    count=20000,
  )
}

///|
test "quickcheck: parse_int64 agrees with the grammar" {
  @quickcheck.check(
    (input : (Int, Array[Int])) => {
      let (base_code, codes) = input
      let base = bases[wrap_index(base_code, bases.length())]
      let text = make_text(codes)
      actual_int64(text, base) == oracle_int64(text, base)
    },
    count=20000,
  )
}

///|
test "quickcheck: parse_uint64 agrees with the grammar" {
  @quickcheck.check(
    (input : (Int, Array[Int])) => {
      let (base_code, codes) = input
      let base = bases[wrap_index(base_code, bases.length())]
      let text = make_text(codes)
      actual_uint64(text, base) == oracle_uint64(text, base)
    },
    count=20000,
  )
}

///|
test "quickcheck: parse_int is parse_int64 narrowed to 32 bits" {
  @quickcheck.check(
    (input : (Int, Array[Int])) => {
      let (base_code, codes) = input
      let base = bases[wrap_index(base_code, bases.length())]
      let text = make_text(codes)
      let expected = match oracle_int64(text, base) {
        Some(v) if v >= -2147483648L && v <= 2147483647L => Some(v.to_int())
        _ => None
      }
      actual_int(text, base) == expected
    },
    count=20000,
  )
}

///|
test "quickcheck: parse_uint is parse_uint64 narrowed to 32 bits" {
  @quickcheck.check(
    (input : (Int, Array[Int])) => {
      let (base_code, codes) = input
      let base = bases[wrap_index(base_code, bases.length())]
      let text = make_text(codes)
      let expected = match oracle_uint64(text, base) {
        Some(v) if v <= 0xffffffffUL => Some(v.to_uint())
        _ => None
      }
      actual_uint(text, base) == expected
    },
    count=20000,
  )
}
