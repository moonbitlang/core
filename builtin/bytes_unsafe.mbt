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

// #region FixedArray

///|
/// **UNSAFE**: Writes a UInt64 to the FixedArray[Byte] in little-endian byte order.
/// 
/// ⚠️ **Warning: This function is unsafe and can cause undefined behavior!**
/// 
/// # Safety
/// - **No bounds checking**: This function does not verify that `index + 7 < bytes.length()`
/// - **Buffer overrun risk**: Writing beyond the array boundary may corrupt memory
/// - **Alignment**: No alignment requirements, but misaligned access may be slower on some architectures
/// - **Responsibility**: Caller must ensure sufficient space is available
/// 
/// # Parameters
/// - `bytes`: The FixedArray[Byte] to write to
/// - `index`: Starting byte index (0-based)
/// - `value`: The UInt64 value to write
/// 
/// # Behavior
/// Writes 8 bytes starting at `index` in little-endian order:
/// - `bytes[index]` ← bits 0-7 (least significant)
/// - `bytes[index+1]` ← bits 8-15
/// - ...
/// - `bytes[index+7]` ← bits 56-63 (most significant)
#intrinsic("%bytes.unsafe_write_uint64_le")
pub fn FixedArray::unsafe_write_uint64_le(
  bytes : FixedArray[Byte],
  index : Int,
  value : UInt64,
) -> Unit {
  for i in 0..=7 {
    bytes.unsafe_set(i + index, (value >> (8 * i)).to_byte())
  }
}

///|
/// **UNSAFE**: Writes a UInt64 to the FixedArray[Byte] in big-endian byte order.
/// 
/// ⚠️ **Warning: This function is unsafe and can cause undefined behavior!**
/// 
/// # Safety
/// - **No bounds checking**: This function does not verify that `index + 7 < bytes.length()`
/// - **Buffer overrun risk**: Writing beyond the array boundary may corrupt memory
/// - **Alignment**: No alignment requirements, but misaligned access may be slower on some architectures
/// - **Responsibility**: Caller must ensure sufficient space is available
/// 
/// # Parameters
/// - `bytes`: The FixedArray[Byte] to write to
/// - `index`: Starting byte index (0-based)
/// - `value`: The UInt64 value to write
/// 
/// # Behavior
/// Writes 8 bytes starting at `index` in big-endian order:
/// - `bytes[index]` ← bits 56-63 (most significant)
/// - `bytes[index+1]` ← bits 48-55
/// - ...
/// - `bytes[index+7]` ← bits 0-7 (least significant)
#intrinsic("%bytes.unsafe_write_uint64_be")
pub fn FixedArray::unsafe_write_uint64_be(
  bytes : FixedArray[Byte],
  index : Int,
  value : UInt64,
) -> Unit {
  for i in 0..=7 {
    bytes.unsafe_set(i + index, (value >> (8 * (7 - i))).to_byte())
  }
}

///|
/// **UNSAFE**: Writes a UInt32 to the FixedArray[Byte] in little-endian byte order.
/// 
/// ⚠️ **Warning: This function is unsafe and can cause undefined behavior!**
/// 
/// # Safety
/// - **No bounds checking**: This function does not verify that `index + 3 < bytes.length()`
/// - **Buffer overrun risk**: Writing beyond the array boundary may corrupt memory
/// - **Alignment**: No alignment requirements, but misaligned access may be slower on some architectures
/// - **Responsibility**: Caller must ensure sufficient space is available
/// 
/// # Parameters
/// - `bytes`: The FixedArray[Byte] to write to
/// - `index`: Starting byte index (0-based)
/// - `value`: The UInt32 value to write
/// 
/// # Behavior
/// Writes 4 bytes starting at `index` in little-endian order:
/// - `bytes[index]` ← bits 0-7 (least significant)
/// - `bytes[index+1]` ← bits 8-15
/// - `bytes[index+2]` ← bits 16-23
/// - `bytes[index+3]` ← bits 24-31 (most significant)
#intrinsic("%bytes.unsafe_write_uint32_le")
pub fn FixedArray::unsafe_write_uint32_le(
  bytes : FixedArray[Byte],
  index : Int,
  value : UInt,
) -> Unit {
  for i in 0..=3 {
    bytes.unsafe_set(i + index, (value >> (8 * i)).to_byte())
  }
}

