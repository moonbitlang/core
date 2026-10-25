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
/// Tail lookup includes the largest classic EOCD and its 16-bit comment.
const DIRECTORY_TAIL_SIZE : Int32 = 65557

///|
const DIRECTORY_CHUNK_SIZE : Int32 = 65536

///|
priv struct ClassicDirectoryEnd {
  offset : UInt64
  disk_entries : Int32
  entries : Int32
  central_size : UInt32
  central_offset : UInt32
  comment : Bytes
}

///|
priv struct DirectoryBounds {
  offset : UInt64
  size : UInt64
  entries : UInt64
  comment : Bytes
}

///|
priv enum DirectoryPhase {
  Initial
  Tail(ReadRange)
  Locator(ClassicDirectoryEnd)
  Zip64(ClassicDirectoryEnd, UInt64)
  Records(DirectoryBounds, UInt64)
  Complete(Directory)
  Failed(ZipErrorKind, String)
}

///|
/// Metadata-only ZIP reader driven by caller-supplied byte ranges. Supports
/// classic ZIP and ZIP64 beyond 2 GiB without retaining the archive or inflating
/// payloads. Retains owned metadata plus a bounded incomplete directory record.
/// File reads, HTTP requests, source consistency, and cancellation between
/// calls belong to the caller. No I/O callback is retained or invoked.
struct DirectoryReader {
  archive_size : UInt64
  limits : DirectoryLimits
  mut phase : DirectoryPhase
  mut entries : Array[DirectoryEntry]
  mut pending : Bytes
}

///|
/// Start reading an archive of the supplied total byte size. No bytes are read
/// until the caller drives `advance` and fulfills the returned ranges.
pub fn DirectoryReader::DirectoryReader(
  archive_size : UInt64,
  limits~ : DirectoryLimits = DirectoryLimits(),
) -> DirectoryReader {
  { archive_size, limits, phase: Initial, entries: [], pending: b"", }
}

///|
/// Initially supply empty input; thereafter supply exactly the bytes requested
/// by the preceding `NeedRead`. Accumulate transport short reads before calling.
/// All ranges must refer to the same immutable archive. Input is borrowed only
/// for this call; retained metadata and incomplete records are copied.
/// Requests are at most 65,557 bytes, and directory chunks at most 64 KiB.
/// `Done` validates directory structure and referenced bounds, not local headers
/// or payload integrity. Empty calls after completion return the same listing.
/// Any error is latched and rethrown on subsequent calls.
pub fn DirectoryReader::advance(
  self : DirectoryReader,
  input : BytesView,
) -> DirectoryStep raise ZipError {
  if self.phase is Failed(kind, message) {
    raise ZipError(kind, message)
  }
  self.advance_active(input) catch {
    ZipError(kind, message) => {
      self.phase = Failed(kind, message)
      self.entries = []
      self.pending = b""
      raise ZipError(kind, message)
    }
  }
}

///|
fn expect_range_input(input : BytesView, length : Int32) -> Unit raise ZipError {
  guard input.length() == length else {
    raise ZipError(
      InvalidRead,
      "zip: response length differs from requested range",
    )
  }
}

///|
fn range_read_length(remaining : UInt64, maximum : Int32) -> Int32 {
  if remaining < maximum.to_uint64() {
    remaining.to_int()
  } else {
    maximum
  }
}

///|
fn check_directory_limit(
  kind : LimitKind,
  limit : UInt64,
  actual : UInt64,
) -> Unit raise ZipError {
  guard actual <= limit else {
    raise ZipError(
      LimitExceeded(kind, limit, actual),
      "zip: directory limit exceeded",
    )
  }
}

