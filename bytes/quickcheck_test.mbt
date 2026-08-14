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
/// Maps an arbitrary integer into `0..<m` (requires `m > 0`).
fn imod(x : Int, m : Int) -> Int {
  let r = x % m
  if r < 0 {
    r + m
  } else {
    r
  }
}

///|
fn sign(x : Int) -> Int {
  if x < 0 {
    -1
  } else if x > 0 {
    1
  } else {
    0
  }
}

///|
/// Maps two arbitrary integers to a valid `(start, end)` slice range for a
/// sequence of length `len`, covering empty, full, and boundary slices.
fn pick_range(len : Int, a : Int, b : Int) -> (Int, Int) {
  let start = imod(a, len + 1)
  let end = start + imod(b, len - start + 1)
  (start, end)
}

///|
fn model_slice(arr : Array[Byte], start : Int, end : Int) -> Array[Byte] {
  let out : Array[Byte] = []
  for i in start..<end {
    out.push(arr[i])
  }
  out
}

///|
/// Shortlex order: shorter first, ties broken bytewise (the documented
/// `Compare` order for `Bytes` and `BytesView`).
fn model_shortlex(a : Array[Byte], b : Array[Byte]) -> Int {
  guard a.length() == b.length() else { return sign(a.length() - b.length()) }
  for i in 0..<a.length() {
    let cmp = a[i].to_int() - b[i].to_int()
    if cmp != 0 {
      return sign(cmp)
    }
  }
  0
}

///|
/// Pure lexicographic order by unsigned byte value, length as tiebreaker (the
/// documented `lexical_compare` order).
fn model_lex(a : Array[Byte], b : Array[Byte]) -> Int {
  let min_len = if a.length() < b.length() { a.length() } else { b.length() }
  for i in 0..<min_len {
    let cmp = a[i].to_int() - b[i].to_int()
    if cmp != 0 {
      return sign(cmp)
    }
  }
  sign(a.length() - b.length())
}

///|
fn matches_at(hay : Array[Byte], needle : Array[Byte], at : Int) -> Bool {
  for i in 0..<needle.length() {
    if hay[at + i] != needle[i] {
      return false
    }
  }
  true
}

///|
fn naive_find(hay : Array[Byte], needle : Array[Byte]) -> Int? {
  let last = hay.length() - needle.length()
  guard last >= 0 else { return None }
  for start in 0..<=last {
    if matches_at(hay, needle, start) {
      return Some(start)
    }
  }
  None
}

///|
fn naive_rev_find(hay : Array[Byte], needle : Array[Byte]) -> Int? {
  let last = hay.length() - needle.length()
  guard last >= 0 else { return None }
  for start = last; start >= 0; {
    if matches_at(hay, needle, start) {
      break Some(start)
    }
    continue start - 1
  } nobreak {
    None
  }
}

///|
test "quickcheck: from_array/to_array roundtrip, makei and from_iter agree" {
  @quickcheck.check(count=300, (arr : Array[Byte]) => {
    let bs = Bytes::from_array(arr)
    guard bs.length() == arr.length() else { return false }
    guard bs.to_array() == arr else { return false }
    guard Bytes::makei(arr.length(), i => arr[i]) == bs else { return false }
    guard Bytes::from_iter(arr.iter()) == bs else { return false }
    guard bs.iter().to_array() == arr else { return false }
    // iter2 and indexed reads agree with the model.
    for i, byte in bs.iter2() {
      guard byte == arr[i] && bs[i] == arr[i] && bs.get(i) == Some(arr[i]) else {
        return false
      }
    }
    bs.get(arr.length()) is None && bs.get(-1) is None
  })
}

///|
test "quickcheck: concat is associative, empty is identity, contents concatenate" {
  @quickcheck.check(count=300, (input : (Bytes, Bytes, Bytes)) => {
    let (a, b, c) = input
    let ab = a + b
    guard ab.length() == a.length() + b.length() else { return false }
    let model = a.to_array()
    model.append(b.to_array())
    guard ab.to_array() == model else { return false }
    guard ab + c == a + (b + c) else { return false }
    a + b"" == a && b"" + a == a
  })
}

