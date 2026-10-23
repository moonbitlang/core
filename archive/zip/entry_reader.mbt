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
/// Bounds for streaming one entry. The ceiling applies to actual decoded bytes
/// and also rejects an oversized directory declaration before reading payloads.
#valtype
struct EntryReadLimits {
  max_output_bytes : UInt64
}

///|
/// Construct a decoded-output ceiling. Omission permits any UInt64 byte count.
pub fn EntryReadLimits::EntryReadLimits(
  max_output_bytes~ : UInt64 = 0xffff_ffff_ffff_ffffUL,
) -> EntryReadLimits {
  { max_output_bytes, }
}

///|
/// Supply the requested range, resume with empty input and another output
/// buffer, or finish after all integrity checks have succeeded. Every successful
/// step may produce output, including a step returning NeedRead or Done.
pub(all) enum EntryStep {
  NeedRead(ReadRange)
  NeedMoreOutput
  Done
}

///|
priv struct EntryLocalHeader {
  crc : UInt32
  compressed_size : UInt32
  uncompressed_size : UInt32
  name_length : Int32
  extra_length : Int32
}

///|
priv enum EntryPhase {
  Initial
  Header
  Name(EntryLocalHeader)
  Extra(EntryLocalHeader)
  PayloadInput(Int32)
  Payload
  Descriptor(Int32)
  Complete
  Failed(ZipErrorKind, String)
}

///|
/// Range-driven extraction of one Store or Deflate entry. Created by
/// Directory::open_entry so metadata and archive bounds cannot be forged.
/// Retains at most one 64 KiB compressed response, bounded local metadata, and
/// the inflater's workspace. Sizes and cumulative progress remain 64-bit.
struct EntryReader {
  entry : DirectoryEntry
  central_offset : UInt64
  max_output : UInt64
  crc : @checksum.Crc32
  mut inflater : @flate.Inflater?
  mut phase : EntryPhase
  mut payload_offset : UInt64
  mut descriptor_zip64 : Bool
  mut requested : UInt64
  mut consumed : UInt64
  mut produced : UInt64
  mut step_produced : Int32
  mut pending : Bytes
  mut pending_pos : Int32
}

///|
/// Open an entry by directory index, preserving the identity of duplicate names.
/// No I/O occurs here. Unknown methods, unsupported flags, encryption, and
/// declared output exceeding the limit are rejected before requesting data.
pub fn Directory::open_entry(
  self : Directory,
  index : Int32,
  limits~ : EntryReadLimits = EntryReadLimits(),
) -> EntryReader raise ZipError {
  guard index >= 0 && index < self.entries.length() else {
    raise ZipError(
      InvalidEntryIndex(index),
      "zip: directory entry index out of bounds",
    )
  }
  let entry = self.entries[index]
  ensure_flags_supported(entry.flags)
  let compression = method_from_code(entry.method_id)
  guard entry.uncompressed_size <= limits.max_output_bytes else {
    raise ZipError(
      LimitExceeded(
        EntryUncompressedBytes,
        limits.max_output_bytes,
        entry.uncompressed_size,
      ),
      "zip: entry exceeds its decoded-output limit",
    )
  }
  if compression is Store {
    guard entry.compressed_size == entry.uncompressed_size else {
      raise ZipError(SizeMismatch, "zip: stored entry sizes differ")
    }
  }
  {
    entry,
    central_offset: self.central_offset,
    max_output: limits.max_output_bytes,
    crc: Crc32(),
    inflater: if compression is Deflate {
      Some(Inflater())
    } else {
      None
    },
    phase: Initial,
    payload_offset: 0UL,
    descriptor_zip64: false,
    requested: 0UL,
    consumed: 0UL,
    produced: 0UL,
    step_produced: 0,
    pending: b"",
    pending_pos: 0,
  }
}

///|
/// Initially supply empty input. After NeedRead, supply exactly the requested
/// bytes from the same immutable archive used for the directory listing. After
/// NeedMoreOutput, supply empty input and another output array; accepted input
/// is retained internally and must not be replayed. Read last_produced after
/// every normal return and process output[:last_produced()] before reusing it.
/// Input and output buffers are released before returning. An empty output
/// array suspends payload decoding. Requests are at most 65,535 bytes for local
/// metadata and 64 KiB for payloads. Cancel by stopping between calls.
/// Done verifies the local header, exact compressed/decoded sizes, CRC-32 and
/// any data descriptor. Earlier output is unverified until Done. On error the
/// output is unspecified, last_produced is zero, and the error remains latched.
pub fn EntryReader::step(
  self : EntryReader,
  input : BytesView,
  output : FixedArray[Byte],
) -> EntryStep raise ZipError {
  self.step_produced = 0
  if self.phase is Failed(kind, message) {
    raise ZipError(kind, message)
  }
  self.step_active(input, output) catch {
    ZipError(kind, message) => {
      self.phase = Failed(kind, message)
      self.step_produced = 0
      self.pending = b""
      self.inflater = None
      raise ZipError(kind, message)
    }
  }
}

