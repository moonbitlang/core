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
fn try_parse_ipv6(
  input : String,
) -> (FixedArray[Byte], Int32, String?) raise InvalidAddr {
  // Make sure the format is [addr]:port
  guard input.has_prefix("[") else {
    // IPv6 address must start with '['
    raise InvalidAddr
  }

  // Find the closing bracket
  guard input.rev_find("]") is Some(bracket_end) else {
    // IPv6 address missing closing ']'
    raise InvalidAddr
  }

  // Check the part after the closing bracket, it must be ":port"
  let remaining = input[bracket_end + 1:]
  guard remaining.has_prefix(":") else {
    // Missing port after IPv6 address
    raise InvalidAddr
  }

  // Parse the IPv6 address and port
  let ip_str = input[1:bracket_end]
  let port_str = remaining[1:]

  // Extract optional zone suffix
  let (ip_str, interface) = if ip_str.find("%") is Some(ip_end) {
    let interface = ip_str[ip_end + 1:]
    guard interface.length() > 0 else { raise InvalidAddr }
    (ip_str[:ip_end], Some(interface.to_owned()))
  } else {
    (ip_str, None)
  }

  // Parse the IPv6 address into a byte array
  let ip_bytes = parse_ipv6_to_bytes(ip_str)

  let port = parse_port(port_str)

  (ip_bytes, port, interface)
}

///|
fn parse_ipv6_to_bytes(
  ip_str : StringView,
) -> FixedArray[Byte] raise InvalidAddr {
  // Handle the case where the IPv6 address is "::"
  if ip_str == "::" {
    return FixedArray::make(16, 0)
  }

  // Check for "::" compression
  match ip_str.split("::").collect() {
    [ip_str] => parse_full_ipv6_to_bytes(ip_str)
    [left_part, right_part] =>
      parse_compressed_ipv6_to_bytes(left_part, right_part)
    _ =>
      // IPv6 address can only have one '::' compression
      raise InvalidAddr
  }
}

///|
fn parse_compressed_ipv6_to_bytes(
  left_part : StringView,
  right_part : StringView,
) -> FixedArray[Byte] raise InvalidAddr {
  let left_groups = if left_part.is_empty() {
    []
  } else {
    left_part.split(":").collect()
  }

  // Parse the right part, which may contain IPv4 address
  let right_groups = if right_part.is_empty() {
    []
  } else {
    right_part.split(":").collect()
  }

  // Check if the last group is an IPv4 address
  let ipv4_bytes = if !right_groups.is_empty() &&
    right_groups[right_groups.length() - 1].contains(".") {
    // Remove the IPv4 part from the right groups
    Some(parse_ipv4_to_bytes(right_groups.unsafe_pop()))
  } else {
    None
  }

  // Calculate the number of groups of compression
  let ipv4_group_count = if ipv4_bytes is None { 0 } else { 2 }
  let total_explicit_groups = left_groups.length() +
    right_groups.length() +
    ipv4_group_count
  guard total_explicit_groups < 8 else {
    // IPv6 address can have at most less than 8 explicit groups if "::" is used
    raise InvalidAddr
  }
  let compression_groups = 8 - total_explicit_groups

  // Build a 16-byte array initialized to zero
  let result : FixedArray[Byte] = FixedArray::make(16, 0)
  let mut byte_index = 0

  // Add left side groups
  for group_str in left_groups {
    let group_value = parse_ipv6_group(group_str)
    result[byte_index] = ((group_value >> 8) & 0xFF).to_byte()
    result[byte_index + 1] = (group_value & 0xFF).to_byte()
    byte_index += 2
  }

  // Add compression groups (zero groups)
  for _ in 0..<compression_groups {
    result[byte_index] = 0
    result[byte_index + 1] = 0
    byte_index += 2
  }

  // Add right side groups
  for group_str in right_groups {
    let group_value = parse_ipv6_group(group_str)
    result[byte_index] = ((group_value >> 8) & 0xFF).to_byte()
    result[byte_index + 1] = (group_value & 0xFF).to_byte()
    byte_index += 2
  }

  // Add IPv4 bytes if they were parsed
  if ipv4_bytes is Some((a, b, c, d)) {
    result[byte_index + 0] = a.to_byte()
    result[byte_index + 1] = b.to_byte()
    result[byte_index + 2] = c.to_byte()
    result[byte_index + 3] = d.to_byte()
  }
  result
}

