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

// offset and len are all in bits

///|
fn UInt::extend_sign(self : UInt, len : Int) -> Int {
  let b = 32 - len
  self.reinterpret_as_int() << b >> b
}

///|
fn UInt64::extend_sign(self : UInt64, len : Int) -> Int64 {
  let b = 64 - len
  self.reinterpret_as_int64() << b >> b
}

//--------------------------------
// ArrayView
//--------------------------------

///|
/// Extract a single bit.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn ArrayView::unsafe_extract_bit(
  bs : ArrayView[Byte],
  offset : Int,
  _len : Int,
) -> UInt {
  let byte_index = offset >> 3
  let bit_shift = 7 - (offset & 7)
  let byte_val = bs.unsafe_get(byte_index).to_uint()
  (byte_val >> bit_shift) & 1U
}

///|
/// Extract a single bit.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn ArrayView::unsafe_extract_bit_signed(
  bs : ArrayView[Byte],
  offset : Int,
  _len : Int,
) -> Int {
  let byte_index = offset >> 3
  let bit_shift = 7 - (offset & 7)
  let byte_val = bs.unsafe_get(byte_index).to_int()
  // Extract bit and convert to signed: 0 -> 0, 1 -> -1
  ((byte_val >> bit_shift) & 1) * -1
}

///|
/// Extract [2..8] bits.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn ArrayView::unsafe_extract_byte(
  bs : ArrayView[Byte],
  offset : Int,
  len : Int,
) -> UInt {
  let byte_index = offset >> 3
  if (offset & 7) == 0 {
    // byte-aligned case
    let byte = bs.unsafe_get(byte_index)
    (byte >> (8 - len)).to_uint()
  } else if (offset & 7) + len <= 8 {
    // All bits are within the same byte - no need to read next byte
    let byte = bs.unsafe_get(byte_index).to_uint()
    let shift = 8 - ((offset & 7) + len)
    let mask = (1U << len) - 1
    (byte >> shift) & mask
  } else {
    // extract 16 bits at [byte_index, byte_index + 1]
    let b0 = bs.unsafe_get(byte_index).to_uint()
    let b1 = bs.unsafe_get(byte_index + 1).to_uint()
    let data = (b0 << 8) | b1
    // mask off the top bits
    let bit_mask = (1U << (16 - (offset & 7))) - 1
    let data = data & bit_mask
    let shift = 16 - ((offset & 7) + len)
    data >> shift
  }
}

///|
/// Extract [9..32] bits in little-endian byte order.
/// 
/// # Invariants
/// - It's guaranteed to have at least 2 bytes available for extraction
/// - Only reads the necessary number of bytes based on the bit length
///
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn ArrayView::unsafe_extract_uint_le(
  bs : ArrayView[Byte],
  offset : Int,
  len : Int,
) -> UInt {
  let bytes_needed = (len + 7) / 8
  // TODO: add fast path for aligned case
  // non-aligned case: extract bytes using unsafe_extract_byte
  let b0 = bs.unsafe_extract_byte(offset, 8)
  match bytes_needed {
    2 => {
      let b1 = bs.unsafe_extract_byte(offset + 8, len - 8)
      (b1 << 8) | b0
    }
    3 => {
      let b1 = bs.unsafe_extract_byte(offset + 8, 8)
      let b2 = bs.unsafe_extract_byte(offset + 16, len - 16)
      (b2 << 16) | (b1 << 8) | b0
    }
    4 => {
      let b1 = bs.unsafe_extract_byte(offset + 8, 8)
      let b2 = bs.unsafe_extract_byte(offset + 16, 8)
      let b3 = bs.unsafe_extract_byte(offset + 24, len - 24)
      (b3 << 24) | (b2 << 16) | (b1 << 8) | b0
    }
    _ => abort("Invalid byte count for int32 extraction")
  }
}

