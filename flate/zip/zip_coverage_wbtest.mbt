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
/// Malformed records, numeric boundaries, and byte-preserving ZIP writes.

///|
fn expect_zip_error(f : () -> Unit raise ZipError) -> Unit raise {
  @test.assert_raise(f)
}

///|
fn expect_zip_kind(
  f : () -> Unit raise ZipError,
  expect : ZipErrorKind,
) -> Unit raise {
  let ZipError(kind, _) = @test.expect_error(f)
  @test.assert_eq(kind, expect)
}

///|
fn push_u16le(buf : Array[Byte], v : Int32) -> Unit {
  buf.push((v & 0xFF).to_byte())
  buf.push(((v >> 8) & 0xFF).to_byte())
}

///|
fn push_u32le(buf : Array[Byte], v : UInt32) -> Unit {
  for i in 0..<4 {
    buf.push(((v >> (i * 8)) & 0xFF).reinterpret_as_int().to_byte())
  }
}

///|
fn push_u64le(buf : Array[Byte], v : UInt64) -> Unit {
  for i in 0..<8 {
    buf.push(((v >> (i * 8)) & 0xFF).to_int().to_byte())
  }
}

///|
fn bytes_of(buf : Array[Byte]) -> Bytes {
  Bytes::from_array(buf)
}

///|
test "zip extra-field and zip64 helpers reject malformed fields" {
  expect_zip_error(() => ignore(extra_field_at(b"", 0)))
  expect_zip_error(() => ignore(extra_field_at(b"\x01\x00\x05\x00", 0)))
  expect_zip_error(() => ignore(read_zip64_extra(b"", true, false, false)))
  expect_zip_error(() => {
    ignore(
      read_zip64_extra(b"\x01\x00\x04\x00\x00\x00\x00\x00", true, false, false),
    )
  })
  let ok = read_zip64_extra(
    b"\x01\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00", false, false, true,
  )
  assert_true(ok.3 is Some(_))
}

///|
test "zip zip64 end record rejects malformed trailers" {
  // Locator declares a second disk.
  let locator_multi_disk = {
    let buf : Array[Byte] = []
    push_u32le(buf, ZIP64_LOCATOR_SIG)
    push_u32le(buf, 0)
    push_u64le(buf, 0)
    push_u32le(buf, 2)
    bytes_of(buf)
  }
  expect_zip_error(() => ignore(read_zip64_eocd(locator_multi_disk, 20)))
  // Locator points at the end record itself (no room for one).
  let out_of_bounds = {
    let buf : Array[Byte] = []
    push_u32le(buf, ZIP64_LOCATOR_SIG)
    push_u32le(buf, 0)
    push_u64le(buf, 0)
    push_u32le(buf, 1)
    bytes_of(buf)
  }
  expect_zip_error(() => ignore(read_zip64_eocd(out_of_bounds, 20)))
  // End record carries the wrong signature.
  let bad_sig = {
    let buf : Array[Byte] = []
    push_u32le(buf, LOCAL_HEADER_SIG)
    for _ in 0..<8 {
      buf.push(b'\x00')
    }
    push_u32le(buf, ZIP64_LOCATOR_SIG)
    push_u32le(buf, 0)
    push_u64le(buf, 0)
    push_u32le(buf, 1)
    bytes_of(buf)
  }
  expect_zip_error(() => ignore(read_zip64_eocd(bad_sig, 32)))
  // End record size does not reach the locator.
  let size_mismatch = {
    let buf : Array[Byte] = []
    push_u32le(buf, ZIP64_EOCD_SIG)
    push_u64le(buf, 44)
    push_u32le(buf, ZIP64_LOCATOR_SIG)
    push_u32le(buf, 0)
    push_u64le(buf, 0)
    push_u32le(buf, 1)
    bytes_of(buf)
  }
  expect_zip_error(() => ignore(read_zip64_eocd(size_mismatch, 32)))
  // End record claims a non-zero disk number.
  let multi_disk = {
    let buf : Array[Byte] = []
    push_u32le(buf, ZIP64_EOCD_SIG)
    push_u64le(buf, 44)
    push_u16le(buf, 45)
    push_u16le(buf, 45)
    push_u32le(buf, 1)
    push_u32le(buf, 0)
    push_u64le(buf, 1)
    push_u64le(buf, 1)
    push_u64le(buf, 0)
    push_u64le(buf, 0)
    push_u32le(buf, ZIP64_LOCATOR_SIG)
    push_u32le(buf, 0)
    push_u64le(buf, 0)
    push_u32le(buf, 1)
    bytes_of(buf)
  }
  expect_zip_error(() => ignore(read_zip64_eocd(multi_disk, 76)))
  // Locator missing entirely (before the archive start).
  expect_zip_error(() => ignore(read_zip64_eocd(b"", 0)))
}

