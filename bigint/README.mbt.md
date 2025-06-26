# `bigint`

This package provides arbitrary-precision integer arithmetic through the `BigInt` type, enabling calculations with integers of unlimited size.

## Creating BigInt Values

There are multiple ways to create `BigInt` values from different sources:

```moonbit
test "creating bigints" {
  // From integer literals
  let a = 42N  // BigInt literal syntax
  let b = BigInt::from_int(42)
  let c = BigInt::from_int64(1234567890123456789L)
  
  // From strings
  let d = BigInt::from_string("123456789012345678901234567890")
  let e = BigInt::from_hex("1F4")
  
  // From unsigned integers
  let f = BigInt::from_uint(4294967295)
  let g = BigInt::from_uint64(18446744073709551615UL)
  
  inspect(a, content="42")
  inspect(b, content="42")
  inspect(c, content="1234567890123456789")
  inspect(d, content="123456789012345678901234567890")
  inspect(e, content="500") // 0x1F4 = 500
  inspect(f, content="4294967295")
  inspect(g, content="18446744073709551615")
}
```

## Basic Arithmetic

`BigInt` supports all standard arithmetic operations with unlimited precision:

```moonbit
test "arithmetic operations" {
  let a = BigInt::from_string("123456789012345678123456789012345678")
  let b = BigInt::from_string("987654321098765432987654321098765432")
  
  // Addition
  let sum = a + b
  inspect(sum, content="1111111110111111111111111110111111110")
  
  // Subtraction
  let diff = a - b
  inspect(diff, content="-864197532086419754864197532086419754")
  
  // Multiplication
  let product = a * b
  inspect(product.to_string().length() > 50, content="true") // Very large number
  
  // Division and modulo
  let quotient = b / a
  let remainder = b % a
  inspect(quotient, content="8")
  inspect(remainder.to_string().length() > 10, content="true") // Also large
}
```

## Bitwise Operations

Perform bitwise operations on big integers:

```moonbit
test "bitwise operations" {
  let a = BigInt::from_hex("FF")
  let b = BigInt::from_hex("F0")
  
  // Bitwise AND
  let and_result = a & b
  inspect(and_result, content="240") // 0xF0
  
  // Bitwise OR
  let or_result = a | b
  inspect(or_result, content="255") // 0xFF
  
  // Bitwise XOR
  let xor_result = a ^ b
  inspect(xor_result, content="15") // 0x0F
  
  // Bit shifting
  let shifted_left = a << 4
  let shifted_right = (a << 8) >> 4
  inspect(shifted_left, content="4080") // 0xFF0
  inspect(shifted_right, content="255") // 0xFF
}
```

## Conversions and Number Formats

Convert `BigInt` values to different formats and types:

```moonbit
test "conversions" {
  let big = BigInt::from_string("1234567890")
  
  // Convert to string representations
  inspect(big.to_string(), content="1234567890")
  inspect(big.to_hex(), content="499602D2")
  inspect(big.to_hex(uppercase=false), content="499602d2")
  
  // Convert to fixed-size integers (with overflow)
  inspect(big.to_int(), content="1234567890")
  inspect(big.to_int64(), content="1234567890")
  inspect(big.to_uint(), content="1234567890")
  inspect(big.to_uint64(), content="1234567890")
  
  // Convert to/from byte arrays
  let bytes = big.to_octets()
  let restored = BigInt::from_octets(bytes)
  assert_eq(big, restored)
}
```

## Comparisons

Compare `BigInt` values with each other and with other integer types:

```moonbit
test "comparisons" {
  let big1 = 123N
  let big2 = 456N
  
  // Compare BigInt values
  assert_true(big1 < big2)
  assert_true(big1.compare(big2) < 0)
  
  // Compare with regular integers
  assert_true(big1.equal_int(123))
  assert_true(big1.equal_int64(123L))
  
  // Compare returns ordering
  inspect(big1.compare_int(100), content="1") // 123 > 100
  inspect(big1.compare_int(123), content="0") // 123 = 123
  inspect(big1.compare_int(200), content="-1") // 123 < 200
}
```

## Mathematical Functions

Perform advanced mathematical operations:

```moonbit
test "mathematical functions" {
  let base = 2N
  let exponent = 10N
  
  // Power function
  let result = base.pow(exponent)
  inspect(result, content="1024")
  
  // Power with modulus for efficient modular exponentiation
  let modular_result = base.pow(exponent, modulus=100N)
  inspect(modular_result, content="24") // 2^10 mod 100 = 24
  
  // Bit length and trailing zeros
  let num = 1024N // 2^10
  inspect(num.bit_length(), content="11") // needs 11 bits
  inspect(num.ctz(), content="10") // 10 trailing zeros
  
  // Check if zero
  assert_true(0N.is_zero())
  assert_false(123N.is_zero())
}
```

## JSON Serialization

`BigInt` values can be serialized to and from JSON:

```moonbit
test "json serialization" {
  let big = 12345678901234567890N
  
  // Convert to JSON (as string to preserve precision)
  let json = big.to_json()
  inspect(json, content="\"12345678901234567890\"")
  
  // The JSON representation preserves exact value
  // Parse back from JSON string would restore the original value
}
```

## Utility Functions

Additional utility functions for working with big integers:

```moonbit
test "utilities" {
  let positive = 42N
  let negative = -42N
  let zero = 0N
  
  // Negation
  inspect(-positive, content="-42")
  inspect(-negative, content="42")
  inspect(-zero, content="0")
  
  // Hash function for use in hash maps/sets
  let hash1 = positive.hash()
  let hash2 = positive.hash()
  assert_eq(hash1, hash2) // Consistent hashing
  
  // Different values should have different hashes
  assert_not_eq(positive.hash(), negative.hash())
}
```

## Common Patterns

Some useful patterns when working with `BigInt`:

```moonbit
test "common patterns" {
  // Check if a BigInt fits in smaller integer types
  let big = 123N
  let large = BigInt::from_string("999999999999999999999")
  
  // Safe conversion with bounds checking
  if big.compare_int64(9223372036854775807L) <= 0 && 
     big.compare_int64(-9223372036854775808L) >= 0 {
    let as_int64 = big.to_int64()
    inspect(as_int64, content="123")
  }
  
  // Check that large numbers don't fit
  inspect(large > BigInt::from_int64(9223372036854775807L), content="true")
  
  // Working with very large numbers
  let factorial_20 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
    .fold(init=1N, fn(acc, n) { acc * BigInt::from_int(n) })
  inspect(factorial_20, content="2432902008176640000")
  
  // Number base conversions
  let hex_str = "DEADBEEF"
  let from_hex = BigInt::from_hex(hex_str)
  let back_to_hex = from_hex.to_hex()
  inspect(back_to_hex, content="DEADBEEF")
}
```

The `BigInt` type provides a complete solution for arbitrary-precision integer arithmetic in MoonBit, supporting all necessary operations while maintaining compatibility with standard integer types through conversion and comparison functions.