///|
/// Extract [9..32] bits in big-endian byte order.
/// 
/// # Invariants
/// - It's guaranteed to have at least 2 bytes available for extraction
/// - Only reads the necessary number of bytes based on the bit length
///
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn ArrayView::unsafe_extract_uint_be(
  bs : ArrayView[Byte],
  offset : Int,
  len : Int,
) -> UInt {
  let bytes_needed = (len + 7) / 8
  // TODO: add fast path for aligned case
  // non-aligned case: extract bytes using unsafe_extract_byte
  let b0 = bs.unsafe_extract_byte(offset, 8)
  match bytes_needed {
    2 => {
      let b1 = bs.unsafe_extract_byte(offset + 8, len - 8)
      let shift = 16 - len
      let data = (b0 << 8) | (b1 << shift)
      data >> shift
    }
    3 => {
      let b1 = bs.unsafe_extract_byte(offset + 8, 8)
      let b2 = bs.unsafe_extract_byte(offset + 16, len - 16)
      let shift = 24 - len
      let data = (b0 << 16) | (b1 << 8) | (b2 << shift)
      data >> shift
    }
    4 => {
      let b1 = bs.unsafe_extract_byte(offset + 8, 8)
      let b2 = bs.unsafe_extract_byte(offset + 16, 8)
      let b3 = bs.unsafe_extract_byte(offset + 24, len - 24)
      let shift = 32 - len
      let data = (b0 << 24) | (b1 << 16) | (b2 << 8) | (b3 << shift)
      data >> shift
    }
    _ => abort("Invalid byte count for int32 extraction")
  }
}

///|
/// Extract [33..64] bits in little-endian byte order.
/// 
/// # Invariants
/// - It's guaranteed to have at least 5 bytes available for extraction
/// - Only reads the necessary number of bytes based on the bit length (5-8 bytes)
/// - For bit lengths < 33, use unsafe_extract_int_le instead
///
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn ArrayView::unsafe_extract_uint64_le(
  bs : ArrayView[Byte],
  offset : Int,
  len : Int,
) -> UInt64 {
  let bytes_needed = (len + 7) / 8
  // TODO: add fast path for aligned case
  // non-aligned case: extract bytes using unsafe_extract_byte
  let b0 = bs.unsafe_extract_byte(offset, 8).to_uint64()
  let b1 = bs.unsafe_extract_byte(offset + 8, 8).to_uint64()
  let b2 = bs.unsafe_extract_byte(offset + 16, 8).to_uint64()
  let b3 = bs.unsafe_extract_byte(offset + 24, 8).to_uint64()
  match bytes_needed {
    5 => {
      let b4 = bs.unsafe_extract_byte(offset + 32, len - 32).to_uint64()
      (b4 << 32) | (b3 << 24) | (b2 << 16) | (b1 << 8) | b0
    }
    6 => {
      let b4 = bs.unsafe_extract_byte(offset + 32, 8).to_uint64()
      let b5 = bs.unsafe_extract_byte(offset + 40, len - 40).to_uint64()
      (b5 << 40) | (b4 << 32) | (b3 << 24) | (b2 << 16) | (b1 << 8) | b0
    }
    7 => {
      let b4 = bs.unsafe_extract_byte(offset + 32, 8).to_uint64()
      let b5 = bs.unsafe_extract_byte(offset + 40, 8).to_uint64()
      let b6 = bs.unsafe_extract_byte(offset + 48, len - 48).to_uint64()
      (b6 << 48) |
      (b5 << 40) |
      (b4 << 32) |
      (b3 << 24) |
      (b2 << 16) |
      (b1 << 8) |
      b0
    }
    8 => {
      let b4 = bs.unsafe_extract_byte(offset + 32, 8).to_uint64()
      let b5 = bs.unsafe_extract_byte(offset + 40, 8).to_uint64()
      let b6 = bs.unsafe_extract_byte(offset + 48, 8).to_uint64()
      let b7 = bs.unsafe_extract_byte(offset + 56, len - 56).to_uint64()
      (b7 << 56) |
      (b6 << 48) |
      (b5 << 40) |
      (b4 << 32) |
      (b3 << 24) |
      (b2 << 16) |
      (b1 << 8) |
      b0
    }
    _ => abort("Invalid byte count for int64 extraction")
  }
}

