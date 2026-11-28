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
// TODO: faster implementation
fn IpAddr::parse_aux(
  host : StringView,
  require_bracket~ : Bool,
  context~ : String,
) -> IpAddr raise {
  if host is ['[', .. ipv6_str, ']'] {
    parse_ipv6(ipv6_str, context~)
  } else {
    try parse_ipv4(host) catch {
      _ if !require_bracket => parse_ipv6(host, context~)
      err => raise err
    } noraise {
      ip => Ipv4(ip)
    }
  }
}

///|
fn parse_ipv6(ip_str : StringView, context~ : String) -> IpAddr raise {
  // Extract optional zone suffix
  let (ip_str, scope_id) = if ip_str.split_once("%") is Some((addr, interface)) {
    guard interface.length() > 0 else { raise InvalidAddr }
    (addr, parse_ipv6_zone_suffix(interface, context~))
  } else {
    (ip_str, 0)
  }

  let bytes = parse_ipv6_bytes(ip_str)
  Ipv6(bytes, scope_id~)
}

///|
fn parse_ipv6_bytes(input : StringView) -> Bytes raise InvalidAddr {
  let bytes : FixedArray[Byte] = FixedArray::make(16, 0)
  let mut gap : Int32? = None
  let input = match input {
    [':', ':', .. rest] => {
      gap = Some(0)
      rest
    }
    _ => input
  }
  let used = for rest = input, offset = 0; !rest.is_empty(); {
    guard offset < 16 else { raise InvalidAddr }
    lexmatch rest with longest {
      (
        re"^" +
        (re"[0-9A-Fa-f]{1,4}" as group) +
        (re"::?|$" as separator),
        after=rest,
      ) => {
        let value = try! @string.parse_uint(group, radix=16)
        bytes[offset] = (value >> 8).to_byte()
        bytes[offset + 1] = value.to_byte()
        match separator {
          "::" => {
            guard gap is None else { raise InvalidAddr }
            gap = Some(offset + 2)
          }
          ":" if rest.is_empty() => raise InvalidAddr
          _ => ()
        }
        continue rest, offset + 2
      }
      _ => {
        guard offset <= 12 else { raise InvalidAddr }
        let (a, b, c, d) = parse_ipv4_to_bytes(rest)
        bytes[offset] = a.to_byte()
        bytes[offset + 1] = b.to_byte()
        bytes[offset + 2] = c.to_byte()
        bytes[offset + 3] = d.to_byte()
        break offset + 4
      }
    }
  } nobreak {
    offset
  }
  if gap is Some(start) {
    guard used < 16 else { raise InvalidAddr }
    // Move the suffix to the end and expand :: into the omitted zero groups.
    let end = start + 16 - used
    bytes.blit_to(bytes, src_offset=start, dst_offset=end, len=used - start)
    bytes.fill(0, start~, end~)
  } else {
    guard used == 16 else { raise InvalidAddr }
  }
  bytes.unsafe_reinterpret_as_bytes()
}

///|
fn parse_ipv6_zone_suffix(zone : StringView, context~ : String) -> UInt32 raise {
  guard zone =~ re"^[0-9]+$" else { return if_nametoindex(zone, context~) }
  @string.parse_uint(zone, radix=10) catch {
    _ => if_nametoindex(zone, context~)
  }
}

///|
fn parse_ipv4_to_bytes(
  ip_str : StringView,
) -> (UInt32, UInt32, UInt32, UInt32) raise InvalidAddr {
  guard ip_str =~ (
    re"^" +
    (re"[0-9]+" as a) +
    re"\." +
    (re"[0-9]+" as b) +
    re"\." +
    (re"[0-9]+" as c) +
    re"\." +
    (re"[0-9]+" as d) +
    re"$"
  ) else {
    raise InvalidAddr
  }
  fn parse_octet(x : StringView) raise InvalidAddr {
    let value = @string.parse_uint(x, radix=10) catch { _ => raise InvalidAddr }
    guard value < 256 else { raise InvalidAddr }
    value
  }
  (parse_octet(a), parse_octet(b), parse_octet(c), parse_octet(d))
}

///|
fn parse_ipv4(input : StringView) -> UInt32 raise InvalidAddr {
  let (a, b, c, d) = parse_ipv4_to_bytes(input)
  (a << 24) | (b << 16) | (c << 8) | d
}

///|
fn parse_port(port_str : StringView) -> UInt16 raise InvalidAddr {
  guard !port_str.is_empty() else { raise InvalidAddr }
  let port = @string.parse_int(port_str) catch { _ => raise InvalidAddr }
  guard 0 <= port && port < 65536 else { raise InvalidAddr }
  port.to_uint16()
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
