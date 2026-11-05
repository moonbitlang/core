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

// `read_all` against DEFLATE entries whose declared uncompressed size lies,
// and against malformed DEFLATE payloads. The full error, including the
// observed count of a limit failure, is pinned.

///|
/// Deterministic text-like data: compressible, but not a single long match,
/// so decoding spans many 8 KiB decoder steps.
fn declared_size_payload(size : Int32) -> Bytes {
  let words : ReadOnlyArray[Bytes] = [
    b"zip ", b"entry ", b"declared ", b"size ", b"deflate ", b"payload ", b"central ",
    b"local ",
  ]
  let mut state = 0x2545F491U
  let out : Array[Byte] = []
  while out.length() < size {
    state = state * 1103515245U + 12345U
    let word = words[((state >> 16) & 7).reinterpret_as_int()]
    for byte in word {
      out.push(byte)
    }
  }
  Bytes::from_array(out)[:size].to_owned()
}

///|
/// The archive offsets of entry `index`'s local header and central record.
fn declared_size_offsets(bytes : Bytes, index : Int32) -> (Int32, Int32) {
  let mut central = zip_test_field(bytes, bytes.length() - 22 + 16, 4)
  for _ in 0..<index {
    central = central +
      46 +
      zip_test_field(bytes, central + 28, 2) +
      zip_test_field(bytes, central + 30, 2) +
      zip_test_field(bytes, central + 32, 2)
  }
  (zip_test_field(bytes, central + 42, 4), central)
}

///|
fn put_u32le(bytes : FixedArray[Byte], offset : Int32, value : UInt32) -> Unit {
  for i in 0..<4 {
    bytes[offset + i] = ((value >> (8 * i)) & 0xFF)
      .reinterpret_as_int()
      .to_byte()
  }
}

///|
/// Rewrite both declarations of entry `index`'s uncompressed size.
fn with_declared_size(bytes : Bytes, index : Int32, size : UInt32) -> Bytes {
  let (local_at, central) = declared_size_offsets(bytes, index)
  let changed = bytes.to_fixedarray()
  put_u32le(changed, local_at + 22, size)
  put_u32le(changed, central + 24, size)
  Bytes::from_array(changed)
}

///|
/// A stored entry `prefix` followed by DEFLATE entry `x` holding `data`.
fn declared_size_archive(data : Bytes) -> Bytes raise @zip.ZipError {
  let archive = @zip.Archive()
  archive.add("prefix", b"12345", compression=Store)
  archive.add("x", data, compression=Deflate)
  @zip.write(archive)
}

///|
/// Store `raw` verbatim as the payload of a single entry, then relabel it as
/// DEFLATE that decodes to `declared` bytes. The CRC is left as written: every
/// case here fails before the CRC check.
fn raw_deflate_archive(
  raw : Bytes,
  declared : UInt32,
) -> Bytes raise @zip.ZipError {
  let archive = @zip.Archive()
  archive.add("raw", raw, compression=Store)
  let bytes = @zip.write(archive)
  let (local_at, central) = declared_size_offsets(bytes, 0)
  let changed = bytes.to_fixedarray()
  changed[local_at + 8] = b'\x08'
  changed[central + 10] = b'\x08'
  with_declared_size(Bytes::from_array(changed), 0, declared)
}

///|
fn read_all_error(bytes : Bytes, limits? : @zip.ReadLimits) -> String raise {
  let err = @test.expect_error(() => @zip.read_all(bytes, limits?))
  "\{err}"
}

///|
test "read_all rejects small DEFLATE entries whose declared size lies" {
  let data = b"0123456789"
  let bytes = declared_size_archive(data)
  @test.assert_eq(@zip.read_all(bytes).get("x"), Some(data))
  // Too small, too large, zero, and a huge size that every limit admits.
  for declared in [9U, 11U, 0U, 0x7FFF_0000U] {
    inspect(
      read_all_error(with_declared_size(bytes, 1, declared)),
      content="SizeMismatch: zip: decoded size does not match central directory",
    )
  }
}

///|
test "read_all rejects large DEFLATE entries whose declared size lies" {
  let size = 300_000
  let data = declared_size_payload(size)
  let bytes = declared_size_archive(data)
  @test.assert_eq(@zip.read_all(bytes).get("x"), Some(data))
  for declared in [size - 1, size + 1, size / 2, size * 2] {
    inspect(
      read_all_error(
        with_declared_size(bytes, 1, declared.reinterpret_as_uint()),
      ),
      content="SizeMismatch: zip: decoded size does not match central directory",
    )
  }
}

