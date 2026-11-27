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
const WINDOWS_CONSOLE_BUFFER_SIZE : Int32 = 4096

///|
/// Intermediate buffer for automatic decoding in Windows console handling.
/// Binary IO over Windows console is interpreted as UTF-8,
/// so we need to perform encoding/decoding before actually invoking
/// `ReadConsoleW`/`WriteConsoleW`.
priv struct WindowsConsoleBuffer {
  buffer : FixedArray[UInt16]
  mut buffer_offset : Int32
  mut buffer_len : Int32
  /// For console input: unpaired high surrogate from the last read.
  /// Zero if there is no unpaired surrogate.
  mut unpaired_surrogate : UInt16
  /// - For console input: bytes from the last read character,
  ///   not delivered due to insufficient user buffer.
  ///   The whole byte sequence is stored right-aligned in `pending`,
  ///   and the number of remaining bytes is determined by `pending_len`
  /// - for console output: incomplete UTF-8 sequence from the last write
  pending : FixedArray[Byte]
  /// number of bytes in `pending`
  mut pending_len : Int32
}

///|
let dummy_console_buffer : WindowsConsoleBuffer = {
  buffer: [],
  buffer_offset: 0,
  buffer_len: 0,
  unpaired_surrogate: 0,
  pending: [],
  pending_len: 0,
}

///|
fn WindowsConsoleBuffer::WindowsConsoleBuffer(
  kind : @fd_util.FileKind,
) -> WindowsConsoleBuffer {
  if kind is Console && platform is Windows {
    {
      buffer: FixedArray::make(WINDOWS_CONSOLE_BUFFER_SIZE, 0),
      buffer_offset: 0,
      buffer_len: 0,
      unpaired_surrogate: 0,
      pending: FixedArray::make(4, 0),
      pending_len: 0,
    }
  } else {
    dummy_console_buffer
  }
}

///|
fn WindowsConsoleBuffer::write_pending(
  self : WindowsConsoleBuffer,
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
) -> Int32 {
  let n = @cmp.minimum(self.pending_len, len)
  self.pending.blit_to(
    buf,
    src_offset=4 - self.pending_len,
    dst_offset=offset,
    len=n,
  )
  self.pending_len -= n
  n
}

///|
fn encode_utf8_char(
  char : Int32,
  buf : FixedArray[Byte],
  offset~ : Int32,
) -> Unit {
  match char {
    _..<0x80 => buf[offset] = char.to_byte()
    _..<0x800 => {
      buf[offset] = (0xC0 | (char >> 6)).to_byte()
      buf[offset + 1] = (0x80 | (char & 0x3F)).to_byte()
    }
    _..<0x10000 => {
      buf[offset] = (0xE0 | (char >> 12)).to_byte()
      buf[offset + 1] = (0x80 | ((char >> 6) & 0x3F)).to_byte()
      buf[offset + 2] = (0x80 | (char & 0x3F)).to_byte()
    }
    _ => {
      buf[offset] = (0xF0 | (char >> 18)).to_byte()
      buf[offset + 1] = (0x80 | ((char >> 12) & 0x3F)).to_byte()
      buf[offset + 2] = (0x80 | ((char >> 6) & 0x3F)).to_byte()
      buf[offset + 3] = (0x80 | (char & 0x3F)).to_byte()
    }
  }
}

///|
/// Return the new value of `produced`
fn WindowsConsoleBuffer::emit_char(
  console : WindowsConsoleBuffer,
  char : Int32,
  buf : FixedArray[Byte],
  offset~ : Int32,
  produced~ : Int32,
  len~ : Int32,
) -> Int32 {
  let char_bytes = match char {
    _..<0x80 => 1
    _..<0x800 => 2
    _..<0x10000 => 3
    _ => 4
  }
  if produced + char_bytes <= len {
    encode_utf8_char(char, buf, offset=offset + produced)
    produced + char_bytes
  } else {
    encode_utf8_char(char, console.pending, offset=4 - char_bytes)
    console.pending_len = char_bytes
    produced +
    console.write_pending(buf, offset=offset + produced, len=len - produced)
  }
}

///|
fn WindowsConsoleBuffer::decode_utf16(
  console : WindowsConsoleBuffer,
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
) -> Int32 {
  let high_surrogate = console.unpaired_surrogate
  console.unpaired_surrogate = 0
  let data = console.buffer[console.buffer_offset:console.buffer_offset +
    console.buffer_len]
  for consumed, code in data; produced = 0, high_surrogate = high_surrogate {
    guard produced < len else {
      console.unpaired_surrogate = high_surrogate
      console.buffer_offset += consumed
      console.buffer_len -= consumed
      break produced
    }
    match (high_surrogate, code) {
      (0, 0xDC00..<=0xDFFF) =>
        continue console.emit_char(0xFFFD, buf, offset~, len~, produced~), 0
      (high, 0xDC00..<=0xDFFF) => {
        let c = ((high.to_int() - 0xD800) << 10) +
          (code.to_int() - 0xDC00) +
          0x10000
        let produced = console.emit_char(
          if c > 0x10FFFF {
            0xFFFD
          } else {
            c
          },
          buf,
          len~,
          offset~,
          produced~,
        )
        continue produced, 0
      }
      _ => {
        let produced = if high_surrogate > 0 {
          // unmatched surrogate
          let produced = console.emit_char(
            0xFFFD,
            buf,
            offset~,
            len~,
            produced~,
          )
          guard produced < len else {
            console.buffer_offset += consumed
            console.buffer_len -= consumed
            break produced
          }
          produced
        } else {
          produced
        }
        if code is (0xD800..<=0xDBFF) {
          continue produced, code
        } else {
          continue console.emit_char(
              code.to_int(),
              buf,
              offset~,
              len~,
              produced~,
            ),
            0
        }
      }
    }
  } nobreak {
    console.unpaired_surrogate = high_surrogate
    console.buffer_offset = 0
    console.buffer_len = 0
    produced
  }
}
