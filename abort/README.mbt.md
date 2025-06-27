# Abort

The `abort` package provides a function to terminate program execution with an error message. It's a fundamental utility for handling unrecoverable errors or impossible situations in MoonBit programs.

## Overview

The package contains a single function `abort` that causes a panic with a provided error message. This function is useful when you encounter a situation that should never happen in your program, or when you need to terminate execution due to an unrecoverable error.

The `abort` function is polymorphic with type `fn[T] abort(msg: String) -> T`, meaning it can be used in any context where a value of any type is expected. However, it never actually returns a value as it always causes a panic.

## Usage

### Basic Usage

You can use `abort` to terminate program execution with a custom error message:

```moonbit
fn divide(a: Int, b: Int) -> Int {
  if b == 0 {
    @abort.abort("Division by zero")
  }
  a / b
}
```

### As an Unreachable Branch

You can use `abort` to mark branches that should never be executed:

```moonbit
fn get_positive(x: Int) -> Int {
  if x > 0 {
    x
  } else {
    @abort.abort("Expected a positive number, got " + x.to_string())
  }
}
```

### In Pattern Matching

You can use `abort` in pattern matching when a case should never occur:

```moonbit
fn head(list: List[T]) -> T {
  match list {
    [x, ..] => x
    [] => @abort.abort("Cannot get head of empty list")
  }
}
```

### In Option/Result Handling

You can use `abort` when unwrapping options or results in contexts where they should never be `None` or `Err`:

```moonbit
fn process_data(data: Option[String]) -> String {
  match data {
    Some(value) => process(value)
    None => @abort.abort("Expected data to be present")
  }
}
```

## Implementation Note

The `abort` function is implemented using a low-level panic mechanism. It will always terminate the program and cannot be caught or recovered from.