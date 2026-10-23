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
test "preset dictionaries retain exactly the final 32 KiB" {
  let dictionary_bytes = Array::make(40000, b'\x00')
  let message_bytes : Array[Byte] = []
  for i in 0..<512 {
    let byte = ((i * 73 + 19) % 251).to_byte()
    dictionary_bytes[40000 - 512 + i] = byte
    message_bytes.push(byte)
  }
  let dictionary = Bytes::from_array(dictionary_bytes)
  let message = Bytes::from_array(message_bytes)
  let deflater = @flate.Deflater(dictionary~)
  let compressed_buffer = FixedArray::make(4096, b'\x00')
  let deflate_status_result = deflater.step(
    message,
    compressed_buffer.mut_view(),
    action=Finish,
  )
  let consumed = deflate_status_result.consumed
  let compressed_size = deflate_status_result.produced
  assert_true(deflate_status_result.status is Done)
  @test.assert_eq(consumed, message.length())
  // A correct final-32-KiB dictionary turns the 512-byte suffix into a match.
  assert_true(compressed_size < 100)
  let compressed = Bytes::from_array(compressed_buffer[:compressed_size])
  let inflater = @flate.Inflater(dictionary~)
  let output = FixedArray::make(1024, b'\x00')
  let inflate_status_result = inflater.step(compressed, output.mut_view())
  let produced = inflate_status_result.produced
  assert_true(inflate_status_result.status is Done)
  @test.assert_eq(produced, message.length())
  for i in 0..<produced {
    @test.assert_eq(output[i], message[i])
  }
  // `reset(dictionary=...)` is the allocation-reusing configuration path; it
  // must preload the same final 32 KiB as construction does.
  deflater.reset(dictionary~)
  let reset_status_result = deflater.step(
    message,
    compressed_buffer.mut_view(),
    action=Finish,
  )
  assert_true(reset_status_result.status is Done)
  @test.assert_eq(reset_status_result.consumed, message.length())
  @test.assert_eq(reset_status_result.produced, compressed_size)
}
