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
test "Adler group bound never forms an index past the end" {
  let max = 2147483647
  for
    (start, end) in [
      (0, 0),
      (0, 7),
      (0, 8),
      (5, 3800),
      (max - 7, max),
      (max - 8, max),
      (max - 3800, max),
      (max - 3807, max - 7),
    ] {
    let groups_end = adler_groups_end(start, end)
    assert_true(groups_end >= start && groups_end <= end)
    assert_true(end - groups_end < 8)
    @test.assert_eq((groups_end - start) % 8, 0)
  }
}

///|
/// The vector kernel against the serial definition, unreduced like the kernel:
/// every start and length around the chunk size, views that end exactly at
/// the end of their backing bytes, and the largest sums a block can reach.
#cfg(any(target="native", target="wasm"))
test "Adler 16-byte chunks agree with the serial sums and stay inside the view" {
  let mut state = 0x2545F491U
  let noise = Bytes::makei(4200, _ => {
    state = state * 1103515245U + 12345U
    (state >> 24).reinterpret_as_int().to_byte()
  })
  let high = Bytes::make(4200, b'\xFF')
  for input in [noise, high] {
    for seed in [(1, 0), (65520, 65520)] {
      for start in 0..<18 {
        for
          length in [
            ..Array::makei(82, i => i),
            127,
            128,
            129,
            3783,
            3784,
            3785,
            ADLER_BLOCK_SIZE,
          ] {
          let end = start + length
          // The backing bytes end where the view ends, then sixteen bytes
          // later: neither may change what the kernel folds.
          for spare in [0, 16] {
            let backing = input[:end + spare].to_owned()
            let view = backing[:end]
            let checksum = Adler32()
            checksum.a = seed.0
            checksum.b = seed.1
            let position = checksum.fold_chunks16(view, start, end)
            @test.assert_eq(position, start + length / 16 * 16)
            let mut a = seed.0
            let mut b = seed.1
            for i in start..<position {
              a = a + view[i].to_int()
              b = b + a
            }
            @test.assert_eq(checksum.a, a)
            @test.assert_eq(checksum.b, b)
          }
        }
      }
    }
  }
}
