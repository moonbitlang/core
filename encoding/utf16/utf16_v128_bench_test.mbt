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
let utf16_v128_bench_size = 100_000

///|
let utf16_v128_bench_ascii : String = String::make(utf16_v128_bench_size, 'a')

///|
let utf16_v128_bench_mixed : String = String::make(50_000, 'a') +
  String::make(25_000, '中') +
  String::make(25_000, 'b')

///|
let utf16_v128_bench_emoji : String = String::make(50_000, '👀')

///|
let utf16_v128_bench_ascii_le : Bytes = @utf16.encode(utf16_v128_bench_ascii)

///|
let utf16_v128_bench_ascii_be : Bytes = @utf16.encode(
  utf16_v128_bench_ascii,
  endianness=Big,
)

///|
let utf16_v128_bench_mixed_le : Bytes = @utf16.encode(utf16_v128_bench_mixed)

///|
let utf16_v128_bench_mixed_be : Bytes = @utf16.encode(
  utf16_v128_bench_mixed,
  endianness=Big,
)

///|
let utf16_v128_bench_emoji_le : Bytes = @utf16.encode(utf16_v128_bench_emoji)

///|
let utf16_v128_bench_emoji_be : Bytes = @utf16.encode(
  utf16_v128_bench_emoji,
  endianness=Big,
)

///|
test "bench utf16 encode ASCII LE n=100000" (it : @bench.T) {
  let s = utf16_v128_bench_ascii
  it.bench(fn() { it.keep(@utf16.encode(s).length()) })
}

///|
test "bench utf16 encode ASCII BE n=100000" (it : @bench.T) {
  let s = utf16_v128_bench_ascii
  it.bench(fn() { it.keep(@utf16.encode(s, endianness=Big).length()) })
}

///|
test "bench utf16 encode mixed LE n=100000" (it : @bench.T) {
  let s = utf16_v128_bench_mixed
  it.bench(fn() { it.keep(@utf16.encode(s).length()) })
}

///|
test "bench utf16 encode mixed BE n=100000" (it : @bench.T) {
  let s = utf16_v128_bench_mixed
  it.bench(fn() { it.keep(@utf16.encode(s, endianness=Big).length()) })
}

///|
test "bench utf16 decode ASCII LE n=100000" (it : @bench.T) {
  let bytes = utf16_v128_bench_ascii_le
  it.bench(fn() { it.keep((try! @utf16.decode(bytes)).length()) })
}

///|
test "bench utf16 decode ASCII BE n=100000" (it : @bench.T) {
  let bytes = utf16_v128_bench_ascii_be
  it.bench(fn() {
    it.keep((try! @utf16.decode(bytes, endianness=Big)).length())
  })
}

///|
test "bench utf16 decode mixed LE n=100000" (it : @bench.T) {
  let bytes = utf16_v128_bench_mixed_le
  it.bench(fn() { it.keep((try! @utf16.decode(bytes)).length()) })
}

///|
test "bench utf16 decode mixed BE n=100000" (it : @bench.T) {
  let bytes = utf16_v128_bench_mixed_be
  it.bench(fn() {
    it.keep((try! @utf16.decode(bytes, endianness=Big)).length())
  })
}

///|
test "bench utf16 decode emoji LE n=100000" (it : @bench.T) {
  let bytes = utf16_v128_bench_emoji_le
  it.bench(fn() { it.keep((try! @utf16.decode(bytes)).length()) })
}

///|
test "bench utf16 decode emoji BE n=100000" (it : @bench.T) {
  let bytes = utf16_v128_bench_emoji_be
  it.bench(fn() {
    it.keep((try! @utf16.decode(bytes, endianness=Big)).length())
  })
}
