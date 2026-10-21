// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
/// The unit type. Its only value is `()`.
#builtin
pub type Unit

///|
/// The boolean type, with the values `true` and `false`.
#builtin
pub type Bool

///|
/// An unsigned 8-bit integer.
#builtin
pub type Byte

///|
/// A Unicode scalar value.
#builtin
pub type Char

///|
/// A signed 32-bit integer.
#builtin
#alias(Int32)
pub type Int

///|
/// A signed 64-bit integer.
#builtin
pub type Int64

///|
/// An unsigned 32-bit integer.
#builtin
#alias(UInt32)
pub type UInt

///|
/// An unsigned 16-bit integer.
#builtin
pub type UInt16

///|
/// An unsigned 64-bit integer.
#builtin
pub type UInt64

///|
/// A 64-bit IEEE 754 floating-point number.
#builtin
pub type Double

///|
/// An immutable sequence of UTF-16 code units.
#builtin
pub type String

///|
/// A 128-bit SIMD vector.
#builtin
pub type V128

///|
/// An immutable sequence of bytes.
#builtin
pub type Bytes

///|
/// A view of a slice of a `String`.
#builtin
#valtype
pub type StringView

///|
/// A view of a slice of a `Bytes`.
#builtin
#valtype
pub type BytesView

///|
/// A mutable array whose length is fixed at creation.
#builtin
pub type FixedArray[T]

///|
/// An immutable array whose length is fixed at creation.
#builtin
pub type ReadOnlyArray[T]

///|
/// The type of error values, which `raise` and `catch` operate on.
#builtin
pub type Error

///|
/// A reference to a function, for use in FFI.
#builtin
pub type FuncRef[T]

///|
/// An optional value: either `Some(value)` or `None`.
#builtin
pub(all) enum Option[T] {
  None
  Some(T)
}

///|
/// The result of an operation that can fail: either `Ok(value)` or `Err(error)`.
pub(all) enum Result[T, E] {
  Err(E)
  Ok(T)
}
