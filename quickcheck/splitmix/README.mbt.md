# QuickCheck SplitMix Package Documentation

This package provides the SplitMix random number generator, which is used internally by the QuickCheck property-based testing framework. SplitMix is a fast, high-quality pseudorandom number generator suitable for testing and simulation.

## Random State Creation

Create and initialize random number generators:

```mbt check
///|
test "random state creation" {
  // Create with default seed
  let rng1 = @splitmix.new()
  debug_inspect(
    rng1,
    content=(
      #|{ seed: 6185074585042305769, gamma: 16934044424796929712 }
    ),
  )

  // Create with specific seed
  let rng2 = @splitmix.new(seed=12345UL)
  debug_inspect(
    rng2,
    content=(
      #|{ seed: 1716623506685013753, gamma: 14663218685290508263 }
    ),
  )

  // Clone existing state
  let rng3 = rng2.clone()
  debug_inspect(
    rng3,
    content=(
      #|{ seed: 1716623506685013753, gamma: 14663218685290508263 }
    ),
  )
}
```

## Generating Random Numbers

Generate various types of random numbers:

```mbt check
///|
test "random number generation" {
  let rng = @splitmix.new(seed=42UL)

  // Generate random integers
  let int_val = rng.next_int()
  debug_inspect(
    int_val,
    content=(
      #|-1716621765
    ),
  )

  // Generate positive integers only
  let pos_int = rng.next_positive_int()
  inspect(pos_int > 0, content="true")

  // Generate UInt values
  let uint_val = rng.next_uint()
  debug_inspect(
    uint_val,
    content=(
      #|40636561
    ),
  )

  // Generate Int64 values
  let int64_val = rng.next_int64()
  debug_inspect(
    int64_val,
    content=(
      #|640680877524568329
    ),
  )

  // Generate UInt64 values
  let uint64_val = rng.next_uint64()
  debug_inspect(
    uint64_val,
    content=(
      #|11629490981681548516
    ),
  )
}
```

## Bounded Unsigned Integers

Pass `limit` to `next_uint` or `next_uint64` for unbiased values below an
exclusive upper bound. Unlike `% limit`, these methods reject excess source
words so every result in the requested interval has the same probability.
Omitting `limit` generates across the complete unsigned range.

```mbt check
///|
test "bounded unsigned generation" {
  let rng = @splitmix.new(seed=42UL)
  debug_inspect(
    (
      rng.next_uint(limit=10U),
      rng.next_uint64(limit=3UL),
      rng.next_uint(limit=16U),
    ),
    content=(
      #|(0, 1, 9)
    ),
  )
}
```

## Floating-Point Random Numbers

Generate random floating-point values:

```mbt check
///|
test "floating point generation" {
  let rng = @splitmix.new(seed=123UL)

  // Generate random doubles [0.0, 1.0)
  let double_val = rng.next_double()
  inspect(double_val >= 0.0, content="true")
  inspect(double_val < 1.0, content="true")

  // Generate random floats [0.0, 1.0)
  let float_val = rng.next_float()
  inspect(float_val >= 0.0, content="true")
  inspect(float_val < 1.0, content="true")

  // Generate multiple values
  let val1 = rng.next_double()
  let val2 = rng.next_double()

  // Should be different (with high probability)
  inspect(val1 != val2, content="true")
}
```

## Advanced Operations

Use advanced RNG operations:

```mbt check
///|
test "advanced operations" {
  let rng = @splitmix.new(seed=999UL)

  // Generate two UInt values at once
  let (uint1, uint2) = rng.next_two_uint()
  debug_inspect(
    uint1,
    content=(
      #|3306273023
    ),
  )
  debug_inspect(
    uint2,
    content=(
      #|472035372
    ),
  )

  // Split the generator (for parallel use)
  let split_rng = rng.split()

  // Both generators should work independently
  let original_val = rng.next_int()
  let split_val = split_rng.next_int()
  debug_inspect(
    original_val,
    content=(
      #|2115132817
    ),
  )
  debug_inspect(
    split_val,
    content=(
      #|400628363
    ),
  )
}
```

## State Management

Manage random number generator state:

```mbt check
///|
test "state management" {
  let rng = @splitmix.new(seed=555UL)

  // Advance the state manually
  rng.next()

  // Generate value after advancing
  let after_advance = rng.next_int()
  debug_inspect(
    after_advance,
    content=(
      #|817660368
    ),
  )

  // Create independent copy
  let independent = rng.clone()

  // Both should generate the same sequence from this point
  let val1 = rng.next_int()
  let val2 = independent.next_int()
  inspect(val1 == val2, content="true") // Should be identical
}
```

## Deterministic Testing

Use seeded generators for reproducible tests:

```mbt check
///|
test "deterministic testing" {
  // Same seed should produce same sequence
  let rng1 = @splitmix.new(seed=777UL)
  let rng2 = @splitmix.new(seed=777UL)

  // Generate same sequence
  let seq1 : ReadOnlyArray[Int] = [
    rng1.next_int(),
    rng1.next_int(),
    rng1.next_int(),
  ]
  let seq2 : ReadOnlyArray[Int] = [
    rng2.next_int(),
    rng2.next_int(),
    rng2.next_int(),
  ]
  inspect(seq1[0] == seq2[0], content="true")
  inspect(seq1[1] == seq2[1], content="true")
  inspect(seq1[2] == seq2[2], content="true")
}
```

## Integration with QuickCheck

This generator is used by QuickCheck for property testing:

```mbt check
///|
test "quickcheck integration concept" {
  // Conceptual usage in property-based testing
  fn test_property_with_random_data() -> Bool {
    let rng = @splitmix.new()

    // Generate test data
    let test_int = rng.next_positive_int()
    let test_double = rng.next_double()

    // Test some property
    test_int > 0 && test_double >= 0.0 && test_double < 1.0
  }

  let property_holds = test_property_with_random_data()
  inspect(property_holds, content="true")
}
```

## SplitMix Algorithm Properties

SplitMix provides:

1. **High quality**: Passes statistical randomness tests
2. **Fast generation**: Optimized for speed
3. **Splittable**: Can create independent generators
4. **Deterministic**: Same seed produces same sequence
5. **Period**: Very long period before repetition

## Performance Characteristics

- **Generation speed**: Very fast (few CPU cycles per number)
- **Memory usage**: Minimal state (two 64-bit values: `seed` and `gamma`)
- **Quality**: Good statistical properties for testing
- **Splitting**: O(1) to create independent generators

## Use Cases

1. **Property-based testing**: Generate random test inputs
2. **Simulation**: Monte Carlo simulations and modeling
3. **Sampling**: Random sampling from data sets
4. **Shuffling**: Randomize array orders
5. **Game development**: Non-cryptographic randomness

## Best Practices

1. **Use seeds for reproducibility**: Fixed seeds for debugging
2. **Split for parallelism**: Create independent generators for parallel testing
3. **Not cryptographically secure**: Don't use for security-sensitive applications
4. **Cache generators**: Reuse generator instances when possible

This package provides the random number generation foundation for QuickCheck's property-based testing capabilities.
