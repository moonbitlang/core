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
/// The ZIP reader: central-directory parsing, local-record validation, bounded
/// materialization of every entry, and the raw source records retained for
/// byte-preserving rewrites.

///|
/// Checked, materializable metadata used only by the whole-buffer reader.
priv struct MemoryEntryMeta {
  name : String
  name_len : Int32
  flags : Int32
  method_id : Int32
  crc : UInt32
  compressed_size : Int32
  uncompressed_size : Int32
  local_offset : Int32
  central_record : BytesView
  central_zip64_offset_position : Int32?
  data_descriptor : Bool
}

///|
/// The parsed local header region of one entry, with the byte range of its
/// payload plus its (optional) data descriptor.
priv struct LocalRecord {
  compressed : BytesView
  end : Int32
}

///|
fn read_local_record(
  bytes : BytesView,
  meta : MemoryEntryMeta,
  central_offset : Int32,
) -> LocalRecord raise ZipError {
  guard meta.local_offset >= 0 && meta.local_offset < central_offset else {
    raise ZipError(Truncated, "zip: local header offset out of bounds")
  }
  let reader = Cursor(bytes, meta.local_offset)
  guard reader.read_u32_raw() == LOCAL_HEADER_SIG else {
    raise ZipError(InvalidSignature, "zip: invalid local header signature")
  }
  ignore(reader.read_u16())
  let flags = reader.read_u16()
  ensure_flags_supported(flags)
  guard flags == meta.flags else {
    raise ZipError(UnsupportedFeature, "zip: local and central flags differ")
  }
  let method_id = reader.read_u16()
  guard method_id == meta.method_id else {
    raise ZipError(UnsupportedFeature, "zip: local and central methods differ")
  }
  ignore(reader.read_u16())
  ignore(reader.read_u16())
  let local_crc = reader.read_u32_raw()
  let comp_size_raw = reader.read_u32_raw()
  let uncomp_size_raw = reader.read_u32_raw()
  let name_len = reader.read_u16()
  let extra_len = reader.read_u16()
  let local_name = reader.read_bytes(name_len)
  let local_extra = reader.read_bytes(extra_len)
  // The central name was already decoded and validated. Reuse its owned raw
  // bytes without allocating another String on the matching-name path.
  // Keep the old decode fallback so malformed UTF-8 still raises InvalidUtf8.
  let central_name = meta.central_record[46:46 + meta.name_len]
  guard local_name == central_name || decode_name(local_name) == meta.name else {
    raise ZipError(UnsupportedFeature, "zip: local and central names differ")
  }
  let has_descriptor = (flags & FLAG_DATA_DESCRIPTOR) != 0
  let need_local_uncomp = uncomp_size_raw == MAX_U32
  let need_local_comp = comp_size_raw == MAX_U32
  let (local_zip_uncomp, local_zip_comp, _, _) = read_zip64_extra(
    local_extra, need_local_uncomp, need_local_comp, false,
  )
  guard local_crc == meta.crc || (has_descriptor && local_crc == 0) else {
    raise ZipError(UnsupportedFeature, "zip: local and central CRC-32 differ")
  }
  guard local_size_matches(
      comp_size_raw,
      local_zip_comp,
      meta.compressed_size.to_uint64(),
      has_descriptor,
    ) &&
    local_size_matches(
      uncomp_size_raw,
      local_zip_uncomp,
      meta.uncompressed_size.to_uint64(),
      has_descriptor,
    ) else {
    raise ZipError(SizeMismatch, "zip: local and central sizes differ")
  }
  guard reader.pos <= central_offset &&
    meta.compressed_size <= central_offset - reader.pos else {
    raise ZipError(Truncated, "zip: compressed payload out of bounds")
  }
  let compressed = reader.read_bytes(meta.compressed_size)
  let end = if has_descriptor {
    // The descriptor's sizes are 64-bit iff the local header declared its
    // sizes through the ZIP64 extra field (0xffffffff placeholders).
    let zip64 = need_local_uncomp || need_local_comp
    let end = reader.pos + data_descriptor_size(bytes, reader.pos, meta, zip64)
    guard end <= central_offset else {
      raise ZipError(Truncated, "zip: data descriptor out of bounds")
    }
    end
  } else {
    reader.pos
  }
  { compressed, end, }
}