///|
fn descriptor_meta(crc~ : UInt32) -> MemoryEntryMeta {
  {
    name: "",
    name_len: 0,
    flags: 0,
    method_id: 0,
    crc,
    compressed_size: 4,
    uncompressed_size: 4,
    local_offset: 0,
    central_record: b"",
    central_zip64_offset_position: None,
    data_descriptor: true,
  }
}

///|
test "zip data-descriptor sizing matches and rejects ambiguous or bad layouts" {
  // Unsigned descriptor (no signature prefix).
  let unsigned = {
    let buf : Array[Byte] = []
    push_u32le(buf, 0x11223344U)
    push_u32le(buf, 4)
    push_u32le(buf, 4)
    bytes_of(buf)
  }
  @test.assert_eq(
    data_descriptor_size(unsigned, 0, descriptor_meta(crc=0x11223344U), false),
    12,
  )
  // Signed descriptor.
  let signed = {
    let buf : Array[Byte] = []
    push_u32le(buf, DATA_DESCRIPTOR_SIG)
    push_u32le(buf, 0x11223344U)
    push_u32le(buf, 4)
    push_u32le(buf, 4)
    bytes_of(buf)
  }
  @test.assert_eq(
    data_descriptor_size(signed, 0, descriptor_meta(crc=0x11223344U), false),
    16,
  )
  // ZIP64-sized unsigned descriptor.
  let zip64 = {
    let buf : Array[Byte] = []
    push_u32le(buf, 0x11223344U)
    push_u64le(buf, 4)
    push_u64le(buf, 4)
    bytes_of(buf)
  }
  @test.assert_eq(
    data_descriptor_size(zip64, 0, descriptor_meta(crc=0x11223344U), true),
    20,
  )
  // A truncated descriptor raises inside the matcher and is rejected.
  let truncated = {
    let buf : Array[Byte] = []
    push_u32le(buf, 0x11223344U)
    bytes_of(buf)
  }
  expect_zip_kind(
    () => {
      ignore(
        data_descriptor_size(
          truncated,
          0,
          descriptor_meta(crc=0x11223344U),
          false,
        ),
      )
    },
    UnsupportedFeature,
  )
  // When CRC, sizes, and signature all share one value, both layouts match.
  let sig_int = DATA_DESCRIPTOR_SIG.reinterpret_as_int()
  let ambiguous_meta : MemoryEntryMeta = {
    name: "",
    name_len: 0,
    flags: 0,
    method_id: 0,
    crc: DATA_DESCRIPTOR_SIG,
    compressed_size: sig_int,
    uncompressed_size: sig_int,
    local_offset: 0,
    central_record: b"",
    central_zip64_offset_position: None,
    data_descriptor: true,
  }
  let ambiguous = {
    let buf : Array[Byte] = []
    for _ in 0..<4 {
      push_u32le(buf, DATA_DESCRIPTOR_SIG)
    }
    bytes_of(buf)
  }
  expect_zip_kind(
    () => ignore(data_descriptor_size(ambiguous, 0, ambiguous_meta, false)),
    UnsupportedFeature,
  )
}

