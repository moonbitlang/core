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
/// Counts prepared records or emits them into an exactly sized buffer. The
/// preparation pass enforces the output ceiling before allocating that buffer.
priv struct Output {
  limit : Int32?
  mut buf : FixedArray[Byte]?
  mut size : Int32
}

///|
fn Output::counting(limit : Int32?) -> Output {
  { limit, buf: None, size: 0, }
}

///|
fn Output::writing(limit : Int32?, size_hint~ : Int32 = 0) -> Output {
  { limit, buf: Some(FixedArray::make(size_hint, b'\x00')), size: 0, }
}

///|
fn Output::is_counting(self : Output) -> Bool {
  self.buf is None
}

///|
fn Output::grow(self : Output, additional : Int32) -> Unit raise ZipError {
  guard additional >= 0 else {
    raise ZipError(UnsupportedFeature, "zip: negative output size")
  }
  if self.limit is Some(limit) {
    guard additional <= limit - self.size else {
      raise ZipError(
        LimitExceeded(
          OutputBytes,
          limit.to_uint64(),
          self.size.to_uint64() + additional.to_uint64(),
        ),
        "zip: output exceeds its byte limit",
      )
    }
  }
  guard additional <= 0x7fff_ffff - self.size else {
    raise ZipError(UnsupportedFeature, "zip: output size exceeds Int range")
  }
  let required = self.size + additional
  if self.buf is Some(buf) && required > buf.length() {
    let capacity = required.max(
      buf.length() + buf.length().min(0x7fff_ffff - buf.length()),
    )
    let grown = FixedArray::make(capacity, b'\x00')
    buf.blit_to(grown, len=self.size)
    self.buf = Some(grown)
  }
  self.size = required
}

///|
fn Output::write_bytes(self : Output, bytes : BytesView) -> Unit raise ZipError {
  self.grow(bytes.length())
  if self.buf is Some(buf) {
    buf.blit_from_bytesview(self.size - bytes.length(), bytes)
  }
}

///|
/// Advance the sizing pass without copying payload bytes.
fn Output::count(self : Output, n : Int32) -> Unit raise ZipError {
  self.grow(n)
}

///|
// grow checks both the output limit and capacity before unchecked field writes.
fn Output::write_u16(self : Output, value : Int32) -> Unit raise ZipError {
  if value < 0 || value > 0xffff {
    raise ZipError(UnsupportedFeature, "zip: u16 overflow")
  }
  self.grow(2)
  if self.buf is Some(buf) {
    buf.unsafe_write_uint16_le(self.size - 2, value.to_uint16())
  }
}

///|
fn Output::write_u32(self : Output, value : UInt32) -> Unit raise ZipError {
  self.grow(4)
  if self.buf is Some(buf) {
    buf.unsafe_write_uint32_le(self.size - 4, value)
  }
}

///|
fn Output::write_u64(self : Output, value : UInt64) -> Unit raise ZipError {
  self.grow(8)
  if self.buf is Some(buf) {
    buf.unsafe_write_uint64_le(self.size - 8, value)
  }
}

///|
/// Consumes the mutable output and returns its immutable contents.
fn Output::finish(self : Output) -> Bytes {
  guard self.buf is Some(buf) else { return b"" }
  // Consume the output: no mutable alias may survive the ownership transfer.
  self.buf = None
  let size = self.size
  self.size = 0
  if size == buf.length() {
    owned_zip_buffer_to_bytes(buf)
  } else {
    let exact = FixedArray::make(size, b'\x00')
    buf.blit_to(exact, len=size)
    owned_zip_buffer_to_bytes(exact)
  }
}

///|
fn write_u16_buf(buf : @buffer.Buffer, value : Int32) -> Unit raise ZipError {
  let raw = value.to_uint_checked()
  buf.write_uint16_le(raw.to_uint16())
}

