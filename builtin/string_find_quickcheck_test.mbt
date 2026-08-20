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

// Randomized equivalence properties for find/rev_find against the naive
// references in string_find_fallback_test.mbt. The first property samples
// arbitrary two-symbol texts (dense candidate collisions arise naturally,
// so the early ratio cutover gets random coverage); the second builds
// inputs that provably exhaust the cutover budget in both directions with
// randomized needle shapes and hit mixtures, so the KMP fallback itself
// is fuzzed.

///|
fn bools_to_ab(bits : Array[Bool]) -> String {
  let sb = StringBuilder(size_hint=bits.length())
  for b in bits {
    sb.write_char(if b { 'a' } else { 'b' })
  }
  sb.to_string()
}

///|
test "quickcheck: find and rev_find agree with naive references" {
  @quickcheck.check(
    (input : (Array[Bool], Array[Bool])) => {
      let (text_bits, needle_bits) = input
      let text = bools_to_ab(text_bits)
      // clamp the needle into the multi-unit regime the two-anchor search
      // handles; single-unit and empty needles take separate code paths
      guard needle_bits.length() >= 2 else { return true }
      let needle = bools_to_ab(needle_bits)
      text.find(needle) == naive_find(text, needle) &&
      text.rev_find(needle) == naive_rev_find(text, needle)
    },
    count=200,
  )
}

///|
test "quickcheck: fallback-forcing inputs agree with naive references" {
  @quickcheck.check(
    (input : (UInt, UInt, UInt, Array[Bool])) => {
      let (p0, q0, flip0, mix) = input
      // needle 'a'*p + 'b' + 'a'*q: anchors are 'a'/'a' (or 'a'/'b' when
      // q == 0), interior mostly 'a' — the adversarial family
      let p = (p0 % 14).reinterpret_as_int() + 1
      let q = (q0 % 15).reinterpret_as_int()
      let needle = String::make(p, 'a') + "b" + String::make(q, 'a')
      let m = needle.length()
      guard m >= 3 else { return true }
      // corrupted block: one interior char flipped, anchors intact, so a
      // block-start candidate passes the anchor test and fails verification
      let flip = 1 +
        (flip0 % (m - 2).reinterpret_as_uint()).reinterpret_as_int()
      let sb = StringBuilder(size_hint=m)
      for i in 0..<m {
        let c = needle.unsafe_get(i)
        if i == flip {
          sb.write_char(if c == 'a' { 'b' } else { 'a' })
        } else {
          sb.write_char(if c == 'a' { 'a' } else { 'b' })
        }
      }
      let corrupted = sb.to_string()
      guard corrupted != needle else { return true }
      // 70 corrupted blocks on each side exhaust the budget in both
      // directions before any mixture hit; the mixture randomizes genuine
      // occurrences and further decoys in the middle
      let buf = StringBuilder(size_hint=(mix.length() + 140) * m)
      for _ in 0..<70 {
        buf.write_string(corrupted)
      }
      for hit in mix {
        buf.write_string(if hit { needle } else { corrupted })
      }
      for _ in 0..<70 {
        buf.write_string(corrupted)
      }
      let text = buf.to_string()
      text.find(needle) == naive_find(text, needle) &&
      text.rev_find(needle) == naive_rev_find(text, needle)
    },
    count=25,
  )
}