///|
fn local_record(
  flags : Int32,
  method_id : Int32,
  crc : UInt32,
  comp_size : Int32,
  uncomp_size : Int32,
  name : Bytes,
  extra : Bytes,
  payload : Bytes,
  descriptor : Bytes,
) -> Bytes {
  let buf : Array[Byte] = []
  push_u32le(buf, LOCAL_HEADER_SIG)
  push_u16le(buf, 20)
  push_u16le(buf, flags)
  push_u16le(buf, method_id)
  push_u16le(buf, 0)
  push_u16le(buf, 0)
  push_u32le(buf, crc)
  push_u32le(buf, comp_size.reinterpret_as_uint())
  push_u32le(buf, uncomp_size.reinterpret_as_uint())
  push_u16le(buf, name.length())
  push_u16le(buf, extra.length())
  for b in name {
    buf.push(b)
  }
  for b in extra {
    buf.push(b)
  }
  for b in payload {
    buf.push(b)
  }
  for b in descriptor {
    buf.push(b)
  }
  bytes_of(buf)
}

///|
fn base_meta() -> MemoryEntryMeta {
  {
    name: "a.txt",
    name_len: 5,
    flags: 0,
    method_id: 0,
    crc: 0x11111111U,
    compressed_size: 3,
    uncompressed_size: 3,
    local_offset: 0,
    central_record: central_record(0, 0, 0, 0x11111111U, 3, 3, b"a.txt", b"", 0),
    central_zip64_offset_position: None,
    data_descriptor: false,
  }
}

///|
test "zip local-record validation rejects each mismatch" {
  let valid = local_record(0, 0, 0x11111111U, 3, 3, b"a.txt", b"", b"abc", b"")
  let record = read_local_record(valid, base_meta(), valid.length())
  @test.assert_eq(record.compressed, b"abc")
  @test.assert_eq(record.end, valid.length())
  for
    invalid in [
      local_record(0x0800, 0, 0x11111111U, 3, 3, b"a.txt", b"", b"abc", b""),
      local_record(0, 8, 0x11111111U, 3, 3, b"a.txt", b"", b"abc", b""),
      local_record(0, 0, 0x11111111U, 3, 3, b"b.txt", b"", b"abc", b""),
      local_record(0, 0, 0x22222222U, 3, 3, b"a.txt", b"", b"abc", b""),
    ] {
    expect_zip_kind(
      () => ignore(read_local_record(invalid, base_meta(), invalid.length())),
      UnsupportedFeature,
    )
  }
  let wrong_size = local_record(
    0, 0, 0x11111111U, 5, 5, b"a.txt", b"", b"abcde", b"",
  )
  expect_zip_kind(
    () => {
      ignore(read_local_record(wrong_size, base_meta(), wrong_size.length()))
    },
    SizeMismatch,
  )
  expect_zip_kind(
    () => {
      ignore(
        read_local_record(valid, { ..base_meta(), local_offset: 100, }, 50),
      )
    },
    Truncated,
  )
  expect_zip_kind(
    () => ignore(read_local_record(valid, base_meta(), valid.length() - 1)),
    Truncated,
  )
  // Validate a complete descriptor first. Its name metadata must match the
  // local name so the truncated version reaches the descriptor-boundary check.
  let descriptor : Array[Byte] = []
  push_u32le(descriptor, 0x11111111U)
  push_u32le(descriptor, 1)
  push_u32le(descriptor, 1)
  let framed = local_record(
    8,
    0,
    0,
    1,
    1,
    b"a.txt",
    b"",
    b"x",
    bytes_of(descriptor),
  )
  let meta = {
    ..base_meta(),
    flags: 8,
    compressed_size: 1,
    uncompressed_size: 1,
    data_descriptor: true,
  }
  @test.assert_eq(
    read_local_record(framed, meta, framed.length()).end,
    framed.length(),
  )
  expect_zip_kind(
    () => ignore(read_local_record(framed, meta, framed.length() - 1)),
    Truncated,
  )
}

///|
test "ZIP entry decoding rejects corrupt, truncated and trailing input" {
  expect_zip_kind(
    () => {
      ignore(
        inflate_entry(
          b"garbage deflate stream",
          100,
          EntryUncompressedBytes,
          100,
          () => false,
        ),
      )
    },
    InvalidDeflate,
  )
  let comp = @flate.deflate_all(b"0123456789")
  @test.assert_eq(
    inflate_entry(comp, 10, EntryUncompressedBytes, 10, () => false),
    b"0123456789",
  )
  expect_zip_kind(
    () => {
      ignore(
        inflate_entry(comp + b"tail", 10, EntryUncompressedBytes, 10, () => {
          false
        }),
      )
    },
    InvalidDeflate,
  )
  expect_zip_kind(
    () => {
      ignore(inflate_entry(b"", 10, EntryUncompressedBytes, 10, () => false))
    },
    Truncated,
  )
}

