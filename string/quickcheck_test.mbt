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

// Property tests pinning the optimized string fast paths (SIMD case
// conversion, specialized UInt16 code-unit comparisons, substring search)
// against naive reference implementations. The references deliberately avoid
// the code paths under test: case mapping goes char by char through `Char`,
// and comparisons go through `Int` rather than `UInt16` operators.

///|
/// ASCII-only lowercase reference: documented spec of `to_lower` maps only
/// 'A'..'Z'; every other character is copied unchanged.
fn qc_lower_ref(s : String) -> String {
  String::from_iter(
    s
    .iter()
    .map(c => {
      if c >= 'A' && c <= 'Z' {
        (c.to_int() + 32).to_char().unwrap()
      } else {
        c
      }
    }),
  )
}

///|
/// ASCII-only uppercase reference mirroring `qc_lower_ref`.
fn qc_upper_ref(s : String) -> String {
  String::from_iter(
    s
    .iter()
    .map(c => {
      if c >= 'a' && c <= 'z' {
        (c.to_int() - 32).to_char().unwrap()
      } else {
        c
      }
    }),
  )
}

///|
fn qc_sign(x : Int) -> Int {
  if x < 0 {
    -1
  } else if x > 0 {
    1
  } else {
    0
  }
}

///|
/// Shortlex reference for `String::compare`: shorter strings sort first, equal
/// lengths fall back to UTF-16 code-unit order. Comparisons go through `Int`
/// so the specialized `UInt16` operators stay out of the reference.
fn qc_shortlex_ref(a : String, b : String) -> Int {
  let au = a.code_units()
  let bu = b.code_units()
  if au.length() != bu.length() {
    return au.length().compare(bu.length())
  }
  for i in 0..<au.length() {
    let x = au[i].to_int()
    let y = bu[i].to_int()
    if x != y {
      return x.compare(y)
    }
  }
  0
}

///|
/// Plain lexicographic reference for `lexical_compare`: code-unit order with
/// the prefix rule, again routed through `Int`.
fn qc_lexical_ref(a : String, b : String) -> Int {
  let au = a.code_units()
  let bu = b.code_units()
  let min_len = if au.length() < bu.length() {
    au.length()
  } else {
    bu.length()
  }
  for i in 0..<min_len {
    let x = au[i].to_int()
    let y = bu[i].to_int()
    if x != y {
      return x.compare(y)
    }
  }
  au.length().compare(bu.length())
}

///|
/// Naive first-occurrence scan over UTF-16 code units, the specification for
/// `String::find` / `String::contains`.
fn qc_naive_find(s : String, pat : String) -> Int? {
  let su = s.code_units()
  let pu = pat.code_units()
  let n = su.length()
  let m = pu.length()
  if m > n {
    return None
  }
  for i in 0..<(n - m + 1) {
    for j in 0..<m {
      if su[i + j].to_int() != pu[j].to_int() {
        break
      }
    } nobreak {
      return Some(i)
    }
  }
  None
}

///|
/// Chars sitting exactly on the boundaries that the SIMD range checks and the
/// UInt16 comparison specialization must get right: the edges of 'A'..'Z' and
/// 'a'..'z', their immediate neighbours, the ASCII/non-ASCII frontier
/// (0x7F/0x80), 0xFF/0x100, the BMP extremes around the surrogate range, and
/// supplementary-plane chars that encode as surrogate pairs in UTF-16.
let qc_boundary_chars : Array[Char] = [
  '@', 'A', 'B', 'Y', 'Z', '[', '`', 'a', 'b', 'y', 'z', '{', '0', ' ', '\u{7F}',
  '\u{80}', '\u{FF}', '\u{100}', '\u{D7FF}', '\u{E000}', '\u{FFFE}', '\u{FFFF}',
  '\u{10000}', '\u{1F600}', '\u{10FFFF}',
]

///|
fn qc_boundary_string(picks : Array[UInt]) -> String {
  String::from_iter(
    picks
    .iter()
    .map(u => {
      qc_boundary_chars[(u % qc_boundary_chars.length().reinterpret_as_uint()).reinterpret_as_int()]
    }),
  )
}

///|
test "quickcheck: to_lower/to_upper match the ASCII char-by-char reference" {
  @quickcheck.check(
    (s : String) => {
      s.to_lower() == qc_lower_ref(s) && s.to_upper() == qc_upper_ref(s)
    },
    count=500,
  )
}

