# Moonbit/Core Strconv

## Overview

This package implements conversions to and from string representations of basic data types.

## Parse

`parse_bool`, `parse_double`, `parse_int`, and `parse_int64` convert strings to values.

```moonbit
let b = parse_bool("true")?         // true
let i1 = parse_int("1234567")?      // 1234567
let i2 = parse_int("101", 2)?       // 5
let d = parse_double("123.4567")?   // 123.4567
```

## TODO

- Format functions.
- Support hexadecimal floating point number.
- Implements Eisel-Lemire algorithm to speed up floating point parsing.
