// Copyright 2025 International Digital Economy Academy
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
