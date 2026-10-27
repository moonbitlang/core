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
      stdin=@process.write_to_process(),
      stdout=@process.read_from_process(),
      stderr=@process.read_from_process(),
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
