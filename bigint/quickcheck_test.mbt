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

// Property suite for BigInt, in the same spirit as the immut/hashmap and
// immut/hashset canonicity sweeps. Three layers:
//
// 1. An Int64 oracle: for 64-bit values, every operation must agree with
//    the machine integer result.
// 2. Construction-path invariance: `from_hex` allocates limbs exactly
//    while the decimal `from_string` path allocates slack, so a value has
//    two internal representations. Every operation must return the same
//    result through both — the generalization of the defect fixed in
//    "make bitwise ops depend on value, not construction history".
// 3. Algebraic and two's-complement laws at arbitrary precision, where no
//    oracle exists.

///|
/// Build a hex string (possibly with leading zeros) from a seed stream.
fn hex_of(seeds : ArrayView[Int]) -> String {
  let digits = "0123456789abcdef"
  let sb = StringBuilder()
  for s in seeds {
    sb.write_char(digits.get_char((s & 0x7fffffff) % 16).unwrap())
  }
  sb.to_string()
}

///|
/// A value built through the exactly-allocating hex path.
fn via_hex(seeds : ArrayView[Int], negative : Bool) -> @bigint.BigInt raise {
  let magnitude = @bigint.BigInt::from_string(hex_of(seeds), radix=16)
  if negative {
    -magnitude
  } else {
    magnitude
  }
}

///|
/// The same value rebuilt through the decimal string path.
fn via_decimal(v : @bigint.BigInt) -> @bigint.BigInt raise {
  @bigint.BigInt::from_string(v.to_string())
}

///|
/// Deterministic sweep: single-bit values through the exactly-allocating
/// hex path, at every bit position 0..=199 (crossing six limb
/// boundaries). The negation identities pin the sign-extension limb —
/// `p ^ -p = -2p` needs one more limb than `p` exactly at positions
/// `32k - 1`, the class of the "bitwise ops depend on construction
/// history" defect.
test "negation identities for every single-bit value" {
  let digits = "0123456789abcdef"
  for s in 0..<200 {
    let sb = StringBuilder()
    sb.write_char(digits.get_char(1 << (s % 4)).unwrap())
    for _i in 0..<(s / 4) {
      sb.write_char('0')
    }
    let p = @bigint.BigInt::from_string(sb.to_string(), radix=16)
    let q = @bigint.BigInt::from_string(p.to_string())
    assert_true(p == q)
    for v in ([p, q] : Array[_]) {
      assert_true((v & -v) == p)
      assert_true((v | -v) == -p)
      assert_true((v ^ -v) == -2N * p)
    }
  }
}

///|
test "quickcheck: Int64 oracle for every operation" {
  @quickcheck.check((pair : (Int64, Int64)) => {
    let (x, y) = pair
    let a = @bigint.BigInt::from_int64(x)
    let b = @bigint.BigInt::from_int64(y)
    guard (a == b) == (x == y) else { return false }
    guard a.compare(b) == x.compare(y) else { return false }
    guard (a & b) == @bigint.BigInt::from_int64(x & y) else { return false }
    guard (a | b) == @bigint.BigInt::from_int64(x | y) else { return false }
    guard (a ^ b) == @bigint.BigInt::from_int64(x ^ y) else { return false }
    // widen through Int to keep +, -, * overflow-free
    let sx = @bigint.BigInt::from_int64((x >> 33).to_int().to_int64())
    let sy = @bigint.BigInt::from_int64((y >> 33).to_int().to_int64())
    let ix = (x >> 33).to_int().to_int64()
    let iy = (y >> 33).to_int().to_int64()
    guard sx + sy == @bigint.BigInt::from_int64(ix + iy) else { return false }
    guard sx - sy == @bigint.BigInt::from_int64(ix - iy) else { return false }
    guard sx * sy == @bigint.BigInt::from_int64(ix * iy) else { return false }
    if iy != 0 {
      guard sx / sy == @bigint.BigInt::from_int64(ix / iy) else { return false }
      guard sx % sy == @bigint.BigInt::from_int64(ix % iy) else { return false }
    }
    true
  })
}

