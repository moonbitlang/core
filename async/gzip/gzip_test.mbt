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
#cfg(any(target="native", target="wasm"))
async fn node_gzip(mode : String, input : Bytes) -> Bytes {
  let mut result = b""
  @async.with_task_group() <| group => {
    let node_proc = @process.spawn(
      group,
      "node",
      ["async/gzip/node_gzip.js", mode],
      stdin=FeedFromParent,
      stdout=Collect,
      stderr=Collect,
    )
    group.spawn_bg() <| () => {
      defer node_proc.stdin.close()
      node_proc.stdin.write(input)
    }
    let stdout = group.spawn() <| () => {
      defer node_proc.stdout.close()
      node_proc.stdout.read_all()
    }
    let stderr = group.spawn() <| () => {
      defer node_proc.stderr.close()
      node_proc.stderr.read_all()
    }
    assert_eq(node_proc.wait(), 0)
    assert_eq(stderr.wait().length(), 0)
    result = stdout.wait()
  }
  result
}

///|
#cfg(any(target="native", target="wasm"))
async fn encode_with_moonbit(input : Bytes) -> Bytes {
  let (r, w) = @io.pipe()
  let mut result = b""
  @async.with_task_group() <| group => {
    group.spawn_bg() <| () => {
      defer w.close()
      @gzip.Encoder(w)..write(input).end()
    }
    defer r.close()
    result = r.read_all()
  }
  result
}

///|
#cfg(any(target="native", target="wasm"))
async fn decode_with_moonbit(input : Bytes) -> Bytes {
  let (r, w) = @io.pipe()
  let mut result = b""
  @async.with_task_group() <| group => {
    group.spawn_bg() <| () => {
      defer w.close()
      w.write(input)
    }
    defer r.close()
    result = @gzip.Decoder(r).read_all()
  }
  result
}

///|
#cfg(any(target="native", target="wasm"))
async fn assert_node_compatibility(input : Bytes) -> Unit {
  let node_encoded = node_gzip("compress", input)
  assert_true(decode_with_moonbit(node_encoded) == input)

  let moonbit_encoded = encode_with_moonbit(input)
  assert_true(node_gzip("decompress", moonbit_encoded) == input)
}

///|
async test "encode decode roundtrip" {
  @async.with_task_group() <| root => {
    let source_chunks = [b"hello ", b"gzip ", b"world"]
    let (compressed_r, compressed_w) = @io.pipe()
    root.spawn_bg() <| () => {
      defer compressed_w.close()
      let encoder = @gzip.Encoder(
        compressed_w,
        mtime=123456789U,
        operating_system=b'\x03',
      )
      for chunk in source_chunks {
        encoder.write(chunk)
        @async.sleep(10)
      }
      encoder.end()
    }

    let decoder = @gzip.Decoder(compressed_r)
    inspect(@utf8.decode(decoder.read_all()), content="hello gzip world")
    compressed_r.close()
  }
}

///|
async test "encoder uses valid blocks across large writes" {
  @async.with_task_group() <| root => {
    let payload = Bytes::makei(70000, i => (i % 251).to_byte())
    let (compressed_r, compressed_w) = @io.pipe()
    root.spawn_bg() <| () => {
      defer compressed_w.close()
      let encoder = @gzip.Encoder(compressed_w)
      encoder.write(payload)
      encoder.end()
    }

    let decoder = @gzip.Decoder(compressed_r)
    inspect(decoder.read_all() == payload, content="true")
    compressed_r.close()
  }
}

///|
async test "encoder emits output when flushed" {
  let log : Array[String] = []
  @async.with_task_group() <| root => {
    let (r, w) = @io.pipe()
    root.spawn_bg() <| () => {
      defer w.close()
      log.push("start init")
      let encoder = @gzip.Encoder(w)
      log.push("encoder ready")
      log.push("write plain ab")
      encoder.write(b"ab")
      encoder.flush()
      @async.sleep(60)
      log.push("write plain cd")
      encoder.write(b"cd")
      encoder.flush()
      @async.sleep(60)
      log.push("end")
      encoder.end()
    }
    root.spawn_bg() <| () => {
      defer r.close()
      while r.read() is Some(chunk) {
        log.push("receive compressed \{chunk.length()}")
      }
    }
  }
  json_inspect(log, content=[
    "start init", "encoder ready", "write plain ab", "receive compressed 13", "write plain cd",
    "receive compressed 3", "end", "receive compressed 10",
  ])
}

