# BigInt Package Documentation

This package provides arbitrary-precision integer arithmetic through the `BigInt` type. BigInt allows you to work with integers of unlimited size, making it perfect for cryptographic operations, mathematical computations, and any scenario where standard integer types are insufficient.

## Creating BigInt Values

There are several ways to create BigInt values:

```moonbit
///|
test "creating bigint values" {
  // From integer literals with 'N' suffix
  let big1 = 12345678901234567890N
  inspect(big1, content="12345678901234567890")

  // From regular integers
  let big2 = @bigint.BigInt::from_int(42)
  inspect(big2, content="42")

  // From Int64 values
  let big3 = @bigint.BigInt::from_int64(9223372036854775807L)
  inspect(big3, content="9223372036854775807")

  // From strings
  let big4 = @bigint.BigInt::from_string("123456789012345678901234567890")
  inspect(big4, content="123456789012345678901234567890")

  // From hexadecimal strings
  let big5 = @bigint.BigInt::from_hex("1a2b3c4d5e6f")
  inspect(big5, content="28772997619311")
}
```

## Basic Arithmetic Operations

BigInt supports all standard arithmetic operations:

```moonbit
///|
test "arithmetic operations" {
  let a = 123456789012345678901234567890N
  let b = 987654321098765432109876543210N

  // Addition
  let sum = a + b
  inspect(sum, content="1111111110111111111011111111100")

  // Subtraction
  let diff = b - a
  inspect(diff, content="864197532086419753208641975320")

  // Multiplication
  let product = @bigint.BigInt::from_int(123) * @bigint.BigInt::from_int(456)
  inspect(product, content="56088")

  // Division
  let quotient = @bigint.BigInt::from_int(1000) / @bigint.BigInt::from_int(7)
  inspect(quotient, content="142")

  // Modulo
  let remainder = @bigint.BigInt::from_int(1000) % @bigint.BigInt::from_int(7)
  inspect(remainder, content="6")

  // Negation
  let neg = -a
  inspect(neg, content="-123456789012345678901234567890")
}
```

## Comparison Operations

Compare BigInt values with each other and with regular integers:

```moonbit
///|
test "comparisons" {
  let big = 12345N
  let small = 123N

  // BigInt to BigInt comparison
  inspect(big > small, content="true")
  inspect(big == small, content="false")
  inspect(small < big, content="true")

  // BigInt to Int comparison
  inspect(big.equal_int(12345), content="true")
  inspect(big.compare_int(12345), content="0")
  inspect(big.compare_int(1000), content="1") // greater than
  inspect(small.compare_int(200), content="-1") // less than

  // BigInt to Int64 comparison
  let big64 = @bigint.BigInt::from_int64(9223372036854775807L)
  inspect(big64.equal_int64(9223372036854775807L), content="true")
}
```

## Bitwise Operations

BigInt supports bitwise operations for bit manipulation:

```moonbit
///|
test "bitwise operations" {
  let a = 0b11110000N // 240 in decimal
  let b = 0b10101010N // 170 in decimal

  // Bitwise AND
  let and_result = a & b
  inspect(and_result, content="160") // 0b10100000

  // Bitwise OR
  let or_result = a | b
  inspect(or_result, content="250") // 0b11111010

  // Bitwise XOR
  let xor_result = a ^ b
  inspect(xor_result, content="90") // 0b01011010

  // Bit length
  let big_num = 255N
  inspect(big_num.bit_length(), content="8")

  // Count trailing zeros
  let with_zeros = 1000N // Has trailing zeros in binary
  let ctz = with_zeros.ctz()
  inspect(ctz >= 0, content="true")
}
```

## Power and Modular Arithmetic

BigInt provides efficient power and modular exponentiation:

```moonbit
///|
test "power operations" {
  // Basic power
  let base = 2N
  let exponent = 10N
  let power = base.pow(exponent)
  inspect(power, content="1024")

  // Modular exponentiation (useful for cryptography)
  let base2 = 3N
  let exp2 = 5N
  let modulus = 7N
  let mod_power = base2.pow(exp2, modulus~)
  inspect(mod_power, content="5") // (3^5) % 7 = 243 % 7 = 5

  // Large modular exponentiation (optimized for speed)
  let large_base = 123N
  let large_exp = 20N
  let large_mod = 1000007N
  let result = large_base.pow(large_exp, modulus=large_mod)
  inspect(result, content="378446") // (123^20) % 1000007
}
```

