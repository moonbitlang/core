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

// QuickCheck property tests for the transcendental and utility functions in
// this package.
//
// Tolerance philosophy: the js backend delegates to the host engine's `Math`
// while wasm-gc/native use fdlibm-style ports (native additionally uses the C
// library for sin/cos), so results legitimately differ by a few ulps between
// backends. Every tolerance below is derived from a first-order error
// propagation argument and then multiplied by a generous safety factor, so a
// failure indicates a genuine defect (wrong branch, wrong quadrant, wrong
// special case, catastrophic cancellation in the implementation) rather than
// an alternate correct rounding. Well-conditioned exact contracts (signs of
// zero, IEEE special values, power-of-two scaling) are checked bitwise.

///|
/// The quickcheck `Double` generator is uniform on [0, 1]; these helpers map
/// it onto the ranges each property needs.
fn sym(u : Double) -> Double {
  2.0 * u - 1.0
}

///|
/// Maps `v` in [0, 1] onto an integer exponent in [lo, hi].
fn expo(v : Double, lo : Int, hi : Int) -> Int {
  lo + (v * (hi - lo).to_double()).to_int()
}

///|
/// A log-uniform positive double: mantissa in [1, 2], binary exponent in
/// [lo, hi]. `scalbn` scaling by a power of two is exact, so this does not
/// itself introduce rounding error.
fn logu(u : Double, v : Double, lo : Int, hi : Int) -> Double {
  @math.scalbn(1.0 + u, expo(v, lo, hi))
}

///|
/// Builds a double from an arbitrary 64-bit pattern (two uniform doubles
/// supply 32 bits each), covering subnormals, both zeros, infinities and NaN.
fn any_double(u : Double, v : Double) -> Double {
  let hi = (u * 4294967296.0).to_uint64() & 0xFFFFFFFF
  let lo = (v * 4294967296.0).to_uint64() & 0xFFFFFFFF
  ((hi << 32) | lo).reinterpret_as_double()
}

///|
fn same_bits(a : Double, b : Double) -> Bool {
  a.reinterpret_as_uint64() == b.reinterpret_as_uint64()
}

///|
/// Maps a double onto an integer key that is monotone in the numeric order,
/// so ulp distance is plain integer distance. Both zeros map to the same key.
fn order_key(x : Double) -> UInt64 {
  let b = x.reinterpret_as_uint64()
  if b >> 63 == 0 {
    b + 0x8000000000000000UL
  } else {
    0x8000000000000000UL - (b & 0x7FFFFFFFFFFFFFFFUL)
  }
}

///|
/// Distance between two non-NaN doubles in units in the last place.
fn ulp_dist(a : Double, b : Double) -> UInt64 {
  let ka = order_key(a)
  let kb = order_key(b)
  if ka > kb {
    ka - kb
  } else {
    kb - ka
  }
}

///|
/// True when `a` and `b` are within `max_ulps` ulps. NaNs only match NaNs;
/// infinities only match exactly.
fn close_ulps(a : Double, b : Double, max_ulps : UInt64) -> Bool {
  if a.is_nan() || b.is_nan() {
    return a.is_nan() && b.is_nan()
  }
  if a == b {
    return true
  }
  if a.is_inf() || b.is_inf() {
    return false
  }
  ulp_dist(a, b) <= max_ulps
}

///|
/// Mixed relative/absolute comparison: |a - b| <= atol + rtol * max(|a|, |b|).
/// NaN never compares close; infinities only match exactly (handled by the
/// `a == b` case).
fn approx(a : Double, b : Double, rtol : Double, atol : Double) -> Bool {
  if a.is_nan() || b.is_nan() {
    return false
  }
  if a == b {
    return true
  }
  if a.is_inf() || b.is_inf() {
    return false
  }
  (a - b).abs() <= atol + rtol * a.abs().max(b.abs())
}

// ---------------------------------------------------------------------------
// Inverse pairs on their principal domains
// ---------------------------------------------------------------------------

///|
test "quickcheck: exp(ln(x)) recovers x over the normal range" {
  // ln contributes ~1 ulp of relative error, which exp turns into a relative
  // error of about |ln x| * 2^-53; allow 4e-16 * (1 + |ln x|), roughly 4x the
  // expected worst case.
  @quickcheck.check(
    (p : (Double, Double)) => {
      let (u, v) = p
      let x = logu(u, v, -1000, 1000)
      let l = @math.ln(x)
      approx(@math.exp(l), x, 4.0e-16 * (1.0 + l.abs()), 0.0)
    },
    count=300,
  )
}

///|
test "quickcheck: ln(exp(x)) recovers x for |x| <= 700" {
  // exp is ~1 ulp accurate, so ln(exp x) differs from x by about 2^-53
  // absolute (from exp) plus ~1 ulp of x (from ln). 4e-15 on both terms is a
  // ~30x margin.
  @quickcheck.check(
    (u : Double) => {
      let x = sym(u) * 700.0
      (@math.ln(@math.exp(x)) - x).abs() <= 4.0e-15 + 4.0e-15 * x.abs()
    },
    count=300,
  )
}

