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
test "Strategy constructors preserve defaults and explicit tuning" {
  @debug.debug_inspect(@flate.Strategy::split(), content="Split(level=6)")
  @debug.debug_inspect(
    @flate.Strategy::split(level=0),
    content="Split(level=0)",
  )
  @debug.debug_inspect(
    @flate.Strategy::optimal(),
    content="Optimal(iterations=15)",
  )
  @debug.debug_inspect(
    @flate.Strategy::optimal(iterations=2),
    content="Optimal(iterations=2)",
  )
  @debug.debug_inspect(@gzip.Strategy::split(), content="Split(level=6)")
  @debug.debug_inspect(
    @gzip.Strategy::optimal(),
    content="Optimal(iterations=15)",
  )
  @debug.debug_inspect(@zlib.Strategy::split(), content="Split(level=6)")
  @debug.debug_inspect(
    @zlib.Strategy::optimal(),
    content="Optimal(iterations=15)",
  )
  let input = b"default strategy default strategy"
  for strategy in [@flate.Strategy::split(), @flate.Strategy::optimal()] {
    assert_eq(@flate.inflate(@flate.deflate_all(input, strategy~)).data, input)
    assert_eq(@gzip.decompress(@gzip.compress(input, strategy~)), input)
    assert_eq(@zlib.decompress(@zlib.compress(input, strategy~)), input)
  }
}

///|
/// Compare round-trip output and encoded size on repeated text containing
/// the lazy-matching pattern "abcde abcdef".
test "Optimal strategy round-trips and beats greedy" {
  let unit = b"optimal parsing pays where greedy grabs too early: abcde abcdef. "
  let arr : Array[Byte] = []
  for _r in 0..<120 {
    for b in unit {
      arr.push(b)
    }
  }
  let src = Bytes::from_array(arr)
  let opt = @flate.deflate_all(src, strategy=Optimal(iterations=8))
  @test.assert_eq(@flate.inflate(opt, mode=Prefix).data, src)
  assert_true(opt.length() <= @flate.deflate_all(src).length())
}

///|
/// On this mixed text and pseudo-random input, compare the optimal output
/// with level 9, allowing 16 bytes of additional output.
test "Optimal strategy splits heterogeneous data" {
  let arr : Array[Byte] = []
  let text = b"a stretch of plain compressible text, over and over again. "
  for _r in 0..<80 {
    for b in text {
      arr.push(b)
    }
  }
  let mut x = 0xDEADBEEFU
  for _i in 0..<4800 {
    x = x ^ (x << 13)
    x = x ^ (x >> 17)
    x = x ^ (x << 5)
    arr.push((x & 0xFF).reinterpret_as_int().to_byte())
  }
  let src = Bytes::from_array(arr)
  let opt = @flate.deflate_all(src, strategy=Optimal(iterations=5))
  @test.assert_eq(@flate.inflate(opt, mode=Prefix).data, src)
  assert_true(
    opt.length() <=
    @flate.deflate_all(src, strategy=Standard(level=9)).length() + 16,
  )
}