///|
async test "decoder yields plain chunks lazily across delayed chunks" {
  let log : Array[String] = []
  @async.with_task_group() <| root => {
    let (compressed_r, compressed_w) = @io.pipe()
    root.spawn_bg() <| () => {
      defer compressed_w.close()
      compressed_w.write(b"\x1f\x8b\x08\x00\x00\x00\x00\x00\x00\xff")
      @async.sleep(20)
      log.push("write plain ab")
      compressed_w.write(b"\x00\x02\x00\xfd\xffab")
      @async.sleep(200)
      log.push("write plain cd")
      compressed_w.write(b"\x00\x02\x00\xfd\xffcd")
      @async.sleep(200)
      log.push("write plain ef")
      compressed_w.write(b"\x00\x02\x00\xfd\xffef")
      @async.sleep(200)
      log.push("finish")
      compressed_w.write(b"\x01\x00\x00\xff\xff")
      compressed_w.write(b"\xef\x39\x8e\x4b\x06\x00\x00\x00")
    }
    let decoder = @gzip.Decoder(compressed_r)
    let buf = FixedArray::make(2, b'\x00')
    while decoder.read_into(buf, max_len=2) is 2 {
      let chunk = buf.unsafe_reinterpret_as_bytes()
      log.push("read plain \{@utf8.decode(chunk)}")
    }
    debug_inspect(decoder.read(), content="None")
  }
  json_inspect(log, content=[
    "write plain ab", "read plain ab", "write plain cd", "read plain cd", "write plain ef",
    "read plain ef", "finish",
  ])
}

///|
async test "decoder supports reads smaller than writer chunks" {
  @async.with_task_group() <| root => {
    let (compressed_r, compressed_w) = @io.pipe()
    root.spawn_bg() <| () => {
      defer compressed_w.close()
      compressed_w.write(b"\x1f\x8b\x08\x00\x00\x00\x00\x00\x00\xff")
      compressed_w.write(b"\x00\x04\x00\xfb\xffabcd")
      @async.sleep(200)
      compressed_w.write(b"\x00\x04\x00\xfb\xffefgh")
      compressed_w.write(b"\x01\x00\x00\xff\xff")
      compressed_w.write(b"\x50\x2a\xef\xae\x08\x00\x00\x00")
    }
    let decoder = @gzip.Decoder(compressed_r)
    let buf = FixedArray::make(2, b'\x00')
    let chunks = [
      for ; decoder.read_into(buf, max_len=2) is 2; => {
        @utf8.decode(buf.unsafe_reinterpret_as_bytes())
      }
    ]
    json_inspect(chunks, content=["ab", "cd", "ef", "gh"])
    debug_inspect(decoder.read(), content="None")
  }
}

///|
#cfg(any(target="native", target="wasm"))
async test "node compatibility on source text file" {
  let input = @fs.read_binary("async/internal/gzip_internal/decoder.mbt")
  assert_node_compatibility(input)
}

///|
#cfg(any(target="native", target="wasm"))
async test "node compatibility on generated binary data" {
  let input = Bytes::makei(65536 + 257, i => ((i * 73 + 19) & 0xff).to_byte())
  assert_node_compatibility(input)
}

///|
/// Bitwise CRC-32 (IEEE), kept local so the regression test below does not
/// depend on the decoder's own checksum code.
fn test_crc32(data : Bytes) -> UInt32 {
  let mut crc = 0xFFFFFFFFU
  for b in data {
    crc = crc ^ b.to_uint()
    for _ in 0..<8 {
      crc = if (crc & 1) != 0 { (crc >> 1) ^ 0xEDB88320U } else { crc >> 1 }
    }
  }
  crc ^ 0xFFFFFFFFU
}

///|
/// Minimal LSB-first bit writer for hand-built DEFLATE blocks.
priv struct BitWriter {
  out : @buffer.Buffer
  mut acc : UInt32
  mut nbits : Int32
}

