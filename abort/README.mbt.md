# Abort

This package preserves the deprecated `@abort.abort` API for compatibility.
Use `abort(message)` from the prelude instead; no package import is needed.

The function terminates execution with an error message and never returns.
JavaScript and native backends print the message to stderr before panicking.
Linear-memory Wasm does the same when linked with WASI support. Otherwise,
Wasm and Wasm GC trap without printing the message or requiring I/O imports.

## Legacy usage

```mbt check
///|
#cfg(any(target="wasm", target="wasm-gc", target="js"))
#warnings("-deprecated")
test "panic abort" {
  @abort.abort("something went wrong")
}
```