///|
test "quickcheck: sin(asin(x)) recovers x on [-1, 1]" {
  // sin'(asin x) = sqrt(1 - x^2) <= 1, so the composition contracts asin's
  // error; a few ulps of x suffice even near |x| = 1 where sin flattens.
  // 16 ulps is far above the ~4 expected but far below any branch error.
  @quickcheck.check(
    (u : Double) => {
      let x = sym(u)
      close_ulps(@math.sin(@math.asin(x)), x, 16)
    },
    count=300,
  )
}

///|
test "quickcheck: cos(acos(x)) recovers x on [-1, 1]" {
  // Near x = 0, acos(x) is near pi/2 and carries ~2 ulps of pi/2 (~5e-16)
  // absolute error which cos passes through, so an absolute term is required;
  // 2e-15 absolute + 1e-14 relative is a 4x margin on that.
  @quickcheck.check(
    (u : Double) => {
      let x = sym(u)
      approx(@math.cos(@math.acos(x)), x, 1.0e-14, 2.0e-15)
    },
    count=300,
  )
}

///|
test "quickcheck: tan(atan(x)) recovers x" {
  // tan amplifies atan's ~1 ulp relative error by (1 + x^2)*|t|/|x|, which is
  // bounded by about (1 + |x|) * 2^-52 on this range; 4e-15 * (1 + |x|)
  // keeps a >4x margin.
  @quickcheck.check(
    (p : (Double, Double, Double)) => {
      let (u, v, w) = p
      let mag = logu(u, v, -60, 10)
      let x = if w < 0.5 { -mag } else { mag }
      approx(@math.tan(@math.atan(x)), x, 4.0e-15 * (1.0 + x.abs()), 0.0)
    },
    count=300,
  )
}

///|
test "quickcheck: cbrt(x)^3 recovers x, including negative x" {
  // cbrt is ~1 ulp; cubing triples the relative error and adds two rounding
  // steps, so ~4 ulps (9e-16) expected; 4e-15 allowed.
  @quickcheck.check(
    (p : (Double, Double, Double)) => {
      let (u, v, w) = p
      let mag = logu(u, v, -300, 300)
      let x = if w < 0.5 { -mag } else { mag }
      let c = @math.cbrt(x)
      approx(c * c * c, x, 4.0e-15, 0.0) &&
      // Odd symmetry is maintained bitwise by sign-magnitude implementations.
      same_bits(@math.cbrt(-x), -c)
    },
    count=300,
  )
}

// ---------------------------------------------------------------------------
// Identities
// ---------------------------------------------------------------------------

///|
test "quickcheck: sin^2 + cos^2 = 1 for |x| < 1e8" {
  // Each of sin/cos is within ~2 ulps on this range on every backend;
  // squaring and summing keeps the defect below ~2e-15 absolute. 1e-14 is a
  // 5x margin. (Beyond 1e8 argument-reduction quality legitimately varies.)
  @quickcheck.check(
    (u : Double) => {
      let x = sym(u) * 1.0e8
      let s = @math.sin(x)
      let c = @math.cos(x)
      (s * s + c * c - 1.0).abs() <= 1.0e-14
    },
    count=300,
  )
}

///|
test "quickcheck: sin(2x) = 2 sin(x) cos(x) for |x| <= 1e3" {
  // Both sides are computed from accurately reduced arguments on this range,
  // so they agree to a relative error of a few ulps; random inputs stay far
  // from the zeros of sin(2x), making 1e-12 relative a >100x margin while
  // still catching any phase incoherence between sin and cos.
  @quickcheck.check(
    (u : Double) => {
      let x = sym(u) * 1.0e3
      approx(
        @math.sin(2.0 * x),
        2.0 * @math.sin(x) * @math.cos(x),
        1.0e-12,
        1.0e-15,
      )
    },
    count=300,
  )
}

///|
test "quickcheck: exp(a + b) = exp(a) * exp(b)" {
  // The dominant error is the rounding of a + b (up to ulp(700)/2 ~ 5.7e-14)
  // amplified through exp; 1e-12 relative is a >10x margin.
  @quickcheck.check(
    (p : (Double, Double)) => {
      let (u, v) = p
      let a = sym(u) * 350.0
      let b = sym(v) * 350.0
      approx(@math.exp(a + b), @math.exp(a) * @math.exp(b), 1.0e-12, 0.0)
    },
    count=300,
  )
}

///|
test "quickcheck: ln(a * b) = ln(a) + ln(b)" {
  // When ln(a) ~ -ln(b) the right-hand side cancels, leaving an absolute
  // error of ~1 ulp of the larger term (up to ulp(140) ~ 3e-14); 1e-12
  // absolute is a ~30x margin.
  @quickcheck.check(
    (p : (Double, Double, Double, Double)) => {
      let (u1, v1, u2, v2) = p
      let a = logu(u1, v1, -100, 100)
      let b = logu(u2, v2, -100, 100)
      approx(@math.ln(a * b), @math.ln(a) + @math.ln(b), 1.0e-14, 1.0e-12)
    },
    count=300,
  )
}

///|
test "quickcheck: log2(x * 2^k) = log2(x) + k" {
  // Exercises exponent extraction: multiplying by 2^k is exact, adding the
  // integer k to log2(x) in [0, 1] rounds once. Expected defect < 1 ulp of
  // the result (~2e-13 at |k| ~ 900); 1e-12 absolute allowed.
  @quickcheck.check(
    (p : (Double, Double)) => {
      let (u, v) = p
      let x = 1.0 + u
      let k = expo(v, -900, 900)
      approx(
        @math.log2(@math.scalbn(x, k)),
        @math.log2(x) + k.to_double(),
        0.0,
        1.0e-12,
      )
    },
    count=300,
  )
}