///|
fn DirectoryReader::advance_active(
  self : DirectoryReader,
  input : BytesView,
) -> DirectoryStep raise ZipError {
  match self.phase {
    Initial => {
      expect_range_input(input, 0)
      guard self.archive_size >= 22UL else {
        raise ZipError(
          MissingEndOfCentral,
          "zip: end of central directory not found",
        )
      }
      let length = range_read_length(self.archive_size, DIRECTORY_TAIL_SIZE)
      let range = { offset: self.archive_size - length.to_uint64(), length, }
      self.phase = Tail(range)
      NeedRead(range)
    }
    Tail(range) => {
      expect_range_input(input, range.length)
      guard find_end_of_central(input) is Some(position) else {
        raise ZipError(
          MissingEndOfCentral,
          "zip: end of central directory not found",
        )
      }
      let reader = Cursor(input, position + 4)
      let disk = reader.read_u16()
      let central_disk = reader.read_u16()
      let disk_entries = reader.read_u16()
      let entries = reader.read_u16()
      let central_size = reader.read_u32_raw()
      let central_offset = reader.read_u32_raw()
      let comment_size = reader.read_u16()
      guard disk == 0 && central_disk == 0 else {
        raise ZipError(
          UnsupportedFeature,
          "zip: multi-disk archives are not supported",
        )
      }
      let classic = {
        offset: range.offset + position.to_uint64(),
        disk_entries,
        entries,
        central_size,
        central_offset,
        comment: reader.read_bytes(comment_size).to_owned(),
      }
      // ZIP64 records may also be present when every classic field fits.
      let zip64 = disk_entries == 0xffff ||
        entries == 0xffff ||
        central_size == MAX_U32 ||
        central_offset == MAX_U32 ||
        UInt64::extend_uint(central_offset) + UInt64::extend_uint(central_size) !=
        classic.offset
      guard !zip64 else {
        guard classic.offset >= 20UL else {
          raise ZipError(Truncated, "zip: zip64 locator out of bounds")
        }
        self.phase = Locator(classic)
        return NeedRead({ offset: classic.offset - 20UL, length: 20, })
      }
      guard disk_entries == entries else {
        raise ZipError(
          UnsupportedFeature,
          "zip: multi-disk archives are not supported",
        )
      }
      self.begin_records(
        UInt64::extend_uint(central_offset),
        UInt64::extend_uint(central_size),
        entries.to_uint64(),
        classic.offset,
        classic.comment,
      )
    }
    Locator(classic) => {
      expect_range_input(input, 20)
      let reader = Cursor(input, 0)
      guard reader.read_u32_raw() == ZIP64_LOCATOR_SIG else {
        raise ZipError(InvalidSignature, "zip: invalid zip64 locator signature")
      }
      let disk = reader.read_u32_raw()
      let offset = reader.read_u64_raw()
      let disks = reader.read_u32_raw()
      guard disk == 0 && disks == 1 else {
        raise ZipError(
          UnsupportedFeature,
          "zip: multi-disk archives are not supported",
        )
      }
      let locator = classic.offset - 20UL
      guard offset <= locator && 56UL <= locator - offset else {
        raise ZipError(Truncated, "zip: zip64 end record out of bounds")
      }
      self.phase = Zip64(classic, offset)
      NeedRead({ offset, length: 56, })
    }
    Zip64(classic, offset) => {
      expect_range_input(input, 56)
      let reader = Cursor(input, 0)
      guard reader.read_u32_raw() == ZIP64_EOCD_SIG else {
        raise ZipError(
          InvalidSignature,
          "zip: invalid zip64 end record signature",
        )
      }
      let record_size = reader.read_u64_raw()
      guard record_size == classic.offset - 20UL - offset - 12UL else {
        raise ZipError(
          UnsupportedFeature,
          "zip: zip64 end record size mismatch",
        )
      }
      ignore(reader.read_u16())
      ignore(reader.read_u16())
      let disk = reader.read_u32_raw()
      let central_disk = reader.read_u32_raw()
      let disk_entries = reader.read_u64_raw()
      let entries = reader.read_u64_raw()
      let central_size = reader.read_u64_raw()
      let central_offset = reader.read_u64_raw()
      guard disk == 0 && central_disk == 0 && disk_entries == entries else {
        raise ZipError(
          UnsupportedFeature,
          "zip: multi-disk archives are not supported",
        )
      }
      guard (
          classic.disk_entries == 0xffff ||
          classic.disk_entries.to_uint64() == entries
        ) &&
        (classic.entries == 0xffff || classic.entries.to_uint64() == entries) &&
        (
          classic.central_size == MAX_U32 ||
          UInt64::extend_uint(classic.central_size) == central_size
        ) &&
        (
          classic.central_offset == MAX_U32 ||
          UInt64::extend_uint(classic.central_offset) == central_offset
        ) else {
        raise ZipError(
          UnsupportedFeature,
          "zip: classic and zip64 directory fields differ",
        )
      }
      self.begin_records(
        central_offset,
        central_size,
        entries,
        offset,
        classic.comment,
      )
    }
    Records(bounds, offset) => {
      let end = bounds.offset + bounds.size
      let length = range_read_length(end - offset, DIRECTORY_CHUNK_SIZE)
      expect_range_input(input, length)
      let bytes : BytesView = if self.pending.length() == 0 {
        input
      } else {
        self.pending + input.to_owned()
      }
      let mut position = 0
      while self.entries.length().to_uint64() < bounds.entries &&
            bytes.length() - position >= 46 {
        let name_size = read_u16_le_at(bytes, position + 28)
        let extra_size = read_u16_le_at(bytes, position + 30)
        let comment_size = read_u16_le_at(bytes, position + 32)
        let record_size = 46 + name_size + extra_size + comment_size
        guard record_size <= bytes.length() - position else { break }
        let parsed = parse_directory_record(
          Cursor(bytes[position:position + record_size], 0),
        )
        let entry = parsed.entry
        // Local variable-length headers are deferred; their fixed prefix and
        // declared payload must at least fit before the central directory.
        guard entry.local_offset <= bounds.offset &&
          30UL <= bounds.offset - entry.local_offset &&
          entry.compressed_size <= bounds.offset - entry.local_offset - 30UL else {
          raise ZipError(
            Truncated,
            "zip: local record or payload out of bounds",
          )
        }
        self.entries.push(entry)
        position += record_size
      }
      let next = offset + length.to_uint64()
      let entries_done = self.entries.length().to_uint64() == bounds.entries
      if entries_done {
        validate_directory_signature(
          bytes[position:],
          end - next + (bytes.length() - position).to_uint64(),
        )
      }
      if next == end {
        guard entries_done else {
          raise ZipError(
            UnsupportedFeature,
            "zip: central directory size/count mismatch",
          )
        }
        self.complete(bounds.comment, bounds.offset)
      } else {
        self.pending = copy_zip_input(bytes[position:])
        self.phase = Records(bounds, next)
        NeedRead({
          offset: next,
          length: range_read_length(end - next, DIRECTORY_CHUNK_SIZE),
        })
      }
    }
    Complete(directory) => {
      expect_range_input(input, 0)
      Done(directory)
    }
    Failed(kind, message) => raise ZipError(kind, message)
  }
}