///|
/// **UNSAFE**: Writes a UInt32 to the FixedArray[Byte] in big-endian byte order.
/// 
/// ⚠️ **Warning: This function is unsafe and can cause undefined behavior!**
/// 
/// # Safety
/// - **No bounds checking**: This function does not verify that `index + 3 < bytes.length()`
/// - **Buffer overrun risk**: Writing beyond the array boundary may corrupt memory
/// - **Alignment**: No alignment requirements, but misaligned access may be slower on some architectures
/// - **Responsibility**: Caller must ensure sufficient space is available
/// 
/// # Parameters
/// - `bytes`: The FixedArray[Byte] to write to
/// - `index`: Starting byte index (0-based)
/// - `value`: The UInt32 value to write
/// 
/// # Behavior
/// Writes 4 bytes starting at `index` in big-endian order:
/// - `bytes[index]` ← bits 24-31 (most significant)
/// - `bytes[index+1]` ← bits 16-23
/// - `bytes[index+2]` ← bits 8-15
/// - `bytes[index+3]` ← bits 0-7 (least significant)
#intrinsic("%bytes.unsafe_write_uint32_be")
pub fn FixedArray::unsafe_write_uint32_be(
  bytes : FixedArray[Byte],
  index : Int,
  value : UInt,
) -> Unit {
  for i in 0..=3 {
    bytes.unsafe_set(i + index, (value >> (8 * (3 - i))).to_byte())
  }
}

///|
/// **UNSAFE**: Writes a UInt16 to the FixedArray[Byte] in little-endian byte order.
/// 
/// ⚠️ **Warning: This function is unsafe and can cause undefined behavior!**
/// 
/// # Safety
/// - **No bounds checking**: This function does not verify that `index + 1 < bytes.length()`
/// - **Buffer overrun risk**: Writing beyond the array boundary may corrupt memory
/// - **Alignment**: No alignment requirements, but misaligned access may be slower on some architectures
/// - **Responsibility**: Caller must ensure sufficient space is available
/// 
/// # Parameters
/// - `bytes`: The FixedArray[Byte] to write to
/// - `index`: Starting byte index (0-based)
/// - `value`: The UInt16 value to write
/// 
/// # Behavior
/// Writes 2 bytes starting at `index` in little-endian order:
/// - `bytes[index]` ← bits 0-7 (least significant)
/// - `bytes[index+1]` ← bits 8-15 (most significant)
#intrinsic("%bytes.unsafe_write_uint16_le")
pub fn FixedArray::unsafe_write_uint16_le(
  bytes : FixedArray[Byte],
  index : Int,
  value : UInt16,
) -> Unit {
  for i in 0..=1 {
    bytes.unsafe_set(i + index, (value >> (8 * i)).to_byte())
  }
}

///|
/// **UNSAFE**: Writes a UInt16 to the FixedArray[Byte] in big-endian byte order.
/// 
/// ⚠️ **Warning: This function is unsafe and can cause undefined behavior!**
/// 
/// # Safety
/// - **No bounds checking**: This function does not verify that `index + 1 < bytes.length()`
/// - **Buffer overrun risk**: Writing beyond the array boundary may corrupt memory
/// - **Alignment**: No alignment requirements, but misaligned access may be slower on some architectures
/// - **Responsibility**: Caller must ensure sufficient space is available
/// 
/// # Parameters
/// - `bytes`: The FixedArray[Byte] to write to
/// - `index`: Starting byte index (0-based)
/// - `value`: The UInt16 value to write
/// 
/// # Behavior
/// Writes 2 bytes starting at `index` in big-endian order:
/// - `bytes[index]` ← bits 8-15 (most significant)
/// - `bytes[index+1]` ← bits 0-7 (least significant)
#intrinsic("%bytes.unsafe_write_uint16_be")
pub fn FixedArray::unsafe_write_uint16_be(
  bytes : FixedArray[Byte],
  index : Int,
  value : UInt16,
) -> Unit {
  for i in 0..=1 {
    bytes.unsafe_set(i + index, (value >> (8 * (1 - i))).to_byte())
  }
}

// #endregion
// #region Bytes

