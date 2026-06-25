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
let utf8_is_valid_bench_size = 4096

///|
fn utf8_is_valid_ascii_bytes() -> Bytes {
  Bytes::makei(utf8_is_valid_bench_size, i => (0x20 + i % 0x5F).to_byte())
}

///|
fn utf8_is_valid_mixed_bytes() -> Bytes {
  Bytes::makei(utf8_is_valid_bench_size, i => {
    match i % 8 {
      0 => b'\xC3'
      1 => b'\xA9'
      2 => b'\xE4'
      3 => b'\xB8'
      4 => b'\xAD'
      _ => (0x41 + i % 26).to_byte()
    }
  })
}

///|
test "bench utf8.is_valid ascii n=4096" (it : @bench.T) {
  let bytes = utf8_is_valid_ascii_bytes()
  it.bench(fn() { it.keep(@utf8.is_valid(bytes)) })
}

///|
test "bench utf8.decode ascii n=4096" (it : @bench.T) {
  let bytes = utf8_is_valid_ascii_bytes()
  it.bench(fn() { it.keep(try! @utf8.decode(bytes)) })
}

///|
test "bench utf8.is_valid mixed n=4096" (it : @bench.T) {
  let bytes = utf8_is_valid_mixed_bytes()
  it.bench(fn() { it.keep(@utf8.is_valid(bytes)) })
}

///|
test "bench utf8.decode mixed n=4096" (it : @bench.T) {
  let bytes = utf8_is_valid_mixed_bytes()
  it.bench(fn() { it.keep(try! @utf8.decode(bytes)) })
}
