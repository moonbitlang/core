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

// offset and len are all in bits

///|
/// Extract a single bit.
#internal(experimental, "subject to breaking change without notice")
pub fn ArrayView::unsafe_extract_bit(
  bs : ArrayView[Byte],
  offset : Int,
  _len : Int,
) -> UInt {
  let byte_index = offset >> 3
  let bit_mask = (1 << (7 - (offset & 7))).to_byte()
  // TODO: branchless for performance
  if (bs.unsafe_get(byte_index) & bit_mask) != 0 {
    1
  } else {
    0
  }
}

///|
/// Extract [2..8] bits.
#internal(experimental, "subject to breaking change without notice")
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
#internal(experimental, "subject to breaking change without notice")
pub fn Array::unsafe_extract_bit(
  bs : Array[Byte],
  offset : Int,
  len : Int,
) -> UInt {
  bs[:].unsafe_extract_bit(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn Array::unsafe_extract_byte(
  bs : Array[Byte],
  offset : Int,
  len : Int,
) -> UInt {
  bs[:].unsafe_extract_byte(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn Array::unsafe_extract_uint_le(
  bs : Array[Byte],
  offset : Int,
  len : Int,
) -> UInt {
  bs[:].unsafe_extract_uint_le(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn Array::unsafe_extract_uint_be(
  bs : Array[Byte],
  offset : Int,
  len : Int,
) -> UInt {
  bs[:].unsafe_extract_uint_be(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn Array::unsafe_extract_uint64_le(
  bs : Array[Byte],
  offset : Int,
  len : Int,
) -> UInt64 {
  bs[:].unsafe_extract_uint64_le(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn Array::unsafe_extract_uint64_be(
  bs : Array[Byte],
  offset : Int,
  len : Int,
) -> UInt64 {
  bs[:].unsafe_extract_uint64_be(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn Array::unsafe_extract_bytesview(
  bs : Array[Byte],
  offset : Int,
  len : Int,
) -> ArrayView[Byte] {
  bs[:].unsafe_extract_bytesview(offset, len)
}