///|
test "quickcheck: repeat matches the concatenation model" {
  @quickcheck.check(count=200, (input : (Bytes, Int)) => {
    let (bs, k) = input
    let n = imod(k, 5)
    let model : Array[Byte] = []
    for _ in 0..<n {
      model.append(bs.to_array())
    }
    bs.repeat(n).to_array() == model
  })
}

///|
test "quickcheck: views agree with array-model slices" {
  @quickcheck.check(count=300, (input : (Bytes, Int, Int)) => {
    let (bs, a, b) = input
    let arr = bs.to_array()
    let len = arr.length()
    let (start, end) = pick_range(len, a, b)
    let v = bs[start:end]
    guard v.length() == end - start else { return false }
    guard v.is_empty() == (start == end) else { return false }
    let slice = model_slice(arr, start, end)
    guard v.to_array() == slice else { return false }
    for i in 0..<v.length() {
      guard v[i] == arr[start + i] && v.get(i) == Some(arr[start + i]) else {
        return false
      }
    }
    guard v.get(v.length()) is None && v.get(-1) is None else { return false }
    guard v.iter().to_array() == slice else { return false }
    for i, byte in v.iter2() {
      guard byte == slice[i] else { return false }
    }
    // View bookkeeping is observable and consistent.
    guard v.data() == bs && v.start_offset() == start else { return false }
    guard v.to_owned() == Bytes::from_array(slice) else { return false }
    // Default arguments of slicing.
    guard bs[start:] == bs[start:len] &&
      bs[:end] == bs[0:end] &&
      bs[:] == bs[0:len] else {
      return false
    }
    // get_view mirrors the aborting slice on valid input and rejects invalid
    // ranges instead of aborting.
    guard bs.get_view(start~, end~) == Some(v) else { return false }
    guard bs.get_view(start=-1) is None else { return false }
    guard bs.get_view(end=len + 1) is None else { return false }
    guard start == end || bs.get_view(start=end, end=start) is None else {
      return false
    }
    // Reading through views never disturbs the immutable parent.
    bs.to_array() == arr
  })
}

///|
test "quickcheck: view-of-view offsets compose" {
  @quickcheck.check(count=300, (input : (Bytes, (Int, Int), (Int, Int))) => {
    let (bs, (a, b), (c, d)) = input
    let arr = bs.to_array()
    let (i, j) = pick_range(arr.length(), a, b)
    let outer = bs[i:j]
    let (k, l) = pick_range(outer.length(), c, d)
    let inner = outer[k:l]
    // b[i:j][k:l] == b[i+k : i+l]
    guard inner == bs[i + k:i + l] else { return false }
    guard inner.to_array() == model_slice(arr, i + k, i + l) else {
      return false
    }
    guard inner.data() == bs && inner.start_offset() == i + k else {
      return false
    }
    // get_view on views composes the same way.
    guard outer.get_view(start=k, end=l) == Some(inner) else { return false }
    guard outer.get_view(end=outer.length() + 1) is None else { return false }
    // One more level of nesting: full and empty sub-views.
    guard inner[:] == inner && inner[0:0] == bs[i + k:i + k] else {
      return false
    }
    guard inner.to_owned().to_array() == inner.to_array() else { return false }
    bs.to_array() == arr
  })
}

