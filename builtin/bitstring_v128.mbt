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

// Runtime support for the `v128le(v)` bitstring pattern. A `V128` has no
// inherent lane structure, so its byte view is the little-endian layout of
// `@v128.v128_load`: byte `k` -> i8x16 lane `k`, with bytes 0..7 in `lo` and
// bytes 8..15 in `hi`. The bitstring pattern is restricted to byte-aligned
// offsets and uses that intrinsic through the private `v128_load` helper in
// `simd.mbt`.

///|
/// Extract 16 byte-aligned bytes as a `V128` (little-endian byte order).
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn ArrayView::unsafe_extract_v128_aligned(
  bs : ArrayView[Byte],
  byte_offset : Int,
) -> V128 {
  v128_load(buffer_to_fixedarray(bs.buf()), bs.start() + byte_offset)
}

///|
/// Extract 16 byte-aligned bytes as a `V128` (little-endian byte order).
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn BytesView::unsafe_extract_v128_aligned(
  bs : BytesView,
  byte_offset : Int,
) -> V128 {
  v128_load(unsafe_from_bytes(bs.bytes()), bs.start() + byte_offset)
}

///|
/// Extract 16 byte-aligned bytes directly from `Bytes` as a `V128`.
#borrow(bs)
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn Bytes::unsafe_extract_v128_aligned(
  bs : Bytes,
  byte_offset : Int,
) -> V128 {
  v128_load(unsafe_from_bytes(bs), byte_offset)
}

///|
/// Forward to `ArrayView::unsafe_extract_v128_aligned`.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn Array::unsafe_extract_v128_aligned(
  bs : Array[Byte],
  byte_offset : Int,
) -> V128 {
  bs[:].unsafe_extract_v128_aligned(byte_offset)
}

///|
/// Load 16 byte-aligned bytes directly from a fixed array.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn FixedArray::unsafe_extract_v128_aligned(
  bs : FixedArray[Byte],
  byte_offset : Int,
) -> V128 {
  v128_load(bs, byte_offset)
}

///|
/// Forward to `FixedArray::unsafe_extract_v128_aligned`.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn ReadOnlyArray::unsafe_extract_v128_aligned(
  bs : ReadOnlyArray[Byte],
  byte_offset : Int,
) -> V128 {
  bs
  .unsafe_reinterpret_to_fixed_array()
  .unsafe_extract_v128_aligned(byte_offset)
}
