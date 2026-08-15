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

// Specification tests for `@range.iter`.
//
// The specification is "`from`, `from + step`, `from + 2 * step`, ...
// while the value is on the correct side of `to`", and the whole
// difficulty is in the words the implementation has to add to make that
// terminate on a fixed-width type: it stops as soon as `current + step`
// fails to make progress past `current`.
//
// So the oracle here computes the sequence in **exact, unbounded
// arithmetic** (`BigInt`) and stops when the next value would leave the
// type's range. That is a genuinely independent statement of the same
// rule: for a two's-complement type, "the exact next value is outside
// `[min, max]`" and "the wrapped next value fails to make progress" are
// the same condition, but the oracle never performs the wrapping
// arithmetic whose corner cases are under test. A reference written
// with the same fixed-width `+` would reproduce an overflow bug rather
// than catch it.
//
// Cases are generated in `BigInt` space and then narrowed to each
// `Step` type, so all nine integral impls -- `Int`, `Int64`, `UInt`,
// `UInt64`, `Int16`, `UInt16`, `Byte`, and `BigInt` itself -- are
// checked against the one oracle, with generators that concentrate on
// the ends of each type's range where the overflow stop actually
// engages. `Float` and `Double` cannot use it (their step is not exact)
// and are specified separately by invariant.

// =====================================================================
// The exact-arithmetic oracle.
// =====================================================================

///|
/// How many values any single property will compare. Generated cases
/// are shaped to stay well under this, but an anchor-derived `step` of
/// 1 across a full-width range would otherwise enumerate billions of
/// values; capping both sides keeps that case a *prefix* check instead
/// of a hang, and still fails if the two disagree anywhere in the
/// prefix or on where the sequence ends.
const CAP : Int = 300

///|
/// The reference enumeration, in exact integer arithmetic.
///
/// `min` and `max` bound the element type. The loop stops when the next
/// value would fall outside them -- the exact-arithmetic statement of
/// the implementation's "no progress" test.
fn model(
  from : BigInt,
  to : BigInt,
  step : BigInt,
  inclusive : Bool,
  min : BigInt,
  max : BigInt,
) -> Array[BigInt] {
  let out = []
  let direction = if step > 0N { 1 } else if step < 0N { -1 } else { 0 }
  let mut current = from
  while out.length() < CAP {
    let in_range = if direction > 0 {
      current < to
    } else if direction < 0 {
      current > to
    } else {
      false
    }
    if !(in_range || (inclusive && current == to)) {
      break
    }
    out.push(current)
    // A zero step never advances, so it yields at most the single
    // `inclusive && from == to` value.
    if direction == 0 {
      break
    }
    let next = current + step
    if next < min || next > max {
      break
    }
    current = next
  }
  out
}

// =====================================================================
// Case generation.
// =====================================================================

///|
/// Maps an arbitrary `Int` into `0..<modulus` without discarding cases.
fn wrap_index(value : Int, modulus : Int) -> Int {
  let r = value % modulus
  if r < 0 {
    r + modulus
  } else {
    r
  }
}

///|
fn clamp(value : BigInt, min : BigInt, max : BigInt) -> BigInt {
  if value < min {
    min
  } else if value > max {
    max
  } else {
    value
  }
}

///|
/// Values worth starting or stopping at: both ends of the type's range
/// and their neighbours (where the overflow stop engages), the
/// midpoint, and the small values around zero.
fn anchors(min : BigInt, max : BigInt) -> Array[BigInt] {
  let mid = (min + max) / 2N
  let candidates = [
    min,
    min + 1N,
    min + 2N,
    mid,
    mid + 1N,
    max - 2N,
    max - 1N,
    max,
    0N,
    1N,
    -1N,
    2N,
  ]
  candidates.filter(v => v >= min && v <= max)
}