///|
test "ZIP entry decoding honors entry and deferred cancellation" {
  let compressed = @flate.deflate_all(Bytes::make(20000, b'x'))
  // Invalid input distinguishes entry cancellation from decoder failure.
  // The valid stream exercises a cancellation request after the initial poll.
  for (input, initially_cancelled) in [(b"\xff", true), (compressed, false)] {
    let mut requested = initially_cancelled
    expect_zip_kind(
      () => {
        ignore(
          inflate_entry(input, 20000, EntryUncompressedBytes, 20000, () => {
            let cancel = requested
            requested = true
            cancel
          }),
        )
      },
      Cancelled,
    )
  }
}

///|
fn classic_eocd(
  disk_no : Int32,
  disk_start : Int32,
  disk_entries : Int32,
  total_entries : Int32,
  central_size : Int32,
  central_offset : Int32,
) -> Bytes {
  let buf : Array[Byte] = []
  push_u32le(buf, END_OF_CENTRAL_SIG)
  push_u16le(buf, disk_no)
  push_u16le(buf, disk_start)
  push_u16le(buf, disk_entries)
  push_u16le(buf, total_entries)
  push_u32le(buf, central_size.reinterpret_as_uint())
  push_u32le(buf, central_offset.reinterpret_as_uint())
  push_u16le(buf, 0)
  bytes_of(buf)
}

///|
fn zip64_trailer(
  zip_entries : UInt64,
  zip_size : UInt64,
  zip_offset : UInt64,
  classic_disk_entries : Int32,
  classic_total_entries : Int32,
  classic_size_raw : UInt32,
  classic_offset_raw : UInt32,
) -> Bytes {
  let buf : Array[Byte] = []
  push_u32le(buf, ZIP64_EOCD_SIG)
  push_u64le(buf, 44)
  push_u16le(buf, 45)
  push_u16le(buf, 45)
  push_u32le(buf, 0)
  push_u32le(buf, 0)
  push_u64le(buf, zip_entries)
  push_u64le(buf, zip_entries)
  push_u64le(buf, zip_size)
  push_u64le(buf, zip_offset)
  push_u32le(buf, ZIP64_LOCATOR_SIG)
  push_u32le(buf, 0)
  push_u64le(buf, 0)
  push_u32le(buf, 1)
  push_u32le(buf, END_OF_CENTRAL_SIG)
  push_u16le(buf, 0)
  push_u16le(buf, 0)
  push_u16le(buf, classic_disk_entries)
  push_u16le(buf, classic_total_entries)
  push_u32le(buf, classic_size_raw)
  push_u32le(buf, classic_offset_raw)
  push_u16le(buf, 0)
  bytes_of(buf)
}