///|
fn parse_full_ipv6_to_bytes(
  ip_str : StringView,
) -> FixedArray[Byte] raise InvalidAddr {
  let parts = ip_str.split(":").collect()
  let result : FixedArray[Byte] = FixedArray::make(16, 0)
  // Check if the last part contains a dot, indicating an embedded IPv4 address
  let ipv4_bytes = if parts[parts.length() - 1].contains(".") {
    guard parts.length() == 7 else {
      // IPv6 address with embedded IPv4 must have 7 parts
      raise InvalidAddr
    }
    Some(parse_ipv4_to_bytes(parts.unsafe_pop()))
  } else {
    guard parts.length() == 8 else {
      // Full IPv6 address must have 8 groups
      raise InvalidAddr
    }
    None
  }

  // Build a 16-byte array initialized to zero
  let mut byte_index = 0
  for part in parts {
    let group_value = parse_ipv6_group(part)
    result[byte_index] = ((group_value >> 8) & 0xFF).to_byte()
    result[byte_index + 1] = (group_value & 0xFF).to_byte()
    byte_index += 2
  }
  if ipv4_bytes is Some((a, b, c, d)) {
    result[byte_index + 0] = a.to_byte()
    result[byte_index + 1] = b.to_byte()
    result[byte_index + 2] = c.to_byte()
    result[byte_index + 3] = d.to_byte()
  }
  result
}

///|
fn parse_ipv6_group(group : StringView) -> UInt32 raise InvalidAddr {
  guard !group.is_empty() && group.length() <= 4 else { raise InvalidAddr }
  @string.parse_uint(group, base=16) catch {
    _ => raise InvalidAddr
  }
}

///|
fn parse_ipv6_zone_suffix(zone : StringView, context~ : String) -> UInt32 raise {
  try @string.parse_uint(zone) catch {
    _ => if_nametoindex(zone, context~)
  } noraise {
    index => index
  }
}

///|
fn parse_ipv4_to_bytes(
  ip_str : StringView,
) -> (UInt32, UInt32, UInt32, UInt32) raise InvalidAddr {
  let parts = ip_str.split(".").collect()
  guard parts.length() == 4 else { raise InvalidAddr }
  fn parse_octal(x : StringView) raise InvalidAddr {
    let value = @string.parse_uint(x) catch { _ => raise InvalidAddr }
    guard value < 256 else { raise InvalidAddr }
    value
  }

  return (
    parse_octal(parts[0]),
    parse_octal(parts[1]),
    parse_octal(parts[2]),
    parse_octal(parts[3]),
  )
}

///|
fn try_parse_ipv4(input : String) -> (UInt32, Int32) raise InvalidAddr {
  // Find the last colon to separate IP and port
  guard input.rev_find(":") is Some(last_colon) else { raise InvalidAddr }
  let ip_str = input[:last_colon]
  let port_str = input[last_colon + 1:]
  let port = parse_port(port_str)
  // Parse the IP address
  let (a, b, c, d) = parse_ipv4_to_bytes(ip_str.view())
  let ip = (a << 24) | (b << 16) | (c << 8) | d
  (ip, port)
}

///|
fn parse_port(port_str : StringView) -> Int32 raise InvalidAddr {
  guard !port_str.is_empty() else { raise InvalidAddr }
  let port = @string.parse_int(port_str) catch { _ => raise InvalidAddr }
  guard 0 <= port && port < 65536 else { raise InvalidAddr }
  port
}

///|
fn write_ipv6_str(addr : BytesView, logger : &Logger) -> Unit {
  let mut longest_zero_group = None
  fn add_zero_group(start, end) {
    if end > start {
      match longest_zero_group {
        Some((start0, end0)) if end0 - start0 >= end - start => ()
        _ => longest_zero_group = Some((start, end))
      }
    }
  }

  for i = 0, zero_group_start = 0; i < 8; i = i + 1 {
    if addr[i * 2] == 0 && addr[i * 2 + 1] == 0 {
      continue
    } else {
      add_zero_group(zero_group_start, i)
      continue i + 1, i + 1
    }
  } nobreak {
    add_zero_group(zero_group_start, i)
  }
  let is_v4_mapped = match longest_zero_group {
    Some((0, 6)) => true
    Some((0, 5)) => addr[10] is 0xff && addr[11] is 0xff
    _ => false
  }
  let hex_format_end = if is_v4_mapped { 6 } else { 8 }
  for i = 0; i < hex_format_end; i = i + 1 {
    match longest_zero_group {
      Some((start, end)) if i == start => {
        if i == 0 {
          logger <+ "::"
        } else {
          logger <+ ":"
        }
        continue end
      }
      _ => ()
    }
    let value = (addr[i * 2].to_int() << 8) | addr[i * 2 + 1].to_int()
    logger <+ "\{value.to_string(radix=16)}"
    if i < 7 {
      logger <+ ":"
    }
  }
  if is_v4_mapped {
    logger <+
      "\{addr[12].to_int()}.\{addr[13].to_int()}.\{addr[14].to_int()}.\{addr[15].to_int()}"
  }
}