///|
/// Output written by the latest successful step, including NeedRead and Done.
pub fn EntryReader::last_produced(self : EntryReader) -> Int32 {
  self.step_produced
}

///|
/// Cumulative compressed payload bytes consumed, excluding headers/descriptors.
pub fn EntryReader::total_consumed(self : EntryReader) -> UInt64 {
  self.consumed
}

///|
/// Cumulative decoded bytes. Integrity is established only after Done.
pub fn EntryReader::total_produced(self : EntryReader) -> UInt64 {
  self.produced
}

///|
fn EntryReader::step_active(
  self : EntryReader,
  input : BytesView,
  output : FixedArray[Byte],
) -> EntryStep raise ZipError {
  match self.phase {
    Initial => {
      expect_range_input(input, 0)
      self.phase = Header
      NeedRead({ offset: self.entry.local_offset, length: 30, })
    }
    Header => self.read_header(input)
    Name(header) => {
      expect_range_input(input, header.name_length)
      self.read_name(header, input)
    }
    Extra(header) => {
      expect_range_input(input, header.extra_length)
      self.read_extra(header, input)
    }
    PayloadInput(length) => {
      expect_range_input(input, length)
      self.pending = copy_zip_input(input)
      self.pending_pos = 0
      self.requested += length.to_uint64()
      self.phase = Payload
      self.read_payload(output)
    }
    Payload => {
      expect_range_input(input, 0)
      self.read_payload(output)
    }
    Descriptor(length) => {
      expect_range_input(input, length)
      ignore(
        checked_data_descriptor_size(
          input,
          self.entry.crc,
          self.entry.compressed_size,
          self.entry.uncompressed_size,
          self.descriptor_zip64,
        ),
      )
      self.phase = Complete
      Done
    }
    Complete => {
      expect_range_input(input, 0)
      Done
    }
    Failed(kind, message) => raise ZipError(kind, message)
  }
}

///|
fn EntryReader::read_header(
  self : EntryReader,
  input : BytesView,
) -> EntryStep raise ZipError {
  expect_range_input(input, 30)
  let reader = Cursor(input, 0)
  guard reader.read_u32_raw() == LOCAL_HEADER_SIG else {
    raise ZipError(InvalidSignature, "zip: invalid local header signature")
  }
  ignore(reader.read_u16())
  let flags = reader.read_u16()
  ensure_flags_supported(flags)
  guard flags == self.entry.flags else {
    raise ZipError(UnsupportedFeature, "zip: local and central flags differ")
  }
  guard reader.read_u16() == self.entry.method_id else {
    raise ZipError(UnsupportedFeature, "zip: local and central methods differ")
  }
  ignore(reader.read_u16())
  ignore(reader.read_u16())
  let header = {
    crc: reader.read_u32_raw(),
    compressed_size: reader.read_u32_raw(),
    uncompressed_size: reader.read_u32_raw(),
    name_length: reader.read_u16(),
    extra_length: reader.read_u16(),
  }
  let header_size = 30UL +
    header.name_length.to_uint64() +
    header.extra_length.to_uint64()
  guard header_size <= self.central_offset - self.entry.local_offset &&
    self.entry.compressed_size <=
    self.central_offset - self.entry.local_offset - header_size else {
    raise ZipError(Truncated, "zip: local header or payload out of bounds")
  }
  self.payload_offset = self.entry.local_offset + header_size
  guard header.name_length != 0 else { return self.read_name(header, b"") }
  self.phase = Name(header)
  NeedRead({
    offset: self.entry.local_offset + 30UL,
    length: header.name_length,
  })
}

///|
fn EntryReader::read_name(
  self : EntryReader,
  header : EntryLocalHeader,
  input : BytesView,
) -> EntryStep raise ZipError {
  guard decode_name(input) == self.entry.name else {
    raise ZipError(UnsupportedFeature, "zip: local and central names differ")
  }
  guard header.extra_length != 0 else { return self.read_extra(header, b"") }
  self.phase = Extra(header)
  NeedRead({
    offset: self.payload_offset - header.extra_length.to_uint64(),
    length: header.extra_length,
  })
}