///|
/// **UNSAFE**: Reads a UInt64 from the bytes in little-endian byte order.
/// 
/// ⚠️ **Warning: This function is unsafe and can cause undefined behavior!**
/// 
/// # Safety
/// - **No bounds checking**: This function does not verify that `index + 7 < bytes.length()`
/// - **Buffer overrun risk**: Reading beyond the buffer boundary may access invalid memory
/// - **Alignment**: No alignment requirements, but misaligned access may be slower on some architectures
/// - **Responsibility**: Caller must ensure sufficient bytes are available
/// 
/// # Parameters
/// - `bytes`: The Bytes to read from
/// - `index`: Starting byte index (0-based)
/// 
/// # Behavior
/// Reads 8 bytes starting at `index` and interprets them as a UInt64 in little-endian order:
/// - `bytes[index]` → bits 0-7 (least significant)
/// - `bytes[index+1]` → bits 8-15
/// - ...
/// - `bytes[index+7]` → bits 56-63 (most significant)
#intrinsic("%bytes.unsafe_read_uint64_le")
#doc(hidden)
pub fn Bytes::unsafe_read_uint64_le(bytes : Bytes, index : Int) -> UInt64 {
  let mut result : UInt64 = 0
  for i in 0..=7 {
    result = result | (bytes.unsafe_get(i + index).to_uint64() << (8 * i))
  }
  result
}

///|
/// **UNSAFE**: Reads a UInt64 from the bytes in big-endian byte order.
/// 
/// ⚠️ **Warning: This function is unsafe and can cause undefined behavior!**
/// 
/// # Safety
/// - **No bounds checking**: This function does not verify that `index + 7 < bytes.length()`
/// - **Buffer overrun risk**: Reading beyond the buffer boundary may access invalid memory
/// - **Alignment**: No alignment requirements, but misaligned access may be slower on some architectures
/// - **Responsibility**: Caller must ensure sufficient bytes are available
/// 
/// # Parameters
/// - `bytes`: The Bytes to read from
/// - `index`: Starting byte index (0-based)
/// 
/// # Behavior
/// Reads 8 bytes starting at `index` and interprets them as a UInt64 in big-endian order:
/// - `bytes[index]` → bits 56-63 (most significant)
/// - `bytes[index+1]` → bits 48-55
/// - ...
/// - `bytes[index+7]` → bits 0-7 (least significant)
#intrinsic("%bytes.unsafe_read_uint64_be")
#doc(hidden)
pub fn Bytes::unsafe_read_uint64_be(bytes : Bytes, index : Int) -> UInt64 {
  let mut result : UInt64 = 0
  for i in 0..=7 {
    result = result | (bytes.unsafe_get(i + index).to_uint64() << (8 * (7 - i)))
  }
  result
}

///|
/// **UNSAFE**: Reads a UInt32 from the bytes in little-endian byte order.
/// 
/// ⚠️ **Warning: This function is unsafe and can cause undefined behavior!**
/// 
/// # Safety
/// - **No bounds checking**: This function does not verify that `index + 3 < bytes.length()`
/// - **Buffer overrun risk**: Reading beyond the buffer boundary may access invalid memory
/// - **Alignment**: No alignment requirements, but misaligned access may be slower on some architectures
/// - **Responsibility**: Caller must ensure sufficient bytes are available
/// 
/// # Parameters
/// - `bytes`: The Bytes to read from
/// - `index`: Starting byte index (0-based)
/// 
/// # Behavior
/// Reads 4 bytes starting at `index` and interprets them as a UInt32 in little-endian order:
/// - `bytes[index]` → bits 0-7 (least significant)
/// - `bytes[index+1]` → bits 8-15
/// - `bytes[index+2]` → bits 16-23
/// - `bytes[index+3]` → bits 24-31 (most significant)
#intrinsic("%bytes.unsafe_read_uint32_le")
#doc(hidden)
pub fn Bytes::unsafe_read_uint32_le(bytes : Bytes, index : Int) -> UInt {
  let mut result : UInt = 0
  for i in 0..=3 {
    result = result | (bytes.unsafe_get(i + index).to_uint() << (8 * i))
  }
  result
}

///|
/// **UNSAFE**: Reads a UInt32 from the bytes in big-endian byte order.
/// 
/// ⚠️ **Warning: This function is unsafe and can cause undefined behavior!**
/// 
/// # Safety
/// - **No bounds checking**: This function does not verify that `index + 3 < bytes.length()`
/// - **Buffer overrun risk**: Reading beyond the buffer boundary may access invalid memory
/// - **Alignment**: No alignment requirements, but misaligned access may be slower on some architectures
/// - **Responsibility**: Caller must ensure sufficient bytes are available
/// 
/// # Parameters
/// - `bytes`: The Bytes to read from
/// - `index`: Starting byte index (0-based)
/// 
/// # Behavior
/// Reads 4 bytes starting at `index` and interprets them as a UInt32 in big-endian order:
/// - `bytes[index]` → bits 24-31 (most significant)
/// - `bytes[index+1]` → bits 16-23
/// - `bytes[index+2]` → bits 8-15
/// - `bytes[index+3]` → bits 0-7 (least significant)
#intrinsic("%bytes.unsafe_read_uint32_be")
#doc(hidden)
pub fn Bytes::unsafe_read_uint32_be(bytes : Bytes, index : Int) -> UInt {
  let mut result : UInt = 0
  for i in 0..=3 {
    result = result | (bytes.unsafe_get(i + index).to_uint() << (8 * (3 - i)))
  }
  result
}

