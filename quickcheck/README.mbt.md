# MoonBit QuickCheck Package

MoonBit QuickCheck package provides property-based testing capabilities by generating random test inputs.

## Checking Properties

Use `check` for the common property shape `(A) -> Bool raise?`. The
input type must implement `Arbitrary`, `Shrink`, and `Debug`.

```mbt check
///|
test "adding zero is an identity" {
  @quickcheck.check((x : Int) => x + 0 == x)
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
  @quickcheck.check((x : Int) => x / x == 1, filter=x => x != 0)
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
  @quickcheck.check(
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

If a test needs to inspect an expected failure, use `report` instead of
catching the `Failure` raised by `check`:

```mbt check
///|
test "inspect a counterexample" {
  let report = @quickcheck.report(
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
      #|  counterexample=-1028290551,
      #|  tests=1,
      #|  size=0,
      #|  shrinks=0,
      #|  shrink_attempts=0,
      #|)
    ),
  )
}
```

`report` returns an abstract `QuickCheckReport[A]` whose `Debug`
representation distinguishes `Passed`, `GaveUp`, `Falsified`, and `Raised`.
Every error from the property is represented by `Raised`; the driver does not
distinguish errors used by `inspect` or snapshot tests. Calling `report` itself
does not raise and does not require the input type to implement `Debug`.

`counterexample_context` attaches a human-readable rendering of the shrunk counterexample
to a failure — useful when the generated value's `Debug` form is not the
most readable description of what failed (for example, a rendered document
rather than its AST):

```mbt check
///|
test "context describes the shrunk counterexample" {
  let report = @quickcheck.report(
    (x : Int) => x < 3,
    counterexample_context=x => "rendered input <\{x}>",
    seed=7,
  )
  debug_inspect(
    report,
    content=(
      #|Falsified(
      #|  counterexample=3,
      #|  context="rendered input <3>",
      #|  tests=2,
      #|  size=1,
      #|  shrinks=30,
      #|  shrink_attempts=33,
      #|)
    ),
  )
}
```

Properties should be deterministic and should not mutate or consume their
input. In particular, an `Iter` is single-use; generate an `Array` and create a
fresh iterator inside the property when replayable sequence behavior matters.

## Observing Generated Data

Use the pure `observe` function to inspect the distribution of successful
generated cases. `label` adds a string, `collect` adds a value's `Debug`
representation, and `classify` counts a named condition:

```mbt check
///|
test "observe generated cases" {
  let report = @quickcheck.report(
    (_ : Unit) => true,
    observe=_ => {
      [@quickcheck.label("unit"), @quickcheck.classify(true, "generated")]
    },
    count=2,
  )
  debug_inspect(
    report,
    content=(
      #|Passed(
      #|  tests=2,
      #|  observations={ labels: { <List: ["unit"]>: 2 }, classes: { "generated": 2 } },
      #|)
    ),
  )
}
```

Labels produced by one case form one joint bucket; classes are counted
independently. Only successful top-level cases run `observe`; filtered and
failing cases, including shrink candidates, do not contribute observations.

After a successful run, `check` prints an aligned observation table when any
observations were collected; otherwise it prints nothing. On failure, the
aggregate from preceding successful cases is included in the failure message.
Use `report` when the structured result should be handled without printing or
raising.

## Basic Usage

Generate random values of any type that implements the `Arbitrary` trait:

```mbt check
///|
test "basic generation" {
  let b : Bool = @quickcheck.gen()
  inspect(b, content="true")
  let x : Int = @quickcheck.gen()
  inspect(
    x,
    content=(
      #|1118850684
    ),
  )

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
  debug_inspect(
    ints,
    content=(
      #|[1118850684, -99999, 846697896, -134217729, 67108863]
    ),
  )
  let strings : Array[String] = @quickcheck.samples(12)
  debug_inspect(
    strings[5:10],
    content=(
      #|<ArrayView: ["(K񁁛!", "", "vx2\b", "", "𶏱Hp9\u{18}Rx"]>
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
      #|(false, '~', 0x4d)
    ),
  )
  // Numeric types
  let v : (Int, Int64, UInt, UInt64, Float, Double, BigInt) = @quickcheck.gen()
  debug_inspect(
    v,
    content=(
      #|(
      #|  -99999,
      #|  5259998046134461054,
      #|  228947857,
      #|  8766027650639656979,
      #|  0.23986786603927612,
      #|  0.7917029935679342,
      #|  0,
      #|)
    ),
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

Integer generation for `Int16`, `UInt16`, `Int`, `UInt`, `Int64`, and `UInt64`
intentionally ignores the size hint. Its default distribution combines
full-width random bit patterns, common small values, values next to powers of
two and ten, and type extrema. This keeps the entire scalar domain reachable
while regularly exercising overflow, bit-width, and formatting boundaries.
`Byte` remains uniformly distributed across all 256 bit patterns so `Bytes`
and other byte-oriented workloads retain broad payload coverage. Fixed-width
integer shrinkers try a midpoint first, then progressively finer candidates
approaching the original value, with zero as the final fallback. With the
greedy shrink driver, large failures still converge without linearly walking
the numeric range while avoiding a likely rejected zero at every level.

## Custom Types

Implement the `Arbitrary` and `Shrink` traits for custom types. Both traits are
available from the `quickcheck` facade; no separate `quickcheck/shrink` import
is needed:

```mbt check
///|
priv struct Point {
  x : Int
  y : Int
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Point with fn arbitrary(size, r0) {
  let r1 = r0.split()
  let y = @quickcheck.Arbitrary::arbitrary(size, r1)
  { x: @quickcheck.Arbitrary::arbitrary(size, r0), y, }
}

///|
impl @quickcheck.Shrink for Point with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.x, self.y)).map(pair => {
    x: pair.0,
    y: pair.1,
  })
}

///|
test "custom type generation" {
  let point : Point = @quickcheck.gen()
  debug_inspect(
    point,
    content=(
      #|{ x: -99999, y: 2 }
    ),
  )
  let points : Array[Point] = @quickcheck.samples(10)
  debug_inspect(
    points[6:],
    content=(
      #|<ArrayView:
      #|  [
      #|    { x: 46354256, y: 1201652877 },
      #|    { x: 1, y: 2147483646 },
      #|    { x: 108552206, y: -1 },
      #|    { x: -1073741824, y: 2147483647 },
      #|  ]>
    ),
  )
}

///|
test "custom type shrinking" {
  let point : Point = { x: 2, y: 1, }
  debug_inspect(
    @quickcheck.Shrink::shrink(point).collect(),
    content=(
      #|[{ x: 1, y: 1 }, { x: 0, y: 1 }, { x: 2, y: 0 }]
    ),
  )
}
```

The package is useful for writing property tests that verify code behavior across a wide range of randomly generated inputs.