///|
/// Extract [33..64] bits in big-endian byte order.
/// 
/// # Invariants
/// - It's guaranteed to have at least 5 bytes available for extraction
/// - Only reads the necessary number of bytes based on the bit length (5-8 bytes)
/// - For bit lengths < 33, use unsafe_extract_int_be instead
///
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn ArrayView::unsafe_extract_uint64_be(
  bs : ArrayView[Byte],
  offset : Int,
  len : Int,
) -> UInt64 {
  let bytes_needed = (len + 7) / 8
  // TODO: add fast path for aligned case
  // non-aligned case: extract bytes using unsafe_extract_byte
  let b0 = bs.unsafe_extract_byte(offset, 8).to_uint64()
  let b1 = bs.unsafe_extract_byte(offset + 8, 8).to_uint64()
  let b2 = bs.unsafe_extract_byte(offset + 16, 8).to_uint64()
  let b3 = bs.unsafe_extract_byte(offset + 24, 8).to_uint64()
  match bytes_needed {
    5 => {
      let b4 = bs.unsafe_extract_byte(offset + 32, len - 32).to_uint64()
      let shift = 40 - len
      let data = (b0 << 32) |
        (b1 << 24) |
        (b2 << 16) |
        (b3 << 8) |
        (b4 << shift)
      data >> shift
    }
    6 => {
      let b4 = bs.unsafe_extract_byte(offset + 32, 8).to_uint64()
      let b5 = bs.unsafe_extract_byte(offset + 40, len - 40).to_uint64()
      let shift = 48 - len
      let data = (b0 << 40) |
        (b1 << 32) |
        (b2 << 24) |
        (b3 << 16) |
        (b4 << 8) |
        (b5 << shift)
      data >> shift
    }
    7 => {
      let b4 = bs.unsafe_extract_byte(offset + 32, 8).to_uint64()
      let b5 = bs.unsafe_extract_byte(offset + 40, 8).to_uint64()
      let b6 = bs.unsafe_extract_byte(offset + 48, len - 48).to_uint64()
      let shift = 56 - len
      let data = (b0 << 48) |
        (b1 << 40) |
        (b2 << 32) |
        (b3 << 24) |
        (b4 << 16) |
        (b5 << 8) |
        (b6 << shift)
      data >> shift
    }
    8 => {
      let b4 = bs.unsafe_extract_byte(offset + 32, 8).to_uint64()
      let b5 = bs.unsafe_extract_byte(offset + 40, 8).to_uint64()
      let b6 = bs.unsafe_extract_byte(offset + 48, 8).to_uint64()
      let b7 = bs.unsafe_extract_byte(offset + 56, len - 56).to_uint64()
      let shift = 64 - len
      let data = (b0 << 56) |
        (b1 << 48) |
        (b2 << 40) |
        (b3 << 32) |
        (b4 << 24) |
        (b5 << 16) |
        (b6 << 8) |
        (b7 << shift)
      data >> shift
    }
    _ => abort("Invalid byte count for int64 extraction")
  }
}

///|
/// Extract a subview from a view. `offset` and `len` are in bits and must be
/// aligned to bytes.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn ArrayView::unsafe_extract_bytesview(
  bs : ArrayView[Byte],
  offset : Int,
  len : Int,
) -> ArrayView[Byte] {
  let start = offset >> 3
  let end = start + (len >> 3)
  bs[start:end]
}

///|
/// Extract [2..8] bits as a signed integer.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn ArrayView::unsafe_extract_byte_signed(
  bs : ArrayView[Byte],
  offset : Int,
  len : Int,
) -> Int {
  let unsigned = bs.unsafe_extract_byte(offset, len)
  unsigned.extend_sign(len)
}

///|
/// Extract [9..32] bits as a signed integer.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn ArrayView::unsafe_extract_int_le(
  bs : ArrayView[Byte],
  offset : Int,
  len : Int,
) -> Int {
  let unsigned = bs.unsafe_extract_uint_le(offset, len)
  unsigned.extend_sign(len)
}

///|
/// Extract [9..32] bits as a signed integer.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn ArrayView::unsafe_extract_int_be(
  bs : ArrayView[Byte],
  offset : Int,
  len : Int,
) -> Int {
  let unsigned = bs.unsafe_extract_uint_be(offset, len)
  unsigned.extend_sign(len)
}

///|
/// Extract [33..64] bits as a signed integer.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn ArrayView::unsafe_extract_int64_le(
  bs : ArrayView[Byte],
  offset : Int,
  len : Int,
) -> Int64 {
  let unsigned = bs.unsafe_extract_uint64_le(offset, len)
  unsigned.extend_sign(len)
}