///|
test "quickcheck: compare is shortlex, lexical_compare is lexicographic, both unsigned" {
  // Bias generation toward bytes >= 0x80: a signed-byte comparison bug is
  // invisible on low bytes, so mix raw, high-biased, and boundary values.
  @quickcheck.check(count=300, (input : (Array[Byte], Array[Byte], Bool)) => {
    let (raw_a, raw_b, bias) = input
    let tweak = (x : Byte) => if bias { x | 0x80 } else { x }
    let a = raw_a.map(tweak)
    let b = raw_b.map(tweak)
    let ba = Bytes::from_array(a)
    let bb = Bytes::from_array(b)
    guard sign(ba.compare(bb)) == model_shortlex(a, b) else { return false }
    guard sign(ba.lexical_compare(bb)) == model_lex(a, b) else { return false }
    guard sign(ba[:].compare(bb)) == model_shortlex(a, b) else { return false }
    guard sign(ba[:].lexical_compare(bb)) == model_lex(a, b) else {
      return false
    }
    // A byte on each side of the 0x7F/0x80 boundary must order unsigned.
    let lo = ba + b"\x7f"
    let hi = ba + b"\x80"
    guard lo.compare(hi) < 0 && lo.lexical_compare(hi) < 0 else { return false }
    // Eq, Compare, and the array model agree on equality.
    guard (ba == bb) == (a == b) else { return false }
    guard (ba.compare(bb) == 0) == (ba == bb) else { return false }
    guard ba[:].equal_to_bytes(bb) == (ba == bb) else { return false }
    true
  })
}

///|
test "quickcheck: equal bytes and equal views hash equally, at any offset" {
  @quickcheck.check(count=300, (input : (Array[Byte], Int)) => {
    let (arr, p) = input
    let bs = Bytes::from_array(arr)
    let copy = Bytes::from_array(arr)
    guard bs == copy && bs.hash() == copy.hash() else { return false }
    // Bytes and its full view are the same sequence, so they hash the same.
    guard bs.hash() == bs[:].hash() else { return false }
    // The same content embedded at a different offset in a different backing
    // buffer hashes the same through a view.
    let pad_len = 1 + imod(p, 7)
    let shifted = (Bytes::make(pad_len, b'\xaa') + bs + b"\x55")[pad_len:pad_len +
      bs.length()]
    guard shifted.equal_to_bytes(bs) else { return false }
    shifted.hash() == bs[:].hash()
  })
}

///|
/// A small alphabet crossing the 0x7F/0x80 boundary: forces frequent matches,
/// dense false candidates, and sign-sensitive byte values.
fn boundary_alphabet(x : Byte) -> Byte {
  match x.to_int() % 4 {
    0 => b'\x7e'
    1 => b'\x7f'
    2 => b'\x80'
    _ => b'\x81'
  }
}

///|
test "quickcheck: find/rev_find agree with a naive scan (bytes and views)" {
  @quickcheck.check(count=300, (input : (Array[Byte], (Int, Int), (Int, Int))) => {
    let (raw, (a, b), (c, d)) = input
    let hay = raw.map(boundary_alphabet)
    let bs = Bytes::from_array(hay)
    let len = hay.length()
    // The needle is a slice of the haystack, so it genuinely occurs.
    let (ns, ne) = pick_range(len, a, b)
    let needle = model_slice(hay, ns, ne)
    let nb = Bytes::from_array(needle)
    guard bs.find(nb) == naive_find(hay, needle) else { return false }
    guard bs.rev_find(nb) == naive_rev_find(hay, needle) else { return false }
    // Aliasing: the needle as a view of the same backing bytes.
    guard bs.find(bs[ns:ne]) == naive_find(hay, needle) else { return false }
    guard bs.rev_find(bs[ns:ne]) == naive_rev_find(hay, needle) else {
      return false
    }
    // Empty pattern semantics.
    guard bs.find(b"") == Some(0) && bs.rev_find(b"") == Some(len) else {
      return false
    }
    // Search inside a random view: offsets must not leak into results.
    let (hs, he) = pick_range(len, c, d)
    let hv = bs[hs:he]
    let hay_slice = model_slice(hay, hs, he)
    guard hv.find(nb) == naive_find(hay_slice, needle) else { return false }
    guard hv.rev_find(nb) == naive_rev_find(hay_slice, needle) else {
      return false
    }
    // A perturbed needle may or may not occur; the model decides.
    if needle.length() > 0 {
      let mutated = needle.copy()
      mutated[imod(a, mutated.length())] = b'\x00'
      let mb = Bytes::from_array(mutated)
      guard bs.find(mb) == naive_find(hay, mutated) else { return false }
      guard bs.rev_find(mb) == naive_rev_find(hay, mutated) else {
        return false
      }
    }
    true
  })
}

