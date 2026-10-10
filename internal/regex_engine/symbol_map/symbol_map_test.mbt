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
fn range(lo : Int, hi : Int) -> @rechar_set.RecharSet {
  @rechar_set.RecharSet::char_range(lo, hi)
}

///|
test "no split points: everything is one symbol" {
  let (table, repr) = @symbol_map.new().finalize(0, 0xFFFF)
  assert_true(repr == [0])
  for c in [0, 1, 127, 128, 255, 256, 0x4E00, 0xFFFF] {
    assert_true(table.map(c) == 0)
  }
}

///|
test "symbols are numbered by ascending run and mapped at every boundary" {
  let m = @symbol_map.new()
  m.split(range('a', 'z'))
  m.split(range(0x4E00, 0x4E01))
  let (table, repr) = m.finalize(0, 0xFFFF)
  assert_true(repr == [0, 'a'.to_int(), 'z'.to_int() + 1, 0x4E00, 0x4E02])
  let expect = [
    (0, 0),
    (96, 0),
    (97, 1),
    (122, 1),
    (123, 2),
    (255, 2),
    (256, 2),
    (0x4DFF, 2),
    (0x4E00, 3),
    (0x4E01, 3),
    (0x4E02, 4),
    (0xFFFF, 4),
  ]
  for e in expect {
    let (c, symbol) = e
    assert_true(table.map(c) == symbol)
  }
  // map_set maps interval boundaries through the same table
  assert_true(
    table
    .map_set(range('b', 'y') + range(0x4E01, 0x9000))
    .intervals()
    .to_array() ==
    [(1, 1), (3, 4)],
  )
}

///|
test "a block split in the middle is materialized, others share a block" {
  let m = @symbol_map.new()
  m.split(range(0x0300, 0x0305))
  let (table, repr) = m.finalize(0, 0xFFFF)
  assert_true(repr == [0, 0x0300, 0x0306])
  assert_true(table.map(0x02FF) == 0)
  assert_true(table.map(0x0300) == 1)
  assert_true(table.map(0x0305) == 1)
  assert_true(table.map(0x0306) == 2)
  assert_true(table.map(0x03FF) == 2)
  assert_true(table.map(0x0400) == 2)
  assert_true(table.map(0xFFFF) == 2)
}

///|
test "byte-sized domain and upper bounds that do not end on a block boundary" {
  let m = @symbol_map.new()
  m.split(range(128, 255))
  let (table, repr) = m.finalize(0, 255)
  assert_true(repr == [0, 128])
  assert_true(table.map(127) == 0)
  assert_true(table.map(128) == 1)
  assert_true(table.map(255) == 1)
  let m2 = @symbol_map.new()
  m2.split(range(0x10FFFF, 0x10FFFF))
  let (table2, repr2) = m2.finalize(0, 0x10FFFF)
  assert_true(repr2 == [0, 0x10FFFF])
  assert_true(table2.map(0x10FFFE) == 0)
  assert_true(table2.map(0x10FFFF) == 1)
  // a lower bound above zero only affects the representative
  let (_, repr3) = @symbol_map.new().finalize(32, 255)
  assert_true(repr3 == [32])
}

///|
test "panic mapping above the upper bound" {
  let (table, _) = @symbol_map.new().finalize(0, 0xFFFF)
  table.map(0x10000) |> ignore
}

///|
test "upper bounds inside a block are enforced exactly" {
  // uniform last block, ub in the middle of it
  let (t1, _) = @symbol_map.new().finalize(0, 300)
  assert_true(t1.map(300) == 0)
  // materialized last block, ub in the middle of it
  let m = @symbol_map.new()
  m.split(range(0x0300, 0x0301))
  let (t2, repr) = m.finalize(0, 0x0302)
  assert_true(repr == [0, 0x0300, 0x0302])
  assert_true(t2.map(0x02FF) == 0)
  assert_true(t2.map(0x0301) == 1)
  assert_true(t2.map(0x0302) == 2)
  // ub below the Latin-1 fast path
  let (t3, _) = @symbol_map.new().finalize(0, 200)
  assert_true(t3.map(200) == 0)
}

///|
test "panic above a uniform last block's upper bound" {
  let (table, _) = @symbol_map.new().finalize(0, 300)
  table.map(301) |> ignore
}

///|
test "panic above a materialized last block's upper bound" {
  let m = @symbol_map.new()
  m.split(range(0x0300, 0x0301))
  let (table, _) = m.finalize(0, 0x0302)
  table.map(0x0303) |> ignore
}

///|
test "panic above an upper bound below the fast path" {
  let (table, _) = @symbol_map.new().finalize(0, 200)
  table.map(201) |> ignore
}