///|
/// Extract [33..64] bits as a signed integer.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn ArrayView::unsafe_extract_int64_be(
  bs : ArrayView[Byte],
  offset : Int,
  len : Int,
) -> Int64 {
  let unsigned = bs.unsafe_extract_uint64_be(offset, len)
  unsigned.extend_sign(len)
}
//--------------------------------
// Array
//--------------------------------

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn Array::unsafe_extract_bit(
  bs : Array[Byte],
  offset : Int,
  len : Int,
) -> UInt {
  bs[:].unsafe_extract_bit(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn Array::unsafe_extract_byte(
  bs : Array[Byte],
  offset : Int,
  len : Int,
) -> UInt {
  bs[:].unsafe_extract_byte(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn Array::unsafe_extract_uint_le(
  bs : Array[Byte],
  offset : Int,
  len : Int,
) -> UInt {
  bs[:].unsafe_extract_uint_le(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn Array::unsafe_extract_uint_be(
  bs : Array[Byte],
  offset : Int,
  len : Int,
) -> UInt {
  bs[:].unsafe_extract_uint_be(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn Array::unsafe_extract_uint64_le(
  bs : Array[Byte],
  offset : Int,
  len : Int,
) -> UInt64 {
  bs[:].unsafe_extract_uint64_le(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn Array::unsafe_extract_uint64_be(
  bs : Array[Byte],
  offset : Int,
  len : Int,
) -> UInt64 {
  bs[:].unsafe_extract_uint64_be(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn Array::unsafe_extract_bytesview(
  bs : Array[Byte],
  offset : Int,
  len : Int,
) -> ArrayView[Byte] {
  bs[:].unsafe_extract_bytesview(offset, len)
}

//--------------------------------
// FixedArray
//--------------------------------

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn FixedArray::unsafe_extract_bit(
  bs : FixedArray[Byte],
  offset : Int,
  len : Int,
) -> UInt {
  bs[:].unsafe_extract_bit(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn FixedArray::unsafe_extract_byte(
  bs : FixedArray[Byte],
  offset : Int,
  len : Int,
) -> UInt {
  bs[:].unsafe_extract_byte(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn FixedArray::unsafe_extract_uint_le(
  bs : FixedArray[Byte],
  offset : Int,
  len : Int,
) -> UInt {
  bs[:].unsafe_extract_uint_le(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn FixedArray::unsafe_extract_uint_be(
  bs : FixedArray[Byte],
  offset : Int,
  len : Int,
) -> UInt {
  bs[:].unsafe_extract_uint_be(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn FixedArray::unsafe_extract_uint64_le(
  bs : FixedArray[Byte],
  offset : Int,
  len : Int,
) -> UInt64 {
  bs[:].unsafe_extract_uint64_le(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn FixedArray::unsafe_extract_uint64_be(
  bs : FixedArray[Byte],
  offset : Int,
  len : Int,
) -> UInt64 {
  bs[:].unsafe_extract_uint64_be(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn FixedArray::unsafe_extract_bytesview(
  bs : FixedArray[Byte],
  offset : Int,
  len : Int,
) -> ArrayView[Byte] {
  bs[:].unsafe_extract_bytesview(offset, len)
}

//--------------------------------
// BytesView
//--------------------------------

///|
/// Extract a single bit.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn BytesView::unsafe_extract_bit(
  bs : BytesView,
  offset : Int,
  _len : Int,
) -> UInt {
  let byte_index = offset >> 3
  let bit_shift = 7 - (offset & 7)
  let byte_val = bs.unsafe_get(byte_index).to_uint()
  (byte_val >> bit_shift) & 1U
}

///|
/// Extract a single bit.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn BytesView::unsafe_extract_bit_signed(
  bs : BytesView,
  offset : Int,
  _len : Int,
) -> Int {
  let byte_index = offset >> 3
  let bit_shift = 7 - (offset & 7)
  let byte_val = bs.unsafe_get(byte_index).to_int()
  // Extract bit and convert to signed: 0 -> 0, 1 -> -1
  ((byte_val >> bit_shift) & 1) * -1
}

///|
/// Extract [2..8] bits.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn BytesView::unsafe_extract_byte(
  bs : BytesView,
  offset : Int,
  len : Int,
) -> UInt {
  let byte_index = offset >> 3
  if (offset & 7) == 0 {
    // byte-aligned case
    let byte = bs.unsafe_get(byte_index)
    (byte >> (8 - len)).to_uint()
  } else if (offset & 7) + len <= 8 {
    // All bits are within the same byte - no need to read next byte
    let byte = bs.unsafe_get(byte_index).to_uint()
    let shift = 8 - ((offset & 7) + len)
    let mask = (1U << len) - 1
    (byte >> shift) & mask
  } else {
    // extract 16 bits at [byte_index, byte_index + 1]
    let b0 = bs.unsafe_get(byte_index).to_uint()
    let b1 = bs.unsafe_get(byte_index + 1).to_uint()
    let data = (b0 << 8) | b1
    // mask off the top bits
    let bit_mask = (1U << (16 - (offset & 7))) - 1
    let data = data & bit_mask
    let shift = 16 - ((offset & 7) + len)
    data >> shift
  }
}

///|
/// Extract [9..32] bits in little-endian byte order.
/// 
/// # Invariants
/// - It's guaranteed to have at least 2 bytes available for extraction
/// - Only reads the necessary number of bytes based on the bit length
///
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn BytesView::unsafe_extract_uint_le(
  bs : BytesView,
  offset : Int,
  len : Int,
) -> UInt {
  let bytes_needed = (len + 7) / 8
  // TODO: add fast path for aligned case
  // non-aligned case: extract bytes using unsafe_extract_byte
  let b0 = bs.unsafe_extract_byte(offset, 8)
  match bytes_needed {
    2 => {
      let b1 = bs.unsafe_extract_byte(offset + 8, len - 8)
      (b1 << 8) | b0
    }
    3 => {
      let b1 = bs.unsafe_extract_byte(offset + 8, 8)
      let b2 = bs.unsafe_extract_byte(offset + 16, len - 16)
      (b2 << 16) | (b1 << 8) | b0
    }
    4 => {
      let b1 = bs.unsafe_extract_byte(offset + 8, 8)
      let b2 = bs.unsafe_extract_byte(offset + 16, 8)
      let b3 = bs.unsafe_extract_byte(offset + 24, len - 24)
      (b3 << 24) | (b2 << 16) | (b1 << 8) | b0
    }
    _ => abort("Invalid byte count for int32 extraction")
  }
}

///|
/// Extract [9..32] bits in big-endian byte order.
/// 
/// # Invariants
/// - It's guaranteed to have at least 2 bytes available for extraction
/// - Only reads the necessary number of bytes based on the bit length
///
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn BytesView::unsafe_extract_uint_be(
  bs : BytesView,
  offset : Int,
  len : Int,
) -> UInt {
  let bytes_needed = (len + 7) / 8
  // TODO: add fast path for aligned case
  // non-aligned case: extract bytes using unsafe_extract_byte
  let b0 = bs.unsafe_extract_byte(offset, 8)
  match bytes_needed {
    2 => {
      let b1 = bs.unsafe_extract_byte(offset + 8, len - 8)
      let shift = 16 - len
      let data = (b0 << 8) | (b1 << shift)
      data >> shift
    }
    3 => {
      let b1 = bs.unsafe_extract_byte(offset + 8, 8)
      let b2 = bs.unsafe_extract_byte(offset + 16, len - 16)
      let shift = 24 - len
      let data = (b0 << 16) | (b1 << 8) | (b2 << shift)
      data >> shift
    }
    4 => {
      let b1 = bs.unsafe_extract_byte(offset + 8, 8)
      let b2 = bs.unsafe_extract_byte(offset + 16, 8)
      let b3 = bs.unsafe_extract_byte(offset + 24, len - 24)
      let shift = 32 - len
      let data = (b0 << 24) | (b1 << 16) | (b2 << 8) | (b3 << shift)
      data >> shift
    }
    _ => abort("Invalid byte count for int32 extraction")
  }
}

///|
/// Extract [33..64] bits in little-endian byte order.
/// 
/// # Invariants
/// - It's guaranteed to have at least 5 bytes available for extraction
/// - Only reads the necessary number of bytes based on the bit length (5-8 bytes)
/// - For bit lengths < 33, use unsafe_extract_int_le instead
///
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn BytesView::unsafe_extract_uint64_le(
  bs : BytesView,
  offset : Int,
  len : Int,
) -> UInt64 {
  let bytes_needed = (len + 7) / 8
  // TODO: add fast path for aligned case
  // non-aligned case: extract bytes using unsafe_extract_byte
  let b0 = bs.unsafe_extract_byte(offset, 8).to_uint64()
  let b1 = bs.unsafe_extract_byte(offset + 8, 8).to_uint64()
  let b2 = bs.unsafe_extract_byte(offset + 16, 8).to_uint64()
  let b3 = bs.unsafe_extract_byte(offset + 24, 8).to_uint64()
  match bytes_needed {
    5 => {
      let b4 = bs.unsafe_extract_byte(offset + 32, len - 32).to_uint64()
      (b4 << 32) | (b3 << 24) | (b2 << 16) | (b1 << 8) | b0
    }
    6 => {
      let b4 = bs.unsafe_extract_byte(offset + 32, 8).to_uint64()
      let b5 = bs.unsafe_extract_byte(offset + 40, len - 40).to_uint64()
      (b5 << 40) | (b4 << 32) | (b3 << 24) | (b2 << 16) | (b1 << 8) | b0
    }
    7 => {
      let b4 = bs.unsafe_extract_byte(offset + 32, 8).to_uint64()
      let b5 = bs.unsafe_extract_byte(offset + 40, 8).to_uint64()
      let b6 = bs.unsafe_extract_byte(offset + 48, len - 48).to_uint64()
      (b6 << 48) |
      (b5 << 40) |
      (b4 << 32) |
      (b3 << 24) |
      (b2 << 16) |
      (b1 << 8) |
      b0
    }
    8 => {
      let b4 = bs.unsafe_extract_byte(offset + 32, 8).to_uint64()
      let b5 = bs.unsafe_extract_byte(offset + 40, 8).to_uint64()
      let b6 = bs.unsafe_extract_byte(offset + 48, 8).to_uint64()
      let b7 = bs.unsafe_extract_byte(offset + 56, len - 56).to_uint64()
      (b7 << 56) |
      (b6 << 48) |
      (b5 << 40) |
      (b4 << 32) |
      (b3 << 24) |
      (b2 << 16) |
      (b1 << 8) |
      b0
    }
    _ => abort("Invalid byte count for int64 extraction")
  }
}

///|
/// Extract [33..64] bits in big-endian byte order.
/// 
/// # Invariants
/// - It's guaranteed to have at least 5 bytes available for extraction
/// - Only reads the necessary number of bytes based on the bit length (5-8 bytes)
/// - For bit lengths < 33, use unsafe_extract_int_be instead
///
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn BytesView::unsafe_extract_uint64_be(
  bs : BytesView,
  offset : Int,
  len : Int,
) -> UInt64 {
  let bytes_needed = (len + 7) / 8
  // TODO: add fast path for aligned case
  // non-aligned case: extract bytes using unsafe_extract_byte
  let b0 = bs.unsafe_extract_byte(offset, 8).to_uint64()
  let b1 = bs.unsafe_extract_byte(offset + 8, 8).to_uint64()
  let b2 = bs.unsafe_extract_byte(offset + 16, 8).to_uint64()
  let b3 = bs.unsafe_extract_byte(offset + 24, 8).to_uint64()
  match bytes_needed {
    5 => {
      let b4 = bs.unsafe_extract_byte(offset + 32, len - 32).to_uint64()
      let shift = 40 - len
      let data = (b0 << 32) |
        (b1 << 24) |
        (b2 << 16) |
        (b3 << 8) |
        (b4 << shift)
      data >> shift
    }
    6 => {
      let b4 = bs.unsafe_extract_byte(offset + 32, 8).to_uint64()
      let b5 = bs.unsafe_extract_byte(offset + 40, len - 40).to_uint64()
      let shift = 48 - len
      let data = (b0 << 40) |
        (b1 << 32) |
        (b2 << 24) |
        (b3 << 16) |
        (b4 << 8) |
        (b5 << shift)
      data >> shift
    }
    7 => {
      let b4 = bs.unsafe_extract_byte(offset + 32, 8).to_uint64()
      let b5 = bs.unsafe_extract_byte(offset + 40, 8).to_uint64()
      let b6 = bs.unsafe_extract_byte(offset + 48, len - 48).to_uint64()
      let shift = 56 - len
      let data = (b0 << 48) |
        (b1 << 40) |
        (b2 << 32) |
        (b3 << 24) |
        (b4 << 16) |
        (b5 << 8) |
        (b6 << shift)
      data >> shift
    }
    8 => {
      let b4 = bs.unsafe_extract_byte(offset + 32, 8).to_uint64()
      let b5 = bs.unsafe_extract_byte(offset + 40, 8).to_uint64()
      let b6 = bs.unsafe_extract_byte(offset + 48, 8).to_uint64()
      let b7 = bs.unsafe_extract_byte(offset + 56, len - 56).to_uint64()
      let shift = 64 - len
      let data = (b0 << 56) |
        (b1 << 48) |
        (b2 << 40) |
        (b3 << 32) |
        (b4 << 24) |
        (b5 << 16) |
        (b6 << 8) |
        (b7 << shift)
      data >> shift
    }
    _ => abort("Invalid byte count for int64 extraction")
  }
}

///|
/// Extract a subview from a view. `offset` and `len` are in bits and must be
/// aligned to bytes.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn BytesView::unsafe_extract_bytesview(
  bs : BytesView,
  offset : Int,
  len : Int,
) -> BytesView {
  BytesView::make(bs.bytes(), bs.start() + (offset >> 3), len >> 3)
}

///|
/// Extract [2..8] bits as a signed integer.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn BytesView::unsafe_extract_byte_signed(
  bs : BytesView,
  offset : Int,
  len : Int,
) -> Int {
  let unsigned = bs.unsafe_extract_byte(offset, len)
  unsigned.extend_sign(len)
}

///|
/// Extract [9..32] bits as a signed integer.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn BytesView::unsafe_extract_int_le(
  bs : BytesView,
  offset : Int,
  len : Int,
) -> Int {
  let unsigned = bs.unsafe_extract_uint_le(offset, len)
  unsigned.extend_sign(len)
}

///|
/// Extract [9..32] bits as a signed integer.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn BytesView::unsafe_extract_int_be(
  bs : BytesView,
  offset : Int,
  len : Int,
) -> Int {
  let unsigned = bs.unsafe_extract_uint_be(offset, len)
  unsigned.extend_sign(len)
}

///|
/// Extract [33..64] bits as a signed integer.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn BytesView::unsafe_extract_int64_le(
  bs : BytesView,
  offset : Int,
  len : Int,
) -> Int64 {
  let unsigned = bs.unsafe_extract_uint64_le(offset, len)
  unsigned.extend_sign(len)
}

///|
/// Extract [33..64] bits as a signed integer.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn BytesView::unsafe_extract_int64_be(
  bs : BytesView,
  offset : Int,
  len : Int,
) -> Int64 {
  let unsigned = bs.unsafe_extract_uint64_be(offset, len)
  unsigned.extend_sign(len)
}

//--------------------------------
// Bytes
//--------------------------------

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn Bytes::unsafe_extract_bit(bs : Bytes, offset : Int, len : Int) -> UInt {
  bs[:].unsafe_extract_bit(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn Bytes::unsafe_extract_byte(bs : Bytes, offset : Int, len : Int) -> UInt {
  bs[:].unsafe_extract_byte(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn Bytes::unsafe_extract_uint_le(
  bs : Bytes,
  offset : Int,
  len : Int,
) -> UInt {
  bs[:].unsafe_extract_uint_le(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn Bytes::unsafe_extract_uint_be(
  bs : Bytes,
  offset : Int,
  len : Int,
) -> UInt {
  bs[:].unsafe_extract_uint_be(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn Bytes::unsafe_extract_uint64_le(
  bs : Bytes,
  offset : Int,
  len : Int,
) -> UInt64 {
  bs[:].unsafe_extract_uint64_le(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn Bytes::unsafe_extract_uint64_be(
  bs : Bytes,
  offset : Int,
  len : Int,
) -> UInt64 {
  bs[:].unsafe_extract_uint64_be(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn Bytes::unsafe_extract_bytesview(
  bs : Bytes,
  offset : Int,
  len : Int,
) -> BytesView {
  bs[:].unsafe_extract_bytesview(offset, len)
}