///|
test "quickcheck: log2 is exact-ish on powers of two, including subnormal" {
  // log2(2^k) is an exactly representable integer; any correct implementation
  // lands within 1 ulp of it (fdlibm and the JS engines return it exactly).
  // Subnormal powers of two exercise the exponent-rescaling path.
  @quickcheck.check(
    (u : Double) => {
      let k = expo(u, -1074, 1023)
      close_ulps(@math.log2(@math.scalbn(1.0, k)), k.to_double(), 1)
    },
    count=400,
  )
}

///|
test "quickcheck: log10(x) = ln(x) / ln(10)" {
  // Both routes are well conditioned (relative error of ln is ~1 ulp of the
  // result even near x = 1); dividing adds half an ulp. 1e-13 relative plus a
  // tiny absolute floor is a large margin.
  @quickcheck.check(
    (p : (Double, Double)) => {
      let (u, v) = p
      let x = logu(u, v, -1000, 1000)
      approx(@math.log10(x), @math.ln(x) / 2.302585092994046, 1.0e-13, 1.0e-15)
    },
    count=300,
  )
}

///|
test "quickcheck: expm1(x) - x behaves like x^2/2 near zero" {
  // |expm1(x) - x| = x^2/2 * (1 + O(x)) <= 0.7 x^2 for |x| <= 0.25, plus ~1
  // ulp of x of implementation error. This catches an expm1 that loses the
  // low-order terms (e.g. one implemented as exp(x) - 1).
  @quickcheck.check(
    (u : Double) => {
      let x = sym(u) * 0.25
      (@math.expm1(x) - x).abs() <= 0.7 * x * x + 4.0e-16 * x.abs()
    },
    count=300,
  )
}

///|
test "quickcheck: ln_1p(x) - x behaves like -x^2/2 near zero" {
  // Same reasoning as the expm1 property: |ln(1+x) - x| <= 0.7 x^2 for
  // |x| <= 0.25.
  @quickcheck.check(
    (u : Double) => {
      let x = sym(u) * 0.25
      (@math.ln_1p(x) - x).abs() <= 0.7 * x * x + 4.0e-16 * x.abs()
    },
    count=300,
  )
}

///|
test "quickcheck: expm1 agrees with exp - 1 away from zero" {
  // For 0.5 <= |x| <= 30 the subtraction exp(x) - 1 loses at most one bit,
  // so both sides agree to a few ulps; 1e-13 relative is generous.
  @quickcheck.check(
    (p : (Double, Double)) => {
      let (u, v) = p
      let mag = 0.5 + u * 29.5
      let x = if v < 0.5 { -mag } else { mag }
      approx(@math.expm1(x), @math.exp(x) - 1.0, 1.0e-13, 0.0)
    },
    count=300,
  )
}

// ---------------------------------------------------------------------------
// hypot
// ---------------------------------------------------------------------------

///|
test "quickcheck: hypot matches naive sqrt(a^2 + b^2) in the safe range" {
  // With exponents in [-150, 150] the naive formula neither overflows nor
  // underflows and is itself ~1.5 ulp accurate; hypot is allowed ~2-3 ulps,
  // so 4e-15 relative (~18 ulps) separates rounding noise from real defects.
  // hypot must also ignore argument signs exactly.
  @quickcheck.check(
    (p : (Double, Double, Double, Double)) => {
      let (u1, v1, u2, v2) = p
      let a = logu(u1, v1, -150, 150)
      let b = logu(u2, v2, -150, 150)
      approx(@math.hypot(a, b), (a * a + b * b).sqrt(), 4.0e-15, 0.0) &&
      @math.hypot(-a, b) == @math.hypot(a, b) &&
      @math.hypot(a, -b) == @math.hypot(a, b)
    },
    count=300,
  )
}

///|
test "quickcheck: hypot survives ranges where the naive formula overflows" {
  // a^2 overflows for exponents >= 512, so this range is exactly what hypot
  // exists for. Scaling both arguments by 2^-200 is exact, so the two routes
  // must agree to hypot's own accuracy (4e-15 relative, as above).
  @quickcheck.check(
    (p : (Double, Double, Double, Double)) => {
      let (u1, v1, u2, v2) = p
      let a = logu(u1, v1, 900, 1020)
      let b = logu(u2, v2, 900, 1020)
      let h = @math.hypot(a, b)
      let scaled = @math.scalbn(
        @math.hypot(@math.scalbn(a, -200), @math.scalbn(b, -200)),
        200,
      )
      !h.is_inf() &&
      h >= a.max(b) * (1.0 - 4.4e-16) &&
      approx(h, scaled, 4.0e-15, 0.0)
    },
    count=300,
  )
}

///|
test "quickcheck: hypot survives ranges where the naive formula underflows" {
  // a^2 underflows to 0 for exponents <= -538; hypot must not lose the
  // magnitude. Scaling up by an exact power of two provides the reference.
  @quickcheck.check(
    (p : (Double, Double, Double, Double)) => {
      let (u1, v1, u2, v2) = p
      let a = logu(u1, v1, -1020, -980)
      let b = logu(u2, v2, -1020, -980)
      let h = @math.hypot(a, b)
      let scaled = @math.scalbn(
        @math.hypot(@math.scalbn(a, 600), @math.scalbn(b, 600)),
        -600,
      )
      h > 0.0 && approx(h, scaled, 4.0e-15, 0.0)
    },
    count=300,
  )
}

