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

// Position arithmetic at the limits of `Int`: none of these states is
// reachable with less than a gigabyte of input, so the functions are tested
// with the numbers themselves.

///|
/// A head that expired long ago can lie further below the position than an
/// `Int` holds: a head of an earlier stream (stamped below this stream's
/// base) that a rebase then moved down by almost 1 GiB. Its link must be the
/// expired sentinel, as for every predecessor beyond the window; the
/// subtraction used to wrap and store an arbitrary distance (zero, a link of
/// the position to itself, in the first case below).
test "expired predecessors saturate however far below the position they lie" {
  let chain = FixedArray::make(WINDOW_SIZE * 2 + 2, b'\x00')
  let expired = [
    // base 2^28, head 0 of an earlier stream after one rebase by 2^30 - 65536
    (805371904, -1073676288 - 268435456),
    (805371905, -1073676288 - 268435456),
    ((1 << 30) + 33000, -1073676288 - 536870911),
    (40000, -2147483648),
    (2147483647, -2147483648),
    (2147483647, 0),
    (WINDOW_SIZE + 1, 0),
    (5 * WINDOW_SIZE, 4 * WINDOW_SIZE - 1),
  ]
  for entry in expired {
    let (position, previous) = entry
    set_chain_previous(chain, position, previous)
    @test.assert_eq(
      chain_previous(chain, position),
      position - (WINDOW_SIZE + 1),
    )
  }
  for distance in [1, 2, 255, 256, WINDOW_SIZE - 1, WINDOW_SIZE] {
    for position in [WINDOW_SIZE, 805371904, 2147483647] {
      set_chain_previous(chain, position, position - distance)
      @test.assert_eq(chain_previous(chain, position), position - distance)
    }
  }
}

///|
/// The same through an insertion: the stamped head of an earlier stream in
/// the slot of the inserted word.
test "insertion after a rebase expires the head of an earlier stream" {
  let finder = MatchFinder()
  finder.position_base = 1 << 28
  let position = 805371904
  let product = 0x12345678U * 0x1E35A7BDU
  let slot = long_hash_product(product, shift=finder.long_shift)
  // Stamped 0 by the first stream, then rebased by 2^30 - 65536.
  finder.head[slot] = -((1 << 30) - STREAM_RING_SIZE)
  finder.insert_window_pos_hashed(position, product)
  @test.assert_eq(finder.head[slot], position + finder.position_base)
  @test.assert_eq(
    chain_previous(finder.prev, position),
    position - (WINDOW_SIZE + 1),
  )
}

///|
/// Tail guards near the largest position. The sum form `position + count <=
/// end` wraps there and holds although fewer bytes remain, which admitted an
/// unchecked four-byte read in `tokenize` and skipped the truncation checks
/// of a stored block.
test "tail guards do not wrap near the largest position" {
  let max = 2147483647
  for count in [3, 4] {
    for back in 0..<8 {
      let position = max - back
      @test.assert_eq(has_bytes_from(position, count, max), back >= count)
    }
  }
  // A stored block's length behind a position near the end of the input.
  assert_false(has_bytes_from(max - 100, 65535, max))
  assert_true(has_bytes_from(max - 65535, 65535, max))
  assert_true(has_bytes_from(0, 0, 0))
  assert_false(has_bytes_from(0, 1, 0))
  assert_true(has_bytes_from(7, 4, 11))
  assert_false(has_bytes_from(8, 4, 11))
}

///|
test "whole-buffer block targets advance through the final Int32-sized tail" {
  let end = 2147483647
  for block_size in [65535, OPTIMAL_MASTER_BLOCK] {
    let start = end - 2 * block_size - 1
    let first = next_block_target(start, end, block_size)
    let second = next_block_target(first, end, block_size)
    let last = next_block_target(second, end, block_size)
    @test.assert_eq(first, end - block_size - 1)
    @test.assert_eq(second, end - 1)
    @test.assert_eq(last, end)
    @test.assert_eq(next_block_target(last, end, block_size), end)
    @test.assert_eq(next_block_target(end - block_size, end, block_size), end)
    @test.assert_eq(
      next_block_target(0, block_size + 1, block_size),
      block_size,
    )
    @test.assert_eq(next_block_target(0, 0, block_size), 0)
  }
}

///|
test "fixed-cadence cuts are independent of the absolute input offset" {
  let tokens = [97, 98, 99]
  // The first cut is valid, but advancing to the next cadence point would
  // overflow at the high offset. The second token must not become a cut.
  let offsets : FixedArray[Int32] = [0, 65535, 65536, 65537]
  for start in [0, 2147483647 - 65537] {
    let positions = offsets.map(offset => start + offset)
    @test.assert_eq(fixed_cadence_cuts(tokens, positions, start, 65535), [1])
  }
  // A final short chunk has no cut, even when its first cadence point would
  // already lie beyond the largest representable position.
  for start in [0, 2147483647 - 3] {
    let positions : FixedArray[Int32] = [start, start + 1, start + 2, start + 3]
    @test.assert_eq(fixed_cadence_cuts(tokens, positions, start, 65535), [])
  }
}
