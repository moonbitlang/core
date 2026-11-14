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
/// ZIP64 and data-descriptor parsing: the ZIP64 extra-field walker, the ZIP64
/// end-of-central record, and disambiguating a signature-prefixed descriptor
/// against the authoritative central-directory metadata.

///|
/// Reads one extra-field header (`ID, size`) at `pos` inside `extra`, returning
/// the id, the data size, and the offset of the field data.
fn extra_field_at(
  extra : BytesView,
  pos : Int32,
) -> (Int32, Int32, Int32) raise ZipError {
  guard pos >= 0 && extra[pos:] is [u16le(header_id), u16le(data_size), .. data] else {
    raise ZipError(UnsupportedFeature, "zip: truncated extra field header")
  }
  let data_size = data_size.reinterpret_as_int()
  if data_size > data.length() {
    raise ZipError(Truncated, "zip: truncated extra field data")
  }
  (header_id.reinterpret_as_int(), data_size, pos + 4)
}

///|
/// Reads the ZIP64 (0x0001) extra field, returning the requested 64-bit
/// uncompressed/compressed sizes and local-header offset, plus the position of
/// the offset field within `extra` (for patching preserved central records).
/// `need_*` selects which fields must be present, in APPNOTE order. A required
/// disk-start field must resolve to zero; split archives remain unsupported.
fn read_zip64_extra(
  extra : BytesView,
  need_uncomp : Bool,
  need_comp : Bool,
  need_offset : Bool,
  need_disk~ : Bool = false,
) -> (UInt64?, UInt64?, UInt64?, Int32?) raise ZipError {
  let mut pos = 0
  while pos < extra.length() {
    let (header_id, data_size, data_offset) = extra_field_at(extra, pos)
    pos = data_offset + data_size
    if header_id == ZIP64_EXTRA_ID {
      let count = (if need_uncomp { 1 } else { 0 }) +
        (if need_comp { 1 } else { 0 }) +
        (if need_offset { 1 } else { 0 })
      if data_size != 8 * count + (if need_disk { 4 } else { 0 }) {
        raise ZipError(
          UnsupportedFeature,
          "zip: zip64 extra field size mismatch",
        )
      }
      // The size check above makes every requested field present.
      let fields = extra[data_offset:data_offset + data_size]
      let (uncomp, fields) = take_zip64_field(fields, need_uncomp)
      let (comp, fields) = take_zip64_field(fields, need_comp)
      let (offset, fields) = take_zip64_field(fields, need_offset)
      if need_disk {
        guard fields is [u32le(0), ..] else {
          raise ZipError(
            UnsupportedFeature,
            "zip: multi-disk archives are not supported",
          )
        }
      }
      let offset_position = if need_offset {
        Some(
          data_offset +
          8 *
          ((if need_uncomp { 1 } else { 0 }) + (if need_comp { 1 } else { 0 })),
        )
      } else {
        None
      }
      return (uncomp, comp, offset, offset_position)
    }
  }
  if need_uncomp || need_comp || need_offset || need_disk {
    raise ZipError(
      UnsupportedFeature,
      "zip: required zip64 extra field is missing",
    )
  }
  (None, None, None, None)
}

///|
/// Takes one 64-bit ZIP64 extra value from the front of `fields` when `need`.
fn take_zip64_field(fields : BytesView, need : Bool) -> (UInt64?, BytesView) {
  guard need && fields is [u64le(value), .. rest] else { return (None, fields) }
  (Some(value), rest)
}