///|
/// **UNSAFE**: Reads a UInt16 from the bytes in little-endian byte order.
/// 
/// ⚠️ **Warning: This function is unsafe and can cause undefined behavior!**
/// 
/// # Safety
/// - **No bounds checking**: This function does not verify that `index + 1 < bytes.length()`
/// - **Buffer overrun risk**: Reading beyond the buffer boundary may access invalid memory
/// - **Alignment**: No alignment requirements, but misaligned access may be slower on some architectures
/// - **Responsibility**: Caller must ensure sufficient bytes are available
/// 
/// # Parameters
/// - `bytes`: The Bytes to read from
/// - `index`: Starting byte index (0-based)
/// 
/// # Behavior
/// Reads 2 bytes starting at `index` and interprets them as a UInt16 in little-endian order:
/// - `bytes[index]` → bits 0-7 (least significant)
/// - `bytes[index+1]` → bits 8-15 (most significant)
#intrinsic("%bytes.unsafe_read_uint16_le")
#doc(hidden)
pub fn Bytes::unsafe_read_uint16_le(bytes : Bytes, index : Int) -> UInt16 {
  let mut result : UInt16 = 0
  for i in 0..=1 {
    result = result | (bytes.unsafe_get(i + index).to_uint16() << (8 * i))
  }
  result
}

///|
/// **UNSAFE**: Reads a UInt16 from the bytes in big-endian byte order.
/// 
/// ⚠️ **Warning: This function is unsafe and can cause undefined behavior!**
/// 
/// # Safety
/// - **No bounds checking**: This function does not verify that `index + 1 < bytes.length()`
/// - **Buffer overrun risk**: Reading beyond the buffer boundary may access invalid memory
/// - **Alignment**: No alignment requirements, but misaligned access may be slower on some architectures
/// - **Responsibility**: Caller must ensure sufficient bytes are available
/// 
/// # Parameters
/// - `bytes`: The Bytes to read from
/// - `index`: Starting byte index (0-based)
/// 
/// # Behavior
/// Reads 2 bytes starting at `index` and interprets them as a UInt16 in big-endian order:
/// - `bytes[index]` → bits 8-15 (most significant)
/// - `bytes[index+1]` → bits 0-7 (least significant)
#intrinsic("%bytes.unsafe_read_uint16_be")
#doc(hidden)
pub fn Bytes::unsafe_read_uint16_be(bytes : Bytes, index : Int) -> UInt16 {
  let mut result : UInt16 = 0
  for i in 0..=1 {
    result = result | (bytes.unsafe_get(i + index).to_uint16() << (8 * (1 - i)))
  }
  result
}

///|
/// **UNSAFE**: Reads a UInt64 from the BytesView in little-endian byte order.
/// 
/// ⚠️ **Warning: This function is unsafe and can cause undefined behavior!**
/// 
/// # Safety
/// - **No bounds checking**: This function does not verify that `index + 7 < bytes.length()`
/// - **Buffer overrun risk**: Reading beyond the view boundary may access invalid memory
/// - **Responsibility**: Caller must ensure sufficient bytes are available within the view
/// 
/// # Parameters
/// - `bytes`: The BytesView to read from
/// - `index`: Relative index within the view (0-based)
/// 
/// # Note
/// This function delegates to `Bytes::unsafe_read_uint64_le` with the proper offset calculation.
#doc(hidden)
pub fn BytesView::unsafe_read_uint64_le(
  bytes : BytesView,
  index : Int,
) -> UInt64 {
  bytes.bytes().unsafe_read_uint64_le(bytes.start() + index)
}

