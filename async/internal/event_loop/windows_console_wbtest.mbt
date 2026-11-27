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
fn console_buffer_for_test(buffer : FixedArray[UInt16]) -> WindowsConsoleBuffer {
  {
    buffer,
    buffer_offset: 0,
    buffer_len: buffer.length(),
    unpaired_surrogate: 0,
    pending: FixedArray::make(4, b'\x00'),
    pending_len: 0,
  }
}

///|
test "decode_utf16 encodes UTF-8 boundary values and surrogate pairs" {
  let console = console_buffer_for_test([
    0x0000, 0x007F, 0x0080, 0x07FF, 0x0800, 0xFFFF, 0xD800, 0xDC00, 0xDBFF, 0xDFFF,
  ])
  let output = FixedArray::make(20, b'\xAA')
  let produced = console.decode_utf16(output, offset=0, len=output.length())
  inspect(
    Bytes::from_array(output[:produced]),
    content=(
      #|b"\x00\x7f\xc2\x80\xdf\xbf\xe0\xa0\x80\xef\xbf\xbf\xf0\x90\x80\x80\xf4\x8f\xbf\xbf"
    ),
  )
  @debug.debug_inspect(
    (
      produced,
      console.buffer_offset,
      console.buffer_len,
      console.unpaired_surrogate.to_int(),
      console.pending_len,
    ),
    content=(
      #|(20, 0, 0, 0, 0)
    ),
  )
}

///|
test "decode_utf16 replaces malformed surrogate sequences" {
  let console = console_buffer_for_test([
    0xDC00, 0xD800, 0x0041, 0xD800, 0xDBFF, 0xDFFF,
  ])
  let output = FixedArray::make(15, b'\xAA')
  let produced = console.decode_utf16(output, offset=0, len=output.length())
  inspect(
    Bytes::from_array(output[:produced]),
    content=(
      #|b"\xef\xbf\xbd\xef\xbf\xbdA\xef\xbf\xbd\xf4\x8f\xbf\xbf"
    ),
  )
  @debug.debug_inspect(
    (
      produced,
      console.buffer_offset,
      console.buffer_len,
      console.unpaired_surrogate.to_int(),
      console.pending_len,
    ),
    content=(
      #|(14, 0, 0, 0, 0)
    ),
  )
}

///|
test "decode_utf16 preserves a surrogate pair split between reads" {
  let console = console_buffer_for_test([0xD83D])
  let output = FixedArray::make(4, b'\xAA')
  let first = console.decode_utf16(output, offset=0, len=output.length())
  @debug.debug_inspect(
    (
      first,
      console.buffer_offset,
      console.buffer_len,
      console.unpaired_surrogate.to_int(),
    ),
    content=(
      #|(0, 0, 0, 55357)
    ),
  )
  console.buffer[0] = 0xDE00
  console.buffer_len = 1
  let second = console.decode_utf16(output, offset=0, len=output.length())
  inspect(
    Bytes::from_array(output[:second]),
    content=(
      #|b"\xf0\x9f\x98\x80"
    ),
  )
  @debug.debug_inspect(
    (
      second,
      console.buffer_offset,
      console.buffer_len,
      console.unpaired_surrogate.to_int(),
    ),
    content=(
      #|(4, 0, 0, 0)
    ),
  )
}

///|
test "decode_utf16 does not restore a replaced high surrogate" {
  let console = console_buffer_for_test([0xD800])
  let output = FixedArray::make(4, b'\xAA')
  let first = console.decode_utf16(output, offset=0, len=output.length())
  @debug.debug_inspect(
    (
      first,
      console.buffer_offset,
      console.buffer_len,
      console.unpaired_surrogate.to_int(),
    ),
    content=(
      #|(0, 0, 0, 55296)
    ),
  )
  console.buffer[0] = 0x0041
  console.buffer_len = 1
  let second = console.decode_utf16(output, offset=0, len=3)
  inspect(
    Bytes::from_array(output[:second]),
    content=(
      #|b"\xef\xbf\xbd"
    ),
  )
  @debug.debug_inspect(
    (
      second,
      console.buffer_offset,
      console.buffer_len,
      console.unpaired_surrogate.to_int(),
    ),
    content=(
      #|(3, 0, 1, 0)
    ),
  )
  let third = console.decode_utf16(output, offset=2, len=1)
  inspect(
    Bytes::from_array(output),
    content=(
      #|b"\xef\xbfA\xaa"
    ),
  )
  @debug.debug_inspect(
    (
      third,
      console.buffer_offset,
      console.buffer_len,
      console.unpaired_surrogate.to_int(),
    ),
    content=(
      #|(1, 0, 0, 0)
    ),
  )
}

///|
test "decode_utf16 resumes partial UTF-8 characters before more input" {
  let console = console_buffer_for_test([0x0800, 0xD800, 0xDC00, 0x0041])
  let output = FixedArray::make(10, b'\xAA')
  let first = console.decode_utf16(output, offset=2, len=1)
  @debug.debug_inspect(
    (first, console.buffer_offset, console.buffer_len, console.pending_len),
    content=(
      #|(1, 1, 3, 2)
    ),
  )
  let pending1 = console.write_pending(output, offset=3, len=1)
  let pending2 = console.write_pending(output, offset=4, len=1)
  let second = console.decode_utf16(output, offset=5, len=2)
  @debug.debug_inspect(
    (
      pending1,
      pending2,
      second,
      console.buffer_offset,
      console.buffer_len,
      console.pending_len,
    ),
    content=(
      #|(1, 1, 2, 3, 1, 2)
    ),
  )
  let pending3 = console.write_pending(output, offset=7, len=2)
  let third = console.decode_utf16(output, offset=9, len=1)
  inspect(
    Bytes::from_array(output),
    content=(
      #|b"\xaa\xaa\xe0\xa0\x80\xf0\x90\x80\x80A"
    ),
  )
  @debug.debug_inspect(
    (
      pending3,
      third,
      console.buffer_offset,
      console.buffer_len,
      console.pending_len,
    ),
    content=(
      #|(2, 1, 0, 0, 0)
    ),
  )
}

///|
test "decode_utf16 respects output offset and zero capacity" {
  let console = console_buffer_for_test([0x0058, 0x0041, 0x0042])
  console.buffer_offset = 1
  console.buffer_len = 2
  let output = FixedArray::make(6, b'\xAA')
  let first = console.decode_utf16(output, offset=2, len=0)
  @debug.debug_inspect(
    (
      first,
      console.buffer_offset,
      console.buffer_len,
      console.unpaired_surrogate.to_int(),
    ),
    content=(
      #|(0, 1, 2, 0)
    ),
  )
  let second = console.decode_utf16(output, offset=2, len=2)
  inspect(
    Bytes::from_array(output),
    content=(
      #|b"\xaa\xaaAB\xaa\xaa"
    ),
  )
  @debug.debug_inspect(
    (
      second,
      console.buffer_offset,
      console.buffer_len,
      console.unpaired_surrogate.to_int(),
    ),
    content=(
      #|(2, 0, 0, 0)
    ),
  )
}
