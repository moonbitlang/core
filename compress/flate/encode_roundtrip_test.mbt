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

// Check encoder semantics without fixing the compressed representation.

///|
priv struct RoundtripRng {
  mut state : UInt32
}

///|
fn RoundtripRng::next(self : RoundtripRng) -> Int32 {
  self.state = self.state * 1103515245U + 12345U
  ((self.state >> 16) & 0x7FFFU).reinterpret_as_int()
}

///|
let roundtrip_words : ReadOnlyArray[String] = [
  "the", "of", "and", "a", "to", "in", "is", "you", "that", "it", "he", "was", "for",
  "on", "are", "as", "with", "his", "they", "at", "be", "this", "have", "from", "or",
  "one", "had", "by", "word", "but", "not", "what", "all", "were", "compression",
  "stream", "window", "literal", "distance", "Huffman", "block",
]

///|
/// Word salad with punctuation and line breaks.
fn roundtrip_text(size : Int32, seed : UInt32) -> Bytes {
  let rng = RoundtripRng::{ state: seed, }
  let buf = Buffer()
  while buf.length() < size {
    buf.write_string_utf8(
      roundtrip_words[rng.next() % roundtrip_words.length()],
    )
    match rng.next() % 16 {
      0 => buf.write_string_utf8(". ")
      1 => buf.write_string_utf8(",\n")
      _ => buf.write_byte(b' ')
    }
  }
  buf.to_bytes()[:size].to_owned()
}

///|
fn roundtrip_random(size : Int32, seed : UInt32) -> Bytes {
  let rng = RoundtripRng::{ state: seed, }
  Bytes::makei(size, _ => (rng.next() & 0xFF).to_byte())
}

///|
/// Text-showing operators with varying coordinates, like a PDF content stream.
fn roundtrip_content_stream(size : Int32, seed : UInt32) -> Bytes {
  let rng = RoundtripRng::{ state: seed, }
  let buf = Buffer()
  while buf.length() < size {
    let x = rng.next() % 600
    let y = rng.next() % 800
    let frac = rng.next() % 100
    buf.write_string_utf8(
      "BT\n/F\{rng.next() % 4} \{8 + rng.next() % 6} Tf\n1 0 0 -1 \{x}.\{frac} \{y} Tm\n[<",
    )
    for _ in 0..<(1 + rng.next() % 12) {
      let gid = rng.next() % 300
      for shift in [8, 4, 0] {
        let digit = (gid >> shift) & 15
        let code = if digit < 10 { 0x30 + digit } else { 0x37 + digit }
        buf.write_byte(code.to_byte())
      }
    }
    buf.write_string_utf8("> \{rng.next() % 500 - 250}] TJ\nET\n")
    if rng.next() % 5 == 0 {
      buf.write_string_utf8(
        "q\n0.\{rng.next() % 1000} 0 0 RG\n\{x} \{y} m \{x + 40} \{y} l S\nQ\n",
      )
    }
  }
  buf.to_bytes()[:size].to_owned()
}

///|
/// Big-endian 16/32-bit records with small deltas, like font tables.
fn roundtrip_binary(size : Int32, seed : UInt32) -> Bytes {
  let rng = RoundtripRng::{ state: seed, }
  let out = FixedArray::make(size, b'\x00')
  let mut value = 0
  let mut i = 0
  while i + 6 <= size {
    value = (value + rng.next() % 40) & 0xFFFF
    out[i] = (value >> 8).to_byte()
    out[i + 1] = (value & 0xFF).to_byte()
    out[i + 2] = b'\x00'
    out[i + 3] = (rng.next() % 3).to_byte()
    out[i + 4] = (rng.next() & 0xFF).to_byte()
    out[i + 5] = if rng.next() % 4 == 0 { b'\xFF' } else { b'\x00' }
    i += 6
  }
  Bytes::makei(size, i => out[i])
}

///|
/// Short periods, long single-byte runs and an exact repeat beyond 32 KiB.
fn roundtrip_repetitive(size : Int32, seed : UInt32) -> Bytes {
  let rng = RoundtripRng::{ state: seed, }
  let buf = Buffer()
  let head = roundtrip_text(40000, seed + 1)
  buf.write_bytes(head)
  while buf.length() < size {
    match rng.next() % 3 {
      0 => {
        let byte = (rng.next() & 0xFF).to_byte()
        for _ in 0..<(rng.next() % 2000) {
          buf.write_byte(byte)
        }
      }
      1 => {
        let period = 1 + rng.next() % 9
        for k in 0..<(rng.next() % 1500) {
          buf.write_byte((k % period + 0x41).to_byte())
        }
      }
      _ => {
        let start = rng.next() % 30000
        buf.write_bytes(head[start:start + 300 + rng.next() % 600].to_owned())
      }
    }
  }
  buf.write_bytes(head)
  buf.to_bytes()
}

///|
fn roundtrip_corpus() -> Array[(String, Bytes)] {
  let mixed = Buffer()
  mixed.write_bytes(roundtrip_text(30000, 7))
  mixed.write_bytes(roundtrip_random(20000, 8))
  mixed.write_bytes(roundtrip_content_stream(30000, 9))
  mixed.write_bytes(roundtrip_binary(20000, 10))
  [
    ("empty", b""),
    ("one", b"a"),
    ("three", b"abc"),
    ("five", b"aaaaa"),
    ("text-259", roundtrip_text(259, 1)),
    ("text", roundtrip_text(100000, 2)),
    ("random", roundtrip_random(40000, 3)),
    ("content", roundtrip_content_stream(120000, 4)),
    ("binary", roundtrip_binary(60000, 5)),
    ("repetitive", roundtrip_repetitive(90000, 6)),
    ("mixed", mixed.to_bytes()),
  ]
}