///|
fn check_sizes(
  uncompressed_size : Int32,
  entry_limit : Int32,
  total_limit : Int32,
  used_total : Int32,
) -> Unit raise ZipError {
  guard uncompressed_size <= entry_limit else {
    raise ZipError(
      LimitExceeded(
        EntryUncompressedBytes,
        entry_limit.to_uint64(),
        uncompressed_size.to_uint64(),
      ),
      "zip: entry exceeds the per-entry uncompressed limit",
    )
  }
  guard used_total >= 0 && uncompressed_size <= total_limit - used_total else {
    raise ZipError(
      LimitExceeded(
        TotalUncompressedBytes,
        total_limit.to_uint64(),
        used_total.to_uint64() + uncompressed_size.to_uint64(),
      ),
      "zip: entries exceed the total uncompressed limit",
    )
  }
}

///|
/// Count and validate before allocating the result. ZIP owns the limit error
/// so its payload can retain the observed count, including previous entries.
fn inflate_entry(
  compressed : BytesView,
  max_output : Int32,
  limit_kind : LimitKind,
  reported_limit : Int32,
  cancelled : () -> Bool,
) -> Bytes raise ZipError {
  check_cancelled(cancelled)
  let inflater = @flate.Inflater()
  let scratch = FixedArray::make(8192, b'\x00')
  // For a total-output limit, max_output is the remaining allowance.
  let previous = (reported_limit - max_output).to_uint64()
  let size = for position = 0, total = 0UL {
    let result = inflater.finish(compressed[position:], scratch.mut_view()) catch {
      err => raise wrap_inflate_error(err)
    }
    let position = position + result.consumed
    let total = total + result.produced.to_uint64()
    check_cancelled(cancelled)
    guard total <= max_output.to_uint64() else {
      raise ZipError(
        LimitExceeded(limit_kind, reported_limit.to_uint64(), previous + total),
        "zip: decompressed size limit exceeded",
      )
    }
    guard result.status is Done else { continue position, total }
    guard position == compressed.length() else {
      raise ZipError(
        InvalidDeflate,
        "zip: trailing bytes in compressed payload",
      )
    }
    // The checked Int32 allowance also bounds the result allocation.
    break total.to_int()
  }
  let output = FixedArray::make(size, b'\x00')
  let written = @flate.inflate_into(compressed, output, cancelled~) catch {
    err => raise wrap_inflate_error(err)
  }
  guard written == size else {
    raise ZipError(InvalidDeflate, "zip: preallocation size mismatch")
  }
  owned_zip_buffer_to_bytes(output)
}

///|
/// The parsed end-of-central-directory header: the central directory's bounds,
/// the classic EOCD position, the optional ZIP64 EOCD position, and the archive
/// comment.
priv struct EndOfCentral {
  eocd_offset : Int32
  entry_count : Int32
  central_size : Int32
  central_offset : Int32
  central_boundary : Int32
  zip64_eocd_offset : Int32?
  comment : Bytes
}

///|
/// Resolve ZIP64 end records and verify any non-sentinel classic fields.
/// Returns (entry_count, central_size, central_offset, zip64_eocd_offset).
fn zip64_central_bounds(
  bytes : BytesView,
  eocd_offset : Int32,
  disk_entries : Int32,
  total_entries : Int32,
  central_size_raw : UInt32,
  central_offset_raw : UInt32,
) -> (Int32, Int32, Int32, Int32) raise ZipError {
  let (zip_entries, zip_size, zip_offset, zip64_offset) = read_zip64_eocd(
    bytes, eocd_offset,
  )
  guard disk_entries == 0xFFFF || disk_entries.to_uint64() == zip_entries else {
    raise ZipError(
      UnsupportedFeature,
      "zip: classic and zip64 entry counts differ",
    )
  }
  guard total_entries == 0xFFFF || total_entries.to_uint64() == zip_entries else {
    raise ZipError(
      UnsupportedFeature,
      "zip: classic and zip64 entry counts differ",
    )
  }
  guard central_size_raw == MAX_U32 ||
    UInt64::extend_uint(central_size_raw) == zip_size else {
    raise ZipError(
      UnsupportedFeature,
      "zip: classic and zip64 central sizes differ",
    )
  }
  guard central_offset_raw == MAX_U32 ||
    UInt64::extend_uint(central_offset_raw) == zip_offset else {
    raise ZipError(
      UnsupportedFeature,
      "zip: classic and zip64 central offsets differ",
    )
  }
  let entry_count = (if total_entries == 0xFFFF {
    zip_entries
  } else {
    total_entries.to_uint64()
  }).to_int_checked()
  let central_size = (if central_size_raw == MAX_U32 {
    zip_size
  } else {
    UInt64::extend_uint(central_size_raw)
  }).to_int_checked()
  let central_offset = (if central_offset_raw == MAX_U32 {
    zip_offset
  } else {
    UInt64::extend_uint(central_offset_raw)
  }).to_int_checked()
  (entry_count, central_size, central_offset, zip64_offset)
}

