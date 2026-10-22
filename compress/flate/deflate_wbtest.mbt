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
/// The block cap keeps both accepted input and generated output bounded even
/// when a large caller-owned view is paired with no output capacity.
test "Deflater pending stays bounded after a large feed" {
  let d = Deflater()
  let no_output = FixedArray::make(0, b'\x00')
  let arr : Array[Byte] = []
  for i in 0..<200000 {
    arr.push((i % 251).to_byte())
  }
  let src = Bytes::from_array(arr)
  let first_status_result = d.step(src, no_output.mut_view())
  let first_status = first_status_result.status
  let first_consumed = first_status_result.consumed
  let first_produced = first_status_result.produced
  assert_true(first_status is NeedMoreOutput)
  assert_true(first_consumed > 0)
  assert_true(first_consumed < src.length())
  @test.assert_eq(first_produced, 0)
  assert_true(d.pending_bytes() <= DEFLATE_BLOCK_SIZE + MIN_LOOKAHEAD)
  assert_true(d.w.out.length() <= DEFLATE_BLOCK_SIZE + MIN_LOOKAHEAD + 16)

  let buf = FixedArray::make(65536, b'\x00')
  let mut pos = first_consumed
  for ;; {
    let status_result = d.step(src[pos:], buf.mut_view())
    let status = status_result.status
    let consumed = status_result.consumed
    pos = pos + consumed
    assert_true(d.pending_bytes() <= DEFLATE_BLOCK_SIZE + MIN_LOOKAHEAD)
    assert_true(d.w.out.length() <= DEFLATE_BLOCK_SIZE + MIN_LOOKAHEAD + 16)
    if status is NeedMoreInput && pos == src.length() {
      break
    }
  }
  @test.assert_eq(pos, src.length())
}

///|
test "Deflater latches end before a completed view is backpressured" {
  let source = Bytes::from_array(
    Array::make(DEFLATE_BLOCK_SIZE + MIN_LOOKAHEAD, b'\x41'),
  )
  let deflater = Deflater(level=0)
  let no_output = FixedArray::make(0, b'\x00')
  let first_status_result = deflater.step(
    source,
    no_output.mut_view(),
    action=Finish,
  )
  let first_status = first_status_result.status
  let consumed = first_status_result.consumed
  let produced = first_status_result.produced
  assert_true(first_status is NeedMoreOutput)
  @test.assert_eq(consumed, source.length())
  @test.assert_eq(produced, 0)
  assert_true(deflater.end_requested)
  let compressed = @buffer.Buffer()
  let output = FixedArray::make(257, b'\x00')
  for ;; {
    // The original one-shot end request must suffice while draining.
    let status_result = deflater.step(b"", output.mut_view())
    let status = status_result.status
    let later_consumed = status_result.consumed
    let n = status_result.produced
    @test.assert_eq(later_consumed, 0)
    for i in 0..<n {
      compressed.write_byte(output[i])
    }
    if status is Done {
      break
    }
    assert_true(status is NeedMoreOutput)
  }
  @test.assert_eq(inflate_all(compressed.to_bytes()), source)
}

///|
test "Deflater reset clears queued flush and end requests" {
  let source = Bytes::make(17000, b'Z')
  let no_output = FixedArray::make(0, b'\x00')
  for action in [SyncFlush, Finish] {
    let deflater = Deflater(level=0)
    @test.assert_eq(
      deflater.step(source, no_output.mut_view()).status,
      NeedMoreOutput,
    )
    @test.assert_eq(
      deflater.step(b"", no_output.mut_view(), action~).status,
      NeedMoreOutput,
    )
    assert_true(
      if action is SyncFlush {
        deflater.flush_requested
      } else {
        deflater.end_requested
      },
    )
    deflater.reset()
    let output = FixedArray::make(64, b'\xA5')
    let status_result = deflater.step(
      b"fresh stream",
      output.mut_view(),
      action=Finish,
    )
    let status = status_result.status
    @test.assert_eq(status, Done)
    @test.assert_eq(status_result.consumed, 12)
    @test.assert_eq(
      inflate_all(Bytes::from_array(output[:status_result.produced])),
      b"fresh stream",
    )
  }
}
