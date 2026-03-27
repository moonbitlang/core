# Abort

Terminates program execution with an error message. The `abort` function always panics and never returns.

## Usage

```mbt check
///|
test "panic abort" {
  abort("something went wrong")
}
```
