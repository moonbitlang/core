# QuickCheck SplitMix Package Documentation

This package provides the SplitMix random number generator, which is used internally by the QuickCheck property-based testing framework. SplitMix is a fast, high-quality pseudorandom number generator suitable for testing and simulation.

## Random State Creation

Create and initialize random number generators:

```mbt check
///|
test "random state creation" {
  // Create with default seed
  let rng1 = @splitmix.new()
  inspect(rng1.to_string().length() > 0, content="true")

  // Create with specific seed
  let rng2 = @splitmix.new(seed=12345UL)
  inspect(rng2.to_string().length() > 0, content="true")

  // Clone existing state
  let rng3 = rng2.clone()
  inspect(rng3.to_string().length() > 0, content="true")
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
  inspect(int_val.to_string().length() > 0, content="true")

  // Generate positive integers only
  let pos_int = rng.next_positive_int()
  inspect(pos_int > 0, content="true")

  // Generate UInt values
  let uint_val = rng.next_uint()
  inspect(uint_val.to_string().length() > 0, content="true")

  // Generate Int64 values
  let int64_val = rng.next_int64()
  inspect(int64_val.to_string().length() > 0, content="true")

  // Generate UInt64 values
  let uint64_val = rng.next_uint64()
  inspect(uint64_val.to_string().length() > 0, content="true")
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
  inspect(uint1.to_string().length() > 0, content="true")
  inspect(uint2.to_string().length() > 0, content="true")

  // Split the generator (for parallel use)
  let split_rng = rng.split()

  // Both generators should work independently
  let original_val = rng.next_int()
  let split_val = split_rng.next_int()
  inspect(original_val.to_string().length() > 0, content="true")
  inspect(split_val.to_string().length() > 0, content="true")
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
  inspect(after_advance.to_string().length() > 0, content="true")

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
  let seq1 = [rng1.next_int(), rng1.next_int(), rng1.next_int()]
  let seq2 = [rng2.next_int(), rng2.next_int(), rng2.next_int()]
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
- **Memory usage**: Minimal state (single 64-bit value)
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
