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
      ["compress/gzip/node_gzip.js", mode],
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
  let (r, w) = @io.memory_pipe()
  let mut result = b""
  @async.with_task_group() <| group => {
    group.spawn_bg() <| () => {
      defer w.close()
      @gzip.StreamEncoder(w)..write(input).end()
    }
    defer r.close()
    result = r.read_all()
  }
  result
}

///|
#cfg(any(target="native", target="wasm"))
async fn decode_with_moonbit(input : Bytes) -> Bytes {
  let (r, w) = @io.memory_pipe()
  let mut result = b""
  @async.with_task_group() <| group => {
    group.spawn_bg() <| () => {
      defer w.close()
      w.write(input)
    }
    defer r.close()
    result = @gzip.StreamDecoder(r).read_all()
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
async test "stream encode decode roundtrip" {
  @async.with_task_group() <| root => {
    let source_chunks = [b"hello ", b"gzip ", b"world"]
    let (compressed_r, compressed_w) = @io.memory_pipe()
    root.spawn_bg() <| () => {
      defer compressed_w.close()
      let encoder = @gzip.StreamEncoder(compressed_w)
      for chunk in source_chunks {
        encoder.write(chunk)
        @async.sleep(10)
      }
      encoder.end()
    }
    let decoder = @gzip.StreamDecoder(compressed_r)
    inspect(@utf8.decode(decoder.read_all()), content="hello gzip world")
    compressed_r.close()
  }
}

///|
async test "multistream decoder waits across member boundary and accepts final EOF" {
  @async.with_task_group() <| root => {
    let first = @gzip.compress(b"first ")
    let second = @gzip.compress(b"second")
    let (compressed_r, compressed_w) = @io.memory_pipe()
    root.spawn_bg() <| () => {
      defer compressed_w.close()
      compressed_w.write(first)
      // Force the decoder to wait at an exact member/read boundary.
      @async.sleep(20)
      compressed_w.write(second)
    }
    let decoder = @gzip.StreamDecoder(compressed_r, multistream=true)
    inspect(@utf8.decode(decoder.read_all()), content="first second")
    compressed_r.close()
  }
}

///|
async test "multistream decoder leaves lone magic prefix at EOF unread" {
  @async.with_task_group() <| root => {
    let first = @gzip.compress(b"first")
    let (compressed_r, compressed_w) = @io.memory_pipe()
    root.spawn_bg() <| () => {
      defer compressed_w.close()
      compressed_w.write(first)
      // A lone magic-prefix byte at physical EOF is trailing data, not a
      // truncated second member.
      compressed_w.write(b"\x1f")
    }
    let decoder = @gzip.StreamDecoder(compressed_r, multistream=true)
    assert_eq(decoder.read_all(), b"first")
    assert_eq(compressed_r.read_all(), b"\x1f")
    compressed_r.close()
  }
}

///|
async test "default stream decoder leaves co-buffered next member unread" {
  @async.with_task_group() <| root => {
    let first = @gzip.compress(b"first")
    let second = @gzip.compress(b"second")
    let joined_buffer = @buffer.Buffer()
    joined_buffer.write_bytesview(first)
    joined_buffer.write_bytesview(second)
    let joined = joined_buffer.to_bytes()
    let (compressed_r, compressed_w) = @io.memory_pipe()
    root.spawn_bg() <| () => {
      defer compressed_w.close()
      compressed_w.write(joined)
    }
    // Ensure one underlying peek spans both members. Exact core consumption
    // must still drop only the first member from the transport.
    ignore(compressed_r.peek_exactly(joined.length()))
    let decoder = @gzip.StreamDecoder(compressed_r)
    assert_eq(decoder.read_all(), b"first")
    assert_eq(compressed_r.read_all(), second)
    compressed_r.close()
  }
}

///|
async test "multistream decoder reports a truncated later member at EOF" {
  @async.with_task_group() <| root => {
    let first = @gzip.compress(b"first")
    let (compressed_r, compressed_w) = @io.memory_pipe()
    root.spawn_bg() <| () => {
      defer compressed_w.close()
      compressed_w.write(first)
      // Two magic bytes commit multistream mode to a second member.
      compressed_w.write(b"\x1f\x8b")
    }
    let decoder = @gzip.StreamDecoder(compressed_r, multistream=true)
    let error = @test.expect_error_async(() => decoder.read_all())
    guard error is TransportError(cause, context="@gzip.StreamDecoder") else {
      fail("expected a wrapped gzip error")
    }
    assert_true(cause is @gzip.GzipError(Truncated, _))
    compressed_r.close()
  }
}

///|
async test "stream wrappers accept one-byte input and output" {
  @async.with_task_group() <| root => {
    let payload = b"one byte at a time still shares one compression history"
    let (compressed_r, compressed_w) = @io.memory_pipe()
    root.spawn_bg() <| () => {
      defer compressed_w.close()
      let encoder = @gzip.StreamEncoder(compressed_w)
      for i in 0..<payload.length() {
        encoder.write(payload[i:i + 1])
      }
      encoder.end()
    }
    let decoder = @gzip.StreamDecoder(compressed_r)
    let byte = FixedArray::make(1, b'\x00')
    let plain = @buffer.Buffer()
    while decoder.read_into(byte.mut_view()) is 1 {
      plain.write_byte(byte[0])
    }
    assert_eq(plain.to_bytes(), payload)
    compressed_r.close()
  }
}

///|
async test "stream encoder uses valid blocks across large writes" {
  @async.with_task_group() <| root => {
    let payload = Bytes::makei(70000, i => (i % 251).to_byte())
    let (compressed_r, compressed_w) = @io.memory_pipe()
    root.spawn_bg() <| () => {
      defer compressed_w.close()
      let encoder = @gzip.StreamEncoder(compressed_w)
      encoder.write(payload)
      encoder.end()
    }
    let decoder = @gzip.StreamDecoder(compressed_r)
    inspect(decoder.read_all() == payload, content="true")
    compressed_r.close()
  }
}

///|
async test "stream encoder emits output when flushed" {
  let log : Array[String] = []
  @async.with_task_group() <| root => {
    let (r, w) = @io.memory_pipe()
    root.spawn_bg() <| () => {
      defer w.close()
      log.push("start init")
      let encoder = @gzip.StreamEncoder(w)
      log.push("encoder ready")
      log.push("write plain ab")
      encoder.write(b"ab")
      encoder.flush_partial_data()
      @async.sleep(60)
      log.push("write plain cd")
      encoder.write(b"cd")
      encoder.flush_partial_data()
      @async.sleep(60)
      log.push("end")
      encoder.end()
    }
    root.spawn_bg() <| () => {
      defer r.close()
      while r.read() is Some(_) {
        log.push("receive compressed")
      }
    }
  }
  json_inspect(log, content=[
    "start init", "encoder ready", "write plain ab", "receive compressed", "write plain cd",
    "receive compressed", "end", "receive compressed",
  ])
}

///|
async test "stream decoder yields plain chunks lazily across delayed chunks" {
  let log : Array[String] = []
  @async.with_task_group() <| root => {
    let (compressed_r, compressed_w) = @io.memory_pipe()
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
    let decoder = @gzip.StreamDecoder(compressed_r)
    let buf = FixedArray::make(2, b'\x00')
    while decoder.read_into(buf.mut_view()) is 2 {
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
async test "stream decoder supports reads smaller than writer chunks" {
  @async.with_task_group() <| root => {
    let (compressed_r, compressed_w) = @io.memory_pipe()
    root.spawn_bg() <| () => {
      defer compressed_w.close()
      compressed_w.write(b"\x1f\x8b\x08\x00\x00\x00\x00\x00\x00\xff")
      compressed_w.write(b"\x00\x04\x00\xfb\xffabcd")
      @async.sleep(200)
      compressed_w.write(b"\x00\x04\x00\xfb\xffefgh")
      compressed_w.write(b"\x01\x00\x00\xff\xff")
      compressed_w.write(b"\x50\x2a\xef\xae\x08\x00\x00\x00")
    }
    let decoder = @gzip.StreamDecoder(compressed_r)
    let buf = FixedArray::make(2, b'\x00')
    let chunks = [
      for ; decoder.read_into(buf.mut_view()) is 2; => {
        @utf8.decode(buf.unsafe_reinterpret_as_bytes())
      }
    ]
    json_inspect(chunks, content=["ab", "cd", "ef", "gh"])
    debug_inspect(decoder.read(), content="None")
  }
}

///|
#cfg(any(target="native", target="wasm"))
async test "stream node compatibility on source text file" {
  let input = @fs.read_binary("compress/gzip/decoder.mbt")
  assert_node_compatibility(input)
}

///|
#cfg(any(target="native", target="wasm"))
async test "stream node compatibility on generated binary data" {
  let input = Bytes::makei(65536 + 257, i => ((i * 73 + 19) & 0xff).to_byte())
  assert_node_compatibility(input)
}

///|
fn stream_test_crc32(data : Bytes) -> UInt32 {
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
priv struct StreamTestBitWriter {
  out : @buffer.Buffer
  mut acc : UInt32
  mut nbits : Int32
}

///|
fn StreamTestBitWriter::bits(
  self : StreamTestBitWriter,
  value : UInt32,
  n : Int32,
) -> Unit {
  self.acc = self.acc | (value << self.nbits)
  self.nbits += n
  while self.nbits >= 8 {
    self.out.write_byte((self.acc & 0xff).to_byte())
    self.acc = self.acc >> 8
    self.nbits -= 8
  }
}

///|
fn StreamTestBitWriter::code(
  self : StreamTestBitWriter,
  code : UInt32,
  n : Int32,
) -> Unit {
  for i = n - 1; i >= 0; i = i - 1 {
    self.bits((code >> i) & 1, 1)
  }
}

///|
fn stream_stored_then_backrefs(
  first_len : Int32,
  second_len : Int32,
) -> (Bytes, Bytes) {
  let first = Bytes::makei(first_len, i => (i % 251).to_byte())
  let second = Bytes::makei(second_len, i => (i % 241).to_byte())
  let plain = @buffer.Buffer()
  plain..write_bytesview(first).write_bytesview(second)
  let stored = plain.to_bytes()
  let n = stored.length()
  plain.write_bytesview(stored[n - 32768:n - 32768 + 3])
  for _ in 0..<258 {
    plain.write_byte(stored[n - 32768 + 2])
  }
  let plain = plain.to_bytes()
  let stream = @buffer.Buffer()
  stream.write_bytesview(b"\x1f\x8b\x08\x00\x00\x00\x00\x00\x00\xff")
  for data in [first, second] {
    let len = data.length()
    stream.write_byte(b'\x00')
    stream.write_uint16_le(len.to_uint16())
    stream.write_uint16_le((len ^ 0xffff).to_uint16())
    stream.write_bytesview(data)
  }
  let bw : StreamTestBitWriter = { out: stream, acc: 0, nbits: 0, }
  bw.bits(1, 1)
  bw.bits(1, 2)
  bw.code(0b0000001, 7)
  bw.code(29, 5)
  bw.bits(32768 - 24577, 13)
  bw.code(0b11000101, 8)
  bw.code(0, 5)
  bw.code(0, 7)
  bw.bits(0, 7)
  stream.write_uint_le(stream_test_crc32(plain))
  stream.write_uint_le(plain.length().reinterpret_as_uint())
  (stream.to_bytes(), plain)
}

///|
async fn stream_decode_buffered(stream : Bytes) -> Bytes {
  let out = @buffer.Buffer()
  @async.with_task_group() <| root => {
    let (r, w) = @io.memory_pipe()
    root.spawn_bg() <| () => {
      defer w.close()
      w.write(stream)
    }
    defer r.close()
    ignore(r.peek_exactly(stream.length()))
    let decoder = @gzip.StreamDecoder(r)
    let buf = FixedArray::make(131072, b'\x00')
    while decoder.read_into(buf.mut_view()) is n && n > 0 {
      out.write_bytesview(buf.unsafe_reinterpret_as_bytes()[:n])
    }
  }
  out.to_bytes()
}

///|
async test "stream decoder keeps the last 32 KiB of a large stored block" {
  for lens in [(32767, 65535), (5, 32768), (0, 65535), (40000, 32769)] {
    let (first, second) = lens
    let (stream, plain) = stream_stored_then_backrefs(first, second)
    let out = stream_decode_buffered(stream)
    assert_eq(out.length(), plain.length())
    assert_true(out == plain)
  }
}