///|
test "quickcheck: hypot is bounded by max(|a|,|b|) and |a| + |b|" {
  // Exact mathematical bounds, relaxed by 2 ulps for rounding. Runs on fully
  // arbitrary finite bit patterns, including subnormals.
  @quickcheck.check(
    (p : (Double, Double, Double, Double)) => {
      let (u1, v1, u2, v2) = p
      let a = any_double(u1, v1)
      let b = any_double(u2, v2)
      guard !a.is_nan() && !b.is_nan() && !a.is_inf() && !b.is_inf() else {
        return true
      }
      let h = @math.hypot(a, b)
      let m = a.abs().max(b.abs())
      let s = a.abs() + b.abs()
      h >= m * (1.0 - 4.4e-16) && (s.is_inf() || h <= s * (1.0 + 4.4e-16))
    },
    count=500,
  )
}

// ---------------------------------------------------------------------------
// atan2
// ---------------------------------------------------------------------------

///|
test "quickcheck: atan2 lands in the correct quadrant" {
  // Signs of (y, x) determine the quadrant exactly; the boundary values
  // themselves cannot be exceeded because pi/2 and pi round downward (the
  // nearest doubles are below the true values). Also checks exact odd
  // symmetry in y and agreement with atan(y/x) in the first quadrant, where
  // the division adds half an ulp and atan contracts it.
  @quickcheck.check(
    (p : (Double, Double, Double, Double)) => {
      let (u1, v1, u2, v2) = p
      let y = logu(u1, v1, -30, 30)
      let x = logu(u2, v2, -30, 30)
      let half_pi = @math.PI / 2.0
      let q1 = @math.atan2(y, x)
      let q2 = @math.atan2(y, -x)
      let q3 = @math.atan2(-y, -x)
      let q4 = @math.atan2(-y, x)
      q1 > 0.0 &&
      q1 <= half_pi &&
      q2 >= half_pi &&
      q2 <= @math.PI &&
      q3 >= -@math.PI &&
      q3 <= -half_pi &&
      q4 < 0.0 &&
      q4 >= -half_pi &&
      q4 == -q1 &&
      q3 == -q2 &&
      approx(q1, @math.atan(y / x), 4.0e-15, 0.0)
    },
    count=300,
  )
}

// ---------------------------------------------------------------------------
// Monotonicity (allowing 2 ulps: faithful-but-not-correct rounding may
// reorder adjacent outputs by 1 ulp; anything beyond that on random pairs is
// a table or branch defect)
// ---------------------------------------------------------------------------

///|
fn non_decreasing_within_2ulp(fa : Double, fb : Double) -> Bool {
  fa <= fb || ulp_dist(fa, fb) <= 2
}

///|
test "quickcheck: exp is monotone" {
  @quickcheck.check(
    (p : (Double, Double)) => {
      let (u, v) = p
      let a = sym(u) * 700.0
      let b = sym(v) * 700.0
      let lo = a.min(b)
      let hi = a.max(b)
      non_decreasing_within_2ulp(@math.exp(lo), @math.exp(hi))
    },
    count=300,
  )
}

///|
test "quickcheck: ln is monotone" {
  @quickcheck.check(
    (p : (Double, Double, Double, Double)) => {
      let (u1, v1, u2, v2) = p
      let a = logu(u1, v1, -1000, 1000)
      let b = logu(u2, v2, -1000, 1000)
      let lo = a.min(b)
      let hi = a.max(b)
      non_decreasing_within_2ulp(@math.ln(lo), @math.ln(hi))
    },
    count=300,
  )
}

///|
test "quickcheck: atan is monotone" {
  @quickcheck.check(
    (p : (Double, Double, Double, Double)) => {
      let (u1, v1, u2, v2) = p
      let a = if u2 < 0.5 {
        -logu(u1, v1, -60, 60)
      } else {
        logu(u1, v1, -60, 60)
      }
      let b = if v2 < 0.5 {
        -logu(v1, u1, -60, 60)
      } else {
        logu(v1, u1, -60, 60)
      }
      let lo = a.min(b)
      let hi = a.max(b)
      non_decreasing_within_2ulp(@math.atan(lo), @math.atan(hi))
    },
    count=300,
  )
}

///|
test "quickcheck: tanh is monotone" {
  @quickcheck.check(
    (p : (Double, Double)) => {
      let (u, v) = p
      let a = sym(u) * 40.0
      let b = sym(v) * 40.0
      let lo = a.min(b)
      let hi = a.max(b)
      non_decreasing_within_2ulp(@math.tanh(lo), @math.tanh(hi))
    },
    count=300,
  )
}

// ---------------------------------------------------------------------------
// Range guarantees on arbitrary bit patterns
// ---------------------------------------------------------------------------

