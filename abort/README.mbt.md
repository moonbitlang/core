# `abort`

This package provides a utility function for aborting program execution with an error message.

## Function Overview

The `abort` function is used to immediately terminate program execution with a specified error message. It always causes a panic, making it useful for situations where the program has reached an unrecoverable state.

```moonbit
fn[T] abort(msg : String) -> T
```

## Usage Examples

### Basic Error Handling

```moonbit
test "basic abort usage" {
  // This would cause a panic:
  // abort("Something went wrong")
  
  // In practice, abort is typically used in guard conditions
  fn safe_divide(a : Int, b : Int) -> Double {
    if b == 0 {
      abort("Division by zero")
    }
    a.to_double() / b.to_double()
  }
}
```

### Bounds Checking

```moonbit
test "bounds checking example" {
  fn safe_array_access[T](arr : Array[T], index : Int) -> T {
    if index < 0 || index >= arr.length() {
      abort("Index out of bounds")
    }
    arr[index]
  }
}
```

### Unreachable Code Protection

```moonbit
test "unreachable code example" {
  enum Status {
    Active
    Inactive
  }
  
  fn process_status(status : Status) -> String {
    match status {
      Active => "Processing active item"
      Inactive => "Processing inactive item"
      // If new variants are added but not handled:
      // _ => abort("Unhandled status variant")
    }
  }
}
```

## Return Type

The `abort` function has a generic return type `T`, which allows it to be used in any context where a value is expected. However, since `abort` always causes a panic, it never actually returns a value.

## When to Use

- **Unrecoverable errors**: When the program cannot continue safely
- **Invariant violations**: When assumptions about program state are broken
- **Invalid inputs**: When function parameters are outside acceptable ranges
- **Missing implementations**: As a placeholder for unimplemented code paths

## Alternative Approaches

For recoverable errors, consider using:
- `Result[T, Error]` for functions that might fail
- `Option[T]` for functions that might not return a value
- Custom error handling mechanisms

The `abort` function should be used sparingly and primarily for situations where immediate program termination is the only safe option.