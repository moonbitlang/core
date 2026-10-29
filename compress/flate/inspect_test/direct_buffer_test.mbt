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
test "direct stored blocks preserve boundaries and handle partial output" {
  let compressor = @flate.Compressor(strategy=Standard(level=0))
  for size in [0, 1, 65534, 65535, 65536, 131070, 131071] {
    let source = Bytes::from_array(
      Array::makei(size, i => (i * 73 + i / 19).to_byte()),
    )
    let expected = @flate.deflate_all(source, strategy=Standard(level=0))
    for capacity in [0, 1, 4, 5, expected.length() - 1] {
      if capacity < expected.length() {
        @test.assert_eq(
          compressor.compress_into(
            source,
            FixedArray::make(capacity, b'\x00').mut_view(),
          ),
          None,
        )
      }
    }
    // Reuse after exhaustion, with both exact capacity and trailing canaries.
    for extra in [0, 13] {
      let output = FixedArray::make(expected.length() + extra, b'\xA5')
      @test.assert_eq(
        compressor.compress_into(source, output.mut_view()),
        Some(expected.length()),
      )
      @test.assert_eq(direct_bytes(output, expected.length()), expected)
      for i in expected.length()..<output.length() {
        @test.assert_eq(output[i], b'\xA5')
      }
    }
  }
}

///|
fn direct_bytes(buffer : FixedArray[Byte], length : Int32) -> Bytes {
  Bytes::from_array(buffer[:length])
}

///|
fn direct_sources() -> Array[Bytes] {
  let varied = Array::make(40000, b'\x00')
  for i in 0..<varied.length() {
    varied[i] = (i * 73 + i / 19).to_byte()
  }
  [
    b"",
    b"caller-owned raw DEFLATE output",
    Bytes::from_array(Array::make(20000, b'R')),
    Bytes::from_array(varied),
  ]
}

///|
test "caller-buffer codecs match one-shot streams and reuse workspace" {
  let strategies : Array[@flate.Strategy] = [
    Standard(level=0),
    Standard(level=1),
    Standard(level=6),
    Standard(level=9),
    Split(level=1),
    Split(level=9),
    Optimal(iterations=1),
  ]
  for strategy in strategies {
    let compressor = @flate.Compressor(strategy~)
    let decompressor = @flate.Decompressor()
    for source in direct_sources() {
      let capacity = @flate.deflate_bound(source.length(), strategy~)
      let storage = Array::make(capacity + 14, b'\xA5')
      let output = storage.mut_view(start=7, end=7 + capacity)
      let length = compressor.compress_into(source, output).unwrap()
      let compressed = Bytes::from_array(output[:length])
      @test.assert_eq(compressed, @flate.deflate_all(source, strategy~))
      @test.assert_eq(
        compressor.compress_into(source, output.mut_view(end=length - 1)),
        None,
      )
      @test.assert_eq(compressor.compress(source), compressed)
      @test.assert_eq(
        @flate.deflate_into(source, output, strategy~),
        Some(length),
      )
      @test.assert_eq(Bytes::from_array(output[:length]), compressed)
      @test.assert_eq(Bytes::from_array(storage[:7]), Bytes::make(7, b'\xA5'))
      @test.assert_eq(
        Bytes::from_array(storage[7 + capacity:]),
        Bytes::make(7, b'\xA5'),
      )

      let decoded_storage = FixedArray::make(source.length() + 18, b'\xA5')
      let decoded_output = decoded_storage.mut_view(
        start=9,
        end=9 + source.length(),
      )
      let decoded = decompressor.decompress_into(compressed, decoded_output)
      @test.assert_eq(decoded.consumed, compressed.length())
      @test.assert_eq(decoded.produced, source.length())
      @test.assert_eq(Bytes::from_array(decoded_output), source)
      @test.assert_eq(
        Bytes::from_array(decoded_storage[:9]),
        Bytes::make(9, b'\xA5'),
      )
      @test.assert_eq(
        Bytes::from_array(decoded_storage[9 + source.length():]),
        Bytes::make(9, b'\xA5'),
      )
    }
  }
}