///|
test "read_all reports DEFLATE output beyond the limits a lying size passed" {
  let size = 300_000
  let bytes = with_declared_size(
    declared_size_archive(declared_size_payload(size)),
    1,
    100_000,
  )
  // The declaration passes both limits; the real output exceeds them.
  inspect(
    read_all_error(
      bytes,
      limits=ReadLimits(max_entry_uncompressed_bytes=150_000),
    ),
    content="LimitExceeded(kind=EntryUncompressedBytes, limit=150000, observed=155648): zip: decompressed size limit exceeded",
  )
  inspect(
    read_all_error(
      bytes,
      limits=ReadLimits(max_total_uncompressed_bytes=150_005),
    ),
    content="LimitExceeded(kind=TotalUncompressedBytes, limit=150005, observed=155653): zip: decompressed size limit exceeded",
  )
  // Tighter per-entry than remaining total: the per-entry limit is reported.
  inspect(
    read_all_error(
      bytes,
      limits=ReadLimits(
        max_entry_uncompressed_bytes=120_000,
        max_total_uncompressed_bytes=200_000,
      ),
    ),
    content="LimitExceeded(kind=EntryUncompressedBytes, limit=120000, observed=122880): zip: decompressed size limit exceeded",
  )
  // A real size within the limits is still only a mismatch.
  inspect(
    read_all_error(bytes, limits=ReadLimits(max_entry_uncompressed_bytes=size)),
    content="SizeMismatch: zip: decoded size does not match central directory",
  )
}

///|
test "read_all classifies malformed DEFLATE payloads" {
  // A final stored block of "hello".
  let final_block = b"\x01\x05\x00\xfa\xffhello"
  // It decodes, so only the CRC (written over the raw payload) fails.
  inspect(
    read_all_error(raw_deflate_archive(final_block, 5)),
    content=(
      #|ChecksumMismatch: zip: CRC-32 mismatch
    ),
  )
  // The same block, not marked final: the stream never ends.
  inspect(
    read_all_error(raw_deflate_archive(b"\x00\x05\x00\xfa\xffhello", 5)),
    content="Truncated: zip: truncated DEFLATE payload",
  )
  // Bytes after the final block.
  inspect(
    read_all_error(raw_deflate_archive(final_block + b"XY", 5)),
    content="InvalidDeflate: zip: trailing bytes in compressed payload",
  )
  // A reserved block type.
  inspect(
    read_all_error(raw_deflate_archive(b"\x07\x00\x00\x00", 5)),
    content=(
      #|InvalidDeflate: corrupt: reserved block type
    ),
  )
  // A distance reaching before the start of the output.
  inspect(
    read_all_error(raw_deflate_archive(b"\x03\x02\x00", 5)),
    content=(
      #|InvalidDeflate: corrupt: distance too far back
    ),
  )
}

///|
test "read_all classifies a DEFLATE payload damaged mid-stream" {
  let size = 300_000
  let bytes = declared_size_archive(declared_size_payload(size))
  let (local_at, _) = declared_size_offsets(bytes, 1)
  let changed = bytes.to_fixedarray()
  // Inside the payload, which starts after the 30-byte header and name "x".
  let at = local_at + 31 + 2000
  changed[at] = changed[at] ^ b'\xFF'
  inspect(
    read_all_error(Bytes::from_array(changed)),
    content=(
      #|SizeMismatch: zip: decoded size does not match central directory
    ),
  )
}

///|
test "read_all raises Cancelled at every poll of a DEFLATE archive" {
  let bytes = declared_size_archive(declared_size_payload(100_000))
  let mut polls = 0
  ignore(
    @zip.read_all(bytes, cancelled=() => {
      polls += 1
      false
    }),
  )
  for target in 1..<=polls {
    let mut count = 0
    let err = @test.expect_error(() => {
      @zip.read_all(bytes, cancelled=() => {
        count += 1
        count >= target
      })
    })
    guard err is ZipError(Cancelled, _) else {
      @test.fail("poll \{target} of \{polls}: \{err}")
    }
  }
}
