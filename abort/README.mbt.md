# Abort

Terminates program execution with an error message. The `abort` function always panics and never returns.

## Usage

```mbt check
///|
test "abort" {
  let result : Result[Int, _] = try? abort("something went wrong")
  inspect(result.is_err(), content="true")
}
```
