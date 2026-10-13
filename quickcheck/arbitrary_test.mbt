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
priv struct H {
  x : Int32
  y : Int32
} derive(@quickcheck.Arbitrary, Debug)

///|
fn[T : @quickcheck.Arbitrary] scalar_samples_at_zero(
  seeds : Array[UInt64],
) -> Array[T] {
  seeds.map(seed => @quickcheck.Arbitrary::arbitrary(0, RandomState(seed~)))
}

///|
test "fixed-width integer Arbitrary exercises its bug-finding portfolio at size zero" {
  // Seeds select, in order: full-width, canonical, binary boundary,
  // decimal boundary, and type-extreme generation.
  let seeds = [1UL, 3UL, 2UL, 6UL, 8UL]
  let int16s : Array[Int16] = scalar_samples_at_zero(seeds)
  let uint16s : Array[UInt16] = scalar_samples_at_zero(seeds)
  let ints : Array[Int32] = scalar_samples_at_zero(seeds)
  let uints : Array[UInt32] = scalar_samples_at_zero(seeds)
  let int64s : Array[Int64] = scalar_samples_at_zero(seeds)
  let uint64s : Array[UInt64] = scalar_samples_at_zero(seeds)
  debug_inspect(
    int16s,
    content=(
      #|[-17438, 1, 1023, -1000, 32766]
    ),
  )
  debug_inspect(
    uint16s,
    content=(
      #|[48098, 1, 1023, 1000, 65533]
    ),
  )
  debug_inspect(
    ints,
    content=(
      #|[316390370, 1, 67108863, -1000, 2147483646]
    ),
  )
  debug_inspect(
    uints,
    content=(
      #|[316390370, 1, 67108863, 1000, 4294967293]
    ),
  )
  debug_inspect(
    int64s,
    content=(
      #|[8873074891056462818, 1, 67108863, -1000, 9223372036854775806]
    ),
  )
  debug_inspect(
    uint64s,
    content=(
      #|[
      #|  8873074891056462818,
      #|  1,
      #|  67108863,
      #|  10000000000000000000,
      #|  18446744073709551613,
      #|]
    ),
  )
}

///|
test "Byte Arbitrary draws raw random bits" {
  let seeds = [1UL, 0UL, 22UL, 6UL, 7UL]
  let bytes : Array[Byte] = scalar_samples_at_zero(seeds)
  debug_inspect(
    bytes,
    content=(
      #|[0xf5, 0xd8, 0xb6, 0x58, 0xc3]
    ),
  )
}

///|
test {
  let state = (Default::default() : @splitmix.RandomState)
  let size = 10
  let v : H = @quickcheck.gen(state~, size~)
  debug_inspect(
    v,
    content=(
      #|{ x: -1757125880, y: -2 }
    ),
  )
  let state = state.split()
  let v : H = @quickcheck.gen(state~, size~)
  debug_inspect(
    v,
    content=(
      #|{ x: 1745005340, y: -1330484014 }
    ),
  )
  let state = state.split()
  let v : H = @quickcheck.gen(state~, size~)
  debug_inspect(
    v,
    content=(
      #|{ x: -480557882, y: 0 }
    ),
  )
}

///|
test "gen with only size" {
  // Call gen with only size parameter to trigger default state line 
  let x : Bool = @quickcheck.gen(size=1)
  inspect(x, content="true")
}

///|
test "gen with default parameters" {
  // Call gen with no parameters, both size and state will be None.
  // Use Bool as the arbitrary type since it's simple.
  // Outputs will be random, but we don't care about the actual value,
  // we only need to trigger those lines.
  let x : Bool = @quickcheck.gen()
  inspect(x, content="true")
}

///|
test "iter arbitrary" {
  let samples : Array[Iter[Int32]] = @quickcheck.samples(20)
  debug_inspect(
    samples[9].to_array(),
    content=(
      #|[90462686, 33554432, 2147483646, 63, 71960070, -1045010830, 2]
    ),
  )
  debug_inspect(
    samples[1:5].map(iter => iter.to_array()),
    content=(
      #|[[], [], [], []]
    ),
  )
  debug_inspect(
    samples[10].to_array(),
    content=(
      #|[2, 4194303, -1710626808, 917696847]
    ),
  )
}

///|
test "arbitrary unit" {
  // generate a random Unit value using the `gen` function
  let generated : Unit = @quickcheck.gen()
  // Unit has only one value, so it must be equal to ()
  inspect(generated, content="()")
}

///|
test "arbitrary float" {
  let state = @splitmix.RandomState()
  let f1 : Float = @quickcheck.gen(size=42, state~)
  let f2 : Float = @quickcheck.gen(size=42, state~)
  // These two random floats should be different
  inspect(f1 != f2, content="true")
}

///|
test "arbitrary_iter_break" {
  let rs = (Default::default() : @splitmix.RandomState)
  let iter : Iter[Int32] = @quickcheck.gen(size=4, state=rs)
  // An Iter with a length greater than 0 is required here
  let mut i = 0
  for _ in iter {
    i += 1
    break
  } nobreak {
    panic()
  }
  inspect(i, content="1")
}

///|
test "arbitrary gen bytes" {
  let rs = (Default::default() : @splitmix.RandomState).split().split()
  let bytes : Bytes = @quickcheck.gen(size=10, state=rs)
  // Check that the length of the generated bytes is within the expected range
  inspect(
    bytes,
    content=(
      #|b"T\xea\x7fM\xe9"
    ),
  )
}

///|
test "arbitrary size branches" {
  let rs1 = (Default::default() : @splitmix.RandomState)
  let _ : Int64 = @quickcheck.Arbitrary::arbitrary(4, rs1)
  let rs2 = (Default::default() : @splitmix.RandomState)
  let _ : UInt64 = @quickcheck.Arbitrary::arbitrary(4, rs2)
  let rs3 = (Default::default() : @splitmix.RandomState)
  let result : Result[Int32, Int32] = for
    _ in 0..<64
    result = (Ok(0) : Result[Int32, Int32]) {
    let result = @quickcheck.Arbitrary::arbitrary(1, rs3)
    if result is Err(_) {
      break result
    }
    continue result
  } nobreak {
    result
  }
  guard result is Err(_) else { fail("expected Err from Result arbitrary") }
  let rs4 = (Default::default() : @splitmix.RandomState)
  let _ : FixedArray[Int32] = @quickcheck.Arbitrary::arbitrary(3, rs4)
}
