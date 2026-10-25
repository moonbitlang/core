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

// Property-based tests for the core DEFLATE engine, driven by
// `moonbitlang/core/quickcheck`.
//
// Every property has a fixed `seed` so a failure is exactly reproducible, and
// uses `max_size` schedules that push past the engine's internal boundaries
// (258-byte match cap, 16 KiB block, 32 KiB window) as well as the ordinary
// literal/stored/dynamic block mix.

///|
priv struct Compressible(Bytes) derive(@debug.Debug)

///|
fn prop_text_byte(rs : @quickcheck.RandomState) -> Byte {
  let text = b"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 the quick brown fox jumps over lazy dog. "
  text[rs.next_positive_int() % text.length()]
}

///|
impl @quickcheck.Arbitrary for Compressible with fn arbitrary(size, rs) {
  let b = @buffer.Buffer()
  let target = match rs.next_uint() % 3 {
    0 => size
    1 => size / 2
    _ => if size == 0 { 0 } else { rs.next_positive_int() % size }
  }
  let mut remaining = target
  while remaining > 0 {
    let style = rs.next_uint() % 6
    match style {
      0 => {
        let n = (1 + rs.next_positive_int() % 64).min(remaining)
        for _ in 0..<n {
          b.write_byte(prop_text_byte(rs))
        }
        remaining = remaining - n
      }
      1 => {
        let n = (1 + rs.next_positive_int() % 300).min(remaining)
        let byte = prop_text_byte(rs)
        for _ in 0..<n {
          b.write_byte(byte)
        }
        remaining = remaining - n
      }
      2 => {
        let plen = (1 + rs.next_positive_int() % 24).min(remaining)
        let pat = Array::make(plen, b'\x00')
        for i in 0..<plen {
          pat[i] = prop_text_byte(rs)
        }
        let reps = if remaining / plen > 0 {
          (1 + rs.next_positive_int() % (remaining / plen + 1)).min(
            remaining / plen,
          )
        } else {
          0
        }
        for _ in 0..<reps {
          for p in pat {
            b.write_byte(p)
          }
          remaining = remaining - plen
        }
      }
      3 => {
        let byte = prop_text_byte(rs)
        for _ in 0..<remaining {
          b.write_byte(byte)
        }
        remaining = 0
      }
      4 =>
        if remaining >= 258 {
          let pat = Array::make(258, b'\x00')
          for i in 0..<258 {
            pat[i] = prop_text_byte(rs)
          }
          let reps = remaining / 258
          for _ in 0..<reps {
            for p in pat {
              b.write_byte(p)
            }
          }
          remaining = remaining % 258
        } else {
          let byte = prop_text_byte(rs)
          for _ in 0..<remaining {
            b.write_byte(byte)
          }
          remaining = 0
        }
      _ => {
        let n = (1 + rs.next_positive_int() % 64).min(remaining)
        for _ in 0..<n {
          b.write_byte(rs.next_positive_int().to_byte())
        }
        remaining = remaining - n
      }
    }
  }
  Compressible(b.to_bytes())
}

///|
impl @quickcheck.Shrink for Compressible with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0).map(b => Compressible(b))
}

// ---------------------------------------------------------------------------
// Properties
// ---------------------------------------------------------------------------

///|
/// Property: the optimal (zopfli-style) and content-splitting parsers both
/// round-trip structured compressible input.
test "property: optimal and split parsers round-trip" {
  @quickcheck.check(
    (input : Compressible) => {
      let data = input.0
      if @flate.inflate_all(@flate.deflate_all_optimal(data, iterations=4)) !=
        data {
        return false
      }
      if @flate.inflate_all(@flate.deflate_all_split(data)) != data {
        return false
      }
      true
    },
    count=40,
    max_size=2000,
    max_shrinks=200,
    seed=0xA11CE002,
  )
}

///|
/// Property: compressible data round-trips at several levels, with sizes
/// growing past the 258-byte match cap, the 16 KiB block size, and the 32 KiB
/// sliding-window limit.
test "property: compressible data round-trips across boundaries" {
  @quickcheck.check(
    (data : Compressible) => {
      let source = data.0
      let levels = [0, 1, 6, 9]
      for level in levels {
        if @flate.inflate_all(@flate.deflate_all(source, level~)) != source {
          return false
        }
      }
      true
    },
    count=40,
    max_size=40000,
    max_shrinks=200,
    seed=0xA11CE003,
  )
}