///|
fn read_zip64_eocd(
  bytes : BytesView,
  eocd_offset : Int32,
) -> (UInt64, UInt64, UInt64, Int32) raise ZipError {
  let locator_offset = eocd_offset - 20
  guard locator_offset >= 0 &&
    bytes[locator_offset:] is [u32le(ZIP64_LOCATOR_SIG), .. locator] else {
    raise ZipError(UnsupportedFeature, "zip: zip64 locator missing")
  }
  guard locator
    is [u32le(locator_disk), u64le(zip64_offset_u64), u32le(locator_disks), ..] else {
    raise ZipError(Truncated, "zip: truncated field")
  }
  if locator_disk != 0 || locator_disks != 1 {
    raise ZipError(
      UnsupportedFeature,
      "zip: multi-disk archives are not supported",
    )
  }
  let zip64_offset = zip64_offset_u64.to_int_checked()
  if zip64_offset > locator_offset || 12 > locator_offset - zip64_offset {
    raise ZipError(Truncated, "zip: zip64 end record out of bounds")
  }
  // The bounds check above leaves room for the signature and record size.
  guard bytes[zip64_offset:] is [u32le(sig), u64le(record_size), .. fields] else {
    raise ZipError(Truncated, "zip: truncated header")
  }
  if sig != ZIP64_EOCD_SIG {
    raise ZipError(InvalidSignature, "zip: invalid zip64 end record signature")
  }
  let expected = (locator_offset - zip64_offset - 12).to_uint64()
  if record_size < 44 || record_size != expected {
    raise ZipError(UnsupportedFeature, "zip: zip64 end record size mismatch")
  }
  guard fields
    is [
      u16le(_),
      u16le(_),
      u32le(disk_no),
      u32le(disk_start),
      u64le(entries_on_disk),
      u64le(total_entries),
      u64le(central_size),
      u64le(central_offset),
      ..,
    ] else {
    raise ZipError(Truncated, "zip: truncated header")
  }
  if disk_no != 0 || disk_start != 0 || entries_on_disk != total_entries {
    raise ZipError(
      UnsupportedFeature,
      "zip: multi-disk archives are not supported",
    )
  }
  (total_entries, central_size, central_offset, zip64_offset)
}

///|
fn data_descriptor_matches(
  bytes : BytesView,
  crc : UInt32,
  comp_size : UInt64,
  uncomp_size : UInt64,
  zip64 : Bool,
  signed : Bool,
) -> Bool {
  let fields = if signed {
    guard bytes is [u32le(DATA_DESCRIPTOR_SIG), .. fields] else { return false }
    fields
  } else {
    bytes
  }
  match fields {
    [u32le(found_crc), u64le(comp), u64le(uncomp), ..] if zip64 =>
      found_crc == crc && comp == comp_size && uncomp == uncomp_size
    [u32le(found_crc), u32le(comp), u32le(uncomp), ..] if !zip64 =>
      found_crc == crc &&
      comp.to_uint64() == comp_size &&
      uncomp.to_uint64() == uncomp_size
    _ => false
  }
}

///|
/// Determines the size of the entry's data descriptor (which may or may not be
/// signature-prefixed) by matching its candidate layouts against the
/// authoritative central-directory metadata.
fn data_descriptor_size(
  bytes : BytesView,
  offset : Int32,
  meta : MemoryEntryMeta,
  zip64 : Bool,
) -> Int32 raise ZipError {
  checked_data_descriptor_size(
    bytes[offset:],
    meta.crc,
    meta.compressed_size.to_uint64(),
    meta.uncompressed_size.to_uint64(),
    zip64,
  )
}

///|
/// Validate either descriptor layout against authoritative 64-bit directory sizes.
fn checked_data_descriptor_size(
  bytes : BytesView,
  crc : UInt32,
  comp_size : UInt64,
  uncomp_size : UInt64,
  zip64 : Bool,
) -> Int32 raise ZipError {
  let signed = data_descriptor_matches(
    bytes, crc, comp_size, uncomp_size, zip64, true,
  )
  let unsigned = data_descriptor_matches(
    bytes, crc, comp_size, uncomp_size, zip64, false,
  )
  if signed && unsigned {
    raise ZipError(UnsupportedFeature, "zip: ambiguous data descriptor")
  }
  if !signed && !unsigned {
    raise ZipError(
      UnsupportedFeature,
      "zip: data descriptor does not match central directory",
    )
  }
  (if signed { 4 } else { 0 }) + 4 + (if zip64 { 16 } else { 8 })
}

///|
fn local_size_matches(
  raw : UInt32,
  zip64 : UInt64?,
  expected : UInt64,
  allow_placeholder : Bool,
) -> Bool {
  let zip64_matches = zip64.map_or(true, value => {
    value == expected || (allow_placeholder && value == 0)
  })
  if allow_placeholder && raw == 0 {
    return zip64_matches
  }
  if raw == MAX_U32 {
    return zip64 is Some(_) && zip64_matches
  }
  raw.to_uint64() == expected && zip64_matches
}