///|
/// Enforce the entry-count and central-bounds limits and assemble the parsed
/// end-of-central-directory record.
fn validate_central_bounds(
  bytes : BytesView,
  limits : ReadLimits,
  eocd_offset : Int32,
  entry_count : Int32,
  central_size : Int32,
  central_offset : Int32,
  central_boundary : Int32,
  zip64_eocd_offset : Int32?,
  comment : Bytes,
) -> EndOfCentral raise ZipError {
  guard entry_count <= limits.max_entries else {
    raise ZipError(
      LimitExceeded(
        Entries,
        limits.max_entries.to_uint64(),
        entry_count.to_uint64(),
      ),
      "zip: entry count exceeds its limit",
    )
  }
  guard central_offset <= central_boundary &&
    central_boundary <= bytes.length() &&
    central_size == central_boundary - central_offset else {
    raise ZipError(Truncated, "zip: central directory out of bounds")
  }
  {
    eocd_offset,
    entry_count,
    central_size,
    central_offset,
    central_boundary,
    zip64_eocd_offset,
    comment,
  }
}

///|
/// Locate and validate the end-of-central-directory record (and the ZIP64 EOCD
/// it points at), enforcing the package size, entry count, and central-bounds
/// limits. Returns the parsed bounds for the central-directory phase.
fn parse_end_of_central(
  bytes : BytesView,
  limits : ReadLimits,
  cancelled : () -> Bool,
) -> EndOfCentral raise ZipError {
  check_cancelled(cancelled)
  guard bytes.length() <= limits.max_package_bytes else {
    raise ZipError(
      LimitExceeded(
        PackageBytes,
        limits.max_package_bytes.to_uint64(),
        bytes.length().to_uint64(),
      ),
      "zip: package exceeds the input size limit",
    )
  }
  guard find_end_of_central(bytes) is Some(eocd_offset) else {
    raise ZipError(
      MissingEndOfCentral,
      "zip: end of central directory not found",
    )
  }
  let reader = Cursor(bytes, eocd_offset)
  ignore(reader.read_u32_raw())
  let disk_no = reader.read_u16()
  let disk_start = reader.read_u16()
  let disk_entries = reader.read_u16()
  let total_entries = reader.read_u16()
  let central_size_raw = reader.read_u32_raw()
  let central_offset_raw = reader.read_u32_raw()
  let comment_len = reader.read_u16()
  guard disk_no == 0 && disk_start == 0 else {
    raise ZipError(
      UnsupportedFeature,
      "zip: multi-disk archives are not supported",
    )
  }
  let comment = copy_cancellable(reader.read_bytes(comment_len), cancelled)
  let needs_zip64 = disk_entries == 0xFFFF ||
    total_entries == 0xFFFF ||
    central_size_raw == MAX_U32 ||
    central_offset_raw == MAX_U32 ||
    UInt64::extend_uint(central_offset_raw) +
    UInt64::extend_uint(central_size_raw) !=
    eocd_offset.to_uint64()
  guard !needs_zip64 else {
    let (entry_count, central_size, central_offset, zip64_offset) = zip64_central_bounds(
      bytes, eocd_offset, disk_entries, total_entries, central_size_raw, central_offset_raw,
    )
    return validate_central_bounds(
      bytes,
      limits,
      eocd_offset,
      entry_count,
      central_size,
      central_offset,
      zip64_offset,
      Some(zip64_offset),
      comment,
    )
  }
  guard disk_entries == total_entries else {
    raise ZipError(
      UnsupportedFeature,
      "zip: multi-disk archives are not supported",
    )
  }
  validate_central_bounds(
    bytes,
    limits,
    eocd_offset,
    total_entries,
    central_size_raw.to_int_checked(),
    central_offset_raw.to_int_checked(),
    eocd_offset,
    None,
    comment,
  )
}

