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
let data : Bytes = b"\xD4\xC3\xB2\xA1\x02\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\xFF\xFF\x00\x00\x01\x00\x00\x00\xBB\x0A\x64\x42\x6B\x54\x0D\x00\x4A\x00\x00\x00\x4A\x00\x00\x00\x00\xA0\xC5\x8F\xE3\xC7\x00\x0C\x76\x1C\x1B\x97\x08\x00\x45\x00\x00\x3C\x92\xA6\x40\x00\x40\x06\xFA\x91\xC0\xA8\x01\x21\xCC\xB2\x1F\x08\xDB\x2D\x02\x34\x67\xA5\x08\x98\x00\x00\x00\x00\x00\xA0\xC2\x16\xD0\x94\xBF\x00\x00\x02\x04\x05\xB4\x04\x02\x08\x0A\x06\x54\x9A\x3E\x00\x00\x00\x00\x01\x03\x03\x02"

///|
fn pcap_test(data : BytesView) -> Unit raise {
  match data {
    [
      u32be(0xa1b2c3d4 | 0xa1b23c4d | 0xd4c3b2a1 | 0x4d3cb2a1 as magic),
      // major version
      u16le(2),
      // minor version
      u16le(4),
      // time zone
      u32be(_),
      // unused
      u32be(0),
      // snaplen
      u32be(_),
      // network
      u32be(_),
      .. packet,
    ] => {
      assert_eq(magic, 0xd4c3b2a1)
      pcap_packet_test(packet)
    }
    _ => fail("Not a valid pcap file")
  }
}

///|
fn pcap_packet_test(packet : BytesView) -> Unit raise {
  match packet {
    [u32be(_), u32be(_), u32le(incl_len), u32le(_orig_len), .. eth] => {
      let incl_len = incl_len.reinterpret_as_int()
      pcap_eth_test(eth[:incl_len])
    }
    _ => fail("Not a valid packet descriptor")
  }
}

///|
fn pcap_eth_test(eth : BytesView) -> Unit raise {
  match eth {
    [
      u8be(0x00),
      u8be(0xA0),
      u8be(0xC5),
      u8be(0x8F),
      u8be(0xE3),
      //  destination MAC
      u8be(0xC7),
      u8be(0x00),
      u8be(0x0C),
      u8be(0x76),
      u8be(0x1C),
      u8be(0x1B),
      //  source MAC
      u8be(0x97),
      //  ethertype
      u16be(0x0800),
      .. ipv4,
    ] => pcap_ipv4_test(ipv4)
    _ => fail("Not a valid ethernet frame")
  }
}

///|
fn pcap_ipv4_test(ipv4 : BytesView) -> Unit raise {
  match ipv4 {
    [
      u4be(4),
      u4be(5),
      //  dscn/ecn
      u8be(0),
      u16be(60),
      //  ident
      u16be(0x92A6),
      //  flags
      u3be(0x02),
      // fragment offset
      u13be(0),
      // ttl
      u8be(64),
      u8be(0x06),
      //  checksum
      u16be(0xFA91),
      u8be(0xC0),
      u8be(0xA8),
      u8be(0x01),
      u8be(0x21),
      u8be(0xCC),
      u8be(0xB2),
      u8be(0x1F),
      u8be(0x08),
      ..,
    ] => ()
    _ => fail("Not a valid ipv4 layer")
  }
}

///|
test "pcap_test" {
  inspect(try? pcap_test(data[:]), content="Ok(())")
}

///|
test "u32le u32be last" {
  match b"\x01\x02\x03\x04" {
    [.., u32le(x)] => assert_eq(x, 0x04030201)
    _ => fail("Not matched")
  }
  match b"\x01\x02\x03\x04" {
    [.., u32be(x)] => assert_eq(x, 0x01020304)
    _ => fail("Not matched")
  }
}