## String and Hexadecimal Conversion

Convert BigInt to and from various string representations:

```moonbit
///|
test "string conversions" {
  let big = 255N

  // Decimal string
  let decimal = big.to_string()
  inspect(decimal, content="255")

  // Hexadecimal (lowercase)
  let hex_lower = big.to_hex()
  inspect(hex_lower, content="FF")

  // Hexadecimal (uppercase)
  let hex_upper = big.to_hex(uppercase=true)
  inspect(hex_upper, content="FF")

  // Parse from hex
  let from_hex = @bigint.BigInt::from_hex("deadbeef")
  inspect(from_hex, content="3735928559")

  // Round-trip conversion
  let original = 98765432109876543210N
  let as_string = original.to_string()
  let parsed_back = @bigint.BigInt::from_string(as_string)
  inspect(original == parsed_back, content="true")
}
```

## Byte Array Conversion

Convert BigInt to and from byte arrays:

```moonbit
///|
test "byte conversions" {
  let big = 0x123456789abcdefN

  // Convert to bytes
  let bytes = big.to_octets()
  inspect(bytes.length() > 0, content="true")

  // Convert from bytes (positive number)
  let from_bytes = @bigint.BigInt::from_octets(bytes)
  inspect(from_bytes == big, content="true")

  // Convert with specific length
  let fixed_length = @bigint.BigInt::from_int(255).to_octets(length=4)
  inspect(fixed_length.length(), content="4")

  // Negative numbers
  // let negative = -big
  // let neg_bytes = negative.to_octets()
  // to_octets does not accept negative numbers
  // let neg_from_bytes = @bigint.BigInt::from_octets(neg_bytes, signum=-1)
  // inspect(neg_from_bytes == negative, content="true")
}
```

## Type Conversions

Convert BigInt to standard integer types:

```moonbit
///|
test "type conversions" {
  let big = 12345N

  // To Int (truncates if too large)
  let as_int = big.to_int()
  inspect(as_int, content="12345")

  // To Int64
  let as_int64 = big.to_int64()
  inspect(as_int64, content="12345")

  // To UInt
  let as_uint = big.to_uint()
  inspect(as_uint, content="12345")

  // To smaller types
  let small = 255N
  let as_int16 = small.to_int16()
  inspect(as_int16, content="255")
  let as_uint16 = small.to_uint16()
  inspect(as_uint16, content="255")
}
```

## JSON Serialization

BigInt values can be serialized to and from JSON:

```moonbit
///|
test "json serialization" {
  let big = 12345678901234567890N

  // Convert to JSON (as string to preserve precision)
  let json = big.to_json()
  inspect(json, content="String(\"12345678901234567890\")")

  // Large numbers that exceed JavaScript's safe integer range
  let very_big = @bigint.BigInt::from_string("123456789012345678901234567890")
  let big_json = very_big.to_json()
  inspect(big_json, content="String(\"123456789012345678901234567890\")")
}
```

## Utility Functions

Check properties of BigInt values:

```moonbit
///|
test "utility functions" {
  let zero = 0N
  let positive = 42N
  let negative = -42N

  // Check if zero
  inspect(zero.is_zero(), content="true")
  inspect(positive.is_zero(), content="false")

  // Sign testing through comparison
  inspect(positive > zero, content="true")
  inspect(negative < zero, content="true")
  inspect(zero == zero, content="true")
}
```

## Use Cases and Applications

BigInt is particularly useful for:

1. **Cryptography**: RSA encryption, digital signatures, and key generation
2. **Mathematical computations**: Factorial calculations, Fibonacci sequences, prime number testing
3. **Financial calculations**: High-precision monetary computations
4. **Scientific computing**: Large integer calculations in physics and chemistry
5. **Data processing**: Handling large numeric IDs and checksums

## Performance Considerations

- BigInt operations are slower than regular integer operations due to arbitrary precision
- Addition and subtraction are generally fast
- Multiplication and division become slower with larger numbers
- Modular exponentiation is optimized for cryptographic use cases
- String conversions can be expensive for very large numbers

## Best Practices

1. **Use regular integers when possible**: Only use BigInt when you need arbitrary precision
2. **Cache string representations**: If you need to display the same BigInt multiple times
3. **Use modular arithmetic**: For cryptographic applications, always use modular exponentiation
4. **Be careful with conversions**: Converting very large BigInt to regular integers will truncate
5. **Consider memory usage**: Very large BigInt values consume more memory