///|
test "zip end-of-central parsing rejects inconsistent trailers" {
  let default_limits = ReadLimits()
  // Multi-disk classic EOCD.
  expect_zip_error(() => {
    ignore(
      parse_end_of_central(classic_eocd(1, 0, 0, 0, 0, 0), default_limits, () => {
        false
      }),
    )
  })
  // Classic entry-count mismatch.
  expect_zip_error(() => {
    ignore(
      parse_end_of_central(classic_eocd(0, 0, 2, 1, 0, 0), default_limits, () => {
        false
      }),
    )
  })
  // Central directory does not fill the declared bounds.
  expect_zip_error(() => {
    ignore(
      parse_end_of_central(classic_eocd(0, 0, 1, 1, 5, 0), default_limits, () => {
        false
      }),
    )
  })
  // Classic disk-entries disagree with the zip64 count.
  expect_zip_error(() => {
    ignore(
      parse_end_of_central(
        zip64_trailer(5, 0, 0, 0, 0xFFFF, 0, 0),
        default_limits,
        () => false,
      ),
    )
  })
  // Classic total-entries disagree with the zip64 count.
  expect_zip_error(() => {
    ignore(
      parse_end_of_central(
        zip64_trailer(5, 0, 0, 0xFFFF, 0, 0, 0),
        default_limits,
        () => false,
      ),
    )
  })
  // Classic central size disagrees with the zip64 size.
  expect_zip_error(() => {
    ignore(
      parse_end_of_central(
        zip64_trailer(5, 100, 0, 0xFFFF, 0xFFFF, 0, 0),
        default_limits,
        () => false,
      ),
    )
  })
  // Classic central offset disagrees with the zip64 offset.
  expect_zip_error(() => {
    ignore(
      parse_end_of_central(
        zip64_trailer(5, 100, 200, 0xFFFF, 0xFFFF, 0xFFFFFFFF, 0),
        default_limits,
        () => false,
      ),
    )
  })
  // Fully sentinel classic fields resolve through the zip64 record.
  let eocd = parse_end_of_central(
    zip64_trailer(3, 0, 0, 0xFFFF, 0xFFFF, 0xFFFFFFFF, 0xFFFFFFFF),
    default_limits,
    () => false,
  )
  @test.assert_eq(eocd.entry_count, 3)
  @test.assert_eq(eocd.central_size, 0)
  @test.assert_eq(eocd.central_offset, 0)
  // Classic fields that mirror the zip64 values still resolve through the
  // zip64 record (only the disk count is sentinel to select the zip64 path).
  let eocd2 = parse_end_of_central(
    zip64_trailer(5, 0, 0, 0xFFFF, 5, 0, 0),
    default_limits,
    () => false,
  )
  @test.assert_eq(eocd2.entry_count, 5)
  @test.assert_eq(eocd2.central_size, 0)
  @test.assert_eq(eocd2.central_offset, 0)
}

///|
fn central_record(
  disk : Int32,
  flags : Int32,
  method_id : Int32,
  crc : UInt32,
  comp_size : Int32,
  uncomp_size : Int32,
  name : Bytes,
  extra : Bytes,
  local_offset : Int32,
) -> Bytes {
  let buf : Array[Byte] = []
  push_u32le(buf, CENTRAL_HEADER_SIG)
  push_u16le(buf, 20)
  push_u16le(buf, 20)
  push_u16le(buf, flags)
  push_u16le(buf, method_id)
  push_u16le(buf, 0)
  push_u16le(buf, 0)
  push_u32le(buf, crc)
  push_u32le(buf, comp_size.reinterpret_as_uint())
  push_u32le(buf, uncomp_size.reinterpret_as_uint())
  push_u16le(buf, name.length())
  push_u16le(buf, extra.length())
  push_u16le(buf, 0)
  push_u16le(buf, disk)
  push_u16le(buf, 0)
  push_u32le(buf, 0)
  push_u32le(buf, local_offset.reinterpret_as_uint())
  for b in name {
    buf.push(b)
  }
  for b in extra {
    buf.push(b)
  }
  bytes_of(buf)
}

///|
fn eocd_for(
  entry_count : Int32,
  central_size : Int32,
  central_len : Int32,
) -> EndOfCentral {
  {
    eocd_offset: central_len,
    entry_count,
    central_size,
    central_offset: 0,
    central_boundary: central_len,
    zip64_eocd_offset: None,
    comment: b"",
  }
}

///|
test "zip central-directory parsing rejects malformed records" {
  let valid = central_record(0, 0, 0, 0x11111111U, 3, 3, b"a.txt", b"", 0)
  let limits = ReadLimits()
  let eocd = eocd_for(1, valid.length(), valid.length())
  let parsed = parse_central_directory(valid, eocd, limits, () => false)
  @test.assert_eq(parsed.length(), 1)
  @test.assert_eq(parsed[0].name, "a.txt")
  let wrong_signature = valid.to_fixedarray()
  wrong_signature[0] = b'\x00'
  expect_zip_kind(
    () => {
      ignore(
        parse_central_directory(
          Bytes::from_array(wrong_signature),
          eocd,
          limits,
          () => false,
        ),
      )
    },
    InvalidSignature,
  )
  let max_int = MAX_U32.reinterpret_as_int()
  for
    invalid in [
      central_record(1, 0, 0, 0x11111111U, 3, 3, b"a.txt", b"", 0),
      central_record(0, 0, 0, 0x11111111U, 3, max_int, b"a.txt", b"", 0),
      central_record(0, 0, 0, 0x11111111U, max_int, 3, b"a.txt", b"", 0),
      central_record(0, 0, 0, 0x11111111U, 3, 3, b"a.txt", b"", max_int),
    ] {
    expect_zip_kind(
      () => ignore(parse_central_directory(invalid, eocd, limits, () => false)),
      UnsupportedFeature,
    )
  }
  expect_zip_kind(
    () => {
      ignore(
        parse_central_directory(
          valid,
          eocd_for(1, valid.length() + 3, valid.length()),
          limits,
          () => false,
        ),
      )
    },
    UnsupportedFeature,
  )
}

