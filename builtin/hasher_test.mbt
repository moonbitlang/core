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
test "combine int" {
  let hash = v => {
    let hasher = Hasher::new(seed=0)
    hasher.combine_int(v)
    hasher.finalize()
  }
  inspect(hash(0), content="148298089")
  inspect(hash(1), content="-205818221")
  inspect(hash(2), content="527729046")
  inspect(hash(2147483647), content="1225377669")
  inspect(hash(-2147483648), content="1509677505")
  inspect(hash(0) == hash(0), content="true")
  inspect(hash(1) == hash(1), content="true")
  inspect(hash(0) == hash(1), content="false")
}

///|
test "combine char" {
  let hash = v => {
    let hasher = Hasher::new(seed=0)
    hasher.combine_char(v)
    hasher.finalize()
  }
  inspect(hash('c'), content="-1500876651")
}

///|
test "combine int64" {
  let hash = v => {
    let hasher = Hasher::new(seed=0)
    hasher.combine_int64(v)
    hasher.finalize()
  }
  inspect(hash(0), content="-558656237")
  inspect(hash(1), content="149775153")
  inspect(hash(2), content="-368796614")
  inspect(hash(9223372036854775807), content="1886677411")
  inspect(hash(-9223372036854775808), content="483163611")
  inspect(hash(0) == hash(0), content="true")
  inspect(hash(1) == hash(1), content="true")
  inspect(hash(0) == hash(1), content="false")
}

///|
test "combine uint" {
  let hash = v => {
    let hasher = Hasher::new(seed=0)
    hasher.combine_uint(v)
    hasher.finalize()
  }
  inspect(hash(0), content="148298089")
  inspect(hash(1), content="-205818221")
  inspect(hash(2), content="527729046")
  inspect(hash(4294967295), content="67608159")
  inspect(hash(0) == hash(0), content="true")
  inspect(hash(1) == hash(1), content="true")
  inspect(hash(0) == hash(1), content="false")
}

///|
test "combine uint64" {
  let hash = v => {
    let hasher = Hasher::new(seed=0)
    hasher.combine_uint64(v)
    hasher.finalize()
  }
  inspect(hash(0), content="-558656237")
  inspect(hash(1), content="149775153")
  inspect(hash(2), content="-368796614")
  inspect(hash(18446744073709551615), content="-1048394023")
  inspect(hash(0) == hash(0), content="true")
  inspect(hash(1) == hash(1), content="true")
  inspect(hash(0) == hash(1), content="false")
}

///|
test "combine double" {
  let hash = v => {
    let hasher = Hasher::new(seed=0)
    hasher.combine_double(v)
    hasher.finalize()
  }
  inspect(hash(0.0), content="-558656237")
  inspect(hash(0.1), content="1840903062")
  inspect(hash(0.2), content="-1200607554")
  inspect(hash(0.0) == hash(0.0), content="true")
  inspect(hash(0.1) == hash(0.1), content="true")
  inspect(hash(0.0) == hash(0.1), content="false")
}

///|
test "combine float" {
  let hash = (v : Float) => {
    let hasher = Hasher::new(seed=0)
    hasher.combine(v)
    hasher.finalize()
  }
  inspect(hash(0.0), content="148298089")
  inspect(hash(0.1), content="1101647392")
  inspect(hash(0.2), content="-352548260")
  inspect(hash(0.0) == hash(0.0), content="true")
  inspect(hash(0.1) == hash(0.1), content="true")
  inspect(hash(0.0) == hash(0.1), content="false")
}

///|
test "combine string" {
  let hash = v => {
    let hasher = Hasher::new(seed=0)
    hasher.combine_string(v)
    hasher.finalize()
  }
  inspect(hash(""), content="46947589")
  inspect(hash("abc"), content="-771846975")
  inspect(
    hash("a quick brown fox jumps over the lazy dog"),
    content="432119934",
  )
  inspect(hash("") == hash(""), content="true")
  inspect(hash("abc") == hash("abc"), content="true")
  inspect(hash("a") == hash("a"), content="true")
  inspect(hash("a") == hash("abc"), content="false")
  inspect(hash("five") == hash("five"), content="true")
}

