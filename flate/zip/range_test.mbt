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
fn archive_range_source(bytes : Bytes) -> (@zip.ReadRange) -> BytesView {
  range => {
    let offset = range.offset().to_int()
    bytes[offset:offset + range.length()]
  }
}

///|
fn drive_directory_ranges(
  reader : @zip.DirectoryReader,
  source : (@zip.ReadRange) -> BytesView,
) -> @zip.Directory raise @zip.ZipError {
  for input = (b"" : BytesView) {
    match reader.advance(input) {
      NeedRead(range) => continue source(range)
      Done(directory) => break directory
    }
  }
}

///|
fn drive_entry_ranges(
  reader : @zip.EntryReader,
  source : (@zip.ReadRange) -> BytesView,
  output_size : Int32,
) -> Bytes raise @zip.ZipError {
  let output = FixedArray::make(output_size, b'\x00')
  let decoded = @buffer.Buffer()
  for input = (b"" : BytesView) {
    let status = reader.step(input, output)
    // NeedRead and Done may carry output too.
    decoded.write_bytes(Bytes::from_array(output[:reader.last_produced()]))
    match status {
      NeedRead(range) => continue source(range)
      NeedMoreOutput => continue b""
      Done => break decoded.to_bytes()
    }
  }
}

///|
test "range readers extract independent classic, ZIP64 and descriptor fixtures" {
  for
    (bytes, name, expected) in [
      (py_mini, "a.txt", b"hi"),
      (py_zip64, "big.bin", b"xxxxxxxx"),
      (py_descriptor, "desc.txt", b"descriptor entry payload"),
      (optional_zip64, "x", b"0123456789"),
    ] {
    let source = archive_range_source(bytes)
    let directory_reader = @zip.DirectoryReader(bytes.length().to_uint64())
    let directory = drive_directory_ranges(directory_reader, source)
    @test.assert_eq(directory.entries().length(), 1)
    let entry = directory.entries()[0]
    @test.assert_eq(entry.name(), name)
    @test.assert_eq(entry.crc32(), @checksum.crc32(expected))
    @test.assert_eq(entry.uncompressed_size(), expected.length().to_uint64())
    guard directory_reader.advance(b"") is Done(repeated) else {
      @test.fail("completed directory reader requested more input")
    }
    @test.assert_eq(repeated.entries()[0].name(), name)
    let reader = directory.open_entry(0)
    @test.assert_eq(drive_entry_ranges(reader, source, 1), expected)
    @test.assert_eq(reader.total_consumed(), entry.compressed_size())
    @test.assert_eq(reader.total_produced(), expected.length().to_uint64())
    assert_true(reader.step(b"", []) is Done)
    @test.assert_eq(reader.last_produced(), 0)
  }
}

///|
test "directory records spanning chunks retain duplicate-name entry identity" {
  let archive = @zip.Archive()
  // A maximum-length ZIP name makes its record larger than one permitted
  // directory response, independently of the reader's chosen chunk size.
  let long_name = String::make(65535, 'a')
  archive.add(long_name, b"", compression=Store)
  archive.add("same", b"first", compression=Store)
  archive.add("same", b"second", compression=Deflate)
  let bytes = @zip.write(archive)
  let source = archive_range_source(bytes)
  let central = zip_test_field(bytes, bytes.length() - 22 + 16, 4).to_uint64()
  let record_end = central + 46UL + long_name.length().to_uint64()
  let mut split_record = false
  let directory = drive_directory_ranges(
    DirectoryReader(bytes.length().to_uint64()),
    range => {
      let end = range.offset() + range.length().to_uint64()
      if end > central && end < record_end {
        split_record = true
      }
      source(range)
    },
  )
  assert_true(split_record)
  @test.assert_eq(directory.entries().length(), 3)
  @test.assert_eq(directory.entries()[0].name(), long_name)
  @test.assert_eq(directory.entries()[1].name(), "same")
  @test.assert_eq(directory.entries()[2].name(), "same")
  @test.assert_eq(
    drive_entry_ranges(directory.open_entry(1), source, 2),
    b"first",
  )
  @test.assert_eq(
    drive_entry_ranges(directory.open_entry(2), source, 2),
    b"second",
  )
}