///|
test "quickcheck: sin/cos stay in [-1, 1] for every finite input" {
  // Exceeding 1 by even 1 ulp is a real bug regardless of backend. Non-finite
  // inputs must produce NaN. Odd/even symmetry must hold bitwise because
  // every implementation reduces |x| and reapplies the sign.
  @quickcheck.check(
    (p : (Double, Double)) => {
      let (u, v) = p
      let x = any_double(u, v)
      if x.is_nan() || x.is_inf() {
        return @math.sin(x).is_nan() &&
          @math.cos(x).is_nan() &&
          @math.tan(x).is_nan()
      }
      let s = @math.sin(x)
      let c = @math.cos(x)
      s.abs() <= 1.0 &&
      c.abs() <= 1.0 &&
      same_bits(@math.sin(-x), -s) &&
      @math.cos(-x) == c
    },
    count=500,
  )
}

///|
test "quickcheck: tanh stays in [-1, 1] and atan within (-pi/2, pi/2)" {
  // atan(x) may equal PI/2 exactly (the nearest double is below the true
  // pi/2) but must never exceed it.
  @quickcheck.check(
    (p : (Double, Double)) => {
      let (u, v) = p
      let x = any_double(u, v)
      guard !x.is_nan() else {
        return @math.tanh(x).is_nan() && @math.atan(x).is_nan()
      }
      @math.tanh(x).abs() <= 1.0 && @math.atan(x).abs() <= @math.PI / 2.0
    },
    count=500,
  )
}

///|
test "quickcheck: asin/acos ranges on [-1, 1], NaN outside" {
  @quickcheck.check(
    (p : (Double, Double, Double)) => {
      let (u, v, w) = p
      let x = sym(u)
      let a = @math.asin(x)
      let c = @math.acos(x)
      let outside = any_double(v, w)
      let outside_ok = if outside.abs() > 1.0 || outside.is_nan() {
        @math.asin(outside).is_nan() && @math.acos(outside).is_nan()
      } else {
        true
      }
      a.abs() <= @math.PI / 2.0 && c >= 0.0 && c <= @math.PI && outside_ok
    },
    count=300,
  )
}

// ---------------------------------------------------------------------------
// floor / ceil / trunc / round
// ---------------------------------------------------------------------------

///|
test "quickcheck: floor/ceil/trunc/round contracts on arbitrary doubles" {
  // Exact contracts (no tolerances): integrality, ordering, reflection
  // ceil(-x) = -floor(x), trunc = toward-zero member, and the documented
  // round-half-up behaviour round(x) - x in (-0.5, 0.5].
  @quickcheck.check(
    (p : (Double, Double)) => {
      let (u, v) = p
      let x = any_double(u, v)
      if x.is_nan() {
        return @math.floor(x).is_nan() &&
          @math.ceil(x).is_nan() &&
          @math.trunc(x).is_nan() &&
          @math.round(x).is_nan()
      }
      if x.is_inf() {
        return @math.floor(x) == x &&
          @math.ceil(x) == x &&
          @math.trunc(x) == x &&
          @math.round(x) == x
      }
      let f = @math.floor(x)
      let c = @math.ceil(x)
      let t = @math.trunc(x)
      let r = @math.round(x)
      // All comparisons are exact: for a subnormal x, `ceil(x) - x` would
      // round to exactly 1.0, so subtraction-based bounds are avoided.
      f <= x &&
      c >= x &&
      (if f == c { x == f } else { c == f + 1.0 && x > f && x < c }) &&
      f == @math.trunc(f) &&
      c == @math.trunc(c) &&
      r == @math.trunc(r) &&
      @math.ceil(-x) == -f &&
      t == (if x < 0.0 { c } else { f }) &&
      (r == f || r == c) &&
      (r - x).abs() <= 0.5 &&
      // Every |x| >= 2^52 is already integral.
      (x.abs() < 4503599627370496.0 || (f == x && c == x && t == x && r == x))
    },
    count=500,
  )
}

///|
test "quickcheck: rounding functions are exact on n and half-up on n + 0.5" {
  // n + 0.5 is exactly representable for the small integers generated here,
  // so ties must follow the documented round-half-up rule: round(n + 0.5) =
  // n + 1 for every integer n, including negatives (round(-3.5) = -3).
  @quickcheck.check(
    (k : Int) => {
      let n = k.to_double()
      let x = n + 0.5
      @math.round(n) == n &&
      @math.floor(n) == n &&
      @math.ceil(n) == n &&
      @math.trunc(n) == n &&
      @math.round(x) == n + 1.0 &&
      @math.floor(x) == n &&
      @math.ceil(x) == n + 1.0 &&
      @math.trunc(x) == (if k < 0 { n + 1.0 } else { n })
    },
    count=300,
  )
}

// ---------------------------------------------------------------------------
// pow
// ---------------------------------------------------------------------------

///|
test "quickcheck: pow(x, 0) = 1 and pow(x, 1) = x" {
  // IEEE 754/C99: pow(x, 0) is 1 for every x, including NaN and infinities
  // (both the fdlibm port and the JS engines test y == 0 before NaN).
  // pow(x, 1) = x holds bitwise for non-NaN x (including -0).
  @quickcheck.check(
    (p : (Double, Double)) => {
      let (u, v) = p
      let x = any_double(u, v)
      guard @math.pow(x, 0.0) == 1.0 && @math.pow(x, -0.0) == 1.0 else {
        return false
      }
      if x.is_nan() {
        @math.pow(x, 1.0).is_nan()
      } else {
        same_bits(@math.pow(x, 1.0), x)
      }
    },
    count=500,
  )
}

