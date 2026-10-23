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
test "Parse IPv4 address" {
  assert_eq(@socket.Addr::parse("127.0.0.1:8080").to_string(), "127.0.0.1:8080")
  assert_eq(@socket.Addr::parse("0.0.0.0:8080").to_string(), "0.0.0.0:8080")
  assert_eq(
    @socket.Addr::parse("255.255.255.255:8080").to_string(),
    "255.255.255.255:8080",
  )
  assert_eq(
    @socket.Addr::parse("172.31.254.253:8080").to_string(),
    "172.31.254.253:8080",
  )
}

///|
test "Parse invalid IPv4 address" {
  // Too short
  @test.assert_raise(() => @socket.Addr::parse("127.0.0.1"))

  // Too long
  @test.assert_raise(() => @socket.Addr::parse("127.0.0.1:8080:8080"))

  // Invalid IP, out of range
  @test.assert_raise(() => @socket.Addr::parse("256.0.0.1:8080"))
}

///|
async test "Parse IPv6 address" {
  let addr = @socket.Addr::parse("[2a02:6b8::11:11]:8080")
  assert_eq(addr.to_string(), "[2a02:6b8::11:11]:8080")
  assert_eq(
    @socket.Addr::parse("[0:0:0:0:0:0:0:0]:8080").to_string(),
    "[::]:8080",
  )
  assert_eq(
    @socket.Addr::parse("[0:0:0:0:0:0:0:1]:8080").to_string(),
    "[::1]:8080",
  )
  assert_eq(@socket.Addr::parse("[::1]:8080").to_string(), "[::1]:8080")
  assert_eq(
    @socket.Addr::parse("[::1%\{test_interface.wait()}]:8080").to_string(),
    "[::1%\{test_interface.wait()}]:8080",
  )
  assert_eq(
    @socket.Addr::parse("[::1%\{test_interface_index.wait()}]:8080").to_string(),
    "[::1%\{test_interface.wait()}]:8080",
  )
}

///|
test "Parse invalid IPv6 address" {
  // Too short
  @test.assert_raise(() => @socket.Addr::parse("[1:2:3:4:5:6:7:8080]"))

  // Too long
  @test.assert_raise(() => @socket.Addr::parse("[1:2:3:4:5:6:7:8:9:8080]"))

  // triple colon
  @test.assert_raise(() => @socket.Addr::parse("[1:2:::6:7:8]:8080]"))

  // two double colons
  @test.assert_raise(() => @socket.Addr::parse("[1:2::6::8]:8080]"))
}

///|
test "Parse IPv6 address with ipv4" {
  let addr = @socket.Addr::parse("[::ffff:192.0.2.33]:8080")
  assert_eq(addr.to_string(), "[::ffff:192.0.2.33]:8080")
  let addr = @socket.Addr::parse("[::FFFF:192.0.2.33]:8080")
  assert_eq(addr.to_string(), "[::ffff:192.0.2.33]:8080")
  // Not enough groups
  @test.assert_raise(() => @socket.Addr::parse("[1:2:3:4:5:127.0.0.1]:8080"))
  // Too many groups
  @test.assert_raise(() => @socket.Addr::parse("[1:2:3:4:5:6:7:127.0.0.1]:8080"))
}