///|
test "combine bytes" {
  let hash = v => {
    let hasher = Hasher::new(seed=0)
    hasher.combine_bytes(v)
    hasher.finalize()
  }
  let b1 : Bytes = [
    65, 0, 66, 0, 67, 0, 68, 0, 69, 0, 70, 0, 71, 0, 72, 0, 73, 0,
  ]
  let b2 : Bytes = [
    65, 0, 66, 0, 67, 0, 68, 0, 69, 0, 70, 0, 71, 0, 72, 0, 74, 0,
  ]
  let b3 : Bytes = [128, 0, 0, 0, 0, 0, 0]
  let b4 : Bytes = [127, 255, 255, 255, 255, 255, 255]
  inspect(hash(b1), content="2001377227")
  inspect(hash(b2), content="-1020996018")
  inspect(hash(b3), content="-1280010923")
  inspect(hash(b4), content="-198077265")
  inspect(hash(b1) == hash(b1), content="true")
  inspect(hash(b2) == hash(b2), content="true")
  inspect(hash(b1) == hash(b2), content="false")
}

///|
test "combine byte" {
  let hash = v => {
    let hasher = Hasher::new(seed=0)
    hasher.combine_byte(v)
    hasher.finalize()
  }
  inspect(hash(b'0'), content="-1971641254")
  inspect(hash(b'1'), content="1943578595")
  inspect(hash(b'2'), content="1881073354")
  inspect(hash(b'0') == hash(b'0'), content="true")
  inspect(hash(b'1') == hash(b'1'), content="true")
  inspect(hash(b'0') == hash(b'1'), content="false")
}

///|
test "combine all" {
  let hasher = Hasher::new(seed=0)
  hasher
  ..combine_int(1)
  ..combine_int64(2147483648)
  ..combine_uint(2)
  ..combine_uint64(4294967296)
  ..combine_double(1.234)
  ..combine_string("Moonbit")
  ..combine_bytes(Bytes::make(10, b'1'))
  inspect(hasher.finalize(), content="1982681228")
  inspect(hasher.finalize() == hasher.finalize(), content="true")
}

///|
test "combine_unit" {
  let hasher = @builtin.Hasher::new(seed=0)
  hasher.combine_unit()
  let hash = hasher.finalize()
  let hasher2 = @builtin.Hasher::new(seed=0)
  hasher2.combine_int(0)
  let hash2 = hasher2.finalize()
  inspect(hash == hash2, content="true")
}

///|
test "combine_bool" {
  let hasher = @builtin.Hasher::new(seed=0)
  hasher.combine_bool(true)
  let hash1 = hasher.finalize()
  let hasher2 = @builtin.Hasher::new(seed=0)
  hasher2.combine_int(1)
  let hash2 = hasher2.finalize()
  assert_eq(hash1, hash2)
  let hasher3 = @builtin.Hasher::new(seed=0)
  hasher3.combine_bool(false)
  let hash3 = hasher3.finalize()
  let hasher4 = @builtin.Hasher::new(seed=0)
  hasher4.combine_int(0)
  let hash4 = hasher4.finalize()
  assert_eq(hash3, hash4)
}

///|
test "Result::hash_combine Ok case" {
  // Test the Ok case
  let hasher = Hasher::new(seed=0)
  let ok_result : Result[Int, String] = Ok(42)
  hasher.combine(ok_result)
  inspect(hasher.finalize(), content="-1948635851")
}

///|
test "Result::hash_combine Err case" {
  let hasher = Hasher::new(seed=0)
  let err_result : Result[Int, String] = Err("error")
  hasher.combine(err_result)
  inspect(hasher.finalize(), content="1953766574")
}

///|
test "option hash" {
  let hasher = @builtin.Hasher::new(seed=0)
  let some_val : Int? = Some(42)
  hasher.combine(some_val)
  inspect(hasher.finalize(), content="2103260413")
  let hasher2 = @builtin.Hasher::new(seed=0)
  let none_val : Int? = None
  hasher2.combine(none_val)
  inspect(hasher2.finalize(), content="148298089")
}

///|
test "UInt64::hash_combine test" {
  let hasher = @builtin.Hasher::new(seed=0)
  let value = 42UL
  @builtin.Hash::hash_combine(value, hasher)
  inspect(hasher.finalize(), content="-1962516083")
}

///|
test "hash_combine for UInt" {
  let hasher = Hasher::new(seed=0)
  let value : UInt = 42U
  Hash::hash_combine(value, hasher)
  inspect(hasher.finalize(), content="1161967057")
}
