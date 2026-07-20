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
let ascii_bench_size = 100_000

///|
let ascii_bench_bytes : Bytes = Bytes::make(ascii_bench_size, b'A')

///|
let ascii_bench_large_size = 1_000_000

///|
let ascii_bench_large_bytes : Bytes = Bytes::make(ascii_bench_large_size, b'A')

///|
let ascii_bench_bytes_15 : Bytes = Bytes::make(15, b'A')

///|
let ascii_bench_bytes_16 : Bytes = Bytes::make(16, b'A')

///|
let ascii_bench_bytes_32 : Bytes = Bytes::make(32, b'A')

///|
let ascii_bench_bytes_64 : Bytes = Bytes::make(64, b'A')

///|
test "bench ASCII decode n=15" (it : @bench.T) {
  let bytes = ascii_bench_bytes_15
  it.bench(fn() { it.keep((try! @ascii.decode(bytes)).length()) })
}

///|
test "bench ASCII decode n=16" (it : @bench.T) {
  let bytes = ascii_bench_bytes_16
  it.bench(fn() { it.keep((try! @ascii.decode(bytes)).length()) })
}

///|
test "bench ASCII decode n=32" (it : @bench.T) {
  let bytes = ascii_bench_bytes_32
  it.bench(fn() { it.keep((try! @ascii.decode(bytes)).length()) })
}

///|
test "bench ASCII decode n=64" (it : @bench.T) {
  let bytes = ascii_bench_bytes_64
  it.bench(fn() { it.keep((try! @ascii.decode(bytes)).length()) })
}

///|
test "bench ASCII decode n=100000" (it : @bench.T) {
  let bytes = ascii_bench_bytes
  it.bench(fn() { it.keep((try! @ascii.decode(bytes)).length()) })
}

///|
test "bench ASCII decode n=1000000" (it : @bench.T) {
  let bytes = ascii_bench_large_bytes
  it.bench(fn() { it.keep((try! @ascii.decode(bytes)).length()) })
}