///|
test "quickcheck: case conversion on boundary code points" {
  // Dense coverage of chars adjacent to the case ranges, where an
  // off-by-one in the SIMD range check or a signedness slip in the UInt16
  // comparison would flip the result.
  @quickcheck.check(
    (picks : Array[UInt]) => {
      let s = qc_boundary_string(picks)
      s.to_lower() == qc_lower_ref(s) && s.to_upper() == qc_upper_ref(s)
    },
    count=500,
  )
}

///|
test "quickcheck: case conversion across SIMD block boundaries" {
  // Slide the first uppercase char through positions 0..69 so the scalar
  // prefix (< 24 units), full 8-lane vector blocks, and the scalar tail of
  // the SIMD search are all exercised, with arbitrary content after it.
  @quickcheck.check(
    (arg : (UInt, String)) => {
      let (n, s) = arg
      let pad = "x".repeat((n % 70).reinterpret_as_int())
      let source = pad + "A" + s
      source.to_lower() == pad + "a" + qc_lower_ref(s) &&
      source.to_lower().length() == source.length()
    },
    count=300,
  )
}

///|
test "quickcheck: case conversion laws" {
  @quickcheck.check(
    (s : String) => {
      let lower = s.to_lower()
      let upper = s.to_upper()
      // Idempotence.
      lower.to_lower() == lower &&
      upper.to_upper() == upper &&
      // ASCII case mapping is length-preserving.
      lower.length() == s.length() &&
      upper.length() == s.length() &&
      // Composition collapses: lowering first cannot change the uppercased
      // result and vice versa.
      lower.to_upper() == upper &&
      upper.to_lower() == lower &&
      // The String and StringView implementations are separate fast paths
      // (SIMD vs scalar vs JS fallback) and must agree.
      StringView::to_lower(s).to_owned() == lower &&
      StringView::to_upper(s).to_owned() == upper
    },
    count=500,
  )
}

///|
test "quickcheck: compare agrees with the shortlex code-unit reference" {
  @quickcheck.check(
    (arg : (String, String)) => {
      let (a, b) = arg
      qc_sign(a.compare(b)) == qc_sign(qc_shortlex_ref(a, b)) &&
      (a == b) == (a.compare(b) == 0) &&
      qc_sign(a.compare(b)) == -qc_sign(b.compare(a)) &&
      a.compare(a) == 0 &&
      (a + b).compare(a + b) == 0
    },
    count=500,
  )
}

///|
test "quickcheck: lexical_compare agrees with the lexicographic reference" {
  @quickcheck.check(
    (arg : (String, String)) => {
      let (a, b) = arg
      qc_sign(a.lexical_compare(b)) == qc_sign(qc_lexical_ref(a, b)) &&
      (a == b) == (a.lexical_compare(b) == 0) &&
      qc_sign(a.lexical_compare(b)) == -qc_sign(b.lexical_compare(a))
    },
    count=500,
  )
}

///|
test "quickcheck: comparisons are invariant under a shared prefix" {
  // Prepending a common prefix forces the comparison loops to run through a
  // long equal run before hitting the deciding code unit, which is exactly
  // where the specialized UInt16 operators do their work.
  @quickcheck.check(
    (arg : (String, String, String)) => {
      let (p, a, b) = arg
      qc_sign((p + a).lexical_compare(p + b)) == qc_sign(a.lexical_compare(b)) &&
      qc_sign((p + a).compare(p + b)) == qc_sign(a.compare(b))
    },
    count=300,
  )
}

///|
test "quickcheck: comparisons on boundary code points" {
  // Code units near 0x7F/0x80 and around 0xFFFF are where a signed/unsigned
  // mix-up in the UInt16 comparison specialization would show.
  @quickcheck.check(
    (arg : (Array[UInt], Array[UInt])) => {
      let a = qc_boundary_string(arg.0)
      let b = qc_boundary_string(arg.1)
      qc_sign(a.compare(b)) == qc_sign(qc_shortlex_ref(a, b)) &&
      qc_sign(a.lexical_compare(b)) == qc_sign(qc_lexical_ref(a, b))
    },
    count=500,
  )
}

///|
test "quickcheck: find and contains agree with a naive scan" {
  @quickcheck.check(
    (arg : (String, String, String)) => {
      let (a, b, c) = arg
      let s = a + b + c
      // A guaranteed occurrence: the result must match the naive scan (which
      // may find an earlier one) and must exist.
      s.find(b) == qc_naive_find(s, b) &&
      s.contains(b) &&
      // A pattern that usually does not occur.
      a.find(c) == qc_naive_find(a, c) &&
      a.contains(c) == (qc_naive_find(a, c) is Some(_))
    },
    count=300,
  )
}
