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

// Divide-and-conquer decimal conversion for native/wasm BigInts.

///|
/// Stored inline in the divisor table to avoid a heap object per entry.
#valtype
priv struct DecimalDivisor {
  value : BigInt
  digits : Int
}

///|
/// A leaf contains at most this many base-10^19 chunks.
const DECIMAL_LEAF_CHUNKS = 16

///|
/// Below this many binary limbs, tabulating divisors costs more than it saves.
const DECIMAL_RECURSIVE_THRESHOLD = 32

///|
fn format_decimal(value : BigInt) -> String {
  if value.is_zero() {
    return "0"
  }
  let magnitude = { ..value, sign: Positive, }
  // 1234/4096 is a slight upper bound for log10(2).
  let digit_hint = magnitude.bit_length() * 1234 / 4096 + 1
  let builder = StringBuilder(
    size_hint=digit_hint + (if value.sign == Negative { 1 } else { 0 }),
  )
  if value.sign == Negative {
    builder.write_char('-')
  }
  if magnitude.len < DECIMAL_RECURSIVE_THRESHOLD {
    write_decimal_leaf(magnitude, 0, builder)
  } else {
    let table = decimal_divisor_table(magnitude)
    write_decimal(magnitude, table, table.length() - 1, 0, builder)
  }
  builder.to_string()
}

///|
/// Successive squares of 10^(19*DECIMAL_LEAF_CHUNKS), through the first power
/// whose bit length reaches half the input's. The last entry is therefore a
/// near-square-root split for the top-level conversion.
fn decimal_divisor_table(value : BigInt) -> Array[DecimalDivisor] {
  let table = []
  let mut divisor = one
  for _ in 0..<DECIMAL_LEAF_CHUNKS {
    divisor = divisor.mul_single_limb(DECIMAL_CHUNK)
  }
  let mut digits = DECIMAL_CHUNK_DIGITS * DECIMAL_LEAF_CHUNKS
  let half_bits = (value.bit_length() + 1) / 2
  while true {
    table.push({ value: divisor, digits, })
    if divisor.bit_length() >= half_bits {
      break
    }
    divisor = divisor * divisor
    digits *= 2
  }
  table
}

///|
/// Write `value`, padding it on the left to `width` digits when nonzero.
fn write_decimal(
  value : BigInt,
  table : Array[DecimalDivisor],
  max_index : Int,
  width : Int,
  builder : StringBuilder,
) -> Unit {
  let mut index = max_index
  while index >= 0 && table[index].value.cmp_mag(value) > 0 {
    index -= 1
  }
  if index < 0 {
    write_decimal_leaf(value, width, builder)
    return
  }
  let divisor = table[index]
  let (quotient, remainder) = if value.cmp_mag(divisor.value) == 0 {
    (one, zero)
  } else {
    value.div_mod_mag(divisor.value)
  }
  write_decimal(
    quotient,
    table,
    index,
    maximum_int(0, width - divisor.digits),
    builder,
  )
  write_decimal(remainder, table, index - 1, divisor.digits, builder)
}

///|
/// Convert a small block iteratively, padding lower recursive blocks exactly.
fn write_decimal_leaf(
  value : BigInt,
  width : Int,
  builder : StringBuilder,
) -> Unit {
  if value.is_zero() {
    for _ in 0..<(if width == 0 { 1 } else { width }) {
      builder.write_char('0')
    }
    return
  }
  let work = make(value.len)
  work.unsafe_blit(0, value.limbs, 0, value.len)
  let mut len = value.len
  let chunks = []
  while len > 1 || work.unsafe_get(0) != 0 {
    chunks.push(
      div_w(work, work, len, DECIMAL_CHUNK, decimal_chunk_reciprocal, 0),
    )
    len = normalize_len(work, len)
  }
  let head = chunks[chunks.length() - 1].to_string()
  let digits = head.length() + (chunks.length() - 1) * DECIMAL_CHUNK_DIGITS
  for _ in digits..<width {
    builder.write_char('0')
  }
  builder.write_string(head)
  for i = chunks.length() - 2; i >= 0; i = i - 1 {
    let chunk = chunks[i].to_string()
    for _ in chunk.length()..<DECIMAL_CHUNK_DIGITS {
      builder.write_char('0')
    }
    builder.write_string(chunk)
  }
}