///|
/// Resolve a central-directory 32-bit field that may spill into a ZIP64 extra
/// entry: the classic field carries the `MAX_U32` sentinel when ZIP64 is in
/// use. `read_zip64_extra` guarantees a ZIP64 value whenever `need` is true (it
/// raises when the field is absent or mis-sized), so `unwrap` is safe there.
fn resolve_zip64_field(
  need : Bool,
  zip64_value : UInt64?,
  classic_raw : UInt32,
) -> UInt64 {
  guard need else { return UInt64::extend_uint(classic_raw) }
  zip64_value.unwrap()
}

///|
/// Adapt shared 64-bit directory metadata to an in-memory entry.
fn parse_central_record(
  central_bytes : BytesView,
  central_reader : Cursor,
) -> MemoryEntryMeta raise ZipError {
  let central_record_start = central_reader.pos
  let parsed = parse_directory_record(central_reader)
  let entry = parsed.entry
  ensure_flags_supported(entry.flags)
  {
    name: entry.name,
    name_len: parsed.name_len,
    flags: entry.flags,
    method_id: entry.method_id,
    crc: entry.crc,
    // Only the eager in-memory adapter narrows file sizes and positions.
    compressed_size: entry.compressed_size.to_int_checked(),
    uncompressed_size: entry.uncompressed_size.to_int_checked(),
    local_offset: entry.local_offset.to_int_checked(),
    central_record: central_bytes[central_record_start:central_reader.pos],
    central_zip64_offset_position: parsed.central_zip64_offset_position,
    data_descriptor: (entry.flags & FLAG_DATA_DESCRIPTOR) != 0,
  }
}

///|
/// Parse every central-directory record into `MemoryEntryMeta`, enforcing the entry
/// count and decompressed-size ceilings.
fn parse_central_directory(
  bytes : BytesView,
  eocd : EndOfCentral,
  limits : ReadLimits,
  cancelled : () -> Bool,
) -> Array[MemoryEntryMeta] raise ZipError {
  let central_bytes = bytes[eocd.central_offset:eocd.central_boundary]
  let central_reader = Cursor(central_bytes, 0)
  let max_plausible = eocd.central_size / 46
  let metas = Array(capacity=eocd.entry_count.min(max_plausible))
  let mut used_total = 0
  for entry_index in 0..<eocd.entry_count {
    if entry_index % 64 == 0 {
      check_cancelled(cancelled)
    }
    let meta = parse_central_record(central_bytes, central_reader)
    check_sizes(
      meta.uncompressed_size,
      limits.max_entry_uncompressed_bytes,
      limits.max_total_uncompressed_bytes,
      used_total,
    )
    used_total = used_total + meta.uncompressed_size
    metas.push(meta)
  }
  guard central_reader.pos == eocd.central_size else {
    raise ZipError(
      UnsupportedFeature,
      "zip: central directory size/count mismatch",
    )
  }
  metas
}

///|
/// Retain views of the original trailer for rewrites of edited archives.
fn build_trailer(bytes : BytesView, eocd : EndOfCentral) -> TrailerTemplate {
  guard eocd.zip64_eocd_offset is Some(zip64_offset) else {
    return {
      classic_end_record: bytes[eocd.eocd_offset:],
      zip64_end_record: None,
      zip64_locator: None,
    }
  }
  let locator_offset = eocd.eocd_offset - 20
  {
    classic_end_record: bytes[eocd.eocd_offset:],
    zip64_end_record: Some(bytes[zip64_offset:locator_offset]),
    zip64_locator: Some(bytes[locator_offset:eocd.eocd_offset]),
  }
}