///|
/// Builds a `(from, to, step)` triple inside `[min, max]`.
///
/// `to` takes one of two shapes: *narrow*, within 64 of `from` — where
/// the boundary conditions (`inclusive`, empty ranges, wrong-direction
/// steps, the last step before overflow) live — or an arbitrary anchor,
/// which spans the type.
///
/// `step` independently takes one of three: a small value including
/// zero; a value scaled so that a few hundred additions cross the whole
/// range, which is what drives a long run into the overflow stop; or an
/// anchor, which is how the extreme steps (`min`, `max`, and a bare
/// `1` across a full-width range) get covered.
fn build_case(
  min : BigInt,
  max : BigInt,
  a : Int,
  b : Int,
  c : Int,
) -> (BigInt, BigInt, BigInt) {
  let anc = anchors(min, max)
  let from = anc[wrap_index(a, anc.length())]
  let to = if wrap_index(b, 2) == 0 {
    clamp(from + BigInt::from_int(wrap_index(b / 2, 129) - 64), min, max)
  } else {
    anc[wrap_index(b / 2, anc.length())]
  }
  let step = match wrap_index(c, 3) {
    // -8 ..= 8, including the zero step
    0 => BigInt::from_int(wrap_index(c / 3, 17) - 8)
    // large enough to cross the whole range in a few hundred additions
    1 => {
      let unit = (max - min) / BigInt::from_int(CAP) + 1N
      let scaled = unit * BigInt::from_int(1 + wrap_index(c / 3, 4))
      if wrap_index(c / 12, 2) == 0 {
        scaled
      } else {
        -scaled
      }
    }
    // the extremes of the type
    _ => anc[wrap_index(c / 3, anc.length())]
  }
  (from, to, clamp(step, min, max))
}

// =====================================================================
// The integral Step impls, against the oracle.
// =====================================================================

///|
/// `Int64` bounds, and the widest range used for `BigInt` (which has no
/// bounds of its own, so the oracle's overflow stop must never fire).
let i64_min : BigInt = -9223372036854775808N

///|
let i64_max : BigInt = 9223372036854775807N

///|
let unbounded : BigInt = 1N << 200

///|
test "quickcheck: Int matches the exact-arithmetic model" {
  @quickcheck.check(
    (input : (Int, Int, Int, Bool)) => {
      let (a, b, c, inclusive) = input
      let min = -2147483648N
      let max = 2147483647N
      let (from, to, step) = build_case(min, max, a, b, c)
      @range.iter(
        from=from.to_int(),
        to=to.to_int(),
        step=step.to_int(),
        inclusive~,
      )
      .take(CAP)
      .to_array()
      .map(BigInt::from_int) ==
      model(from, to, step, inclusive, min, max)
    },
    count=2000,
  )
}

///|
test "quickcheck: Int64 matches the exact-arithmetic model" {
  @quickcheck.check(
    (input : (Int, Int, Int, Bool)) => {
      let (a, b, c, inclusive) = input
      let (from, to, step) = build_case(i64_min, i64_max, a, b, c)
      @range.iter(
        from=from.to_int64(),
        to=to.to_int64(),
        step=step.to_int64(),
        inclusive~,
      )
      .take(CAP)
      .to_array()
      .map(BigInt::from_int64) ==
      model(from, to, step, inclusive, i64_min, i64_max)
    },
    count=2000,
  )
}

///|
test "quickcheck: UInt matches the exact-arithmetic model" {
  @quickcheck.check(
    (input : (Int, Int, Int, Bool)) => {
      let (a, b, c, inclusive) = input
      let min = 0N
      let max = 4294967295N
      let (from, to, step) = build_case(min, max, a, b, c)
      @range.iter(
        from=from.to_uint(),
        to=to.to_uint(),
        step=step.to_uint(),
        inclusive~,
      )
      .take(CAP)
      .to_array()
      .map(BigInt::from_uint) ==
      model(from, to, step, inclusive, min, max)
    },
    count=2000,
  )
}

///|
test "quickcheck: UInt64 matches the exact-arithmetic model" {
  @quickcheck.check(
    (input : (Int, Int, Int, Bool)) => {
      let (a, b, c, inclusive) = input
      let min = 0N
      let max = 18446744073709551615N
      let (from, to, step) = build_case(min, max, a, b, c)
      @range.iter(
        from=from.to_uint64(),
        to=to.to_uint64(),
        step=step.to_uint64(),
        inclusive~,
      )
      .take(CAP)
      .to_array()
      .map(BigInt::from_uint64) ==
      model(from, to, step, inclusive, min, max)
    },
    count=2000,
  )
}

///|
test "quickcheck: Int16 matches the exact-arithmetic model" {
  @quickcheck.check(
    (input : (Int, Int, Int, Bool)) => {
      let (a, b, c, inclusive) = input
      let min = -32768N
      let max = 32767N
      let (from, to, step) = build_case(min, max, a, b, c)
      @range.iter(
        from=Int16::from_int(from.to_int()),
        to=Int16::from_int(to.to_int()),
        step=Int16::from_int(step.to_int()),
        inclusive~,
      )
      .take(CAP)
      .to_array()
      .map(v => BigInt::from_int(v.to_int())) ==
      model(from, to, step, inclusive, min, max)
    },
    count=2000,
  )
}

