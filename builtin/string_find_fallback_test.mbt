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

// End-to-end coverage for the guaranteed-linear KMP fallback behind the
// SIMD two-anchor substring search. The cutover has two triggers: an
// early ratio check (`failures > 4 + scanned / 8`) and a hard cap
// (`failures > 64`). The decoy constructions here space their false
// candidates one period apart, which keeps the ratio check quiet, so
// these tests deterministically force the HARD-CAP path by providing
// more than 65 positions where both anchor code units match but
// verification fails, in the direction under test, before the
// interesting region — misses, hits beyond the cutover point,
// overlapping hits resolved through the fallback, and naive-reference
// cross-checks.

///|
fn adversarial_needle() -> String {
  // both anchors are 'a' and a 32-unit prefix of the needle recurs at every
  // position of an all-'a' haystack: every candidate passes the anchor test
  // and fails only deep inside verification
  String::make(32, 'a') + "Z" + String::make(31, 'a')
}

///|
test "dense-anchor miss stays correct through the kmp fallback" {
  let haystack = String::make(4096, 'a')
  debug_inspect(haystack.find(adversarial_needle()), content="None")
  debug_inspect(haystack.rev_find(adversarial_needle()), content="None")
}

///|
test "hit located after the cutover point is found" {
  let needle = adversarial_needle()
  let haystack = String::make(2000, 'a') + needle + String::make(50, 'a')
  debug_inspect(haystack.find(needle), content="Some(2000)")
  debug_inspect(haystack.rev_find(needle), content="Some(2000)")
  // a second occurrence: find returns the first, rev_find the last
  let doubled = String::make(1000, 'a') +
    needle +
    String::make(1000, 'a') +
    needle
  debug_inspect(doubled.find(needle), content="Some(1000)")
  debug_inspect(doubled.rev_find(needle), content="Some(2064)")
}

///|
// One decoy block per repetition: for the periodic needle used below
// (anchors 'a' and 'b', length 82), each block contributes exactly one
// position whose anchors match but whose interior verification fails.
fn decoy_blocks(count : Int) -> String {
  (String::make(81, 'a') + "b").repeat(count)
}

///|
// 40a b 40a b 40a b: contains the 82-unit needle 40a b 40a b at
// offsets 0 and 41 — two overlapping occurrences.
fn overlapping_hits_block() -> String {
  let half = String::make(40, 'a') + "b"
  half + half + half
}

///|
test "forward cutover then kmp finds the first hit" {
  let needle = String::make(40, 'a') + "b" + String::make(40, 'a') + "b"
  // 70 false candidates precede the hits, exhausting the 65-failure budget;
  // the first genuine occurrence straddles the last decoy block and the
  // hits block (40 decoy 'a's, the decoy 'b' at 5739, 40 hit 'a's, and the
  // hit 'b' at 5780), so kmp must report 5699, not the hits-block start
  let haystack = decoy_blocks(70) + overlapping_hits_block()
  debug_inspect(haystack.find(needle), content="Some(5699)")
}

///|
test "reverse cutover then kmp keeps the rightmost overlapping hit" {
  let needle = String::make(40, 'a') + "b" + String::make(40, 'a') + "b"
  // hits sit at the start; 70 false candidates follow them, so the reverse
  // scan burns its budget before reaching the hits and hands off to the
  // kmp fallback, which must resolve the overlap to the rightmost start
  let haystack = overlapping_hits_block() + decoy_blocks(70)
  debug_inspect(haystack.rev_find(needle), content="Some(41)")
  // sanity: the forward search over the same input needs no fallback
  debug_inspect(haystack.find(needle), content="Some(0)")
}

///|
fn naive_find(haystack : String, needle : String) -> Int? {
  let n = haystack.length()
  let m = needle.length()
  for start in 0..<=(n - m) {
    let matched = for i in 0..<m {
      if haystack.unsafe_get(start + i) != needle.unsafe_get(i) {
        break false
      }
    } nobreak {
      true
    }
    if matched {
      break Some(start)
    }
  } nobreak {
    None
  }
}

///|
fn naive_rev_find(haystack : String, needle : String) -> Int? {
  let n = haystack.length()
  let m = needle.length()
  for start = n - m; start >= 0; {
    let matched = for i in 0..<m {
      if haystack.unsafe_get(start + i) != needle.unsafe_get(i) {
        break false
      }
    } nobreak {
      true
    }
    if matched {
      break Some(start)
    }
    continue start - 1
  } nobreak {
    None
  }
}

///|
test "fallback and fast paths agree with naive references" {
  let needle = String::make(40, 'a') + "b" + String::make(40, 'a') + "b"
  let hits = overlapping_hits_block()
  // decoys 0 (fast path) and 70 (fallback path); hits absent / leading /
  // trailing / embedded; checked in both directions
  for decoys in [0, 70] {
    let d = decoy_blocks(decoys)
    for text in [d, d + hits, hits + d, d + hits + d] {
      assert_eq(text.find(needle), naive_find(text, needle))
      assert_eq(text.rev_find(needle), naive_rev_find(text, needle))
    }
  }
  // adversarial all-'a' shapes against the references as well
  let adv = adversarial_needle()
  for
    text in [
      String::make(300, 'a'),
      String::make(200, 'a') + adv,
      adv + String::make(200, 'a'),
    ] {
    assert_eq(text.find(adv), naive_find(text, adv))
    assert_eq(text.rev_find(adv), naive_rev_find(text, adv))
  }
}
