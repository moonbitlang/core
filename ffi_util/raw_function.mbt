/// A compiler builtin type for raw functions, i.e. functions without any capture.
/// This is useful when passing callbacks to FFI.
/// Here `T` must be a function type in `RawFunction[T]`
pub type RawFunction[T]