///|
/// **UNSAFE**: Reads a UInt64 from the BytesView in big-endian byte order.
/// 
/// ⚠️ **Warning: This function is unsafe and can cause undefined behavior!**
/// 
/// # Safety
/// - **No bounds checking**: This function does not verify that `index + 7 < bytes.length()`
/// - **Buffer overrun risk**: Reading beyond the view boundary may access invalid memory
/// - **Responsibility**: Caller must ensure sufficient bytes are available within the view
/// 
/// # Parameters
/// - `bytes`: The BytesView to read from
/// - `index`: Relative index within the view (0-based)
/// 
/// # Note
/// This function delegates to `Bytes::unsafe_read_uint64_be` with the proper offset calculation.
#doc(hidden)
pub fn BytesView::unsafe_read_uint64_be(
  bytes : BytesView,
  index : Int,
) -> UInt64 {
  bytes.bytes().unsafe_read_uint64_be(bytes.start() + index)
}

///|
/// **UNSAFE**: Reads a UInt32 from the BytesView in little-endian byte order.
/// 
/// ⚠️ **Warning: This function is unsafe and can cause undefined behavior!**
/// 
/// # Safety
/// - **No bounds checking**: This function does not verify that `index + 3 < bytes.length()`
/// - **Buffer overrun risk**: Reading beyond the view boundary may access invalid memory
/// - **Responsibility**: Caller must ensure sufficient bytes are available within the view
/// 
/// # Parameters
/// - `bytes`: The BytesView to read from
/// - `index`: Relative index within the view (0-based)
/// 
/// # Note
/// This function delegates to `Bytes::unsafe_read_uint32_le` with the proper offset calculation.
#doc(hidden)
pub fn BytesView::unsafe_read_uint32_le(bytes : BytesView, index : Int) -> UInt {
  bytes.bytes().unsafe_read_uint32_le(bytes.start() + index)
}

///|
/// **UNSAFE**: Reads a UInt32 from the BytesView in big-endian byte order.
/// 
/// ⚠️ **Warning: This function is unsafe and can cause undefined behavior!**
/// 
/// # Safety
/// - **No bounds checking**: This function does not verify that `index + 3 < bytes.length()`
/// - **Buffer overrun risk**: Reading beyond the view boundary may access invalid memory
/// - **Responsibility**: Caller must ensure sufficient bytes are available within the view
/// 
/// # Parameters
/// - `bytes`: The BytesView to read from
/// - `index`: Relative index within the view (0-based)
/// 
/// # Note
/// This function delegates to `Bytes::unsafe_read_uint32_be` with the proper offset calculation.
#doc(hidden)
pub fn BytesView::unsafe_read_uint32_be(bytes : BytesView, index : Int) -> UInt {
  bytes.bytes().unsafe_read_uint32_be(bytes.start() + index)
}

///|
/// **UNSAFE**: Reads a UInt16 from the BytesView in little-endian byte order.
/// 
/// ⚠️ **Warning: This function is unsafe and can cause undefined behavior!**
/// 
/// # Safety
/// - **No bounds checking**: This function does not verify that `index + 1 < bytes.length()`
/// - **Buffer overrun risk**: Reading beyond the view boundary may access invalid memory
/// - **Responsibility**: Caller must ensure sufficient bytes are available within the view
/// 
/// # Parameters
/// - `bytes`: The BytesView to read from
/// - `index`: Relative index within the view (0-based)
/// 
/// # Note
/// This function delegates to `Bytes::unsafe_read_uint16_le` with the proper offset calculation.
#doc(hidden)
pub fn BytesView::unsafe_read_uint16_le(
  bytes : BytesView,
  index : Int,
) -> UInt16 {
  bytes.bytes().unsafe_read_uint16_le(bytes.start() + index)
}

///|
/// **UNSAFE**: Reads a UInt16 from the BytesView in big-endian byte order.
/// 
/// ⚠️ **Warning: This function is unsafe and can cause undefined behavior!**
/// 
/// # Safety
/// - **No bounds checking**: This function does not verify that `index + 1 < bytes.length()`
/// - **Buffer overrun risk**: Reading beyond the view boundary may access invalid memory
/// - **Responsibility**: Caller must ensure sufficient bytes are available within the view
/// 
/// # Parameters
/// - `bytes`: The BytesView to read from
/// - `index`: Relative index within the view (0-based)
/// 
/// # Note
/// This function delegates to `Bytes::unsafe_read_uint16_be` with the proper offset calculation.
#doc(hidden)
pub fn BytesView::unsafe_read_uint16_be(
  bytes : BytesView,
  index : Int,
) -> UInt16 {
  bytes.bytes().unsafe_read_uint16_be(bytes.start() + index)
}

// #endregion
