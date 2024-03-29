# Moonbit/Core Test

## Overview

Tools to write unit tests in MoonBit.

The `@test` package includes common functions to write unit tests, specifically
for the ones defined with the `test` keyword. For example:

```moonbit
fn my_add(x: Int, y: Int) -> Int { x + y }

test "my_add" {
  @test.eq(my_add(3, 5), 8)?
}
```