///|
test "quickcheck: every operation is construction-path invariant" {
  @quickcheck.check((input : (Array[Int], Array[Int], Bool, Bool)) => {
    let (xs, ys, xneg, yneg) = input
    guard xs.length() > 0 && ys.length() > 0 else { return true }
    let a1 = via_hex(xs, xneg)
    let b1 = via_hex(ys, yneg)
    let a2 = via_decimal(a1)
    let b2 = via_decimal(b1)
    // the two paths must be equal, hash equal, and compare equal
    guard a1 == a2 && b1 == b2 else { return false }
    guard Hash::hash(a1) == Hash::hash(a2) else { return false }
    guard a1.compare(b1) == a2.compare(b2) else { return false }
    // and every operation must give the same result through both paths
    guard (a1 & b1) == (a2 & b2) else { return false }
    guard (a1 | b1) == (a2 | b2) else { return false }
    guard (a1 ^ b1) == (a2 ^ b2) else { return false }
    guard a1 + b1 == a2 + b2 else { return false }
    guard a1 - b1 == a2 - b2 else { return false }
    guard a1 * b1 == a2 * b2 else { return false }
    if !b1.is_zero() {
      guard a1 / b1 == a2 / b2 else { return false }
      guard a1 % b1 == a2 % b2 else { return false }
    }
    let n = (xs[0] & 0x7fffffff) % 100
    guard a1 << n == a2 << n else { return false }
    guard a1 >> n == a2 >> n else { return false }
    // representation-independent renderings
    guard a1.to_string() == a2.to_string() else { return false }
    guard a1.to_string(radix=16) == a2.to_string(radix=16) else { return false }
    guard a1.to_json() == a2.to_json() else { return false }
    true
  })
}

///|
test "quickcheck: algebraic and two's-complement laws" {
  @quickcheck.check((input : (Array[Int], Array[Int], Array[Int], Bool)) => {
    let (xs, ys, zs, neg) = input
    guard xs.length() > 0 && ys.length() > 0 && zs.length() > 0 else {
      return true
    }
    let a = via_hex(xs, neg)
    let b = via_hex(ys, !neg)
    let c = via_hex(zs, neg)
    let zero = 0N
    let neg_one = -1N
    // ring laws
    guard a + b == b + a else { return false }
    guard a + b + c == a + (b + c) else { return false }
    guard a * b == b * a else { return false }
    guard a * (b + c) == a * b + a * c else { return false }
    guard a + b - b == a else { return false }
    guard a - a == zero else { return false }
    guard @bigint.BigInt::pow(a, 2N) == a * a else { return false }
    // truncated division laws
    if !b.is_zero() {
      guard a / b * b + a % b == a else { return false }
      let r = a % b
      let abs_r = if r < zero { -r } else { r }
      let abs_b = if b < zero { -b } else { b }
      guard abs_r < abs_b else { return false }
      guard -a / b == -(a / b) else { return false }
      guard -a % b == -(a % b) else { return false }
    }
    // bitwise laws (two's complement at arbitrary precision)
    guard (a & b) == (b & a) else { return false }
    guard (a | b) == (b | a) else { return false }
    guard (a ^ b) == (b ^ a) else { return false }
    guard (a & b & c) == (a & (b & c)) else { return false }
    guard (a | b | c) == (a | (b | c)) else { return false }
    guard (a ^ b ^ c) == (a ^ (b ^ c)) else { return false }
    guard (a ^ b ^ b) == a else { return false }
    guard (a & a) == a && (a | a) == a && (a ^ a) == zero else { return false }
    guard (a & zero) == zero && (a | zero) == a && (a ^ zero) == a else {
      return false
    }
    // complement identity and De Morgan: ~x == x ^ -1 == -x - 1
    guard (a ^ neg_one) == -a - 1N else { return false }
    guard ((a & b) ^ neg_one) == ((a ^ neg_one) | (b ^ neg_one)) else {
      return false
    }
    // absorption
    guard (a & (a | b)) == a && (a | (a & b)) == a else { return false }
    // negation identities: the lowest set bit governs all three
    if !a.is_zero() {
      let l = a & -a
      guard (l & (l - 1N)) == zero else { return false }
      guard (a | -a) == -l else { return false }
      guard (a ^ -a) == -2N * l else { return false }
    }
    // shifts: compose, cancel, and floor decomposition
    let m = (xs[0] & 0x7fffffff) % 80
    let n = (ys[0] & 0x7fffffff) % 80
    guard a << m << n == a << (m + n) else { return false }
    guard a << n >> n == a else { return false }
    let mask = (1N << n) - 1N
    guard (a >> n << n) + (a & mask) == a else { return false }
    // round trips
    guard @bigint.BigInt::from_string(a.to_string(radix=16), radix=16) == a else {
      return false
    }
    guard @bigint.BigInt::from_string(a.to_string()) == a else { return false }
    guard @json.from_json(a.to_json()) == a else { return false }
    true
  })
}
