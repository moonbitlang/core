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
let max_huffman_bits = 15

///|
priv struct HuffmanTree {
  table : FixedArray[Int32]
  max_bits : Int32
}

///|
fn reverse_bits(code : Int32, bit_len : Int32) -> Int32 {
  let mut reversed = 0
  for i in 0..<bit_len {
    reversed = (reversed << 1) | ((code >> i) & 1)
  }
  reversed
}

///|
fn build_huffman_tree(lengths : FixedArray[Int32]) -> HuffmanTree raise {
  let counts = FixedArray::make(max_huffman_bits + 1, 0)
  let mut max_bits = 0
  let mut num_codes = 0
  for bit_len in lengths {
    guard bit_len >= 0 && bit_len <= max_huffman_bits else {
      raise InvalidBlock("invalid huffman code length")
    }
    if bit_len > 0 {
      counts[bit_len] += 1
      num_codes += 1
      if bit_len > max_bits {
        max_bits = bit_len
      }
    }
  }
  guard num_codes > 0 else { raise InvalidBlock("empty huffman tree") }

  let mut left = 1
  for bit_len in 1..<=max_huffman_bits {
    left = (left << 1) - counts[bit_len]
    guard left >= 0 else { raise InvalidBlock("oversubscribed huffman tree") }
  }

  let next_code = FixedArray::make(max_huffman_bits + 1, 0)
  let mut code = 0
  for bit_len in 1..<=max_huffman_bits {
    code = (code + counts[bit_len - 1]) << 1
    next_code[bit_len] = code
  }

  let table = FixedArray::make(1 << max_bits, 0)
  for symbol, bit_len in lengths {
    if bit_len == 0 {
      continue
    }
    let code = next_code[bit_len]
    next_code[bit_len] = code + 1
    let reversed = reverse_bits(code, bit_len)
    let packed = (symbol << 5) | bit_len
    let num_suffixes = 1 << (max_bits - bit_len)
    for suffix in 0..<num_suffixes {
      let index = reversed | (suffix << bit_len)
      guard table[index] == 0 else {
        raise InvalidBlock("duplicate huffman code")
      }
      table[index] = packed
    }
  }
  { table, max_bits, }
}

///|
fn build_huffman_tree_or_abort(lengths : FixedArray[Int32]) -> HuffmanTree {
  build_huffman_tree(lengths) catch {
    err => abort(err.to_string())
  }
}

///|
let fixed_literal_tree : HuffmanTree = build_huffman_tree_or_abort(
  FixedArray::makei(288) <| i => {
    if i < 144 {
      8
    } else if i < 256 {
      9
    } else if i < 280 {
      7
    } else {
      8
    }
  },
)

///|
let fixed_distance_tree : HuffmanTree = build_huffman_tree_or_abort(
  FixedArray::make(32, 5),
)

///|
let code_length_order : FixedArray[Int32] = [
  16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15,
]

///|
let length_bases : FixedArray[Int32] = [
  3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83,
  99, 115, 131, 163, 195, 227, 258,
]

///|
let length_extras : FixedArray[Int32] = [
  0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5,
  5, 0,
]

///|
let distance_bases : FixedArray[Int32] = [
  1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769,
  1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577,
]

///|
let distance_extras : FixedArray[Int32] = [
  0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11,
  12, 12, 13, 13,
]
