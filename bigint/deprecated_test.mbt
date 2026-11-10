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

// The deprecated `to_octets` / `from_octets` keep their old contracts until
// they are removed: `length` is a minimum, and `signum` picks the sign.

///|
#warnings("-deprecated")
test "to_octets length is a minimum" {
  // shorter values are padded
  inspect(256N.to_octets(length=4), content="b\"\\x00\\x00\\x01\\x00\"")
  // longer values are returned in full instead of panicking
  inspect(256N.to_octets(length=1), content="b\"\\x01\\x00\"")
  inspect((1N << 64).to_octets(length=8).length(), content="9")
  inspect(256N.to_octets(), content="b\"\\x01\\x00\"")
}

///|
#warnings("-deprecated")
test "panic to_octets negative length" {
  256N.to_octets(length=-1) |> ignore
}

///|
#warnings("-deprecated")
test "panic to_octets negative value" {
  (-1N).to_octets(length=4) |> ignore
}

///|
#warnings("-deprecated")
test "from_octets applies signum" {
  inspect(@bigint.BigInt::from_octets(b"\x01\x02"), content="258")
  inspect(@bigint.BigInt::from_octets(b"\x01\x02", signum=5), content="258")
  inspect(@bigint.BigInt::from_octets(b"\x01\x02", signum=-1), content="-258")
  inspect(@bigint.BigInt::from_octets(b"\x01\x02", signum=-7), content="-258")
  // signum = 0 yields zero regardless of the bytes
  inspect(@bigint.BigInt::from_octets(b"\x01\x02", signum=0), content="0")
  inspect(@bigint.BigInt::from_octets(b"", signum=-1), content="0")
}
