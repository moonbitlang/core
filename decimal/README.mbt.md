# Decimal

`Decimal` provides arbitrary-precision finite decimal arithmetic. Values are
stored canonically as an integer coefficient and a base-10 exponent, so
`1.50`, `1.5`, and `1.500e0` compare and hash as the same value.

## Creating Values

```mbt check
///|
test "create decimals" {
  let a = @decimal.Decimal::from_string("123.4500")
  inspect(a, content="123.45")

  let b = @decimal.Decimal::from_bigint(
    @bigint.BigInt::from_string("12345"),
    exponent=-2,
  )
  inspect(b, content="123.45")

  inspect(a == b, content="true")
}
```

## Arithmetic

```mbt check
///|
test "decimal arithmetic" {
  let subtotal = @decimal.Decimal::from_string("19.99")
  let tax = @decimal.Decimal::from_string("1.65")
  inspect(subtotal + tax, content="21.64")

  let quantity = @decimal.Decimal::from_int(3)
  inspect(subtotal * quantity, content="59.97")
}
```

## Rounding And Division

There is intentionally no `/` operator for `Decimal`. Division can either be
exact or require an explicit scale and rounding mode.

Rounded results are still canonical values. The requested scale controls the
rounding position, but `to_string` does not keep trailing zeros added by that
rounding step.

```mbt check
///|
test "decimal division" {
  inspect(
    @decimal.Decimal::from_string("1").div_exact(
      @decimal.Decimal::from_string("4"),
    ),
    content="0.25",
  )

  inspect(
    @decimal.Decimal::from_string("1").div_round(
      @decimal.Decimal::from_string("3"),
      scale=2,
      mode=@decimal.HalfEven,
    ),
    content="0.33",
  )
}
```

## JSON

Decimals are encoded as JSON strings to preserve precision across JSON parsers
that represent numbers as IEEE 754 doubles.

```mbt check
///|
test "decimal json" {
  let value = @decimal.Decimal::from_string("12345678901234567890.125")
  let json = value.to_json()
  inspect(json, content="String(\"12345678901234567890.125\")")

  let decoded : @decimal.Decimal = @json.from_json(json)
  inspect(decoded == value, content="true")
}
```
