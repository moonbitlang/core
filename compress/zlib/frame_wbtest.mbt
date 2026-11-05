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
/// The original framing: DEFLATE into its own `Bytes`, then header, payload
/// and trailer through a growing buffer. `compress` must match it byte for byte.
fn reference_compress(
  input : BytesView,
  strategy : @flate.Strategy,
  dictionary : BytesView?,
  fast_store : Bool,
) -> Bytes {
  let deflated = @flate.deflate_all(input, strategy~, dictionary?, fast_store~)
  let out = @buffer.Buffer()
  for byte in zlib_header(dictionary) {
    out.write_byte(byte)
  }
  out.write_bytes(deflated)
  out.write_uint_be(@checksum.adler32(input))
  out.to_bytes()
}

///|
fn frame_random(size : Int32) -> Bytes {
  let mut state = 0x12345678U
  Bytes::makei(size, _ => {
    state = state * 1103515245U + 12345U
    ((state >> 16) & 0xFF).reinterpret_as_int().to_byte()
  })
}

///|
fn frame_text(size : Int32) -> Bytes {
  let unit = b"The quick brown fox jumps over the lazy dog. Pack my box. "
  Bytes::makei(size, i => unit[i % unit.length()])
}

///|
test "compress output matches the original framing byte for byte" {
  let inputs : Array[(String, Bytes)] = [
    ("empty", b""),
    ("one", b"x"),
    ("small", b"hello, hello, hello zlib"),
    ("random-1MiB", frame_random(1 << 20)),
    ("text-1MiB", frame_text(1 << 20)),
    ("zeros-1MiB", Bytes::make(1 << 20, b'\x00')),
    ("mixed", frame_text(70_000) + frame_random(70_000)),
  ]
  let strategies : Array[@flate.Strategy] = [
    Standard(level=0),
    Standard(level=1),
    Standard(level=6),
    Standard(level=9),
    Split(level=6),
    Optimal(iterations=1),
  ]
  let dictionaries : Array[BytesView?] = [None, Some(b"brown fox lazy dog")]
  let summary = StringBuilder()
  for entry in inputs {
    let (name, input) = entry
    for strategy in strategies {
      // Optimal parsing is slow; its framing is the same for any size.
      guard !(strategy is Optimal(_)) || input.length() <= 200_000 else {
        continue
      }
      for dictionary in dictionaries {
        for fast_store in [false, true] {
          let actual = compress(input, strategy~, dictionary?, fast_store~)
          let expected = reference_compress(
            input, strategy, dictionary, fast_store,
          )
          guard actual == expected else {
            fail(
              "\{name} \{@debug.to_string(strategy)} dictionary=\{dictionary is Some(_)} fast_store=\{fast_store}",
            )
          }
          @test.assert_eq(decompress(actual, dictionary?), input)
        }
      }
    }
    let standard = compress(input)
    let with_dictionary = compress(input, dictionary=b"brown fox lazy dog")
    summary.write_string(
      "\{name}: \{standard.length()} \{@checksum.crc32(standard)} \{with_dictionary.length()} \{@checksum.crc32(with_dictionary)}\n",
    )
  }
  inspect(
    summary.to_string(),
    content=(
      #|empty: 8 1299389632 12 4016121087
      #|one: 9 1452107822 13 3762902827
      #|small: 21 242157642 25 1735710540
      #|random-1MiB: 1048664 1021960498 1048668 4043175161
      #|text-1MiB: 3325 1664837578 3323 2330042978
      #|zeros-1MiB: 1224 1270897055 1228 3592513591
      #|mixed: 70361 2502928430 70359 4286252242
      #|
    ),
  )
}
