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
test "encoded_len" {
  inspect(@hex.encoded_len(0), content="0")
  inspect(@hex.encoded_len(1), content="2")
  inspect(@hex.encoded_len(13), content="26")
}

///|
test "encode" {
  inspect(@hex.encode(b""), content="")
  inspect(@hex.encode(b"Hello"), content="48656c6c6f")
  inspect(@hex.encode(b"Hello Gopher!"), content="48656c6c6f20476f7068657221")
  inspect(@hex.encode(b"\x00\x0f\x10\x7f\x80\xff"), content="000f107f80ff")
}

///|
test "encode all byte values" {
  let bytes = Bytes::makei(256, i => i.to_byte())
  let encoded = @hex.encode(bytes)
  inspect(encoded.length(), content="512")
  inspect(encoded[:32], content="000102030405060708090a0b0c0d0e0f")
  inspect(encoded[-32:], content="f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff")
}
