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
test "stored bound equals encoded size at block boundaries" {
  for strategy in [Standard(level=0), Split(level=0)] {
    for size in [0, 1, 2, 65534, 65535, 65536, 131069, 131070, 131071, 262144] {
      let backing = Bytes::makei(size + 5, i => (i % 251).to_byte())
      let source = backing[3:3 + size]
      let capacity = deflate_bound(size, strategy~)
      for dictionary in [None, Some(b"preset dictionary"[:])] {
        for fast_store in [false, true] {
          let codec = Compressor(strategy~, dictionary?, fast_store~)
          let encoded = codec.compress(source)
          @test.assert_eq(capacity, encoded.length())
          let storage = FixedArray::make(capacity + 6, b'\xA5')
          let output = storage.mut_view(start=3, end=3 + capacity)
          @test.assert_eq(codec.compress_into(source, output), Some(capacity))
          @test.assert_eq(Bytes::from_array(storage[3:3 + capacity]), encoded)
          @test.assert_eq(storage[2], b'\xA5')
          @test.assert_eq(storage[3 + capacity], b'\xA5')
          @test.assert_eq(
            codec.compress_into(
              source,
              storage.mut_view(start=3, end=2 + capacity),
            ),
            None,
          )
        }
      }
    }
  }
}

///|
test "stored bound remains representable at the final Int32 capacity" {
  for strategy in [Standard(level=0), Split(level=0)] {
    @test.assert_eq(deflate_bound(2147319812, strategy~), 2147483647)
  }
}

///|
fn materialize_stored_bound(input : BytesView, capacity : Int32) -> Bytes {
  let storage = FixedArray::make(capacity, b'\x00')
  let codec = Compressor(strategy=Standard(level=0))
  guard codec.compress_into(input, storage.mut_view()) is Some(produced) else {
    abort("stored output does not fit its bound")
  }
  Bytes::from_array(storage[:produced])
}

///|
test "bench materializing stored output" (b : @bench.T) {
  for size in [0, 1024, 262144, 1048576] {
    let input = Bytes::makei(size, i => (i % 251).to_byte())
    let blocks = ((size + 65534) / 65535).min(size).max(1)
    let previous = size + 5 * (size / 65535 + blocks) + blocks + 1
    let exact = deflate_bound(size, strategy=Standard(level=0))
    b.bench(name="stored \{size} previous bound", count=7, () => {
      b.keep(materialize_stored_bound(input, previous))
    })
    b.bench(name="stored \{size} exact bound", count=7, () => {
      b.keep(materialize_stored_bound(input, exact))
    })
  }
}