///|
fn build_zip64_extra(
  uncomp~ : Int32?,
  comp~ : Int32?,
  offset~ : Int32?,
) -> Bytes raise ZipError {
  let mut count = 0
  if uncomp is Some(_) {
    count = count + 1
  }
  if comp is Some(_) {
    count = count + 1
  }
  if offset is Some(_) {
    count = count + 1
  }
  if count == 0 {
    return b""
  }
  let buf = @buffer.Buffer()
  write_u16_buf(buf, ZIP64_EXTRA_ID)
  write_u16_buf(buf, 8 * count)
  if uncomp is Some(value) {
    buf.write_uint64_le(value.to_uint64_checked())
  }
  if comp is Some(value) {
    buf.write_uint64_le(value.to_uint64_checked())
  }
  if offset is Some(value) {
    buf.write_uint64_le(value.to_uint64_checked())
  }
  buf.to_bytes()
}

///|
/// A prepared payload; stored data remains owned by its entry.
priv struct PreparedPayload {
  compressed_size : Int32
  compressed : Bytes?
}

///|
/// Compress an entry once using the archive's reusable workspace.
fn Entry::prepare_payload(
  entry : Entry,
  compressor : @flate.Compressor,
) -> PreparedPayload {
  match entry.compression {
    Store => { compressed_size: entry.data.length(), compressed: None, }
    Deflate => {
      let compressed = compressor.compress(entry.data)
      { compressed_size: compressed.length(), compressed: Some(compressed), }
    }
  }
}

///|
fn Entry::name_bytes(entry : Entry) -> Bytes raise ZipError {
  let name = @encoding/utf8.encode(entry.name)
  if name.length() > 0xffff {
    raise ZipError(UnsupportedFeature, "zip: entry name too long")
  }
  name
}

///|
fn Output::write_local_record(
  output : Output,
  entry : Entry,
  name_bytes : Bytes,
  payload : PreparedPayload,
  use_descriptor : Bool,
  force_zip64 : Bool,
) -> Unit raise ZipError {
  let method_id = entry.compression.code()
  let data_len = entry.data.length()
  let compressed_size = payload.compressed_size
  let crc = entry.crc32
  let needs_zip64_sizes = force_zip64 ||
    data_len.to_uint_checked() > MAX_U32 ||
    compressed_size.to_uint_checked() > MAX_U32
  if output.is_counting() {
    let extra_size = if needs_zip64_sizes { 20 } else { 0 }
    output.count(30 + name_bytes.length() + extra_size)
    output.count(compressed_size)
    if use_descriptor {
      output.count(if needs_zip64_sizes { 24 } else { 16 })
    }
    return
  }
  let version = if needs_zip64_sizes { 45 } else { 20 }
  let flags = FLAG_UTF8 |
    (if use_descriptor { FLAG_DATA_DESCRIPTOR } else { 0 })
  let local_extra = if needs_zip64_sizes {
    build_zip64_extra(
      uncomp=Some(data_len),
      comp=Some(compressed_size),
      offset=None,
    )
  } else {
    b""
  }
  guard name_bytes.length() <= 0xffff else {
    raise ZipError(UnsupportedFeature, "zip: u16 overflow")
  }
  let comp_field = if needs_zip64_sizes {
    MAX_U32
  } else if use_descriptor {
    0
  } else {
    compressed_size.to_uint_checked()
  }
  let uncomp_field = if needs_zip64_sizes {
    MAX_U32
  } else if use_descriptor {
    0
  } else {
    data_len.to_uint_checked()
  }
  let start = output.size
  output.grow(30)
  if output.buf is Some(buf) {
    // grow reserves the entire fixed header before any unchecked store.
    // All u16 fields are constants, bounded enum codes, or validated lengths.
    buf.unsafe_write_uint32_le(start, LOCAL_HEADER_SIG)
    buf.unsafe_write_uint16_le(start + 4, version.to_uint16())
    buf.unsafe_write_uint16_le(start + 6, flags.to_uint16())
    buf.unsafe_write_uint16_le(start + 8, method_id.to_uint16())
    buf.unsafe_write_uint32_le(start + 10, 0)
    buf.unsafe_write_uint32_le(start + 14, if use_descriptor { 0 } else { crc })
    buf.unsafe_write_uint32_le(start + 18, comp_field)
    buf.unsafe_write_uint32_le(start + 22, uncomp_field)
    buf.unsafe_write_uint16_le(start + 26, name_bytes.length().to_uint16())
    buf.unsafe_write_uint16_le(start + 28, local_extra.length().to_uint16())
  }
  output.write_bytes(name_bytes)
  output.write_bytes(local_extra)
  // Both stored and compressed payloads may be followed by a descriptor.
  if payload.compressed is Some(compressed) {
    output.write_bytes(compressed)
  } else {
    output.write_bytes(entry.data)
  }
  if use_descriptor {
    output.write_u32(DATA_DESCRIPTOR_SIG)
    output.write_u32(crc)
    if needs_zip64_sizes {
      output.write_u64(compressed_size.to_uint64_checked())
      output.write_u64(data_len.to_uint64_checked())
    } else {
      output.write_u32(compressed_size.to_uint_checked())
      output.write_u32(data_len.to_uint_checked())
    }
  }
}

