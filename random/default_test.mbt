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
test "int32 without a bound returns non-negative integers" {
  for _ in 0..<100 {
    assert_true(@random.int32() >= 0)
  }
}

///|
test "int32 respects exclusive bounds" {
  inspect(@random.int32(limit=1), content="0")
  for limit in [2, 3, 16, 17, 0x40000001, 0x7fffffff] {
    for _ in 0..<100 {
      let value = @random.int32(limit~)
      assert_true(value >= 0 && value < limit)
    }
  }
}

///|
test "panic int32 rejects a negative limit" {
  ignore(@random.int32(limit=-1))
}

///|
test "panic int32 rejects a zero limit" {
  ignore(@random.int32(limit=0))
}

///|
test "int64 respects exclusive bounds" {
  inspect(@random.int64(limit=1L), content="0")
  for limit in [2L, 3L, 16L, 17L, 0x4000000000000001L, 0x7fffffffffffffffL] {
    for _ in 0..<100 {
      let value = @random.int64(limit~)
      assert_true(value >= 0L && value < limit)
    }
  }
}

///|
test "panic int64 rejects a zero limit" {
  ignore(@random.int64(limit=0L))
}

///|
test "panic int64 rejects a negative limit" {
  ignore(@random.int64(limit=-1L))
}

///|
test "uint32 respects exclusive bounds" {
  inspect(@random.uint32(limit=1U), content="0")
  for limit in [2U, 3U, 16U, 17U, 0x80000001U, 0xffffffffU] {
    for _ in 0..<100 {
      let value = @random.uint32(limit~)
      assert_true(value < limit)
    }
  }
}

///|
test "panic uint32 rejects a zero limit" {
  ignore(@random.uint32(limit=0U))
}

///|
test "uint64 respects exclusive bounds" {
  inspect(@random.uint64(limit=1UL), content="0")
  for
    limit in [2UL, 3UL, 16UL, 17UL, 0x8000000000000001UL, 0xffffffffffffffffUL] {
    for _ in 0..<100 {
      let value = @random.uint64(limit~)
      assert_true(value < limit)
    }
  }
}

///|
test "panic uint64 rejects a zero limit" {
  ignore(@random.uint64(limit=0UL))
}

///|
test "unbounded integer functions" {
  for _ in 0..<100 {
    assert_true(@random.int64() >= 0L)
    let _ : UInt32 = @random.uint32()
    let _ : UInt64 = @random.uint64()
  }
}

///|
test "floating point default and optional bounds" {
  for _ in 0..<100 {
    let d = @random.double()
    assert_true(d >= 0.0 && d < 1.0)
    let d = @random.double(min=-2.0)
    assert_true(d >= -2.0 && d < 1.0)
    let d = @random.double(max=3.0)
    assert_true(d >= 0.0 && d < 3.0)
    let d = @random.double(min=2.0, max=3.0)
    assert_true(d >= 2.0 && d < 3.0)
    let f = @random.float()
    assert_true(f >= 0.0F && f < 1.0F)
    let f = @random.float(min=-2.0F)
    assert_true(f >= -2.0F && f < 1.0F)
    let f = @random.float(max=3.0F)
    assert_true(f >= 0.0F && f < 3.0F)
    let f = @random.float(min=2.0F, max=3.0F)
    assert_true(f >= 2.0F && f < 3.0F)
  }
}

///|
test "panic double rejects an empty range" {
  ignore(@random.double(min=1.0, max=1.0))
}

///|
test "panic float rejects an inverted range" {
  ignore(@random.float(min=2.0F, max=1.0F))
}

///|
test "bigint respects bit counts" {
  inspect(@random.bigint(0), content="0")
  for bits in [1, 7, 8, 9, 31, 32, 63, 64, 65, 128] {
    for _ in 0..<10 {
      let value = @random.bigint(bits)
      assert_true(value >= 0N && value.bit_length() <= bits)
    }
  }
}

///|
test "panic bigint rejects negative bits" {
  ignore(@random.bigint(-1))
}

///|
test "shuffle skips callbacks for zero and one elements" {
  @random.shuffle(0, (_, _) => abort("unexpected swap"))
  @random.shuffle(1, (_, _) => abort("unexpected swap"))
}

///|
test "shuffle preserves elements and supports random calls in callbacks" {
  let values = [1, 2, 3, 4, 5]
  let mut swaps = 0
  @random.shuffle(values.length(), (i, j) => {
    guard i >= 0 && i < values.length() else { abort("invalid first index") }
    guard j >= 0 && j < values.length() else { abort("invalid second index") }
    let tmp = values[i]
    values[i] = values[j]
    values[j] = tmp
    swaps += 1
    ignore(@random.boolean())
    ignore(@random.uint64())
  })
  inspect(swaps, content="4")
  values.sort()
  debug_inspect(values, content="[1, 2, 3, 4, 5]")
}

///|
test "panic shuffle rejects negative length" {
  @random.shuffle(-1, (_, _) => ())
}
