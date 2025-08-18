// Copyright 2025 International Digital Economy Academy
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
let data : Bytes = b"\xD4\xC3\xB2\xA1\x02\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\xFF\xFF\x00\x00\x01\x00\x00\x00\xBB\x0A\x64\x42\x6B\x54\x0D\x00\x4A\x00\x00\x00\x4A\x00\x00\x00\x00\xA0\xC5\x8F\xE3\xC7\x00\x0C\x76\x1C\x1B\x97\x08\x00\x45\x00\x00\x3C\x92\xA6\x40\x00\x40\x06\xFA\x91\xC0\xA8\x01\x21\xCC\xB2\x1F\x08\xDB\x2D\x02\x34\x67\xA5\x08\x98\x00\x00\x00\x00\x00\xA0\xC2\x16\xD0\x94\xBF\x00\x00\x02\x04\x05\xB4\x04\x02\x08\x0A\x06\x54\x9A\x3E\x00\x00\x00\x00\x01\x03\x03\x02"

///|
fn pcap_test(data : @bytes.View) -> Unit raise {
  match data {
    [
      i32(0xa1b2c3d4 | 0xa1b23c4d | 0xd4c3b2a1 | 0x4d3cb2a1 as magic),
      // major version
      i16le(2),
      // minor version
      i16le(4),
      // time zone
      i32(_),
      // unused
      i32(0),
      // snaplen
      i32(_),
      // network
      i32(_),
      .. packet,
    ] => {
      assert_eq(magic, 0xd4c3b2a1)
      pcap_packet_test(packet)
    }
    _ => fail("Not a valid pcap file")
  }
}

///|
fn pcap_packet_test(packet : @bytes.View) -> Unit raise {
  match packet {
    [i32(_), i32(_), i32le(incl_len), i32le(_orig_len), .. eth] =>
      pcap_eth_test(eth[:incl_len])
    _ => fail("Not a valid packet descriptor")
  }
}

///|
fn pcap_eth_test(eth : @bytes.View) -> Unit raise {
  match eth {
    [
      i8(0x00),
      i8(0xA0),
      i8(0xC5),
      i8(0x8F),
      i8(0xE3),
      //  destination MAC
      i8(0xC7),
      i8(0x00),
      i8(0x0C),
      i8(0x76),
      i8(0x1C),
      i8(0x1B),
      //  source MAC
      i8(0x97),
      //  ethertype
      i16be(0x0800),
      .. ipv4,
    ] => pcap_ipv4_test(ipv4)
    _ => fail("Not a valid ethernet frame")
  }
}

///|
fn pcap_ipv4_test(ipv4 : @bytes.View) -> Unit raise {
  match ipv4 {
    [
      i4(4),
      i4(5),
      //  dscn/ecn
      i8(0),
      i16be(60),
      //  ident
      i16be(0x92A6),
      //  flags
      i3(0x02),
      // fragment offset
      i13be(0),
      // ttl
      i8(64),
      i8(0x06),
      //  checksum
      i16be(0xFA91),
      i8(0xC0),
      i8(0xA8),
      i8(0x01),
      i8(0x21),
      i8(0xCC),
      i8(0xB2),
      i8(0x1F),
      i8(0x08),
      ..,
    ] => ()
    _ => fail("Not a valid ipv4 layer")
  }
}

///|
test "pcap_test" {
  inspect(try? pcap_test(data[:]), content="Ok(())")
}
