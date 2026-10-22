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
/// Validate the one's-complement length pair carried by a stored block.
#inline
fn validate_stored_length(len : Int32, nlen : Int32) -> Unit raise InflateError {
  guard len == (nlen ^ 0xFFFF) else {
    raise InflateError(Corrupt, "stored block length mismatch")
  }
}

///|
/// Interpret HLIT while preserving its reserved-value diagnostic before any
/// later dynamic-header fields are read.
#inline
fn dynamic_literal_count(bits : Int32) -> Int32 raise InflateError {
  let count = bits + 257
  guard count <= MAX_NUM_LIT else {
    raise InflateError(Corrupt, "corrupt: too many literal codes")
  }
  count
}

///|
/// Interpret HDIST and reject the two reserved five-bit encodings.
#inline
fn dynamic_distance_count(bits : Int32) -> Int32 raise InflateError {
  let count = bits + 1
  guard count <= MAX_NUM_DIST else {
    raise InflateError(Corrupt, "corrupt: too many distance codes")
  }
  count
}

///|
/// Check that a back-reference reaches a byte in the decoder's available
/// history. The caller supplies the history size appropriate to its execution
/// strategy (one-shot output or the streaming circular window), which is
/// always non-negative. Subtracting one as `UInt` turns the inclusive valid
/// interval `1..=available_history` into one upper-bound comparison; zero and
/// negative distances wrap above the bound and are rejected as well.
#inline
fn back_reference_distance_is_valid(
  distance : Int32,
  available_history : Int32,
) -> Bool {
  distance.reinterpret_as_uint() - 1U < available_history.reinterpret_as_uint()
}

///|
/// Static interpretation of one dynamic-header repeat symbol. Keeping this
/// independent of either bit reader makes the streaming and in-memory decoders
/// agree on the symbol's base count, extra-bit width, and repeated value.
#valtype
priv struct CodeLengthRepeat {
  base : Int32
  extra_bits : Int32
  value : Int32
}

///|
fn interpret_code_length_repeat(
  symbol : Int32,
  previous : Int32?,
) -> CodeLengthRepeat raise InflateError {
  match symbol {
    16 => {
      guard previous is Some(value) else {
        raise InflateError(Corrupt, "corrupt: repeat with no previous length")
      }
      { base: 3, extra_bits: 2, value, }
    }
    17 => { base: 3, extra_bits: 3, value: 0, }
    18 => { base: 11, extra_bits: 7, value: 0, }
    _ => raise InflateError(Corrupt, "corrupt: bad code-length symbol")
  }
}

///|
/// The fixed-Huffman distance symbol carried by a raw five-bit code: the code
/// is stored bit-reversed in the lowest five bits (RFC 1951 §3.2.6).
#inline
fn fixed_distance_symbol(bits5 : Int32) -> Int32 {
  reverse8(((bits5 << 3) & 0xFF).to_byte()).to_int()
}

///|
/// Decode one dynamic-Huffman block header, shared by the streaming `Inflater`
/// and the in-memory `MemDecoder` so both interpret HLIT/HDIST/HCLEN and the
/// code-length run-length encoding identically. `read_bits` and `huff_sym`
/// come from the caller's bit reader and raise only `InflateError`; the
/// streaming decoder's input-suspension signal is converted to `Truncated` at
/// its call site. `huff_sym` reads from the code-length tree, which this
/// function has just initialized inside `dyn_litlen`. `codebits` must have
/// `NUM_CODES` slots and `clbits` room for `nlit + ndist`. Returns the
/// literal/length and distance code counts.
fn decode_dynamic_header(
  read_bits : (Int32) -> Int32 raise InflateError,
  huff_sym : () -> Int32 raise InflateError,
  dyn_litlen : HuffmanDecoder,
  codebits : FixedArray[Int32],
  clbits : FixedArray[Int32],
) -> (Int32, Int32) raise InflateError {
  let nlit = dynamic_literal_count(read_bits(5))
  let ndist = dynamic_distance_count(read_bits(5))
  let nclen = read_bits(4) + 4
  for i in 0..<nclen {
    codebits[code_order[i]] = read_bits(3)
  }
  for i in nclen..<code_order.length() {
    codebits[code_order[i]] = 0
  }
  guard dyn_litlen.initialize(codebits) else {
    raise InflateError(Corrupt, "corrupt: bad code-length tree")
  }
  let n = nlit + ndist
  let mut i = 0
  while i < n {
    let x = huff_sym()
    guard x >= 16 else {
      clbits[i] = x
      i = i + 1
      continue
    }
    let previous = if i == 0 { None } else { Some(clbits[i - 1]) }
    let repeat = interpret_code_length_repeat(x, previous)
    let rep = repeat.base + read_bits(repeat.extra_bits)
    guard i + rep <= n else {
      raise InflateError(Corrupt, "corrupt: code-length repeat overflow")
    }
    clbits.fill(repeat.value, start=i, end=i + rep)
    i += rep
  }
  (nlit, ndist)
}
