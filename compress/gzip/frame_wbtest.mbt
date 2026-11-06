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
  fast_store : Bool,
) -> Bytes {
  let deflated = @flate.deflate_all(input, strategy~, fast_store~)
  let out = @buffer.Buffer()
  out.write_bytes(b"\x1f\x8b\x08\x00\x00\x00\x00\x00\x00\xff")
  out.write_bytes(deflated)
  out.write_uint_le(@checksum.crc32(input))
  out.write_uint_le(input.length().reinterpret_as_uint())
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
    ("small", b"hello, hello, hello gzip"),
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
  let summary = StringBuilder()
  for entry in inputs {
    let (name, input) = entry
    for strategy in strategies {
      // Optimal parsing is slow; its framing is the same for any size.
      guard !(strategy is Optimal(_)) || input.length() <= 200_000 else {
        continue
      }
      for fast_store in [false, true] {
        let actual = compress(input, strategy~, fast_store~)
        let expected = reference_compress(input, strategy, fast_store)
        guard actual == expected else {
          fail("\{name} \{@debug.to_string(strategy)} fast_store=\{fast_store}")
        }
        // The fallback for inputs too large to reserve a bound for.
        let fallback = gzip_frame(input, strategy, fast_store, reserve_limit=-1)
        guard fallback == expected else {
          fail("fallback \{name} \{@debug.to_string(strategy)}")
        }
        @test.assert_eq(decompress(actual), input)
      }
    }
    let standard = compress(input)
    summary.write_string(
      "\{name}: \{standard.length()} \{@checksum.crc32(standard)}\n",
    )
  }
  inspect(
    summary.to_string(),
    content=(
      #|empty: 20 1161266512
      #|one: 21 2189303710
      #|small: 33 1848395263
      #|random-1MiB: 1048676 3508178333
      #|text-1MiB: 3337 3880519454
      #|zeros-1MiB: 1236 23431936
      #|mixed: 70373 4052051841
      #|
    ),
  )
}