///|
test "quickcheck: long needles (Rabin-Karp/long-scanner paths) agree with naive scan" {
  @quickcheck.check(count=150, (input : (Array[Byte], (Int, Int))) => {
    let (raw, (a, b)) = input
    // Two-symbol alphabet over a doubled buffer: long haystacks packed with
    // false candidates, driving the long-pattern and Rabin-Karp fallbacks.
    let half = raw.map(x => if x.to_int() % 2 == 0 { b'\x80' } else { b'\x7f' })
    let hay = half.copy()
    hay.append(half)
    hay.append(half)
    let bs = Bytes::from_array(hay)
    let len = hay.length()
    let ns = imod(a, len + 1)
    // Prefer needles longer than the 32-byte short-pattern cutoff.
    let ne = ns + imod(b, len - ns + 1)
    let needle = model_slice(hay, ns, ne)
    let nb = Bytes::from_array(needle)
    guard bs.find(nb) == naive_find(hay, needle) else { return false }
    guard bs.rev_find(nb) == naive_rev_find(hay, needle) else { return false }
    // A needle that shares a long prefix with the haystack but cannot occur.
    let miss = needle.copy()
    miss.push(b'\x00')
    let mb = Bytes::from_array(miss)
    guard bs.find(mb) == naive_find(hay, miss) else { return false }
    bs.rev_find(mb) == naive_rev_find(hay, miss)
  })
}

///|
test "quickcheck: prefix/suffix predicates and chops agree with the model" {
  @quickcheck.check(count=300, (input : (Array[Byte], (Int, Int))) => {
    let (raw, (a, b)) = input
    let arr = raw.map(boundary_alphabet)
    let bs = Bytes::from_array(arr)
    let len = arr.length()
    // A genuine prefix and a genuine suffix.
    let pre_len = imod(a, len + 1)
    let suf_len = imod(b, len + 1)
    let prefix = model_slice(arr, 0, pre_len)
    let suffix = model_slice(arr, len - suf_len, len)
    let pb = Bytes::from_array(prefix)
    let sb = Bytes::from_array(suffix)
    guard bs.has_prefix(pb) && bs.has_suffix(sb) else { return false }
    guard bs.chop_prefix(pb) == Some(bs[pre_len:]) else { return false }
    guard bs.chop_suffix(sb) == Some(bs[:len - suf_len]) else { return false }
    guard bs.chop_prefix(pb).unwrap().to_array() ==
      model_slice(arr, pre_len, len) else {
      return false
    }
    // An arbitrary candidate agrees with the model definition.
    let cand = model_slice(arr, imod(b, len + 1), len).map(x => {
      x ^ (if a % 2 == 0 { b'\x00' } else { b'\x01' })
    })
    let cb = Bytes::from_array(cand)
    let model_is_prefix = cand.length() <= len && matches_at(arr, cand, 0)
    let model_is_suffix = cand.length() <= len &&
      matches_at(arr, cand, len - cand.length())
    guard bs.has_prefix(cb) == model_is_prefix else { return false }
    guard bs.has_suffix(cb) == model_is_suffix else { return false }
    guard (bs.chop_prefix(cb) is Some(_)) == model_is_prefix else {
      return false
    }
    guard (bs.chop_suffix(cb) is Some(_)) == model_is_suffix else {
      return false
    }
    // The same predicates through a view with a nonzero offset.
    let shifted = (b"\xaa" + bs)[1:]
    guard shifted.has_prefix(pb) && shifted.has_suffix(sb) else { return false }
    guard shifted.chop_prefix(pb).unwrap().to_array() ==
      model_slice(arr, pre_len, len) else {
      return false
    }
    true
  })
}
