# `char`

This package provides a set of utilities for working with characters, focusing on character classification and validation.

## Basic ASCII Classification

Functions for determining if a character belongs to various ASCII categories.

```moonbit
test "ascii classification" {
  // Basic ASCII checks
  inspect!(@char.is_ascii('A'), content="true")
  inspect!(@char.is_ascii('λ'), content="false")

  // Letter classification
  inspect!(@char.is_ascii_alphabetic('Z'), content="true")
  inspect!(@char.is_ascii_alphabetic('1'), content="false")

  // Case classification
  inspect!(@char.is_ascii_uppercase('A'), content="true")
  inspect!(@char.is_ascii_uppercase('a'), content="false")
  inspect!(@char.is_ascii_lowercase('a'), content="true")
  inspect!(@char.is_ascii_lowercase('A'), content="false")
}
```

## Number Classification

Functions for identifying digits in different number bases.

```moonbit
test "number classification" {
  // Decimal digits
  inspect!(@char.is_ascii_digit('5'), content="true")
  inspect!(@char.is_ascii_digit('x'), content="false")

  // Hexadecimal digits
  inspect!(@char.is_ascii_hexdigit('F'), content="true")
  inspect!(@char.is_ascii_hexdigit('G'), content="false")

  // Octal digits
  inspect!(@char.is_ascii_octdigit('7'), content="true")
  inspect!(@char.is_ascii_octdigit('8'), content="false")

  // Custom base digits
  inspect!(@char.is_digit('5', 6U), content="true")
  inspect!(@char.is_digit('6', 6U), content="false")

  // General numeric characters
  inspect!(@char.is_numeric('1'), content="true")
  inspect!(@char.is_numeric('A'), content="false")
}
```

## Special Characters

Functions for identifying whitespace, control characters and other special characters.

```moonbit
test "special characters" {
  // Whitespace characters
  inspect!(@char.is_ascii_whitespace(' '), content="true")
  inspect!(@char.is_whitespace('\n'), content="true")

  // Control characters
  inspect!(@char.is_ascii_control('\u0000'), content="true")
  inspect!(@char.is_control('\u007F'), content="true")

  // Graphic and punctuation characters
  inspect!(@char.is_ascii_graphic('!'), content="true")
  inspect!(@char.is_ascii_graphic(' '), content="false")
  inspect!(@char.is_ascii_punctuation(','), content="true")
}
```

## Method Style Usage

All character classification functions can also be called as methods directly on characters.

```moonbit
test "method style" {
  // Letter methods
  let c = 'A'
  inspect!(c.is_ascii(), content="true")
  inspect!(c.is_ascii_alphabetic(), content="true")
  inspect!(c.is_ascii_uppercase(), content="true")

  // Digit methods
  let d = '7'
  inspect!(d.is_ascii_digit(), content="true")
  inspect!(d.is_digit(8U), content="true")
  inspect!(d.is_ascii_hexdigit(), content="true")

  // Special character methods
  let s = ' '
  inspect!(s.is_ascii_whitespace(), content="true")
  inspect!(s.is_whitespace(), content="true")
}
```