///|
/// The central directory may end with one digital-signature record. Validate
/// its framing only, not the signature itself. `remaining` includes bytes in
/// this chunk and later chunks; the 16-bit size bounds retained input even when
/// the header straddles reads or an untrusted directory declares a huge tail.
fn validate_directory_signature(
  bytes : BytesView,
  remaining : UInt64,
) -> Unit raise ZipError {
  guard remaining != 0UL else { return }
  guard remaining >= 6UL && remaining <= 65541UL else {
    raise ZipError(UnsupportedFeature, "zip: invalid directory signature size")
  }
  if bytes.length() >= 4 {
    guard read_u32_le_at_raw(bytes, 0) == DIRECTORY_SIGNATURE_SIG else {
      raise ZipError(InvalidSignature, "zip: invalid directory signature")
    }
  }
  if bytes.length() >= 6 {
    guard 6UL + read_u16_le_at(bytes, 4).to_uint64() == remaining else {
      raise ZipError(
        UnsupportedFeature,
        "zip: directory signature size mismatch",
      )
    }
  }
}

///|
fn DirectoryReader::begin_records(
  self : DirectoryReader,
  offset : UInt64,
  size : UInt64,
  entries : UInt64,
  boundary : UInt64,
  comment : Bytes,
) -> DirectoryStep raise ZipError {
  guard offset <= boundary && size == boundary - offset else {
    raise ZipError(Truncated, "zip: central directory out of bounds")
  }
  check_directory_limit(DirectoryBytes, self.limits.max_directory_bytes, size)
  let entry_limit = if self.limits.max_entries < 0x7fff_ffffUL {
    self.limits.max_entries
  } else {
    0x7fff_ffffUL
  }
  check_directory_limit(Entries, entry_limit, entries)
  guard entries <= size / 46UL else {
    raise ZipError(
      Truncated,
      "zip: central directory entry count exceeds its size",
    )
  }
  guard size != 0UL else { return self.complete(comment, offset) }
  let bounds = { offset, size, entries, comment, }
  self.phase = Records(bounds, offset)
  NeedRead({ offset, length: range_read_length(size, DIRECTORY_CHUNK_SIZE), })
}

///|
fn DirectoryReader::complete(
  self : DirectoryReader,
  comment : Bytes,
  central_offset : UInt64,
) -> DirectoryStep {
  let directory = { entries: self.entries, comment, central_offset, }
  self.entries = []
  self.pending = b""
  self.phase = Complete(directory)
  Done(directory)
}