///|
fn Output::write_central_record(
  output : Output,
  entry : Entry,
  name_bytes : Bytes,
  local_offset : Int32,
  compressed_size : Int32,
  use_descriptor : Bool,
  force_zip64 : Bool,
) -> Unit raise ZipError {
  let method_id = entry.compression.code()
  let data_len = entry.data.length()
  let needs_zip64_sizes = force_zip64 ||
    data_len.to_uint_checked() > MAX_U32 ||
    compressed_size.to_uint_checked() > MAX_U32
  let needs_zip64_offset = force_zip64 ||
    local_offset.to_uint_checked() > MAX_U32
  if output.is_counting() {
    let extra_size = (if needs_zip64_sizes { 16 } else { 0 }) +
      (if needs_zip64_offset { 8 } else { 0 })
    output.count(
      46 +
      name_bytes.length() +
      (if extra_size > 0 { 4 + extra_size } else { 0 }),
    )
    return
  }
  let needs_zip64_entry = needs_zip64_sizes || needs_zip64_offset
  let version = if needs_zip64_entry { 45 } else { 20 }
  let flags = FLAG_UTF8 |
    (if use_descriptor { FLAG_DATA_DESCRIPTOR } else { 0 })
  let central_extra = build_zip64_extra(
    uncomp=if needs_zip64_sizes { Some(data_len) } else { None },
    comp=if needs_zip64_sizes { Some(compressed_size) } else { None },
    offset=if needs_zip64_offset { Some(local_offset) } else { None },
  )
  guard name_bytes.length() <= 0xffff else {
    raise ZipError(UnsupportedFeature, "zip: u16 overflow")
  }
  let comp_field = if needs_zip64_sizes {
    MAX_U32
  } else {
    compressed_size.to_uint_checked()
  }
  let uncomp_field = if needs_zip64_sizes {
    MAX_U32
  } else {
    data_len.to_uint_checked()
  }
  let offset_field = if needs_zip64_offset {
    MAX_U32
  } else {
    local_offset.to_uint_checked()
  }
  let start = output.size
  output.grow(46)
  if output.buf is Some(buf) {
    // grow reserves all 46 bytes; the generated extra is at most 28 bytes.
    buf.unsafe_write_uint32_le(start, CENTRAL_HEADER_SIG)
    buf.unsafe_write_uint16_le(start + 4, version.to_uint16())
    buf.unsafe_write_uint16_le(start + 6, version.to_uint16())
    buf.unsafe_write_uint16_le(start + 8, flags.to_uint16())
    buf.unsafe_write_uint16_le(start + 10, method_id.to_uint16())
    buf.unsafe_write_uint32_le(start + 12, 0)
    buf.unsafe_write_uint32_le(start + 16, entry.crc32)
    buf.unsafe_write_uint32_le(start + 20, comp_field)
    buf.unsafe_write_uint32_le(start + 24, uncomp_field)
    buf.unsafe_write_uint16_le(start + 28, name_bytes.length().to_uint16())
    buf.unsafe_write_uint16_le(start + 30, central_extra.length().to_uint16())
    buf.unsafe_write_uint32_le(start + 32, 0)
    buf.unsafe_write_uint16_le(start + 36, 0)
    buf.unsafe_write_uint32_le(start + 38, 0)
    buf.unsafe_write_uint32_le(start + 42, offset_field)
  }
  output.write_bytes(name_bytes)
  output.write_bytes(central_extra)
}

