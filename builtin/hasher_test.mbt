// Copyright 2024 International Digital Economy Academy
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

test "combine int" {
  fn hash(v) {
    Hasher::new()..combine_int(v).finalize()
  }

  inspect!(hash(0), content="148298089")
  inspect!(hash(1), content="-205818221")
  inspect!(hash(2), content="527729046")
  inspect!(hash(2147483647), content="1225377669")
  inspect!(hash(-2147483648), content="1509677505")
  inspect!(hash(0) == hash(0), content="true")
  inspect!(hash(1) == hash(1), content="true")
  inspect!(hash(0) == hash(1), content="false")
}

test "combine int64" {
  fn hash(v) {
    Hasher::new()..combine_int64(v).finalize()
  }

  inspect!(hash(0), content="-558656237")
  inspect!(hash(1), content="149775153")
  inspect!(hash(2), content="-368796614")
  inspect!(hash(9223372036854775807), content="1886677411")
  inspect!(hash(-9223372036854775808), content="483163611")
  inspect!(hash(0) == hash(0), content="true")
  inspect!(hash(1) == hash(1), content="true")
  inspect!(hash(0) == hash(1), content="false")
}

test "combine uint" {
  fn hash(v) {
    Hasher::new()..combine_uint(v).finalize()
  }

  inspect!(hash(0), content="148298089")
  inspect!(hash(1), content="-205818221")
  inspect!(hash(2), content="527729046")
  inspect!(hash(4294967295), content="67608159")
  inspect!(hash(0) == hash(0), content="true")
  inspect!(hash(1) == hash(1), content="true")
  inspect!(hash(0) == hash(1), content="false")
}

test "combine uint64" {
  fn hash(v) {
    Hasher::new()..combine_uint64(v).finalize()
  }

  inspect!(hash(0), content="-558656237")
  inspect!(hash(1), content="149775153")
  inspect!(hash(2), content="-368796614")
  inspect!(hash(18446744073709551615), content="-1048394023")
  inspect!(hash(0) == hash(0), content="true")
  inspect!(hash(1) == hash(1), content="true")
  inspect!(hash(0) == hash(1), content="false")
}

test "combine double" {
  fn hash(v) {
    Hasher::new()..combine_double(v).finalize()
  }

  inspect!(hash(0.0), content="-558656237")
  inspect!(hash(0.1), content="1840903062")
  inspect!(hash(0.2), content="-1200607554")
  inspect!(hash(0.0) == hash(0.0), content="true")
  inspect!(hash(0.1) == hash(0.1), content="true")
  inspect!(hash(0.0) == hash(0.1), content="false")
}

test "combine string" {
  fn hash(v) {
    Hasher::new()..combine_string(v).finalize()
  }

  inspect!(hash(""), content="46947589")
  inspect!(hash("abc"), content="-771846975")
  inspect!(
    hash("a quick brown fox jumps over the lazy dog"),
    content="432119934",
  )
  inspect!(hash("") == hash(""), content="true")
  inspect!(hash("abc") == hash("abc"), content="true")
  inspect!(hash("a") == hash("a"), content="true")
  inspect!(hash("a") == hash("abc"), content="false")
  inspect!(hash("five") == hash("five"), content="true")
}

test "combine bytes" {
  fn bytes_of(arr : Array[Int]) {
    let rv = Bytes::new(arr.length())
    for i = 0; i < arr.length(); i = i + 1 {
      rv[i] = arr[i].to_byte()
    }
    rv
  }

  fn hash(v) {
    Hasher::new()..combine_bytes(v).finalize()
  }

  let b1 = bytes_of(
    [65, 0, 66, 0, 67, 0, 68, 0, 69, 0, 70, 0, 71, 0, 72, 0, 73, 0],
  )
  let b2 = bytes_of(
    [65, 0, 66, 0, 67, 0, 68, 0, 69, 0, 70, 0, 71, 0, 72, 0, 74, 0],
  )
  let b3 = bytes_of([128, 0, 0, 0, 0, 0, 0])
  let b4 = bytes_of([127, 255, 255, 255, 255, 255, 255])
  inspect!(hash(b1), content="2001377227")
  inspect!(hash(b2), content="-1020996018")
  inspect!(hash(b3), content="-1280010923")
  inspect!(hash(b4), content="-198077265")
  inspect!(hash(b1) == hash(b1), content="true")
  inspect!(hash(b2) == hash(b2), content="true")
  inspect!(hash(b1) == hash(b2), content="false")
}

test "combine byte" {
  fn hash(v) {
    Hasher::new()..combine_byte(v).finalize()
  }

  inspect!(hash(b'0'), content="-1971641254")
  inspect!(hash(b'1'), content="1943578595")
  inspect!(hash(b'2'), content="1881073354")
  inspect!(hash(b'0') == hash(b'0'), content="true")
  inspect!(hash(b'1') == hash(b'1'), content="true")
  inspect!(hash(b'0') == hash(b'1'), content="false")
}

test "combine all" {
  let hasher = Hasher::new()
  hasher..combine_int(1)..combine_int64(2147483648)..combine_uint(2)..combine_uint64(
    4294967296,
  )..combine_double(1.234)..combine_string("Moonbit").combine_bytes(
    Bytes::make(10, b'1'),
  )
  inspect!(hasher.finalize(), content="1982681228")
  inspect!(hasher.finalize() == hasher.finalize(), content="true")
}
