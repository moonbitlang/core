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
#internal(experimental, "subject to breaking change without notice")
pub fn View::unsafe_extract_byte(bs : View, offset : Int, len : Int) -> Byte {
  guard len == 8
  let byte_index = offset / 8
  bs.unsafe_get(byte_index)
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn View::unsafe_extract_int_le(bs : View, offset : Int, len : Int) -> Int {
  guard len <= 32
  let byte_index = offset / 8
  if len == 16 {
    let b0 = bs.unsafe_get(byte_index).to_uint()
    let b1 = bs.unsafe_get(byte_index + 1).to_uint()
    (b0 | (b1 << 8)).reinterpret_as_int()
  } else if len == 24 {
    let b0 = bs.unsafe_get(byte_index).to_uint()
    let b1 = bs.unsafe_get(byte_index + 1).to_uint()
    let b2 = bs.unsafe_get(byte_index + 2).to_uint()
    (b0 | (b1 << 8) | (b2 << 16)).reinterpret_as_int()
  } else if len == 32 {
    let b0 = bs.unsafe_get(byte_index).to_uint()
    let b1 = bs.unsafe_get(byte_index + 1).to_uint()
    let b2 = bs.unsafe_get(byte_index + 2).to_uint()
    let b3 = bs.unsafe_get(byte_index + 3).to_uint()
    (b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)).reinterpret_as_int()
  } else {
    abort("unsupported length")
  }
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn View::unsafe_extract_int_be(bs : View, offset : Int, len : Int) -> Int {
  guard len <= 32 && len % 8 == 0
  let byte_index = offset / 8
  if len == 16 {
    let b0 = bs.unsafe_get(byte_index).to_uint()
    let b1 = bs.unsafe_get(byte_index + 1).to_uint()
    ((b0 << 8) | b1).reinterpret_as_int()
  } else if len == 24 {
    let b0 = bs.unsafe_get(byte_index).to_uint()
    let b1 = bs.unsafe_get(byte_index + 1).to_uint()
    let b2 = bs.unsafe_get(byte_index + 2).to_uint()
    ((b0 << 16) | (b1 << 8) | b2).reinterpret_as_int()
  } else if len == 32 {
    let b0 = bs.unsafe_get(byte_index).to_uint()
    let b1 = bs.unsafe_get(byte_index + 1).to_uint()
    let b2 = bs.unsafe_get(byte_index + 2).to_uint()
    let b3 = bs.unsafe_get(byte_index + 3).to_uint()
    ((b0 << 24) | (b1 << 16) | (b2 << 8) | b3).reinterpret_as_int()
  } else {
    abort("unsupported length")
  }
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn View::unsafe_extract_int64_le(
  bs : View,
  offset : Int,
  len : Int,
) -> Int64 {
  guard len <= 64 && len % 8 == 0
  let byte_index = offset / 8
  if len == 16 {
    let b0 = bs.unsafe_get(byte_index).to_int().to_uint64()
    let b1 = bs.unsafe_get(byte_index + 1).to_int().to_uint64()
    (b0 | (b1 << 8)).reinterpret_as_int64()
  } else if len == 24 {
    let b0 = bs.unsafe_get(byte_index).to_int().to_uint64()
    let b1 = bs.unsafe_get(byte_index + 1).to_int().to_uint64()
    let b2 = bs.unsafe_get(byte_index + 2).to_int().to_uint64()
    (b0 | (b1 << 8) | (b2 << 16)).reinterpret_as_int64()
  } else if len == 32 {
    let b0 = bs.unsafe_get(byte_index).to_int().to_uint64()
    let b1 = bs.unsafe_get(byte_index + 1).to_int().to_uint64()
    let b2 = bs.unsafe_get(byte_index + 2).to_int().to_uint64()
    let b3 = bs.unsafe_get(byte_index + 3).to_int().to_uint64()
    (b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)).reinterpret_as_int64()
  } else if len == 40 {
    let b0 = bs.unsafe_get(byte_index).to_int().to_uint64()
    let b1 = bs.unsafe_get(byte_index + 1).to_int().to_uint64()
    let b2 = bs.unsafe_get(byte_index + 2).to_int().to_uint64()
    let b3 = bs.unsafe_get(byte_index + 3).to_int().to_uint64()
    let b4 = bs.unsafe_get(byte_index + 4).to_int().to_uint64()
    (b0 | (b1 << 8) | (b2 << 16) | (b3 << 24) | (b4 << 32)).reinterpret_as_int64()
  } else if len == 48 {
    let b0 = bs.unsafe_get(byte_index).to_int().to_uint64()
    let b1 = bs.unsafe_get(byte_index + 1).to_int().to_uint64()
    let b2 = bs.unsafe_get(byte_index + 2).to_int().to_uint64()
    let b3 = bs.unsafe_get(byte_index + 3).to_int().to_uint64()
    let b4 = bs.unsafe_get(byte_index + 4).to_int().to_uint64()
    let b5 = bs.unsafe_get(byte_index + 5).to_int().to_uint64()
    (b0 | (b1 << 8) | (b2 << 16) | (b3 << 24) | (b4 << 32) | (b5 << 40)).reinterpret_as_int64()
  } else if len == 56 {
    let b0 = bs.unsafe_get(byte_index).to_int().to_uint64()
    let b1 = bs.unsafe_get(byte_index + 1).to_int().to_uint64()
    let b2 = bs.unsafe_get(byte_index + 2).to_int().to_uint64()
    let b3 = bs.unsafe_get(byte_index + 3).to_int().to_uint64()
    let b4 = bs.unsafe_get(byte_index + 4).to_int().to_uint64()
    let b5 = bs.unsafe_get(byte_index + 5).to_int().to_uint64()
    let b6 = bs.unsafe_get(byte_index + 6).to_int().to_uint64()
    (b0 |
    (b1 << 8) |
    (b2 << 16) |
    (b3 << 24) |
    (b4 << 32) |
    (b5 << 40) |
    (b6 << 48)).reinterpret_as_int64()
  } else if len == 64 {
    let b0 = bs.unsafe_get(byte_index).to_int().to_uint64()
    let b1 = bs.unsafe_get(byte_index + 1).to_int().to_uint64()
    let b2 = bs.unsafe_get(byte_index + 2).to_int().to_uint64()
    let b3 = bs.unsafe_get(byte_index + 3).to_int().to_uint64()
    let b4 = bs.unsafe_get(byte_index + 4).to_int().to_uint64()
    let b5 = bs.unsafe_get(byte_index + 5).to_int().to_uint64()
    let b6 = bs.unsafe_get(byte_index + 6).to_int().to_uint64()
    let b7 = bs.unsafe_get(byte_index + 7).to_int().to_uint64()
    (b0 |
    (b1 << 8) |
    (b2 << 16) |
    (b3 << 24) |
    (b4 << 32) |
    (b5 << 40) |
    (b6 << 48) |
    (b7 << 56)).reinterpret_as_int64()
  } else {
    abort("unsupported length")
  }
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn View::unsafe_extract_int64_be(
  bs : View,
  offset : Int,
  len : Int,
) -> Int64 {
  guard len <= 64 && len % 8 == 0
  let byte_index = offset / 8
  if len == 16 {
    let b0 = bs.unsafe_get(byte_index).to_int().to_uint64()
    let b1 = bs.unsafe_get(byte_index + 1).to_int().to_uint64()
    ((b0 << 8) | b1).reinterpret_as_int64()
  } else if len == 24 {
    let b0 = bs.unsafe_get(byte_index).to_int().to_uint64()
    let b1 = bs.unsafe_get(byte_index + 1).to_int().to_uint64()
    let b2 = bs.unsafe_get(byte_index + 2).to_int().to_uint64()
    ((b0 << 16) | (b1 << 8) | b2).reinterpret_as_int64()
  } else if len == 32 {
    let b0 = bs.unsafe_get(byte_index).to_int().to_uint64()
    let b1 = bs.unsafe_get(byte_index + 1).to_int().to_uint64()
    let b2 = bs.unsafe_get(byte_index + 2).to_int().to_uint64()
    let b3 = bs.unsafe_get(byte_index + 3).to_int().to_uint64()
    ((b0 << 24) | (b1 << 16) | (b2 << 8) | b3).reinterpret_as_int64()
  } else if len == 40 {
    let b0 = bs.unsafe_get(byte_index).to_int().to_uint64()
    let b1 = bs.unsafe_get(byte_index + 1).to_int().to_uint64()
    let b2 = bs.unsafe_get(byte_index + 2).to_int().to_uint64()
    let b3 = bs.unsafe_get(byte_index + 3).to_int().to_uint64()
    let b4 = bs.unsafe_get(byte_index + 4).to_int().to_uint64()
    ((b0 << 32) | (b1 << 24) | (b2 << 16) | (b3 << 8) | b4).reinterpret_as_int64()
  } else if len == 48 {
    let b0 = bs.unsafe_get(byte_index).to_int().to_uint64()
    let b1 = bs.unsafe_get(byte_index + 1).to_int().to_uint64()
    let b2 = bs.unsafe_get(byte_index + 2).to_int().to_uint64()
    let b3 = bs.unsafe_get(byte_index + 3).to_int().to_uint64()
    let b4 = bs.unsafe_get(byte_index + 4).to_int().to_uint64()
    let b5 = bs.unsafe_get(byte_index + 5).to_int().to_uint64()
    ((b0 << 40) | (b1 << 32) | (b2 << 24) | (b3 << 16) | (b4 << 8) | b5).reinterpret_as_int64()
  } else if len == 56 {
    let b0 = bs.unsafe_get(byte_index).to_int().to_uint64()
    let b1 = bs.unsafe_get(byte_index + 1).to_int().to_uint64()
    let b2 = bs.unsafe_get(byte_index + 2).to_int().to_uint64()
    let b3 = bs.unsafe_get(byte_index + 3).to_int().to_uint64()
    let b4 = bs.unsafe_get(byte_index + 4).to_int().to_uint64()
    let b5 = bs.unsafe_get(byte_index + 5).to_int().to_uint64()
    let b6 = bs.unsafe_get(byte_index + 6).to_int().to_uint64()
    ((b0 << 48) |
    (b1 << 40) |
    (b2 << 32) |
    (b3 << 24) |
    (b4 << 16) |
    (b5 << 8) |
    b6).reinterpret_as_int64()
  } else if len == 64 {
    let b0 = bs.unsafe_get(byte_index).to_int().to_uint64()
    let b1 = bs.unsafe_get(byte_index + 1).to_int().to_uint64()
    let b2 = bs.unsafe_get(byte_index + 2).to_int().to_uint64()
    let b3 = bs.unsafe_get(byte_index + 3).to_int().to_uint64()
    let b4 = bs.unsafe_get(byte_index + 4).to_int().to_uint64()
    let b5 = bs.unsafe_get(byte_index + 5).to_int().to_uint64()
    let b6 = bs.unsafe_get(byte_index + 6).to_int().to_uint64()
    let b7 = bs.unsafe_get(byte_index + 7).to_int().to_uint64()
    ((b0 << 56) |
    (b1 << 48) |
    (b2 << 40) |
    (b3 << 32) |
    (b4 << 24) |
    (b5 << 16) |
    (b6 << 8) |
    b7).reinterpret_as_int64()
  } else {
    abort("unsupported length")
  }
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn Bytes::unsafe_extract_byte(bs : Bytes, offset : Int, len : Int) -> Byte {
  bs[:].unsafe_extract_byte(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn Bytes::unsafe_extract_int_le(bs : Bytes, offset : Int, len : Int) -> Int {
  bs[:].unsafe_extract_int_le(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn Bytes::unsafe_extract_int_be(bs : Bytes, offset : Int, len : Int) -> Int {
  bs[:].unsafe_extract_int_be(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn Bytes::unsafe_extract_int64_le(
  bs : Bytes,
  offset : Int,
  len : Int,
) -> Int64 {
  bs[:].unsafe_extract_int64_le(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn Bytes::unsafe_extract_int64_be(
  bs : Bytes,
  offset : Int,
  len : Int,
) -> Int64 {
  bs[:].unsafe_extract_int64_be(offset, len)
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn View::unsafe_extract_bytesview(
  bs : View,
  offset : Int,
  len : Int,
) -> View {
  View::make(bs.bytes(), bs.start() + offset / 8, len / 8)
}

///|
#internal(experimental, "subject to breaking change without notice")
pub fn Bytes::unsafe_extract_bytesview(
  bs : Bytes,
  offset : Int,
  len : Int,
) -> View {
  bs[:].unsafe_extract_bytesview(offset, len)
}