///|
/// Materialize one entry: validate its local record against the central
/// metadata, decompress or copy its payload under the caller's limits, and
/// retain the raw source records for byte-preserving rewrites.
fn decode_entry(
  bytes : BytesView,
  meta : MemoryEntryMeta,
  central_offset : Int32,
  limits : ReadLimits,
  actual_total : Int32,
  cancelled : () -> Bool,
) -> Entry raise ZipError {
  check_cancelled(cancelled)
  let record = read_local_record(bytes, meta, central_offset)
  let entry_limit = limits.max_entry_uncompressed_bytes
  let total_limit = limits.max_total_uncompressed_bytes
  let remaining = total_limit - actual_total
  let (effective_cap, limit_kind, reported_limit) = if remaining < entry_limit {
    (remaining, TotalUncompressedBytes, total_limit)
  } else {
    (entry_limit, EntryUncompressedBytes, entry_limit)
  }
  let compression = method_from_code(meta.method_id)
  let data = {
    guard !(record.compressed.length() == 0 && meta.uncompressed_size == 0) else {
      b""
    }
    match compression {
      Store => {
        check_sizes(
          record.compressed.length(),
          entry_limit,
          total_limit,
          actual_total,
        )
        copy_cancellable(record.compressed, cancelled)
      }
      Deflate =>
        inflate_entry(
          record.compressed,
          effective_cap,
          limit_kind,
          reported_limit,
          cancelled,
        )
    }
  }
  guard data.length() == meta.uncompressed_size else {
    raise ZipError(
      SizeMismatch,
      "zip: decoded size does not match central directory",
    )
  }
  guard data.length() <= total_limit - actual_total else {
    raise ZipError(
      LimitExceeded(
        TotalUncompressedBytes,
        total_limit.to_uint64(),
        actual_total.to_uint64() + data.length().to_uint64(),
      ),
      "zip: entries exceed the total uncompressed limit",
    )
  }
  let crc = crc32_cancellable(data, cancelled~)
  guard crc == meta.crc else {
    raise ZipError(ChecksumMismatch, "zip: CRC-32 mismatch")
  }
  let source = Some({
    local_record: bytes[meta.local_offset:record.end],
    central_record: meta.central_record,
    central_zip64_offset_position: meta.central_zip64_offset_position,
  })
  {
    name: meta.name,
    data,
    compression,
    crc32: meta.crc,
    data_descriptor: meta.data_descriptor,
    compressed_size: meta.compressed_size,
    source,
    origin_local_offset: Some(meta.local_offset),
  }
}

///|
fn read_impl(
  bytes : BytesView,
  limits : ReadLimits,
  cancelled : () -> Bool,
) -> Archive raise ZipError {
  let eocd = parse_end_of_central(bytes, limits, cancelled)
  // Own exactly the supplied view once. All record views share this copy.
  let original = copy_cancellable(bytes, cancelled)
  let bytes = original[:]
  let metas = parse_central_directory(bytes, eocd, limits, cancelled)
  let archive = {
    original: Some(original),
    entries: [],
    comment: eocd.comment,
    trailer: Some(build_trailer(bytes, eocd)),
  }
  let mut actual_total = 0
  for meta in metas {
    let entry = decode_entry(
      bytes,
      meta,
      eocd.central_offset,
      limits,
      actual_total,
      cancelled,
    )
    actual_total = actual_total + entry.data().length()
    archive.entries.push(entry)
  }
  check_cancelled(cancelled)
  archive
}

///|
/// Read a ZIP archive from `bytes`, decoding every entry. `limits` bounds the
/// package size, entry count, per-entry and total decompressed bytes, and the
/// complete source retained for byte-preserving rewrites; `cancelled` is polled
/// across parsing, decoding, and CRC-32 verification. Every decoded entry must
/// match its stored CRC-32. Failures carry a stable `ZipErrorKind`
/// plus a diagnostic.
pub fn read(
  bytes : BytesView,
  limits~ : ReadLimits = ReadLimits(),
  cancelled~ : () -> Bool = () => false,
) -> Archive raise ZipError {
  guard limits.max_package_bytes >= 0 &&
    limits.max_entries >= 0 &&
    limits.max_entry_uncompressed_bytes >= 0 &&
    limits.max_total_uncompressed_bytes >= 0 else {
    raise ZipError(InvalidArgument, "zip: read limits must be non-negative")
  }
  read_impl(bytes, limits, cancelled)
}