///|
test "quickcheck: pow squares, square roots and negative bases" {
  // pow(x, 2) and pow(x, 0.5) are special-cased to x*x and sqrt(x) in the
  // reference implementations, so 1 ulp covers any correct variant. A
  // negative base with a non-integer exponent must produce NaN.
  @quickcheck.check(
    (p : (Double, Double, Double)) => {
      let (u, v, w) = p
      let x = logu(u, v, -500, 500)
      let frac_exp = expo(w, -20, 20).to_double() + 0.5
      close_ulps(@math.pow(x, 2.0), x * x, 1) &&
      close_ulps(@math.pow(x, 0.5), x.sqrt(), 1) &&
      @math.pow(-x, frac_exp).is_nan()
    },
    count=300,
  )
}

///|
test "quickcheck: pow(x, a) * pow(x, b) = pow(x, a + b)" {
  // pow's relative error grows with |y * ln x|; with |ln x| <= 2.1 and
  // |a|, |b| <= 20 the expected defect stays below ~1e-14 relative; 1e-12
  // gives two orders of magnitude of margin.
  @quickcheck.check(
    (p : (Double, Double, Double, Double)) => {
      let (u1, v1, u2, v2) = p
      let x = logu(u1, v1, -3, 3)
      let a = sym(u2) * 20.0
      let b = sym(v2) * 20.0
      approx(
        @math.pow(x, a + b),
        @math.pow(x, a) * @math.pow(x, b),
        1.0e-12,
        0.0,
      )
    },
    count=300,
  )
}

// ---------------------------------------------------------------------------
// Hyperbolic functions
// ---------------------------------------------------------------------------

///|
test "quickcheck: cosh(x) + sinh(x) = exp(x) for x >= 0" {
  // For x >= 0 both terms are non-negative, so the sum does not cancel and
  // the identity holds to a few ulps; 4e-15 relative (~18 ulps) allowed.
  @quickcheck.check(
    (u : Double) => {
      let x = u * 700.0
      approx(@math.cosh(x) + @math.sinh(x), @math.exp(x), 4.0e-15, 0.0)
    },
    count=300,
  )
}

///|
test "quickcheck: cosh(x) - sinh(x) = exp(-x) for x <= 0" {
  // For x <= 0, sinh(x) <= 0 so the subtraction adds magnitudes: again no
  // cancellation.
  @quickcheck.check(
    (u : Double) => {
      let x = -u * 700.0
      approx(@math.cosh(x) - @math.sinh(x), @math.exp(-x), 4.0e-15, 0.0)
    },
    count=300,
  )
}

///|
test "quickcheck: tanh(x) = sinh(x) / cosh(x)" {
  // Away from overflow (|x| <= 700) the quotient is well conditioned; the
  // three functions contribute ~1-2 ulps each.
  @quickcheck.check(
    (u : Double) => {
      let x = sym(u) * 700.0
      approx(@math.tanh(x), @math.sinh(x) / @math.cosh(x), 4.0e-15, 1.0e-300)
    },
    count=300,
  )
}

///|
test "quickcheck: asinh(sinh(x)) recovers x" {
  // asinh contracts sinh's error (derivative 1/sqrt(1+s^2) <= 1), so a small
  // relative tolerance plus an absolute floor for x near 0 suffices.
  @quickcheck.check(
    (u : Double) => {
      let x = sym(u) * 700.0
      approx(@math.asinh(@math.sinh(x)), x, 4.0e-15, 1.0e-15)
    },
    count=300,
  )
}

///|
test "quickcheck: atanh(tanh(x)) recovers x on [-1, 1]" {
  // On [-1, 1], 1 - tanh(x)^2 >= 0.42, so atanh amplifies tanh's ~1 ulp
  // error by at most ~2.4x; 1e-13 relative is a >50x margin.
  @quickcheck.check(
    (u : Double) => {
      let x = sym(u)
      approx(@math.atanh(@math.tanh(x)), x, 1.0e-13, 1.0e-16)
    },
    count=300,
  )
}

///|
test "quickcheck: acosh(cosh(x)) recovers x on [1, 700]" {
  // For x >= 1 the amplification factor cosh/sinh = 1/tanh(x) <= 1.32, so
  // 1e-13 relative is generous. (Near 0 the identity is genuinely
  // ill-conditioned, hence the domain cut.)
  @quickcheck.check(
    (u : Double) => {
      let x = 1.0 + u * 699.0
      approx(@math.acosh(@math.cosh(x)), x, 1.0e-13, 0.0)
    },
    count=300,
  )
}

///|
test "quickcheck: asinh is odd and acosh is non-negative" {
  @quickcheck.check(
    (p : (Double, Double)) => {
      let (u, v) = p
      let x = any_double(u, v)
      guard !x.is_nan() else { return @math.asinh(x).is_nan() }
      let odd_ok = same_bits(@math.asinh(-x), -@math.asinh(x))
      let acosh_ok = if x >= 1.0 {
        @math.acosh(x) >= 0.0
      } else {
        @math.acosh(x).is_nan()
      }
      odd_ok && acosh_ok
    },
    count=500,
  )
}

// ---------------------------------------------------------------------------
// scalbn
// ---------------------------------------------------------------------------