///|
test "quickcheck: UInt16 matches the exact-arithmetic model" {
  @quickcheck.check(
    (input : (Int, Int, Int, Bool)) => {
      let (a, b, c, inclusive) = input
      let min = 0N
      let max = 65535N
      let (from, to, step) = build_case(min, max, a, b, c)
      @range.iter(
        from=from.to_int().to_uint16(),
        to=to.to_int().to_uint16(),
        step=step.to_int().to_uint16(),
        inclusive~,
      )
      .take(CAP)
      .to_array()
      .map(v => BigInt::from_int(v.to_int())) ==
      model(from, to, step, inclusive, min, max)
    },
    count=2000,
  )
}

///|
test "quickcheck: Byte matches the exact-arithmetic model" {
  @quickcheck.check(
    (input : (Int, Int, Int, Bool)) => {
      let (a, b, c, inclusive) = input
      let min = 0N
      let max = 255N
      let (from, to, step) = build_case(min, max, a, b, c)
      @range.iter(
        from=from.to_int().to_byte(),
        to=to.to_int().to_byte(),
        step=step.to_int().to_byte(),
        inclusive~,
      )
      .take(CAP)
      .to_array()
      .map(v => BigInt::from_int(v.to_int())) ==
      model(from, to, step, inclusive, min, max)
    },
    count=2000,
  )
}

///|
test "quickcheck: BigInt matches the exact-arithmetic model" {
  // `BigInt` has no range to overflow, so the oracle's stop condition
  // must never fire: the sequence is decided purely by `to`.
  @quickcheck.check(
    (input : (Int, Int, Int, Bool)) => {
      let (a, b, c, inclusive) = input
      let (from, to, step) = build_case(i64_min, i64_max, a, b, c)
      @range.iter(from~, to~, step~, inclusive~).take(CAP).to_array() ==
      model(from, to, step, inclusive, -unbounded, unbounded)
    },
    count=2000,
  )
}

// =====================================================================
// Properties that hold for every element type.
// =====================================================================

///|
test "quickcheck: the general shape of an Int enumeration" {
  // Restating the contract without reference to the oracle: the values
  // are an arithmetic progression, strictly monotonic in the step's
  // direction, each strictly on the correct side of `to` (or equal to
  // it exactly once, at the end, when inclusive).
  @quickcheck.check(
    (input : (Int, Int, Int, Bool)) => {
      let (a, b, c, inclusive) = input
      let min = -2147483648N
      let max = 2147483647N
      let (from, to, step) = build_case(min, max, a, b, c)
      let values = @range.iter(
          from=from.to_int(),
          to=to.to_int(),
          step=step.to_int(),
          inclusive~,
        )
        .take(CAP)
        .to_array()
        .map(BigInt::from_int)
      if values.is_empty() {
        return true
      }
      // it starts at `from`
      guard values[0] == from else { return false }
      for i in 0..<values.length() {
        // it is an arithmetic progression with common difference `step`
        guard values[i] == from + step * BigInt::from_int(i) else {
          return false
        }
        // every value is on the correct side of `to`; `to` itself may
        // appear only when the range is inclusive
        let past_end = if step > 0N {
          values[i] > to
        } else if step < 0N {
          values[i] < to
        } else {
          false
        }
        guard !past_end else { return false }
        guard values[i] != to || inclusive else { return false }
      }
      true
    },
    count=2000,
  )
}

///|
test "quickcheck: an inclusive range is the exclusive one plus at most its endpoint" {
  @quickcheck.check(
    (input : (Int, Int, Int)) => {
      let (a, b, c) = input
      let min = -2147483648N
      let max = 2147483647N
      let (from, to, step) = build_case(min, max, a, b, c)
      let run = (inclusive : Bool) => {
        @range.iter(
          from=from.to_int(),
          to=to.to_int(),
          step=step.to_int(),
          inclusive~,
        )
        .take(CAP)
        .to_array()
      }
      let exclusive = run(false)
      let inclusive = run(true)
      // The inclusive run is the exclusive one, possibly with `to`
      // appended -- it can never differ anywhere else.
      if inclusive == exclusive {
        true
      } else {
        inclusive.length() == exclusive.length() + 1 &&
        inclusive[0:exclusive.length()].to_owned() == exclusive &&
        BigInt::from_int(inclusive[exclusive.length()]) == to
      }
    },
    count=2000,
  )
}

