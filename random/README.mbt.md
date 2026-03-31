# Random

Pseudo-random number generation based on the ChaCha8 stream cipher. Provides unbiased generation of integers, floats, booleans, and big integers, as well as Fisher-Yates shuffling.

## Overview

The `Rand` type wraps a `Source` trait object that produces 64-bit random values. The default source is a ChaCha8 cipher seeded with a fixed 32-byte key. For reproducible results, use the same seed; for distinct streams, supply different seeds via `Rand::chacha8(seed~)`.

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
  assert_eq(a, b) // same seed → same sequence
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
  assert_eq(a, [1, 2, 3, 4, 5]) // same elements, just reordered
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
impl @random.Source for MySource with next(self) -> UInt64 {
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
