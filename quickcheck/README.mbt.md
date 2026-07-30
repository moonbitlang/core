# MoonBit QuickCheck Package

MoonBit QuickCheck package provides property-based testing capabilities by generating random test inputs.

## Checking Properties

Use `quickcheck` for the common property shape `(A) -> Bool raise?`. The
input type must implement `Arbitrary`, `Shrink`, and `Debug`.

```mbt check
///|
test "adding zero is an identity" {
  @quickcheck.quickcheck((x : Int) => x + 0 == x)
}
```

Returning `true` passes a case; returning `false` reports a logical
counterexample. A raised error is reported separately as an exceptional
counterexample. The first failure is greedily shrunk while preserving that
distinction: a `false` result cannot shrink into an error, and an error cannot
shrink into `false`.

Use the pure `filter` function for a precondition:

```mbt check
///|
test "division identity" {
  @quickcheck.quickcheck((x : Int) => x / x == 1, filter=x => x != 0)
}
```

Filtered cases do not count toward `count`. The driver gives up after ten
discarded cases per requested test by default. During shrinking, a filtered candidate
consumes one shrink attempt, its subtree is skipped, and shrinking continues
with the next candidate.

The optional controls are deterministic:

```mbt check
///|
test "configured property run" {
  @quickcheck.quickcheck(
    (xs : Array[Int]) => xs.length() >= 0,
    count=200,
    max_size=50,
    max_shrinks=100,
    discard_ratio=10,
    seed=2026,
  )
}
```

`count`, `max_size`, `max_shrinks`, and `discard_ratio` are unsigned. A zero
`count` performs no tests. `discard_ratio` defaults to ten discarded cases per
requested test; zero gives up on the first discarded case. Generator size grows
from zero to `max_size`; consecutive discards temporarily increase the
requested size so filtering cannot leave the run stuck at size zero. Because
`Arbitrary` receives an `Int` size, larger values saturate at `Int::MAX_VALUE`.
`max_shrinks` counts every shrink candidate examined, including filtered
candidates, so zero disables shrinking and even an infinite or cyclic shrink
stream terminates at the limit. A failure report includes the final
counterexample, error when applicable, size, and shrink counts.

If a test needs to inspect an expected failure, use `quickcheck_report` instead
of catching the `Failure` raised by `quickcheck`:

```mbt check
///|
test "inspect a counterexample" {
  let report = @quickcheck.quickcheck_report(
    (_ : Int) => false,
    count=1,
    max_size=0,
    max_shrinks=0,
    seed=7,
  )
  debug_inspect(
    report,
    content=(
      #|Falsified(
      #|  counterexample=0,
      #|  tests=1,
      #|  size=0,
      #|  shrinks=0,
      #|  shrink_attempts=0,
      #|)
    ),
  )
}
```

`quickcheck_report` returns `Passed`, `GaveUp`, `Falsified`, or `Raised`. Every
error from the property is a value in `Raised`; the driver does not distinguish
errors used by `inspect` or snapshot tests. `QuickCheckReport[A]` implements
`Debug` when `A` does, but unlike `quickcheck`, calling `quickcheck_report`
itself does not raise and does not require the input type to implement `Debug`.

Properties should be deterministic and should not mutate or consume their
input. In particular, an `Iter` is single-use; generate an `Array` and create a
fresh iterator inside the property when replayable sequence behavior matters.

## Basic Usage

Generate random values of any type that implements the `Arbitrary` trait:

```mbt check
///|
test "basic generation" {
  let b : Bool = @quickcheck.gen()
  inspect(b, content="true")
  let x : Int = @quickcheck.gen()
  inspect(x, content="0")

  // Generate with size parameter
  let sized : Array[Int] = @quickcheck.gen(size=5)
  inspect(sized.length() <= 5, content="true")
}
```

## Multiple Samples

Generate multiple test cases using the `samples` function:

```mbt check
///|
test "multiple samples" {
  let ints : Array[Int] = @quickcheck.samples(5)
  debug_inspect(ints, content="[0, 0, 0, -1, -1]")
  let strings : Array[String] = @quickcheck.samples(12)
  debug_inspect(
    strings[5:10],
    content=(
      #|<ArrayView: ["E\b\u{0f} ", "", "K\u{1f}[", "!@", "xvLxb"]>
    ),
  )
}
```

## Built-in Types

QuickCheck provides `Arbitrary` implementations for all basic MoonBit types:

```mbt check
///|
test "builtin types" {
  // Basic types
  let v : (Bool, Char, Byte) = @quickcheck.gen()
  debug_inspect(
    v,
    content=(
      #|(false, '\u{02}', 0x4d)
    ),
  )
  // Numeric types
  let v : (Int, Int64, UInt, UInt64, Float, Double, BigInt) = @quickcheck.gen()
  debug_inspect(
    v,
    content="(0, 0, 0, 0, 0.23986786603927612, 0.7917029935679342, 0)",
  )
  // Collections
  let v : (String, Bytes, Iter[Int]) = @quickcheck.gen()
  let (s, b, iter) = v
  debug_inspect(
    (s, b, iter.to_array()),
    content=(
      #|("", <Bytes: []>, [])
    ),
  )
}
```

## Custom Types

Implement `Arbitrary` trait for custom types:

```mbt check
///|
priv struct Point {
  x : Int
  y : Int
} derive(Debug)

///|
impl Arbitrary for Point with fn arbitrary(size, r0) {
  let r1 = r0.split()
  let y = @quickcheck.Arbitrary::arbitrary(size, r1)
  { x: @quickcheck.Arbitrary::arbitrary(size, r0), y }
}

///|
test "custom type generation" {
  let point : Point = @quickcheck.gen()
  debug_inspect(
    point,
    content=(
      #|{ x: 0, y: 0 }
    ),
  )
  let points : Array[Point] = @quickcheck.samples(10)
  debug_inspect(
    points[6:],
    content=(
      #|<ArrayView:
      #|  [{ x: 0, y: 1 }, { x: -1, y: -5 }, { x: -6, y: -6 }, { x: -1, y: 7 }]>
    ),
  )
}
```

The package is useful for writing property tests that verify code behavior across a wide range of randomly generated inputs.