///|
test "zip classic trailer rejects too many entries and long comments" {
  let out = Output::writing(None)
  expect_zip_error(() => {
    out.write_generated_classic_end_record(false, 70000, 0, 0, b"")
  })
  let long_comment = Bytes::from_array(Array::make(70000, b'x'))
  expect_zip_error(() => {
    out.write_generated_classic_end_record(false, 1, 0, 0, long_comment)
  })
}

///|
test "zip entry names and output limits are checked" {
  let long_name = String::make(70000, 'x')
  let archive = Archive()
  archive.add(long_name, b"")
  expect_zip_error(() => ignore(write(archive)))
  let small = Archive()
  small.add("a.txt", b"x")
  expect_zip_kind(
    () => ignore(write(small, max_output_bytes=-1)),
    InvalidArgument,
  )
  expect_zip_kind(
    () => ignore(write(small, max_output_bytes=-1, preserve=true)),
    InvalidArgument,
  )
  expect_zip_kind(
    () => ignore(read(write(small), limits=ReadLimits(max_entries=-1))),
    InvalidArgument,
  )
  @test.assert_eq(
    write(small, max_output_bytes=1000, preserve=true),
    write(small),
  )
}

///|
test "zip owned copy handles chunk boundaries and cancellation" {
  for length in [0, 1, 65535, 65536, 65537, 131073] {
    let source = Bytes::makei(length + 2, i => (i % 251).to_byte())
    let mut polls = 0
    let copied = copy_cancellable(source[1:length + 1], () => {
      polls += 1
      false
    })
    @test.assert_eq(copied, source[1:length + 1].to_owned())
    let expected_polls = 2 + (length + 65535) / 65536
    @test.assert_eq(polls, expected_polls)
    for cancel_at in 1..<(expected_polls + 1) {
      let mut calls = 0
      expect_zip_kind(
        () => {
          ignore(
            copy_cancellable(source[1:length + 1], () => {
              calls += 1
              calls == cancel_at
            }),
          )
        },
        Cancelled,
      )
      @test.assert_eq(calls, cancel_at)
    }
  }
}

///|
test "zip output writes unaligned fields and transfers only written bytes" {
  let expected = b"\xff\x34\x12\x78\x56\x34\x12\x08\x07\x06\x05\x04\x03\x02\x01"
  for capacity in [0, 1, 15, 64] {
    let out = Output::writing(Some(15), size_hint=capacity)
    out.write_bytes(b"\xff")
    out.write_u16(0x1234)
    out.write_u32(0x12345678)
    out.write_u64(0x0102030405060708)
    expect_zip_kind(
      () => out.write_bytes(b"x"),
      LimitExceeded(OutputBytes, 15, 16),
    )
    @test.assert_eq(out.finish(), expected)
  }
}

///|
test "zip matching raw names preserve empty and Unicode names" {
  for name in ["", "a.txt", "目录/🙂.txt", "é.txt", "é.txt"] {
    let archive = Archive()
    archive.add(name, b"payload", compression=Store)
    let encoded = write(archive)
    let decoded = read(encoded)
    @test.assert_eq(decoded.entries()[0].name(), name)
    @test.assert_eq(decoded.entries()[0].data().to_owned(), b"payload")
    @test.assert_eq(write(decoded, preserve=true), encoded)
  }
}

