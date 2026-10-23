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
test "round-trip: repetitive data actually compresses" {
  let s = b"abcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabc"
  let comp = @flate.deflate_all(s)
  assert_true(comp.length() < s.length())
  @test.assert_eq(@flate.inflate_all(comp), s)
}

///|
/// A final-input request is accepted only after older output is drained. The
/// caller re-presents an unconsumed suffix with `action=Finish`; once accepted, the
/// request remains sticky and later protocol input is left untouched.
test "Deflater finalization preserves unconsumed input under backpressure" {
  let prefix = Bytes::from_array(Array::make(17000, b'\x5A'))
  let final_input = b"terminal-state payload"
  let after_end = b"belongs to the next protocol state"
  let def = @flate.Deflater(level=0)
  let no_output = FixedArray::make(0, b'\x00')
  let compressed = @buffer.Buffer()
  let prefix_status_result = def.step(prefix, no_output.mut_view())
  let prefix_status = prefix_status_result.status
  let prefix_consumed = prefix_status_result.consumed
  let prefix_produced = prefix_status_result.produced
  assert_true(prefix_status is NeedMoreOutput)
  assert_true(prefix_consumed < prefix.length())
  @test.assert_eq(prefix_produced, 0)
  let obuf = FixedArray::make(257, b'\x00')
  let mut prefix_pos = prefix_consumed
  for ;; {
    let status_result = def.step(prefix[prefix_pos:], obuf.mut_view())
    let status = status_result.status
    let consumed = status_result.consumed
    let produced = status_result.produced
    prefix_pos = prefix_pos + consumed
    for i in 0..<produced {
      compressed.write_byte(obuf[i])
    }
    if prefix_pos == prefix.length() && status is NeedMoreInput {
      break
    }
  }
  // Queue a sync-flush marker without output room so final input first meets
  // older compressed output and must remain wholly unconsumed.
  let flush_status_result = def.step(
    b"",
    no_output.mut_view(),
    action=SyncFlush,
  )
  let flush_status = flush_status_result.status
  let _flush_consumed = flush_status_result.consumed
  let _flush_produced = flush_status_result.produced
  assert_true(flush_status is NeedMoreOutput)
  let first_status_result = def.step(
    final_input,
    no_output.mut_view(),
    action=Finish,
  )
  let first_status = first_status_result.status
  let first_consumed = first_status_result.consumed
  let first_produced = first_status_result.produced
  assert_true(first_status is NeedMoreOutput)
  @test.assert_eq(first_consumed, 0)
  @test.assert_eq(first_produced, 0)
  let mut drain_calls = 0
  let mut final_pos = 0
  for ;; {
    let view = if final_pos < final_input.length() {
      final_input[final_pos:]
    } else {
      after_end
    }
    let status_result = def.step(
      view,
      obuf.mut_view(),
      action=if final_pos < final_input.length() { Finish } else { Continue },
    )
    let status = status_result.status
    let consumed = status_result.consumed
    let produced = status_result.produced
    if final_pos < final_input.length() {
      final_pos = final_pos + consumed
    } else {
      @test.assert_eq(consumed, 0)
    }
    for i in 0..<produced {
      compressed.write_byte(obuf[i])
    }
    drain_calls = drain_calls + 1
    if status is Done {
      break
    }
    assert_true(status is NeedMoreOutput)
  }
  assert_true(drain_calls > 1)
  @test.assert_eq(final_pos, final_input.length())
  assert_true(def.is_finished())
  let expected = @buffer.Buffer()
  for byte in prefix {
    expected.write_byte(byte)
  }
  for byte in final_input {
    expected.write_byte(byte)
  }
  @test.assert_eq(
    @flate.inflate_all(compressed.to_bytes()),
    expected.to_bytes(),
  )
  let sentinel = FixedArray::make(4, b'\xA5')
  let done_status_result = def.step(
    after_end,
    sentinel.mut_view(),
    action=SyncFlush,
  )
  let done_status = done_status_result.status
  let done_consumed = done_status_result.consumed
  let done_produced = done_status_result.produced
  assert_true(done_status is Done)
  @test.assert_eq(done_consumed, 0)
  @test.assert_eq(done_produced, 0)
  for byte in sentinel {
    @test.assert_eq(byte, b'\xA5')
  }
}