///|
test "quickcheck: reversing the step reverses the enumeration" {
  // Walking `from -> to` and then walking back from the last value with
  // the negated step must retrace exactly the same values. This ties
  // the ascending and descending branches together without the oracle.
  @quickcheck.check(
    (input : (Int, Int)) => {
      let start = wrap_index(input.0, 200) - 100
      let step = 1 + wrap_index(input.1, 9)
      let count = wrap_index(input.0 / 200, 30)
      let stop = start + step * count
      let up = @range.iter(from=start, to=stop, step~).to_array()
      if up.is_empty() {
        return true
      }
      let last = up[up.length() - 1]
      let down = @range.iter(from=last, to=start, step=-step, inclusive=true).to_array()
      down.rev() == up
    },
    count=1000,
  )
}

// =====================================================================
// Float and Double.
// =====================================================================

///|
/// The floating-point impls cannot be checked against exact arithmetic
/// (`from + k * step` is not what repeated addition computes), so they
/// are specified by invariant instead: strictly monotonic, every value
/// on the correct side of `to`, and -- the property that keeps a
/// sub-precision step from silently spinning forever -- terminating.
test "quickcheck: Double enumerations are monotonic, bounded, and finite" {
  @quickcheck.check(
    (input : (Int, Int, Int, Bool)) => {
      let (a, b, c, inclusive) = input
      let from = (wrap_index(a, 400) - 200).to_double() / 8.0
      let to = (wrap_index(b, 400) - 200).to_double() / 8.0
      let step = (wrap_index(c, 21) - 10).to_double() / 4.0
      let values = @range.iter(from~, to~, step~, inclusive~)
        .take(CAP)
        .to_array()
      if values.is_empty() {
        return true
      }
      guard values[0] == from else { return false }
      // strictly monotonic in the step's direction, and never past `to`
      for i in 0..<values.length() {
        if i > 0 {
          guard (if step > 0.0 {
            values[i] > values[i - 1]
          } else {
            values[i] < values[i - 1]
          }) else {
            return false
          }
        }
        let past_end = if step > 0.0 {
          values[i] > to
        } else if step < 0.0 {
          values[i] < to
        } else {
          false
        }
        guard !past_end else { return false }
        guard values[i] != to || inclusive else { return false }
      }
      // a zero step yields at most the single inclusive endpoint
      guard step != 0.0 || values.length() == 1 else { return false }
      true
    },
    count=2000,
  )
}

///|
test "quickcheck: Float agrees with Double on exactly representable values" {
  // Eighths of small integers are exact in both widths, so the two
  // impls must enumerate the same values -- any divergence is a bug in
  // one of the two `Step` instances rather than a rounding artefact.
  @quickcheck.check(
    (input : (Int, Int, Int, Bool)) => {
      let (a, b, c, inclusive) = input
      let from = (wrap_index(a, 400) - 200).to_double() / 8.0
      let to = (wrap_index(b, 400) - 200).to_double() / 8.0
      let step = (wrap_index(c, 21) - 10).to_double() / 4.0
      let wide = @range.iter(from~, to~, step~, inclusive~).take(CAP).to_array()
      let narrow = @range.iter(
          from=Float::from_double(from),
          to=Float::from_double(to),
          step=Float::from_double(step),
          inclusive~,
        )
        .take(CAP)
        .to_array()
      narrow.map(Float::to_double) == wide
    },
    count=2000,
  )
}

///|
test "a sub-precision step terminates instead of spinning" {
  // 1.0 is far below the ULP of 1e300, so `current + step == current`
  // and the iterator has to notice that it made no progress. Without
  // that check this would not terminate at all.
  inspect(
    @range.iter(from=1.0e300, to=1.0e301, step=1.0).to_array().length(),
    content=(
      #|1
    ),
  )
  inspect(
    @range.iter(from=(1.0e30 : Float), to=(1.0e31 : Float), step=1.0)
    .to_array()
    .length(),
    content=(
      #|1
    ),
  )
}

///|
test "a NaN endpoint yields nothing rather than looping" {
  let nan = (0.0 : Double) / 0.0
  // `Compare` on Double reports 0 against NaN, so the range check fails
  // immediately; the inclusive check uses `==`, which NaN also fails.
  inspect(
    @range.iter(from=0.0, to=nan).to_array().length(),
    content=(
      #|0
    ),
  )
  inspect(
    @range.iter(from=nan, to=10.0).to_array().length(),
    content=(
      #|0
    ),
  )
  inspect(
    @range.iter(from=0.0, to=nan, inclusive=true).to_array().length(),
    content=(
      #|0
    ),
  )
  inspect(
    @range.iter(from=0.0, to=10.0, step=nan).to_array().length(),
    content=(
      #|0
    ),
  )
  // a NaN step with from == to still yields nothing but the endpoint,
  // because the step makes no progress
  inspect(
    @range.iter(from=0.0, to=0.0, step=nan, inclusive=true).to_array().length(),
    content=(
      #|1
    ),
  )
}
