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
fn range(lo : Int32, hi : Int32) -> @shared_types.ByteSet {
  @shared_types.ByteSet::char_range(lo, hi)
}

///|
test "no split points: everything is one symbol" {
  let (table, repr) = @symbol_map.new().finalize()
  assert_true(repr == [0])
  for c in [0, 1, 127, 128, 255] {
    assert_true(table.map(c.to_byte()) == 0)
  }
}

///|
test "symbols are numbered by ascending run and mapped at every boundary" {
  let m = @symbol_map.new()
  m.split(range('a', 'z'))
  m.split(range(0xF0, 0xFF))
  let (table, repr) = m.finalize()
  assert_true(repr == [0, 'a'.to_int(), 'z'.to_int() + 1, 0xF0])
  let expect = [
    (0, 0),
    (96, 0),
    (97, 1),
    (122, 1),
    (123, 2),
    (0xEF, 2),
    (0xF0, 3),
    (0xFF, 3),
  ]
  for e in expect {
    let (c, symbol) = e
    assert_true(table.map(c.to_byte()) == symbol)
  }
  // map_set maps runs of bytes to runs of symbols
  assert_true(
    table.map_set(range('b', 'y') + range(0xF1, 0xF2)).intervals().to_array() ==
    [(1, 1), (3, 3)],
  )
}

///|
test "overlapping splits make one symbol per distinct class" {
  let m = @symbol_map.new()
  m.split(range('a', 'f'))
  m.split(range('d', 'z'))
  m.split(range(0, 0))
  let (table, repr) = m.finalize()
  assert_true(
    repr == [0, 1, 'a'.to_int(), 'd'.to_int(), 'g'.to_int(), 'z'.to_int() + 1],
  )
  assert_true(table.map(b'e') == table.map(b'd'))
  assert_true(table.map(b'g') != table.map(b'f'))
  assert_true(table.map(b'\xff') == table.map(b'{'))
}