///|
fn Output::write_preserved_central_record(
  output : Output,
  source : SourceRecord,
  local_offset : Int32,
) -> Unit raise ZipError {
  let template = source.central_record
  guard template.length() >= 46 &&
    read_u32_le_at_raw(template, 0) == CENTRAL_HEADER_SIG else {
    raise ZipError(
      UnsupportedFeature,
      "zip: preserved central record is malformed",
    )
  }
  guard source.central_zip64_offset_position is Some(position) else {
    output.write_bytes(template[0:42])
    output.write_u32(local_offset.to_uint_checked())
    output.write_bytes(template[46:])
    return
  }
  output.write_bytes(template[0:position])
  output.write_u64(local_offset.to_uint64_checked())
  output.write_bytes(template[position + 8:])
}

///|
fn Output::write_generated_classic_end_record(
  output : Output,
  zip64 : Bool,
  total_entries : Int32,
  central_size : Int32,
  central_offset : Int32,
  comment : Bytes,
) -> Unit raise ZipError {
  output.write_u32(END_OF_CENTRAL_SIG)
  output.write_u16(0)
  output.write_u16(0)
  if zip64 {
    output.write_u16(0xffff)
    output.write_u16(0xffff)
    output.write_u32(MAX_U32)
    output.write_u32(MAX_U32)
  } else {
    if total_entries > 0xffff {
      raise ZipError(
        UnsupportedFeature,
        "zip: too many entries for a classic archive",
      )
    }
    output.write_u16(total_entries)
    output.write_u16(total_entries)
    output.write_u32(central_size.to_uint_checked())
    output.write_u32(central_offset.to_uint_checked())
  }
  if comment.length() > 0xffff {
    raise ZipError(UnsupportedFeature, "zip: archive comment too long")
  }
  output.write_u16(comment.length())
  output.write_bytes(comment)
}

///|
fn Output::write_generated_zip64_trailer(
  output : Output,
  total_entries : Int32,
  central_size : Int32,
  central_offset : Int32,
  comment : Bytes,
) -> Unit raise ZipError {
  let zip64_offset = output.size
  output.write_u32(ZIP64_EOCD_SIG)
  output.write_u64((44).to_uint64_checked())
  output.write_u16(45)
  output.write_u16(45)
  output.write_u32(0)
  output.write_u32(0)
  let entry_count = total_entries.to_uint64_checked()
  output.write_u64(entry_count)
  output.write_u64(entry_count)
  output.write_u64(central_size.to_uint64_checked())
  output.write_u64(central_offset.to_uint64_checked())
  output.write_u32(ZIP64_LOCATOR_SIG)
  output.write_u32(0)
  output.write_u64(zip64_offset.to_uint64_checked())
  output.write_u32(1)
  output.write_generated_classic_end_record(
    true, total_entries, central_size, central_offset, comment,
  )
}