///|
fn BitWriter::bits(self : BitWriter, value : UInt32, n : Int32) -> Unit {
  self.acc = self.acc | (value << self.nbits)
  self.nbits += n
  while self.nbits >= 8 {
    self.out.write_byte((self.acc & 0xff).to_byte())
    self.acc = self.acc >> 8
    self.nbits -= 8
  }
}

///|
/// Write a Huffman code, which DEFLATE packs most significant bit first.
fn BitWriter::code(self : BitWriter, code : UInt32, n : Int32) -> Unit {
  for i = n - 1; i >= 0; i = i - 1 {
    self.bits((code >> i) & 1, 1)
  }
}

///|
/// A gzip stream of two stored blocks of `first_len` and `second_len` bytes,
/// then a fixed-Huffman block copying 3 bytes from distance 32768 and 258
/// bytes from distance 1, so that the result depends on the history ring
/// holding exactly the last 32 KiB. Returns the stream and the decoded text.
fn stored_then_backrefs(
  first_len : Int32,
  second_len : Int32,
) -> (Bytes, Bytes) {
  let first = Bytes::makei(first_len, i => (i % 251).to_byte())
  let second = Bytes::makei(second_len, i => (i % 241).to_byte())
  let plain = @buffer.Buffer()
  plain..write_bytes(first).write_bytes(second)
  let stored = plain.to_bytes()
  let n = stored.length()
  plain.write_bytes(stored[n - 32768:n - 32768 + 3])
  // distance 1 repeats the last byte copied above
  for _ in 0..<258 {
    plain.write_byte(stored[n - 32768 + 2])
  }
  let plain = plain.to_bytes()
  let stream = @buffer.Buffer()
  stream.write_bytes(b"\x1f\x8b\x08\x00\x00\x00\x00\x00\x00\xff")
  for data in [first, second] {
    let len = data.length()
    stream.write_byte(b'\x00')
    stream.write_uint16_le(len.to_uint16())
    stream.write_uint16_le((len ^ 0xffff).to_uint16())
    stream.write_bytes(data)
  }
  let bw = { out: stream, acc: 0, nbits: 0, }
  bw.bits(1, 1) // BFINAL
  bw.bits(1, 2) // BTYPE = fixed Huffman
  bw.code(0b0000001, 7) // length code 257: length 3
  bw.code(29, 5) // distance code 29: 24577 + 13 extra bits
  bw.bits(32768 - 24577, 13)
  bw.code(0b11000101, 8) // length code 285: length 258
  bw.code(0, 5) // distance code 0: distance 1
  bw.code(0, 7) // end of block
  bw.bits(0, 7) // flush the last partial byte
  stream.write_uint_le(test_crc32(plain))
  stream.write_uint_le(plain.length().reinterpret_as_uint())
  (stream.to_bytes(), plain)
}

///|
async fn decode_buffered(stream : Bytes) -> Bytes {
  let out = @buffer.Buffer()
  @async.with_task_group() <| root => {
    let (r, w) = @io.pipe()
    root.spawn_bg() <| () => {
      defer w.close()
      w.write(stream)
    }
    defer r.close()
    // Buffer the whole stream up front so that each stored block is available
    // to the decoder in one piece, as it would be from a fast socket.
    ignore(r.peek_exactly(stream.length()))
    let decoder = @gzip.Decoder(r)
    // An output buffer larger than the history ring lets a whole stored block
    // be produced by a single call.
    let buf = FixedArray::make(131072, b'\x00')
    while decoder.read_into(buf) is n && n > 0 {
      out.write_bytes(buf.unsafe_reinterpret_as_bytes()[:n])
    }
  }
  out.to_bytes()
}

///|
async test "decoder keeps the last 32 KiB of a large stored block" {
  // A 32767-byte stored block leaves the 32 KiB history ring at position
  // 32767; the following 65535-byte stored block used to be copied into the
  // ring in one wrap, overrunning it.
  for lens in [(32767, 65535), (5, 32768), (0, 65535), (40000, 32769)] {
    let (first, second) = lens
    let (stream, plain) = stored_then_backrefs(first, second)
    let out = decode_buffered(stream)
    assert_eq(out.length(), plain.length())
    assert_true(out == plain)
  }
}