///|
test "range protocol errors latch and empty output suspends extraction" {
  let source = archive_range_source(py_mini)
  let directory_reader = @zip.DirectoryReader(py_mini.length().to_uint64())
  guard directory_reader.advance(b"") is NeedRead(range) else {
    @test.fail("expected initial tail request")
  }
  let ZipError(kind, _) = @test.expect_error(() => directory_reader.advance(b""))
  @test.assert_eq(kind, InvalidRead)
  let ZipError(repeated, _) = @test.expect_error(() => {
    directory_reader.advance(source(range))
  })
  @test.assert_eq(repeated, kind)
  let directory = drive_directory_ranges(
    DirectoryReader(py_mini.length().to_uint64()),
    source,
  )
  let reader = directory.open_entry(0)
  guard reader.step(b"", []) is NeedRead(header) else {
    @test.fail("expected local-header request")
  }
  let ZipError(kind, _) = @test.expect_error(() => reader.step(b"", []))
  @test.assert_eq(kind, InvalidRead)
  let ZipError(repeated, _) = @test.expect_error(() => {
    reader.step(source(header), [])
  })
  @test.assert_eq(repeated, kind)
  @test.assert_eq(reader.last_produced(), 0)
  @test.assert_eq(reader.total_consumed(), 0UL)
  @test.assert_eq(reader.total_produced(), 0UL)

  let reader = directory.open_entry(0)
  for input = (b"" : BytesView) {
    match reader.step(input, []) {
      NeedRead(range) => continue source(range)
      NeedMoreOutput => break
      Done => @test.fail("empty output completed a nonempty payload")
    }
  }
  @test.assert_eq(reader.last_produced(), 0)
  @test.assert_eq(reader.total_consumed(), 0UL)
  @test.assert_eq(drive_entry_ranges(reader, source, 1), b"hi")
}

///|
test "range entry failures preserve CRC, descriptor and limit categories" {
  let archive = @zip.Archive()
  archive.add("x", b"0123456789", compression=Store)
  let original = @zip.write(archive)
  let changed = original.to_array()
  changed[31] = b'x' // first stored payload byte, after the one-byte name
  let damaged = Bytes::from_array(changed)
  let source = archive_range_source(damaged)
  let directory = drive_directory_ranges(
    DirectoryReader(damaged.length().to_uint64()),
    source,
  )
  let reader = directory.open_entry(0)
  let ZipError(kind, _) = @test.expect_error(() => {
    drive_entry_ranges(reader, source, 2)
  })
  @test.assert_eq(kind, ChecksumMismatch)
  @test.assert_eq(reader.last_produced(), 0)
  let ZipError(repeated, _) = @test.expect_error(() => {
    reader.step(b"unexpected", [])
  })
  @test.assert_eq(repeated, kind)
  @test.assert_eq(reader.last_produced(), 0)
  let ZipError(kind, _) = @test.expect_error(() => {
    directory.open_entry(0, limits=EntryReadLimits(max_output_bytes=9UL))
  })
  @test.assert_eq(kind, LimitExceeded(EntryUncompressedBytes, 9UL, 10UL))
  let ZipError(kind, _) = @test.expect_error(() => directory.open_entry(1))
  @test.assert_eq(kind, InvalidEntryIndex(1))

  let source = archive_range_source(py_descriptor)
  let directory = drive_directory_ranges(
    DirectoryReader(py_descriptor.length().to_uint64()),
    source,
  )
  // Python fixture: 30-byte local header, eight-byte name, no extra field.
  let descriptor = 38 + directory.entries()[0].compressed_size().to_int()
  let changed = py_descriptor.to_array()
  changed[descriptor + 4] = (changed[descriptor + 4].to_int() ^ 1).to_byte()
  let damaged = Bytes::from_array(changed)
  let source = archive_range_source(damaged)
  let directory = drive_directory_ranges(
    DirectoryReader(damaged.length().to_uint64()),
    source,
  )
  let reader = directory.open_entry(0)
  let ZipError(kind, _) = @test.expect_error(() => {
    drive_entry_ranges(reader, source, 3)
  })
  @test.assert_eq(kind, UnsupportedFeature)
  @test.assert_eq(reader.last_produced(), 0)
  let ZipError(repeated, _) = @test.expect_error(() => reader.step(b"", []))
  @test.assert_eq(repeated, kind)
}

///|
test "ZIP readers report observed per-entry and cumulative output limits" {
  let bytes = zip_with_underreported_size(Deflate)
  let cases : Array[(@zip.ReadLimits, @zip.LimitKind, UInt64, UInt64)] = [
    (
      ReadLimits(max_entry_uncompressed_bytes=5),
      EntryUncompressedBytes,
      5UL,
      10UL,
    ),
    (
      ReadLimits(max_total_uncompressed_bytes=10),
      TotalUncompressedBytes,
      10UL,
      15UL,
    ),
  ]
  for (limits, expected_kind, ceiling, full_size) in cases {
    let ZipError(kind, _) = @test.expect_error(() => @zip.read(bytes, limits~))
    guard kind is LimitExceeded(resource, limit, actual) else {
      @test.fail("expected a decoded-output limit error")
    }
    @test.assert_eq(resource, expected_kind)
    @test.assert_eq(limit, ceiling)
    // The observed batch may vary; the old limit-as-actual result must fail.
    assert_true(actual > limit && actual <= full_size)
  }
  let source = archive_range_source(bytes)
  let directory = drive_directory_ranges(
    DirectoryReader(bytes.length().to_uint64()),
    source,
  )
  let reader = directory.open_entry(
    1,
    limits=EntryReadLimits(max_output_bytes=5UL),
  )
  let ZipError(kind, _) = @test.expect_error(() => {
    drive_entry_ranges(reader, source, 16)
  })
  guard kind is LimitExceeded(EntryUncompressedBytes, 5UL, actual) else {
    @test.fail("expected the entry output limit")
  }
  assert_true(actual > 5UL && actual <= 10UL)
  @test.assert_eq(reader.last_produced(), 0)
  let ZipError(repeated, _) = @test.expect_error(() => reader.step(b"", []))
  @test.assert_eq(repeated, kind)
}