///|
test "quickcheck: scalbn round-trips exactly while the result stays normal" {
  // Scaling by a power of two is exact as long as no overflow or subnormal
  // truncation occurs, so the round trip must be bitwise exact.
  @quickcheck.check(
    (p : (Double, Double)) => {
      let (u, v) = p
      let m = 1.0 + u
      let k = expo(v, -1021, 1021)
      same_bits(@math.scalbn(@math.scalbn(m, k), -k), m) &&
      same_bits(@math.scalbn(m, 0), m)
    },
    count=300,
  )
}

// ---------------------------------------------------------------------------
// Float variants (shared pure-MoonBit implementations on every backend)
// ---------------------------------------------------------------------------

///|
test "quickcheck: float trig ranges and asin round-trip" {
  // Float tolerances scale with the 2^-24 epsilon: 1e-6 absolute on the
  // sinf(asinf(x)) round trip is ~8 float ulps at |x| = 1.
  @quickcheck.check(
    (p : (Double, Double)) => {
      let (u, v) = p
      let big = Float::from_double(sym(u) * 1.0e6)
      let x = Float::from_double(sym(v))
      @math.sinf(big).to_double().abs() <= 1.0 &&
      @math.cosf(big).to_double().abs() <= 1.0 &&
      @math.tanhf(big).to_double().abs() <= 1.0 &&
      (@math.sinf(@math.asinf(x)).to_double() - x.to_double()).abs() <= 1.0e-6
    },
    count=300,
  )
}

///|
test "quickcheck: expf(lnf(x)) recovers x" {
  // lnf's ~1 float-ulp error is amplified to |ln x| * 2^-24 by expf; with
  // |ln x| <= 14 that is ~1e-6 relative, so 1e-4 is a large margin.
  @quickcheck.check(
    (p : (Double, Double)) => {
      let (u, v) = p
      let x = logu(u, v, -20, 20)
      let xf = Float::from_double(x)
      let r = @math.expf(@math.lnf(xf)).to_double()
      (r - xf.to_double()).abs() <= 1.0e-4 * xf.to_double()
    },
    count=300,
  )
}

// ---------------------------------------------------------------------------
// Special values (exact, per IEEE 754 / C99 and the package docs)
// ---------------------------------------------------------------------------

///|
test "special values: logarithms" {
  let inf = @double.infinity
  assert_eq(@math.ln(0.0), @double.neg_infinity)
  assert_eq(@math.ln(-0.0), @double.neg_infinity)
  assert_eq(@math.ln(1.0), 0.0)
  assert_true(@math.ln(-1.0).is_nan())
  assert_eq(@math.ln(inf), inf)
  assert_true(@math.ln(@double.not_a_number).is_nan())
  assert_eq(@math.ln_1p(-1.0), @double.neg_infinity)
  assert_true(@math.ln_1p(-1.5).is_nan())
  assert_true(same_bits(@math.ln_1p(0.0), 0.0))
  assert_true(same_bits(@math.ln_1p(-0.0), -0.0))
  assert_eq(@math.log2(0.0), @double.neg_infinity)
  assert_eq(@math.log2(1.0), 0.0)
  assert_eq(@math.log2(2.0), 1.0)
  assert_eq(@math.log2(inf), inf)
  assert_eq(@math.log10(0.0), @double.neg_infinity)
  assert_eq(@math.log10(1.0), 0.0)
  assert_true(@math.log10(-3.0).is_nan())
}

///|
test "special values: exponentials" {
  let inf = @double.infinity
  assert_eq(@math.exp(0.0), 1.0)
  assert_eq(@math.exp(inf), inf)
  assert_true(same_bits(@math.exp(@double.neg_infinity), 0.0))
  assert_true(@math.exp(@double.not_a_number).is_nan())
  assert_true(same_bits(@math.expm1(0.0), 0.0))
  assert_true(same_bits(@math.expm1(-0.0), -0.0))
  assert_eq(@math.expm1(@double.neg_infinity), -1.0)
  assert_eq(@math.expm1(inf), inf)
}

///|
test "special values: trigonometric" {
  let inf = @double.infinity
  let half_pi = @math.PI / 2.0
  assert_true(same_bits(@math.sin(0.0), 0.0))
  assert_true(same_bits(@math.sin(-0.0), -0.0))
  assert_eq(@math.cos(0.0), 1.0)
  assert_true(same_bits(@math.tan(0.0), 0.0))
  assert_true(same_bits(@math.tan(-0.0), -0.0))
  assert_true(@math.sin(inf).is_nan())
  assert_true(@math.cos(@double.neg_infinity).is_nan())
  assert_true(@math.tan(inf).is_nan())
  assert_true(same_bits(@math.asin(0.0), 0.0))
  assert_true(same_bits(@math.asin(-0.0), -0.0))
  assert_eq(@math.asin(1.0), half_pi)
  assert_eq(@math.asin(-1.0), -half_pi)
  assert_eq(@math.acos(1.0), 0.0)
  assert_eq(@math.acos(-1.0), @math.PI)
  assert_eq(@math.acos(0.0), half_pi)
  assert_true(@math.asin(1.5).is_nan())
  assert_true(@math.acos(-1.5).is_nan())
  assert_true(same_bits(@math.atan(0.0), 0.0))
  assert_true(same_bits(@math.atan(-0.0), -0.0))
  assert_eq(@math.atan(inf), half_pi)
  assert_eq(@math.atan(@double.neg_infinity), -half_pi)
}

