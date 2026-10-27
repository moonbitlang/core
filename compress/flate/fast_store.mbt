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

// Optional speed/ratio trade-off inspired by fzip's byte-diversity and
// repetition checks. This is a heuristic, not a proof of incompressibility.
// It never changes decompressed bytes, but can miss profitable LZ matches.

///|
fn fast_store_sample(length : Int32, byte_at : (Int32) -> Byte) -> Bool {
  let frequencies = FixedArray::make(256, 0)
  if length < 8192 {
    let mut distinct = 0
    let mut largest = 0
    for i in 0..<length {
      let value = byte_at(i).to_int()
      if frequencies[value] == 0 {
        distinct += 1
      }
      frequencies[value] += 1
      largest = largest.max(frequencies[value])
    }
    // A small alphabet or a frequent byte still benefits from coding.
    guard distinct > 240 && largest <= length / 32 else { return false }
    for distance in [1, 2, 4, 8, 16, 32, 64, 128, 256, 512] {
      // The adapters require at least 1024 bytes, so all 64 probes fit.
      let matches = for i = 0, matches = 0 {
        guard i < 64 else { break matches }
        continue i + 1,
          matches + (if byte_at(i) == byte_at(i + distance) { 1 } else { 0 })
      }
      guard matches <= 32 else { return false }
    }
    return true
  }
  // Bound work to 2048 samples. Require all four regions to look random,
  // rather than allowing a random suffix to dominate a compressible prefix.
  let quarter = length / 4
  for region in 0..<4 {
    frequencies.fill(0)
    let start = region * quarter
    let end = if region == 3 { length } else { start + quarter }
    let stride = (end - start) / 512
    let mut distinct = 0
    let mut largest = 0
    let mut local_matches = 0
    for sample in 0..<512 {
      let position = start + sample * stride
      let byte = byte_at(position)
      let value = byte.to_int()
      if frequencies[value] == 0 {
        distinct += 1
      }
      frequencies[value] += 1
      largest = largest.max(frequencies[value])
      if position >= start + 3 &&
        (
          byte == byte_at(position - 1) ||
          (
            byte == byte_at(position - 2) &&
            byte_at(position - 1) == byte_at(position - 3)
          )
        ) {
        local_matches += 1
      }
    }
    guard distinct > 200 && largest <= 16 && local_matches * 10 < 512 else {
      return false
    }
  }
  true
}

///|
fn should_fast_store(input : BytesView) -> Bool {
  // Avoid classifier/allocation overhead on tiny inputs.
  guard input.length() >= 1024 else { return false }
  fast_store_sample(input.length(), i => input[i])
}

///|
fn should_fast_store_window(
  data : FixedArray[Byte],
  start : Int32,
  end : Int32,
) -> Bool {
  guard end - start >= 1024 else { return false }
  fast_store_sample(end - start, i => data[(start + i) & STREAM_RING_MASK])
}
