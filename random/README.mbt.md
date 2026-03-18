# Random

Cryptographically secure pseudo-random number generation based on the ChaCha8 cipher.

## Create

Create a random number generator with `Rand::new()`. Use a fixed seed for reproducible results:

```mbt check
///|
test "create" {
  let r = @random.Rand::new()
  inspect(r.uint(limit=100) < 100, content="true")
}
```

## Generating Values

Generate random values of different types:

```mbt check
///|
test "types" {
  let r = @random.Rand::new()
  let _i : Int = r.int()
  let _i_limited : Int = r.int(limit=100)
  let _u : UInt = r.uint()
  let _i64 : Int64 = r.int64()
  let _u64 : UInt64 = r.uint64()
  let _d : Double = r.double() // in [0.0, 1.0)
  let _f : Float = r.float() // in [0.0, 1.0)
  let _b : Bool = r.boolean()
}
```

## Shuffling

Shuffle elements using the Fisher-Yates algorithm:

```mbt check
///|
test "shuffle" {
  let r = @random.Rand::new()
  let a = [1, 2, 3, 4, 5]
  r.shuffle(a.length(), (i, j) => {
    let t = a[i]
    a[i] = a[j]
    a[j] = t
  })
  // Array is permuted, same elements
  a.sort()
  inspect(a, content="[1, 2, 3, 4, 5]")
}
```

## BigInt

Generate random big integers with a specified bit length:

```mbt check
///|
test "bigint" {
  let r = @random.Rand::new()
  let big = r.bigint(128)
  inspect(big >= 0N, content="true")
}
```