///|
fn Output::write_preserved_trailer(
  output : Output,
  trailer : TrailerTemplate,
  total_entries : Int32,
  central_size : Int32,
  central_offset : Int32,
) -> Unit raise ZipError {
  let classic = trailer.classic_end_record
  guard classic.length() >= 22 &&
    read_u32_le_at_raw(classic, 0) == END_OF_CENTRAL_SIG else {
    raise ZipError(UnsupportedFeature, "zip: preserved end record is malformed")
  }
  guard trailer.zip64_end_record is Some(end_record) else {
    output.write_preserved_classic_end_record(
      classic, total_entries, central_size, central_offset,
    )
    return
  }
  guard end_record.length() >= 56 &&
    read_u32_le_at_raw(end_record, 0) == ZIP64_EOCD_SIG else {
    raise ZipError(
      UnsupportedFeature,
      "zip: preserved zip64 end record is malformed",
    )
  }
  let zip64_offset = output.size
  // Patch the two entry-count fields, central size, and central offset
  // (offsets 24/32/40/48 within the record) over the verbatim template.
  output.write_bytes(end_record[0:24])
  output.write_u64(total_entries.to_uint64_checked())
  output.write_u64(total_entries.to_uint64_checked())
  output.write_u64(central_size.to_uint64_checked())
  output.write_u64(central_offset.to_uint64_checked())
  output.write_bytes(end_record[56:])
  guard trailer.zip64_locator is Some(locator) else {
    raise ZipError(
      UnsupportedFeature,
      "zip: preserved zip64 locator is missing",
    )
  }
  guard locator.length() == 20 &&
    read_u32_le_at_raw(locator, 0) == ZIP64_LOCATOR_SIG else {
    raise ZipError(
      UnsupportedFeature,
      "zip: preserved zip64 locator is malformed",
    )
  }
  output.write_bytes(locator[0:8])
  output.write_u64(zip64_offset.to_uint64_checked())
  output.write_bytes(locator[16:])
  // Optional ZIP64 trailers can retain ordinary classic fields. Patch those
  // fields too, leaving any ZIP64 sentinels untouched.
  output.write_preserved_classic_end_record(
    classic, total_entries, central_size, central_offset,
  )
}

///|
/// Streams a classic end record while patching both entry-count fields
/// (offsets 8, 10) and the central size/offset (offsets 12, 16). Fields
/// carrying ZIP64 sentinels are left untouched.
fn Output::write_preserved_classic_end_record(
  output : Output,
  classic : BytesView,
  total_entries : Int32,
  central_size : Int32,
  central_offset : Int32,
) -> Unit raise ZipError {
  if classic.length() < 22 ||
    read_u32_le_at_raw(classic, 0) != END_OF_CENTRAL_SIG {
    raise ZipError(UnsupportedFeature, "zip: preserved end record is malformed")
  }
  let count = total_entries.min(0xffff)
  let mut cursor = 0
  let entries_on_disk = read_u16_le_at(classic, 8)
  if entries_on_disk != 0xffff {
    output.write_bytes(classic[cursor:8])
    output.write_u16(count)
    cursor = 10
  }
  let total_on_disk = read_u16_le_at(classic, 10)
  if total_on_disk != 0xffff {
    output.write_bytes(classic[cursor:10])
    output.write_u16(count)
    cursor = 12
  }
  let size_field = read_u32_le_at_raw(classic, 12)
  if size_field != MAX_U32 {
    output.write_bytes(classic[cursor:12])
    output.write_u32(central_size.to_uint_checked())
    cursor = 16
  }
  let offset_field = read_u32_le_at_raw(classic, 16)
  if offset_field != MAX_U32 {
    output.write_bytes(classic[cursor:16])
    output.write_u32(central_offset.to_uint_checked())
    cursor = 20
  }
  output.write_bytes(classic[cursor:])
}

///|
/// Each fresh entry is encoded once during preparation. Emission consumes the
/// retained payload so it can be released as soon as it has been copied.
priv struct EntryPlan {
  local_offset : Int32
  compressed_size : Int32
  name_bytes : Bytes
  mut payload : PreparedPayload
}

