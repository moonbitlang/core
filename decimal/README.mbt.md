# `Decimal`

This package provides the use of high-precision decimal numbers.

## Creating Decimals

You can create a Decimal from parts, from an integer, or from other values:

```moonbit
test "create decimal" {
  // From mantissa and scale
  let d1 = @decimal.from_parts(@bigint.BigInt::from_int(12345), 2)
  inspect(d1.to_string(), content="123.45")

  // From integer
  let d2 = @decimal.from_int(42)
  inspect(d2.to_string(), content="42")

  // Negative decimal
  let d3 = @decimal.from_parts(@bigint.BigInt::from_int(-9876), 3)
  inspect(d3.to_string(), content="-9.876")
}
```

## Comparison

Decimal implements both Eq and Compare traits, so you can compare them just like numbers:

```moonbit
test "compare decimals" {
  let a = @decimal.from_parts(@bigint.BigInt::from_int(100), 2) // 1.00
  let b = @decimal.from_parts(@bigint.BigInt::from_int(99), 2)  // 0.99

  inspect(a == a, content="true")
  inspect(a == b, content="false")

  inspect(a > b, content="true")
  inspect(b < a, content="true")

  // Equal after normalization
  let c = @decimal.from_parts(@bigint.BigInt::from_int(1000), 3) // 1.000
  inspect(a == c, content="true")
}
```

## String Conversion

You can convert a Decimal to its string representation using to_string:

```moonbit
test "to_string" {
  let d1 = @decimal.from_parts(@bigint.BigInt::from_int(5), 0)
  inspect(d1.to_string(), content="5")

  let d2 = @decimal.from_parts(@bigint.BigInt::from_int(5), 3)
  inspect(d2.to_string(), content="0.005")

  let d3 = @decimal.from_parts(@bigint.BigInt::from_int(-123456), 4)
  inspect(d3.to_string(), content="-12.3456")
}
``` 

## Basic operations of addition, subtraction, multiplication, and division

Decimal implements addition, subtraction, multiplication, and division, so you can perform operations on it:

```moonbit
test "Four basic operations" {
  let d1 = from_parts(@bigint.BigInt::from_int(123), 1)  
  let d2 = from_parts(@bigint.BigInt::from_int(456), 1)  
  let result = add(d1, d2)
  inspect(result.to_string(), content="57.9")

  let d1 = from_parts(@bigint.BigInt::from_int(123), 1)  
  let d2 = from_parts(@bigint.BigInt::from_int(456), 1)  
  let result = sub(d1, d2)
  inspect(result.to_string(), content="-33.3")

  let d1 = from_parts(@bigint.BigInt::from_int(1234), 2)  
  let d2 = from_parts(@bigint.BigInt::from_int(56), 1)    
  let result = mul(d1, d2)                                
  inspect(result.to_string(), content="69.104")

  let d1 = from_parts(@bigint.BigInt::from_int(123), 1)  
  let d2 = from_parts(@bigint.BigInt::from_int(41), 1)   
  let result = div(d1, d2)                                
  inspect(result.to_string(), content="3.0000000000000000000000000000")
}
``` 
