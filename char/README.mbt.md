# `char`

This package provides a set of utilities for working with characters, focusing on character classification and validation.

## Basic ASCII Classification

Functions for determining if a character belongs to various ASCII categories.

```moonbit
///|
test "ascii classification" {
  // Basic ASCII checks
  inspect('A'.is_ascii(), content="true")
  inspect('λ'.is_ascii(), content="false")

  // Letter classification
  inspect('Z'.is_ascii_alphabetic(), content="true")
  inspect('1'.is_ascii_alphabetic(), content="false")

  // Case classification
  inspect('A'.is_ascii_uppercase(), content="true")
  inspect('a'.is_ascii_uppercase(), content="false")
  inspect('a'.is_ascii_lowercase(), content="true")
  inspect('A'.is_ascii_lowercase(), content="false")
}
```

## Number Classification

Functions for identifying digits in different number bases.

```moonbit
///|
test "number classification" {
  // Decimal digits
  inspect('5'.is_ascii_digit(), content="true")
  inspect('x'.is_ascii_digit(), content="false")

  // Hexadecimal digits
  inspect('F'.is_ascii_hexdigit(), content="true")
  inspect('G'.is_ascii_hexdigit(), content="false")

  // Octal digits
  inspect('7'.is_ascii_octdigit(), content="true")
  inspect('8'.is_ascii_octdigit(), content="false")

  // Custom base digits
  inspect('5'.is_digit(6U), content="true")
  inspect('6'.is_digit(6U), content="false")

  // General numeric characters
  inspect('1'.is_numeric(), content="true")
  inspect('A'.is_numeric(), content="false")
}
```

## Special Characters

Functions for identifying whitespace, control characters and other special characters.

```moonbit
///|
test "special characters" {
  // Whitespace characters
  inspect(' '.is_ascii_whitespace(), content="true")
  inspect('\n'.is_whitespace(), content="true")

  // Control characters
  inspect('\u0000'.is_ascii_control(), content="true")
  inspect('\u007F'.is_control(), content="true")

  // Graphic and punctuation characters
  inspect('!'.is_ascii_graphic(), content="true")
  inspect(' '.is_ascii_graphic(), content="false")
  inspect(','.is_ascii_punctuation(), content="true")
}
```

## Method Style Usage

All character classification functions can also be called as methods directly on characters.

```moonbit
///|
test "method style" {
  // Letter methods
  let c = 'A'
  inspect(c.is_ascii(), content="true")
  inspect(c.is_ascii_alphabetic(), content="true")
  inspect(c.is_ascii_uppercase(), content="true")

  // Digit methods
  let d = '7'
  inspect(d.is_ascii_digit(), content="true")
  inspect(d.is_digit(8U), content="true")
  inspect(d.is_ascii_hexdigit(), content="true")

  // Special character methods
  let s = ' '
  inspect(s.is_ascii_whitespace(), content="true")
  inspect(s.is_whitespace(), content="true")
}
```