///|
test "zip local name mismatch preserves UTF-8 error classification" {
  for name in [b"b.txt", b"a", b"a.txtx", b"", b"\xc3\xa9.txt"] {
    let local_bytes = local_record(
      0, 0, 0x11111111U, 3, 3, name, b"", b"abc", b"",
    )
    expect_zip_kind(
      () => {
        ignore(
          read_local_record(local_bytes, base_meta(), local_bytes.length()),
        )
      },
      UnsupportedFeature,
    )
  }
  for name in [b"\xff.txt", b"\xc0\xaf", b"\xed\xa0\x80", b"\xe2\x82"] {
    let local_bytes = local_record(
      0, 0, 0x11111111U, 3, 3, name, b"", b"abc", b"",
    )
    expect_zip_kind(
      () => {
        ignore(
          read_local_record(local_bytes, base_meta(), local_bytes.length()),
        )
      },
      InvalidUtf8,
    )
    // Even identical invalid raw names must fail central-directory decoding.
    let central = central_record(0, 0, 0, 0x11111111U, 3, 3, name, b"", 0)
    expect_zip_kind(
      () => ignore(parse_central_record(central, Cursor(central, 0))),
      InvalidUtf8,
    )
  }
}

///|
test "zip output rejects Int overflow and oversized raw header names" {
  let counting = Output::counting(None)
  counting.count(0x7fff_ffff)
  expect_zip_kind(() => counting.count(1), UnsupportedFeature)
  let archive = Archive()
  archive.add("a", b"", compression=Store)
  let entry = archive.entries()[0]
  let long_name = Bytes::make(65536, b'x')
  expect_zip_kind(
    () => {
      Output::writing(None).write_local_record(
        entry,
        long_name,
        { compressed_size: 0, compressed: None, },
        false,
        false,
      )
    },
    UnsupportedFeature,
  )
  expect_zip_kind(
    () => {
      Output::writing(None).write_central_record(
        entry, long_name, 0, 0, false, false,
      )
    },
    UnsupportedFeature,
  )
  expect_zip_kind(
    () => ignore(write(archive, max_output_bytes=1)),
    LimitExceeded(OutputBytes, 1, 31),
  )
}

///|
test "zip local order sorts source offsets and keeps new entries stable" {
  let archive = Archive()
  for i in 0..<32 {
    archive.add("entry-\{i}", b"", compression=Store)
    if i % 3 == 0 {
      archive.entries[i] = {
        ..archive.entries[i],
        origin_local_offset: Some((31 - i) * 10),
      }
    }
  }
  let order = archive.local_order()
  for i in 0..<11 {
    @test.assert_eq(order[i], 30 - i * 3)
  }
  let mut next = 11
  for i in 0..<32 {
    if i % 3 != 0 {
      @test.assert_eq(order[next], i)
      next += 1
    }
  }
}

///|
test "ZIP64 sizing agrees with emitted headers and descriptors" {
  let archive = Archive()
  archive.add("a", b"", compression=Store)
  let entry = archive.entries()[0]
  let counting = Output::counting(None)
  let output = Output::writing(None)
  for out in [counting, output] {
    out.write_local_record(
      entry,
      b"a",
      { compressed_size: 0, compressed: None, },
      true,
      true,
    )
    out.write_central_record(entry, b"a", 0, 0, true, true)
  }
  let bytes = output.finish()
  @test.assert_eq(counting.size, bytes.length())
  @test.assert_eq(bytes.length(), 150)
  @test.assert_eq(read_u32_le_at_raw(bytes, 51), DATA_DESCRIPTOR_SIG)
  @test.assert_eq(read_u32_le_at_raw(bytes, 75), CENTRAL_HEADER_SIG)
  @test.assert_eq(read_u16_le_at(bytes, 105), 28)
}

///|
/// Moved from the checksum package: cancellation belongs to the ZIP driver.
test "CRC-32 computation honours ZIP cancellation" {
  inspect(crc32_cancellable(b"", cancelled=() => false), content="0")
  let data = Bytes::make(16 * 1024, b'x')
  @test.assert_eq(
    crc32_cancellable(data, cancelled=() => false),
    @checksum.crc32(data),
  )
  let mut polls = 0
  let ZipError(kind, _) = @test.expect_error(() => {
    crc32_cancellable(data, cancelled=() => {
      polls += 1
      polls >= 4
    })
  })
  @test.assert_eq(kind, Cancelled)
  assert_true(polls >= 4)
}
