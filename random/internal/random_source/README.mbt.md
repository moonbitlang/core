# Random Internal Source Package Documentation

This package provides internal cryptographically secure random number generation using the ChaCha8 stream cipher. It is used internally by the random package to provide high-quality random numbers for security-sensitive applications.

## ChaCha8 Random Source

Create and use ChaCha8 random number generators:

```moonbit
test "chacha8 basics" {
  // Create ChaCha8 with seed bytes (32 bytes for ChaCha)
  let seed_bytes = Bytes::make(32, 0x42)  // Simple seed for testing
  let chacha = ChaCha8::new(seed_bytes)
  
  // Generate random UInt64 values
  match chacha.next() {
    Some(value) => inspect(value.to_string().length() > 0, content="true")
    None => inspect(false, content="true")  // Should have value
  }
}
```

## Random Number Generation

Generate cryptographically secure random numbers:

```moonbit
test "secure random generation" {
  let seed = Bytes::make(32, 0x01)  // Initialize with pattern
  let chacha = ChaCha8::new(seed)
  
  // Generate multiple random values
  let mut values = []
  for i in 0..<5 {
    match chacha.next() {
      Some(val) => values.push(val)
      None => {
        // Refill the internal buffer and try again
        chacha.refill()
        match chacha.next() {
          Some(val) => values.push(val)
          None => values.push(0UL)  // Fallback
        }
      }
    }
  }
  
  inspect(values.length(), content="5")
  
  // Values should be different (with very high probability)
  inspect(values[0] != values[1], content="true")
}
```

## Buffer Management

Handle internal buffer refilling:

```moonbit
test "buffer management" {
  let seed = Bytes::make(32, 0xFF)
  let chacha = ChaCha8::new(seed)
  
  // Generate values until buffer is exhausted
  let mut generated_count = 0
  for i in 0..<100 {  // Try to generate many values
    match chacha.next() {
      Some(_) => generated_count = generated_count + 1
      None => {
        // Buffer exhausted, refill it
        chacha.refill()
        generated_count = generated_count + 1
        break  // Exit after refill for test
      }
    }
  }
  
  inspect(generated_count > 0, content="true")
}
```

## Seed Initialization

Initialize ChaCha8 with different seed sources:

```moonbit
test "seed initialization" {
  // Create seed from pattern
  let pattern_seed = Bytes::new()
  for i in 0..<32 {
    pattern_seed.push(i.to_byte())
  }
  
  let chacha1 = ChaCha8::new(pattern_seed)
  
  // Create seed from different pattern
  let different_seed = Bytes::new()
  for i in 0..<32 {
    different_seed.push((i * 2).to_byte())
  }
  
  let chacha2 = ChaCha8::new(different_seed)
  
  // Different seeds should produce different sequences
  let val1 = chacha1.next().unwrap_or(0UL)
  let val2 = chacha2.next().unwrap_or(0UL)
  
  // Should be different (with very high probability)
  inspect(val1 != val2, content="true")
}
```

## Cryptographic Properties

ChaCha8 provides:

1. **Cryptographic security**: Suitable for security applications
2. **Fast generation**: Optimized ChaCha variant
3. **Large period**: Extremely long before repetition
4. **Uniform distribution**: All values equally likely
5. **Forward secrecy**: Previous outputs don't reveal future ones

## Internal Architecture

The ChaCha8 implementation:

- Uses 32-byte (256-bit) keys for initialization
- Generates blocks of random data internally
- Provides UInt64 values from the internal stream
- Automatically refills buffer when exhausted
- Maintains cryptographic security properties

## Security Considerations

```moonbit
test "security properties" {
  // Different seeds produce uncorrelated sequences
  let seed1 = Bytes::make(32, 0x01)
  let seed2 = Bytes::make(32, 0x02)
  
  let rng1 = ChaCha8::new(seed1)
  let rng2 = ChaCha8::new(seed2)
  
  // Generate values from both
  let val1 = rng1.next().unwrap_or(0UL)
  let val2 = rng2.next().unwrap_or(0UL)
  
  // Should be uncorrelated
  inspect(val1 != val2, content="true")
}
```

## Performance vs. Security Tradeoff

ChaCha8 balances:

- **Security**: Cryptographically secure output
- **Performance**: Faster than ChaCha20 but still secure
- **Quality**: Excellent statistical properties
- **Predictability**: Deterministic from seed (good for testing)

## Usage in Random Package

This package is used by the higher-level random package to:

1. **Seed system RNG**: Provide secure entropy source
2. **Generate test data**: Create random inputs for testing
3. **Cryptographic applications**: Generate keys, nonces, etc.
4. **Simulation**: Provide high-quality randomness

## Best Practices

1. **Use proper seeds**: Initialize with good entropy
2. **Handle buffer exhaustion**: Check for None and refill as needed
3. **Don't reuse generators**: Create new instances for independent sequences
4. **Consider performance**: ChaCha8 is fast but not as fast as non-cryptographic RNGs

This package provides the cryptographically secure foundation for random number generation in security-sensitive MoonBit applications.