///|
/// Drive a streaming compressor with fixed input and output chunk sizes,
/// optionally requesting a sync flush after every input chunk.
fn roundtrip_stream(
  input : Bytes,
  level : Int32,
  in_chunk : Int32,
  out_chunk : Int32,
  sync_flush~ : Bool = false,
  dictionary? : Bytes,
) -> Bytes {
  let deflater = match dictionary {
    Some(dict) => @flate.Deflater(level~, dictionary=dict)
    None => Deflater(level~)
  }
  let out = FixedArray::make(out_chunk, b'\x00')
  let result = Buffer()
  let mut pos = 0
  for ;; {
    let end = (pos + in_chunk).min(input.length())
    let action : @flate.DeflateAction = if end == input.length() {
      Finish
    } else if sync_flush {
      SyncFlush
    } else {
      Continue
    }
    let status_result = deflater.step(input[pos:end], out.mut_view(), action~)
    let status = status_result.status
    for i in 0..<status_result.produced {
      result.write_byte(out[i])
    }
    pos += status_result.consumed
    if status is Done {
      break
    }
  }
  result.to_bytes()
}

///|
fn assert_decodes(
  compressed : Bytes,
  expected : BytesView,
  dictionary? : BytesView,
) -> Unit raise {
  let decoder = @flate.Inflater(dictionary?)
  let output = FixedArray::make(8192, b'\x00')
  let decoded = Buffer()
  let mut pos = 0
  for ;; {
    let status_result = decoder.step(compressed[pos:], output.mut_view())
    let status = status_result.status
    assert_false(status is NeedMoreInput, msg="truncated compressed output")
    pos += status_result.consumed
    for i in 0..<status_result.produced {
      decoded.write_byte(output[i])
    }
    if status is Done {
      break
    }
  }
  assert_eq(pos, compressed.length())
  assert_eq(decoded.to_bytes()[:], expected)
}

///|
test "deflate round trips: one-shot and streaming, levels 0-9" {
  for (_, data) in roundtrip_corpus() {
    for level in 0..<=9 {
      assert_decodes(@flate.deflate_all(data, level~), data)
      assert_decodes(
        roundtrip_stream(data, level, data.length() + 1, 65536),
        data,
      )
    }
  }
}

///|
test "deflate round trips: chunking, flushes and dictionaries" {
  let dictionary = roundtrip_text(40000, 11)
  for (_, data) in roundtrip_corpus() {
    for level in [1, 4, 6, 9] {
      assert_decodes(roundtrip_stream(data, level, 4093, 1021), data)
      assert_decodes(
        roundtrip_stream(data, level, 9000, 4096, sync_flush=true),
        data,
      )
    }
    assert_decodes(
      roundtrip_stream(data, 6, 5000, 777, dictionary~),
      data,
      dictionary~,
    )
  }
  let tiny = roundtrip_content_stream(5000, 12)
  assert_decodes(roundtrip_stream(tiny, 6, 1, 1), tiny)
}

///|
test "deflate round trips: whole-buffer encoders" {
  let compressor = @flate.Compressor(level=6)
  for (_, data) in roundtrip_corpus() {
    assert_decodes(compressor.compress(data), data)
    let output = FixedArray::make(@flate.deflate_bound(data.length()), b'\x00')
    let length = @flate.deflate_into(data, output, level=6).unwrap()
    assert_decodes(Bytes::makei(length, i => output[i]), data)
    for level in [1, 6, 9] {
      assert_decodes(@flate.deflate_all_split(data, level~), data)
    }
    assert_decodes(@flate.deflate_all_optimal(data, iterations=2), data)
    assert_decodes(@flate.deflate_all(data, level=6, fast_store=true), data)
  }
}

///|
test "deflate round trips: randomized streaming schedules with reuse" {
  let corpus = roundtrip_corpus()
  let source = Buffer()
  for entry in corpus {
    source.write_bytes(entry.1)
  }
  let source = source.to_bytes()
  for seed in 0..<24 {
    let rng = RoundtripRng::{
      state: seed.reinterpret_as_uint() * 2654435761U + 1,
    }
    let level = rng.next() % 10
    let fast_store = rng.next() % 4 == 0
    let deflater = @flate.Deflater(level~, fast_store~)
    for stream in 0..<3 {
      let mut dictionary : BytesView? = None
      let compressed = Buffer()
      if stream > 0 {
        if rng.next() % 2 == 0 {
          let start = rng.next() * 7 % (source.length() - 50000)
          let length = rng.next() % 3 * 17000 + rng.next() % 100
          dictionary = Some(source[start:start + length])
          deflater.reset(dictionary?)
        } else {
          deflater.reset()
        }
      }
      let start = rng.next() * 13 % (source.length() - 140000)
      let input = source[start:start + rng.next() * 5 % 140000]
      let mut pos = 0
      for ;; {
        let in_chunk = match rng.next() % 4 {
          0 => 0
          1 => rng.next() % 300
          _ => rng.next() % 30000
        }
        let end = (pos + in_chunk).min(input.length())
        let action : @flate.DeflateAction = if end == input.length() {
          Finish
        } else if rng.next() % 6 == 0 {
          SyncFlush
        } else {
          Continue
        }
        let out = FixedArray::make(
          if rng.next() % 8 == 0 {
            0
          } else {
            1 + rng.next() % 9000
          },
          b'\x00',
        )
        let status_result = deflater.step(
          input[pos:end],
          out.mut_view(),
          action~,
        )
        let status = status_result.status
        for i in 0..<status_result.produced {
          compressed.write_byte(out[i])
        }
        pos += status_result.consumed
        if status is Done {
          break
        }
      }
      assert_decodes(compressed.to_bytes(), input, dictionary?)
    }
  }
}