///|
/// The order in which local records are written: entries that originated in a
/// read archive first, in their original local-record order, then entries
/// created in memory. A `replace` keeps the replaced entry's original position
/// (its source records are dropped for re-encoding, but its ordering hint
/// survives), so a byte-preserving rewrite never silently moves an edited part
/// to the end of the archive.
fn Archive::local_order(archive : Archive) -> FixedArray[Int32] {
  let order = FixedArray::makei(archive.entries.length(), index => index)
  // Most archives are already in local-record order, including all newly built
  // archives. Avoid sorting (and its comparisons) on this common path.
  let mut previous = -1
  let mut fresh_seen = false
  let mut ordered = true
  for entry in archive.entries {
    if entry.origin_local_offset is Some(offset) {
      if fresh_seen || offset < previous {
        ordered = false
        break
      }
      previous = offset
    } else {
      fresh_seen = true
    }
  }
  guard !ordered else { return order }
  order.sort_by((left, right) => {
    match
      (
        archive.entries[left].origin_local_offset,
        archive.entries[right].origin_local_offset,
      ) {
      (Some(a), Some(b)) => a.compare(b)
      (Some(_), None) => -1
      (None, Some(_)) => 1
      (None, None) => left.compare(right)
    }
  })
  order
}

///|
/// Prepare local records once, measuring exact offsets without allocating the
/// final ZIP buffer. Preserved and stored payloads continue to reference their
/// existing bytes. A compressor is allocated only when a fresh Deflate entry
/// is encountered.
fn prepare_archive(
  out : Output,
  archive : Archive,
  order : FixedArray[Int32],
  preserve : Bool,
  level : Int32,
  fast_store : Bool,
) -> Array[EntryPlan] raise ZipError {
  let plans : Array[EntryPlan] = []
  let mut compressor : @flate.Compressor? = None
  for index in order {
    let entry = archive.entries[index]
    let local_offset = out.size
    if preserve && entry.source is Some(source) {
      out.count(source.local_record.length())
      plans.push({
        local_offset,
        compressed_size: entry.compressed_size,
        name_bytes: b"",
        payload: { compressed_size: entry.compressed_size, compressed: None, },
      })
      continue
    }
    let name_bytes = entry.name_bytes()
    // Reject an impossible header before doing compression work.
    if out.limit is Some(limit) {
      guard 30 + name_bytes.length() <= limit - out.size else {
        raise ZipError(
          LimitExceeded(
            OutputBytes,
            limit.to_uint64(),
            out.size.to_uint64() + 30UL + name_bytes.length().to_uint64(),
          ),
          "zip: output exceeds its byte limit",
        )
      }
    }
    let payload = match entry.compression {
      Store => { compressed_size: entry.data.length(), compressed: None, }
      Deflate => {
        let codec = compressor.unwrap_or_else(() => {
          let codec = @flate.Compressor(level~, fast_store~)
          compressor = Some(codec)
          codec
        })
        entry.prepare_payload(codec)
      }
    }
    out.write_local_record(
      entry,
      name_bytes,
      payload,
      entry.data_descriptor,
      false,
    )
    plans.push({
      local_offset,
      compressed_size: payload.compressed_size,
      name_bytes,
      payload,
    })
  }
  plans
}

///|
fn write_directory(
  out : Output,
  archive : Archive,
  positions : FixedArray[Int32],
  plans : Array[EntryPlan],
  preserve : Bool,
) -> Unit raise ZipError {
  for index in 0..<archive.entries.length() {
    let entry = archive.entries[index]
    let plan = plans[positions[index]]
    if preserve && entry.source is Some(source) {
      out.write_preserved_central_record(source, plan.local_offset)
    } else {
      out.write_central_record(
        entry,
        plan.name_bytes,
        plan.local_offset,
        plan.compressed_size,
        entry.data_descriptor,
        false,
      )
    }
  }
}

