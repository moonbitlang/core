# Abort

Terminates program execution by raising a panic; the `abort` function never
returns. The message is printed only on the native backend — the
wasm/js implementation discards it.

## Usage

```mbt check
///|
test "panic abort" {
  abort("something went wrong")
}
```