///|
test "ZIP64 range offsets exceed 4 GiB without allocating the archive" {
  let base = 0x1_0000_0000UL
  let changed = py_zip64.to_array()
  // Relocate the independent ZIP64 fixture behind a virtual zero prefix.
  // Patch the central extra's local offset, ZIP64 central offset, and locator.
  for (offset, value) in [(138, base), (194, base + 65UL), (210, base + 146UL)] {
    for i = 0; i < 8; i = i + 1 {
      changed[offset + i] = ((value >> (8 * i)) & 0xffUL).to_int().to_byte()
    }
  }
  let suffix = Bytes::from_array(changed)
  let archive_size = base + suffix.length().to_uint64()
  let requested : Array[UInt64] = []
  let source = (range : @zip.ReadRange) => {
    let start = range.offset()
    requested.push(start)
    let output = FixedArray::make(range.length(), b'\x00')
    let destination = if start < base { (base - start).to_int() } else { 0 }
    let offset = if start > base { (start - base).to_int() } else { 0 }
    if destination < output.length() {
      output.blit_from_bytes(
        destination,
        suffix,
        offset,
        output.length() - destination,
      )
    }
    (Bytes::from_array(output) : BytesView)
  }
  let directory = drive_directory_ranges(DirectoryReader(archive_size), source)
  @test.assert_eq(directory.entries()[0].name(), "big.bin")
  let reader = directory.open_entry(0)
  @test.assert_eq(drive_entry_ranges(reader, source, 3), b"xxxxxxxx")
  @test.assert_eq(reader.total_consumed(), 8UL)
  @test.assert_eq(reader.total_produced(), 8UL)
  assert_true(requested.any(offset => offset == base))
}

///|
// Little-endian fields in small classic ZIP test archives (all fit Int32).
fn zip_test_field(bytes : Bytes, offset : Int32, width : Int32) -> Int32 {
  for i = 0, value = 0 {
    guard i < width else { break value }
    continue i + 1, value | (bytes[offset + i].to_int() << (8 * i))
  }
}

///|
fn zip_with_underreported_size(
  compression : @zip.Compression,
) -> Bytes raise @zip.ZipError {
  let archive = @zip.Archive()
  archive.add("prefix", b"12345", compression=Store)
  archive.add("x", b"0123456789", compression~)
  let bytes = @zip.write(archive)
  let first = zip_test_field(bytes, bytes.length() - 22 + 16, 4)
  let second = first +
    46 +
    zip_test_field(bytes, first + 28, 2) +
    zip_test_field(bytes, first + 30, 2) +
    zip_test_field(bytes, first + 32, 2)
  let local_offset = zip_test_field(bytes, second + 42, 4)
  let changed = bytes.to_array()
  // Match the caller's limit so smaller decode batches cannot encounter a
  // declaration mismatch before exceeding that limit.
  changed[local_offset + 22] = b'\x05'
  changed[second + 24] = b'\x05'
  Bytes::from_array(changed)
}

///|
test "memory and range readers agree on decoded size mismatches" {
  for compression in [@zip.Compression::Store, Deflate] {
    let bytes = zip_with_underreported_size(compression)
    let source = archive_range_source(bytes)
    let directory = drive_directory_ranges(
      DirectoryReader(bytes.length().to_uint64()),
      source,
    )
    let ZipError(kind, _) = @test.expect_error(() => @zip.read(bytes))
    @test.assert_eq(kind, SizeMismatch)
    let ZipError(kind, _) = @test.expect_error(() => {
      drive_entry_ranges(directory.open_entry(1), source, 3)
    })
    @test.assert_eq(kind, SizeMismatch)
  }
}

///|
test "memory and range readers agree on local size mismatches" {
  for compression in [@zip.Compression::Store, Deflate] {
    let archive = @zip.Archive()
    archive.add("x", b"0123456789", compression~)
    let original = @zip.write(archive)
    let source = archive_range_source(original)
    let directory = drive_directory_ranges(
      DirectoryReader(original.length().to_uint64()),
      source,
    )
    @test.assert_eq(
      drive_entry_ranges(directory.open_entry(0), source, 3),
      b"0123456789",
    )
    let changed = original.to_array()
    changed[22] = b'\x04'
    let bytes = Bytes::from_array(changed)
    let source = archive_range_source(bytes)
    let directory = drive_directory_ranges(
      DirectoryReader(bytes.length().to_uint64()),
      source,
    )
    let ZipError(kind, _) = @test.expect_error(() => @zip.read(bytes))
    @test.assert_eq(kind, SizeMismatch)
    let ZipError(kind, _) = @test.expect_error(() => {
      drive_entry_ranges(directory.open_entry(0), source, 3)
    })
    @test.assert_eq(kind, SizeMismatch)
  }
}
