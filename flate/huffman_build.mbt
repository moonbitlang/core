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

// Length-limited canonical Huffman construction for the encode pipeline:
// frequencies in, (code lengths, bit-reversed code words) out.
//

///|
#valtype
priv struct Node {
  lit : Int32
  freq : Int32
}

///|
priv struct LevelInfo {
  mut level : Int32
  mut last_freq : Int32
  mut next_char_freq : Int32
  mut next_pair_freq : Int32
  mut needed : Int32
}

///|
fn LevelInfo::LevelInfo() -> LevelInfo {
  { level: 0, last_freq: 0, next_char_freq: 0, next_pair_freq: 0, needed: 0, }
}

///|
fn reverse_bits(number : UInt32, bit_length : Int32) -> UInt32 {
  reverse16(number << (16 - bit_length))
}

///|
/// Number of codes assigned to each bit length (index = length). Requires
/// `nodes` sorted by ascending frequency, with `n >= 3`.
fn bounded_bit_counts(
  nodes : Array[Node],
  n : Int32,
  max_bits_in : Int32,
) -> FixedArray[Int32] {
  let maxi = 2147483647
  let max_bits = max_bits_in.min(n - 1)
  let levels = FixedArray::makei(17, _ => LevelInfo())
  let leaf_counts = FixedArray::make(17 * 17, 0)
  for level in 1..<=max_bits {
    levels[level].level = level
    levels[level].last_freq = nodes[1].freq
    levels[level].next_char_freq = nodes[2].freq
    levels[level].next_pair_freq = nodes[0].freq + nodes[1].freq
    levels[level].needed = 0
    leaf_counts[level * 17 + level] = 2
    if level == 1 {
      levels[level].next_pair_freq = maxi
    }
  }
  levels[max_bits].needed = 2 * n - 4
  let mut level = max_bits
  for ;; {
    let lv = levels[level]
    if lv.next_pair_freq == maxi && lv.next_char_freq == maxi {
      lv.needed = 0
      levels[level + 1].next_pair_freq = maxi
      level = level + 1
      continue
    }
    let prev_freq = lv.last_freq
    if lv.next_char_freq < lv.next_pair_freq {
      let nn = leaf_counts[level * 17 + level] + 1
      lv.last_freq = lv.next_char_freq
      leaf_counts[level * 17 + level] = nn
      lv.next_char_freq = if nn < n { nodes[nn].freq } else { maxi }
    } else {
      lv.last_freq = lv.next_pair_freq
      leaf_counts.blit_to(
        leaf_counts,
        len=level,
        src_offset=(level - 1) * 17,
        dst_offset=level * 17,
      )
      levels[lv.level - 1].needed = 2
    }
    lv.needed = lv.needed - 1
    if lv.needed == 0 {
      if lv.level == max_bits {
        break
      }
      levels[lv.level + 1].next_pair_freq = prev_freq + lv.last_freq
      level = level + 1
    } else {
      while levels[level - 1].needed > 0 {
        level = level - 1
      }
    }
  }
  let bit_count = FixedArray::make(max_bits + 1, 0)
  let counts = leaf_counts[max_bits * 17:(max_bits + 1) * 17]
  let mut bits = 1
  for lvl = max_bits; lvl > 0; lvl = lvl - 1 {
    bit_count[bits] = counts[lvl] - counts[lvl - 1]
    bits = bits + 1
  }
  bit_count
}

///|
fn assign_codes(
  bit_count : FixedArray[Int32],
  nodes : Array[Node],
  code_len : FixedArray[Int32],
  code_val : FixedArray[UInt32]?,
) -> Unit {
  // Assign lengths in frequency order, then generate canonical codes in
  // symbol order. No per-length arrays or sorting are needed.
  let mut rem = nodes.length()
  for nlen in 1..<bit_count.length() {
    let bits = bit_count[nlen]
    for k in (rem - bits)..<rem {
      code_len[nodes[k].lit] = nlen
    }
    rem = rem - bits
  }
  guard code_val is Some(values) else { return }
  let next_code = FixedArray::make(bit_count.length(), 0)
  for nlen in 1..<bit_count.length() {
    next_code[nlen] = (next_code[nlen - 1] + bit_count[nlen - 1]) << 1
  }
  for symbol in 0..<code_len.length() {
    let nlen = code_len[symbol]
    if nlen > 0 {
      values[symbol] = reverse_bits(next_code[nlen].reinterpret_as_uint(), nlen)
      next_code[nlen] += 1
    }
  }
}

///|
/// Build length-limited canonical Huffman codes for `size` symbols from their
/// frequencies into caller-owned arrays. Omit `code_val` when only lengths are
/// needed; this avoids both the unused code array and a tuple return allocation.
fn gen_huffman(
  freq : FixedArray[Int32],
  size : Int32,
  max_bits : Int32,
  code_len : FixedArray[Int32],
  code_val? : FixedArray[UInt32],
) -> Unit {
  let nodes : Array[Node] = []
  for i in 0..<size {
    if freq[i] != 0 {
      nodes.push({ lit: i, freq: freq[i], })
    }
  }
  let count = nodes.length()
  guard count != 0 else { return }
  guard count > 2 else {
    for k in 0..<count {
      code_len[nodes[k].lit] = 1
      if code_val is Some(values) {
        values[nodes[k].lit] = reverse_bits(k.reinterpret_as_uint(), 1)
      }
    }
    return
  }
  nodes.sort_by((a, b) => {
    if a.freq != b.freq {
      a.freq - b.freq
    } else {
      a.lit - b.lit
    }
  })
  let bit_count = bit_counts(nodes, count, max_bits)
  assign_codes(bit_count, nodes, code_len, code_val)
}

///|
// Two sorted queues build an unrestricted optimal tree in linear time.
// Internal nodes are created after their children; walking parents backward
// then replaces indices with depths. Use the length-limited construction only
// when a depth exceeds the DEFLATE limit.
fn bit_counts(
  nodes : Array[Node],
  n : Int32,
  max_bits : Int32,
) -> FixedArray[Int32] {
  let parents = FixedArray::make(2 * n - 1, 0)
  let weights = FixedArray::make(n - 1, 0)
  let mut leaf = 0
  let mut branch = 0
  for built in 0..<(n - 1) {
    let mut sum = 0
    for _ in 0..<2 {
      if leaf < n && (branch == built || nodes[leaf].freq < weights[branch]) {
        sum += nodes[leaf].freq
        parents[leaf] = n + built
        leaf += 1
      } else {
        sum += weights[branch]
        parents[n + branch] = n + built
        branch += 1
      }
    }
    weights[built] = sum
  }
  let counts = FixedArray::make(max_bits + 1, 0)
  for i = 2 * n - 3; i >= 0; i = i - 1 {
    let depth = parents[parents[i]] + 1
    guard depth <= max_bits else {
      return bounded_bit_counts(nodes, n, max_bits)
    }
    parents[i] = depth
    if i < n {
      counts[depth] += 1
    }
  }
  counts
}