///|
fn write_trailer(
  out : Output,
  archive : Archive,
  total_entries : Int32,
  central_size : Int32,
  central_offset : Int32,
  preserve : Bool,
  force_zip64 : Bool,
) -> Unit raise ZipError {
  let needs_zip64 = force_zip64 ||
    total_entries >= 0xffff ||
    central_size.to_uint_checked() > MAX_U32 ||
    central_offset.to_uint_checked() > MAX_U32
  match (preserve, archive.trailer) {
    (true, Some(trailer)) if !needs_zip64 || trailer.zip64_end_record is Some(_) =>
      out.write_preserved_trailer(
        trailer, total_entries, central_size, central_offset,
      )
    _ =>
      if needs_zip64 {
        out.write_generated_zip64_trailer(
          total_entries,
          central_size,
          central_offset,
          archive.comment,
        )
      } else {
        out.write_generated_classic_end_record(
          false,
          total_entries,
          central_size,
          central_offset,
          archive.comment,
        )
      }
  }
}

///|
/// Prepare once, then serialize into an exactly sized buffer. The output limit
/// is checked before allocating the final archive; no entry is recompressed.
fn write_impl(
  archive : Archive,
  preserve : Bool,
  level : Int32,
  max_output : Int32?,
  fast_store : Bool,
) -> Bytes raise ZipError {
  if preserve && archive.original is Some(bytes) {
    let counting = Output::counting(max_output)
    counting.count(bytes.length())
    let out = Output::writing(None, size_hint=bytes.length())
    out.write_bytes(bytes)
    return out.finish()
  }
  let order = archive.local_order()
  // Map central-directory order to the plans prepared in local-record order.
  let positions = FixedArray::make(order.length(), 0)
  for position in 0..<order.length() {
    positions[order[position]] = position
  }
  let counting = Output::counting(max_output)
  let plans = prepare_archive(
    counting, archive, order, preserve, level, fast_store,
  )
  let central_offset = counting.size
  write_directory(counting, archive, positions, plans, preserve)
  let central_size = counting.size - central_offset
  write_trailer(
    counting,
    archive,
    archive.entries.length(),
    central_size,
    central_offset,
    preserve,
    false,
  )
  let out = Output::writing(None, size_hint=counting.size)
  for position in 0..<order.length() {
    let entry = archive.entries[order[position]]
    let plan = plans[position]
    if preserve && entry.source is Some(source) {
      out.write_bytes(source.local_record)
    } else {
      out.write_local_record(
        entry,
        plan.name_bytes,
        plan.payload,
        entry.data_descriptor,
        false,
      )
      plan.payload = {
        compressed_size: plan.compressed_size,
        compressed: None,
      }
    }
  }
  write_directory(out, archive, positions, plans, preserve)
  write_trailer(
    out,
    archive,
    archive.entries.length(),
    central_size,
    central_offset,
    preserve,
    false,
  )
  out.finish()
}

///|
/// Serialize `archive` into a ZIP byte stream.
///
/// By default every entry is encoded fresh. With `preserve=true`, unchanged
/// entries reuse their source records with updated offsets. A pristine archive
/// round-trips byte-for-byte, including prefixes, gaps and directory ordering. After any
/// edit, records are rebuilt in their respective local and directory orders;
/// bytes outside records (such as prefixes and gaps) are not retained in the
/// output. Replaced and newly added entries are encoded normally.
/// `level` is clamped to 0-9. `fast_store` opts into a speed/ratio heuristic.
/// If `max_output_bytes` is supplied, the output is sized before allocation
/// and an oversized archive raises `LimitExceeded(OutputBytes, ...)`.
/// A negative limit raises `InvalidArgument`.
pub fn write(
  archive : Archive,
  preserve~ : Bool = false,
  max_output_bytes? : Int32,
  level~ : Int32 = 6,
  fast_store~ : Bool = false,
) -> Bytes raise ZipError {
  if max_output_bytes is Some(limit) {
    guard limit >= 0 else {
      raise ZipError(InvalidArgument, "zip: output limit must be non-negative")
    }
  }
  write_impl(archive, preserve, level, max_output_bytes, fast_store)
}
