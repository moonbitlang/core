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
fn fast_store_noise(size : Int32) -> Bytes {
  let mut state = 0x91E10DA5U
  Bytes::makei(size, _ => {
    state = state ^ (state << 13)
    state = state ^ (state >> 17)
    state = state ^ (state << 5)
    (state >> 24).reinterpret_as_int().to_byte()
  })
}

///|
test "fast store remains opt in across compression entry points" {
  let input = Bytes::makei(32768, i => (i % 251).to_byte())
  for level in [0, 1, 6, 9] {
    @test.assert_eq(
      deflate_all(input, level~),
      deflate_all(input, level~, fast_store=false),
    )
    @test.assert_eq(
      inflate_all(deflate_all(input, level~, fast_store=true)),
      input,
    )
  }
  @test.assert_eq(inflate_all(deflate_all_split(input, fast_store=true)), input)
  @test.assert_eq(
    inflate_all(deflate_all_optimal(input, iterations=1, fast_store=true)),
    input,
  )
}

///|
test "fast store output respects capacities bounds and codec reuse" {
  let codec = Compressor(fast_store=true)
  for size in [4096, 8192, 65535, 65536, 131073] {
    let input = fast_store_noise(size)
    let expected = deflate_all(input, fast_store=true)
    @test.assert_eq(expected.length() <= deflate_bound(size), true)
    @test.assert_eq(
      codec.compress_into(
        input,
        FixedArray::make(expected.length() - 1, b'\x00'),
      ),
      None,
    )
    let output = FixedArray::make(expected.length() + 7, b'\xA5')
    @test.assert_eq(codec.compress_into(input, output), Some(expected.length()))
    @test.assert_eq(Bytes::from_array(output[:expected.length()]), expected)
    for i in expected.length()..<output.length() {
      @test.assert_eq(output[i], b'\xA5')
    }
    @test.assert_eq(
      deflate_into(input, output, fast_store=true),
      Some(expected.length()),
    )
    @test.assert_eq(codec.compress(input), expected)
    @test.assert_eq(
      codec.compress(b"abcabcabcabc"),
      deflate_all(b"abcabcabcabc"),
    )
    @test.assert_eq(inflate_all(codec.compress(b"")), b"")
  }
}

///|
test "stored streaming blocks remain searchable as history" {
  let d = Deflater(fast_store=true)
  let input = fast_store_noise(DEFLATE_BLOCK_SIZE)
  for byte in input {
    d.push_pending(Bytes::make(1, byte))
  }
  @test.assert_eq(d.try_fast_store(DEFLATE_BLOCK_SIZE, is_final=false), true)
  let start = d.parse_pos
  for i in 0..<64 {
    d.push_pending(Bytes::make(1, input[DEFLATE_BLOCK_SIZE - 512 + i]))
  }
  d.chain_ready_history()
  let packed_match = d.finder.find_window_match(
    d.pending,
    start,
    d.pending_end,
    0,
    d.cfg,
  )
  @test.assert_eq(packed_match >> 16, 64)
  @test.assert_eq(packed_match & 0xFFFF, 512)
  d.reset()
  @test.assert_eq(d.fast_store, true)
  @test.assert_eq(d.try_fast_store(0, is_final=true), false)
}

///|
fn append_fast_store_stream(
  encoder : Deflater,
  input : Bytes,
  action : DeflateAction,
  result : Array[Byte],
) -> Unit raise {
  let output = FixedArray::make(7, b'\x00')
  let mut consumed = 0
  for ;; {
    let status_result = encoder.step(
      input[consumed:],
      output.mut_view(),
      action~,
    )
    let status = status_result.status
    let accepted = status_result.consumed
    let written = status_result.produced
    consumed += accepted
    for i in 0..<written {
      result.push(output[i])
    }
    match status {
      Done => {
        @test.assert_eq(consumed, input.length())
        return
      }
      NeedMoreInput if consumed == input.length() && action is SyncFlush =>
        return
      _ => ()
    }
    guard accepted > 0 || written > 0 else { abort("stream made no progress") }
  }
}

///|
test "fast store transitions across sync flush backpressure and reset" {
  let noise = fast_store_noise(16384)
  let text = Bytes::makei(12000, i => b"ordinary repeated text "[i % 23])
  for pair in [(noise, text), (text, noise)] {
    let (first, last) = pair
    let fast = Deflater(fast_store=true)
    let encoded : Array[Byte] = []
    append_fast_store_stream(fast, first, SyncFlush, encoded)
    append_fast_store_stream(fast, last, Finish, encoded)
    @test.assert_eq(inflate_all(Bytes::from_array(encoded)), first + last)
    fast.reset()
    encoded.clear()
    append_fast_store_stream(fast, noise, Finish, encoded)
    @test.assert_eq(inflate_all(Bytes::from_array(encoded)), noise)
    let defaults : Array[Byte] = []
    let explicit : Array[Byte] = []
    let normal = Deflater()
    let disabled = Deflater(fast_store=false)
    append_fast_store_stream(normal, first, SyncFlush, defaults)
    append_fast_store_stream(normal, last, Finish, defaults)
    append_fast_store_stream(disabled, first, SyncFlush, explicit)
    append_fast_store_stream(disabled, last, Finish, explicit)
    @test.assert_eq(defaults, explicit)
  }
}
