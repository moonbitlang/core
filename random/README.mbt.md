# Random

Pseudo-random number generation based on the ChaCha8 stream cipher. Provides unbiased generation of integers, floats, booleans, and big integers, as well as Fisher-Yates shuffling.

## Overview

The `Rand` type wraps a `Source` trait object that produces 64-bit random values. By default, `Rand::new()` uses a ChaCha8 cipher seeded from platform entropy when available, and falls back to the default fixed seed on unsupported targets. For reproducible results, use `Rand::chacha8(seed~)` with the same 32-byte seed; for distinct reproducible streams, supply different seeds.

## Create

Create a generator with the default ChaCha8 source:

```mbt check
///|
test {
  let r = @random.Rand::new()
  inspect(r.uint(limit=100) < 100, content="true")
}
```

Supply a custom 32-byte seed for a different (but reproducible) stream:

```mbt check
///|
test {
  let r = @random.Rand::chacha8(seed=b"0123456789abcdef0123456789abcdef")
  let a = r.int()
  let r2 = @random.Rand::chacha8(seed=b"0123456789abcdef0123456789abcdef")
  let b = r2.int()
  @test.assert_eq(a, b) // same seed → same sequence
}
```

## Generating Integers

`int()`, `uint()`, `int64()`, and `uint64()` each accept an optional `limit` parameter. When omitted (or zero), the full non-negative range is returned. When provided, the result is in `[0, limit)` with no modulo bias.

```mbt check
///|
test {
  let r = @random.Rand::new()
  // full range
  let _ : Int = r.int() // [0, 2^31)
  let _ : UInt = r.uint() // [0, 2^32)
  let _ : Int64 = r.int64() // [0, 2^63)
  let _ : UInt64 = r.uint64() // [0, 2^64)
  // bounded
  let die = r.int(limit=6) // [0, 6)
  inspect(die >= 0 && die < 6, content="true")
  let pct = r.uint(limit=100U)
  inspect(pct < 100U, content="true")
}
```

## Generating Floats

`double()` returns a value in `[0.0, 1.0)` with 53-bit precision. `float()` returns a value in `[0.0, 1.0)` with 24-bit precision.

```mbt check
///|
test {
  let r = @random.Rand::new()
  let d = r.double()
  inspect(d >= 0.0 && d < 1.0, content="true")
  let f = r.float()
  inspect(f >= (0.0 : Float) && f < (1.0 : Float), content="true")
}
```

Pass `min` and `max` to `double()` or `float()` for an arbitrary half-open
interval. Non-unit intervals use Goualard's gamma-section algorithm: they select
uniformly from a fixed grid whose step is the larger endpoint spacing. Grid
values are one step apart, except for a possible shorter gap at the included
lower bound. In contrast, scaling a value from `[0.0, 1.0)` with
`min + (max - min) * x` can bias the result or return the open upper bound
because of intermediate rounding.

```mbt check
///|
test {
  let r = @random.Rand::new()
  let d = r.double(min=-10.0, max=10.0)
  inspect(d >= -10.0 && d < 10.0, content="true")
  let f = r.float(min=-10.0F, max=10.0F)
  inspect(f >= -10.0F && f < 10.0F, content="true")
}
```

To prevent quarter-scaling a bound into the subnormal range, these methods
reject non-zero bounds whose magnitude is below four times the smallest
positive normal value for the corresponding type. Zero remains a valid bound.
The selected grid step may still be subnormal, where IEEE 754 gradual
underflow preserves it exactly. `double()` additionally rejects an
interval if scaling either bound by that step would underflow;
`float()` performs the setup calculation exactly in `Double` precision.

## Boolean

`boolean()` returns `true` or `false` with equal probability.

```mbt check
///|
test {
  let r = @random.Rand::new()
  let _ : Bool = r.boolean()
}
```

## Shuffling

`shuffle(n, swap)` performs a Fisher-Yates shuffle over `n` elements using the provided swap callback.

```mbt check
///|
test {
  let r = @random.Rand::new()
  let a = [1, 2, 3, 4, 5]
  r.shuffle(a.length(), fn(i, j) {
    let t = a[i]
    a[i] = a[j]
    a[j] = t
  })
  a.sort()
  @test.assert_eq(a, [1, 2, 3, 4, 5]) // same elements, just reordered
}
```

## BigInt

Generate a random non-negative `BigInt` with a given number of bits:

```mbt check
///|
test {
  let r = @random.Rand::new()
  let big = r.bigint(128)
  inspect(big >= 0N, content="true")
}
```

## Custom Source

Implement the `Source` trait to plug in your own RNG backend. The trait requires a single method `next(Self) -> UInt64`.

```mbt nocheck
///|
struct MySource {
  mut value : UInt64
}

///|
impl @random.Source for MySource with fn next(self) -> UInt64 {
  self.value = self.value * 6364136223846793005UL + 1UL
  self.value
}

///|
test {
  let gen : MySource = { value: 42 }
  let r = @random.Rand::new(generator=gen as &@random.Source)
  let _ = r.uint64()
}
```