///|
test "special values: atan2" {
  let half_pi = @math.PI / 2.0
  assert_true(same_bits(@math.atan2(0.0, 1.0), 0.0))
  assert_true(same_bits(@math.atan2(-0.0, 1.0), -0.0))
  assert_eq(@math.atan2(0.0, -1.0), @math.PI)
  assert_eq(@math.atan2(-0.0, -1.0), -@math.PI)
  assert_eq(@math.atan2(0.0, -0.0), @math.PI)
  assert_eq(@math.atan2(1.0, 0.0), half_pi)
  assert_eq(@math.atan2(-1.0, 0.0), -half_pi)
  // C99 F.9.1.4: atan2(±inf, +inf) = ±pi/4; allow 1 ulp because 3*pi/4 is
  // not exactly 3 * (PI/4) after rounding.
  let inf = @double.infinity
  assert_eq(@math.atan2(inf, inf), @math.PI / 4.0)
  assert_eq(@math.atan2(-inf, inf), -@math.PI / 4.0)
  assert_true(close_ulps(@math.atan2(inf, -inf), 3.0 * (@math.PI / 4.0), 1))
  assert_true(@math.atan2(@double.not_a_number, 1.0).is_nan())
}

///|
test "special values: algebraic and hyperbolic" {
  let inf = @double.infinity
  assert_true(same_bits(@math.cbrt(0.0), 0.0))
  assert_true(same_bits(@math.cbrt(-0.0), -0.0))
  assert_eq(@math.cbrt(inf), inf)
  assert_eq(@math.cbrt(@double.neg_infinity), @double.neg_infinity)
  assert_true(@math.cbrt(@double.not_a_number).is_nan())
  assert_true(close_ulps(@math.cbrt(-8.0), -2.0, 1))
  assert_eq(@math.hypot(3.0, 4.0), 5.0)
  assert_eq(@math.hypot(0.0, 0.0), 0.0)
  // C99 F.9.4.3: hypot(±inf, y) = +inf even when y is NaN.
  assert_eq(@math.hypot(inf, @double.not_a_number), inf)
  assert_eq(@math.hypot(@double.not_a_number, inf), inf)
  assert_true(@math.hypot(@double.not_a_number, 1.0).is_nan())
  assert_true(same_bits(@math.sinh(0.0), 0.0))
  assert_true(same_bits(@math.sinh(-0.0), -0.0))
  assert_eq(@math.sinh(inf), inf)
  assert_eq(@math.cosh(0.0), 1.0)
  assert_eq(@math.cosh(inf), inf)
  assert_eq(@math.cosh(@double.neg_infinity), inf)
  assert_eq(@math.tanh(inf), 1.0)
  assert_eq(@math.tanh(@double.neg_infinity), -1.0)
  assert_true(same_bits(@math.tanh(0.0), 0.0))
  assert_true(same_bits(@math.tanh(-0.0), -0.0))
  assert_true(same_bits(@math.asinh(0.0), 0.0))
  assert_true(same_bits(@math.asinh(-0.0), -0.0))
  assert_eq(@math.acosh(1.0), 0.0)
  assert_true(@math.acosh(0.5).is_nan())
  assert_eq(@math.atanh(1.0), inf)
  assert_eq(@math.atanh(-1.0), @double.neg_infinity)
  assert_true(@math.atanh(2.0).is_nan())
  assert_true(same_bits(@math.atanh(0.0), 0.0))
  assert_true(same_bits(@math.atanh(-0.0), -0.0))
}

///|
test "special values: pow and scalbn" {
  let inf = @double.infinity
  let nan = @double.not_a_number
  assert_eq(@math.pow(0.0, 0.0), 1.0)
  assert_eq(@math.pow(nan, 0.0), 1.0)
  assert_eq(@math.pow(inf, 0.0), 1.0)
  assert_true(same_bits(@math.pow(-0.0, 3.0), -0.0))
  assert_true(same_bits(@math.pow(-0.0, 2.0), 0.0))
  assert_eq(@math.pow(0.0, -2.0), inf)
  assert_eq(@math.pow(-0.0, -3.0), @double.neg_infinity)
  assert_eq(@math.pow(inf, 2.0), inf)
  assert_true(same_bits(@math.pow(inf, -2.0), 0.0))
  assert_eq(@math.pow(@double.neg_infinity, 3.0), @double.neg_infinity)
  assert_eq(@math.pow(2.0, inf), inf)
  assert_true(same_bits(@math.pow(2.0, @double.neg_infinity), 0.0))
  assert_true(same_bits(@math.pow(0.5, inf), 0.0))
  assert_eq(@math.pow(0.5, @double.neg_infinity), inf)
  assert_true(@math.pow(-2.0, 0.5).is_nan())
  assert_true(same_bits(@math.scalbn(0.0, 100), 0.0))
  assert_true(same_bits(@math.scalbn(-0.0, 100), -0.0))
  assert_eq(@math.scalbn(1.0, 2000), inf)
  assert_true(same_bits(@math.scalbn(1.0, -2000), 0.0))
  assert_eq(@math.scalbn(@double.neg_infinity, -10), @double.neg_infinity)
}