///|
fn EntryReader::read_extra(
  self : EntryReader,
  header : EntryLocalHeader,
  input : BytesView,
) -> EntryStep raise ZipError {
  let descriptor = (self.entry.flags & FLAG_DATA_DESCRIPTOR) != 0
  let need_uncomp = header.uncompressed_size == MAX_U32
  let need_comp = header.compressed_size == MAX_U32
  let (zip_uncomp, zip_comp, _, _) = read_zip64_extra(
    input, need_uncomp, need_comp, false,
  )
  guard header.crc == self.entry.crc || (descriptor && header.crc == 0U) else {
    raise ZipError(UnsupportedFeature, "zip: local and central CRC-32 differ")
  }
  guard local_size_matches(
      header.compressed_size,
      zip_comp,
      self.entry.compressed_size,
      descriptor,
    ) &&
    local_size_matches(
      header.uncompressed_size,
      zip_uncomp,
      self.entry.uncompressed_size,
      descriptor,
    ) else {
    raise ZipError(SizeMismatch, "zip: local and central sizes differ")
  }
  self.descriptor_zip64 = need_uncomp ||
    need_comp ||
    self.entry.compressed_size >= 0xffff_ffffUL ||
    self.entry.uncompressed_size >= 0xffff_ffffUL
  guard self.entry.compressed_size != 0UL else {
    guard self.entry.uncompressed_size == 0UL else {
      raise ZipError(Truncated, "zip: empty DEFLATE payload")
    }
    return self.finish_payload()
  }
  self.request_payload()
}

///|
fn EntryReader::request_payload(self : EntryReader) -> EntryStep {
  let length = range_read_length(
    self.entry.compressed_size - self.requested,
    65536,
  )
  self.pending = b""
  self.pending_pos = 0
  self.phase = PayloadInput(length)
  NeedRead({ offset: self.payload_offset + self.requested, length, })
}

///|
fn EntryReader::record_output(
  self : EntryReader,
  output : FixedArray[Byte],
  produced : Int32,
  consumed : Int32,
) -> Unit raise ZipError {
  guard produced.to_uint64() <= 0xffff_ffff_ffff_ffffUL - self.produced else {
    raise ZipError(SizeMismatch, "zip: decoded size exceeds UInt64 range")
  }
  let actual = self.produced + produced.to_uint64()
  guard actual <= self.max_output else {
    raise ZipError(
      LimitExceeded(EntryUncompressedBytes, self.max_output, actual),
      "zip: entry exceeds its decoded-output limit",
    )
  }
  guard actual <= self.entry.uncompressed_size else {
    raise ZipError(
      SizeMismatch,
      "zip: decoded size exceeds central directory size",
    )
  }
  self.crc.update(borrowed_zip_buffer_bytes(output)[:produced])
  self.produced = actual
  self.consumed += consumed.to_uint64()
  self.pending_pos += consumed
  self.step_produced = produced
}

///|
fn EntryReader::read_payload(
  self : EntryReader,
  output : FixedArray[Byte],
) -> EntryStep raise ZipError {
  guard output.length() != 0 else { return NeedMoreOutput }
  if self.inflater is Some(inflater) {
    let status_result = try {
      if self.requested == self.entry.compressed_size {
        inflater.finish(self.pending[self.pending_pos:], output.mut_view())
      } else {
        inflater.step(self.pending[self.pending_pos:], output.mut_view())
      }
    } catch {
      error => raise wrap_inflate_error(error)
    }
    let status = status_result.status
    self.record_output(output, status_result.produced, status_result.consumed)
    match status {
      Done => {
        guard self.consumed == self.entry.compressed_size else {
          raise ZipError(
            InvalidDeflate,
            "zip: trailing bytes in compressed payload",
          )
        }
        self.finish_payload()
      }
      NeedMoreOutput => NeedMoreOutput
      NeedMoreInput => {
        guard self.requested < self.entry.compressed_size else {
          raise ZipError(Truncated, "zip: truncated DEFLATE payload")
        }
        self.request_payload()
      }
    }
  } else {
    let count = (self.pending.length() - self.pending_pos).min(output.length())
    output.blit_from_bytesview(
      0,
      self.pending[self.pending_pos:self.pending_pos + count],
    )
    self.record_output(output, count, count)
    guard self.pending_pos == self.pending.length() else {
      return NeedMoreOutput
    }
    if self.requested == self.entry.compressed_size {
      self.finish_payload()
    } else {
      self.request_payload()
    }
  }
}

///|
fn EntryReader::finish_payload(self : EntryReader) -> EntryStep raise ZipError {
  guard self.produced == self.entry.uncompressed_size else {
    raise ZipError(
      SizeMismatch,
      "zip: decoded size differs from central directory size",
    )
  }
  guard self.crc.finish() == self.entry.crc else {
    raise ZipError(ChecksumMismatch, "zip: CRC-32 mismatch")
  }
  self.pending = b""
  self.inflater = None
  guard (self.entry.flags & FLAG_DATA_DESCRIPTOR) != 0 else {
    self.phase = Complete
    return Done
  }
  let offset = self.payload_offset + self.entry.compressed_size
  let minimum = if self.descriptor_zip64 { 20 } else { 12 }
  guard minimum.to_uint64() <= self.central_offset - offset else {
    raise ZipError(Truncated, "zip: data descriptor out of bounds")
  }
  let length = range_read_length(self.central_offset - offset, minimum + 4)
  self.phase = Descriptor(length)
  NeedRead({ offset, length, })
}
