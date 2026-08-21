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

// Scalar and public (vectorized on the linear-memory backends) codec paths
// benchmarked side by side, so a single run per target reports both.

///|
let hex_bench_input_64 : Bytes = sample_bytes(64)

///|
let hex_bench_input_4k : Bytes = sample_bytes(4096)

///|
let hex_bench_input_64k : Bytes = sample_bytes(65536)

///|
let hex_bench_text_4k : String = encode_scalar(hex_bench_input_4k)

///|
let hex_bench_text_64k : String = encode_scalar(hex_bench_input_64k)

///|
test "bench encode scalar 4k" (it : @bench.T) {
  it.bench(fn() { it.keep(encode_scalar(hex_bench_input_4k).length()) })
}

///|
test "bench encode public 64" (it : @bench.T) {
  it.bench(fn() { it.keep(encode(hex_bench_input_64).length()) })
}

///|
test "bench encode public 4k" (it : @bench.T) {
  it.bench(fn() { it.keep(encode(hex_bench_input_4k).length()) })
}

///|
test "bench encode public 64k" (it : @bench.T) {
  it.bench(fn() { it.keep(encode(hex_bench_input_64k).length()) })
}

///|
test "bench decode scalar 4k" (it : @bench.T) {
  it.bench(fn() {
    let bytes = try! decode_scalar(hex_bench_text_4k)
    it.keep(bytes.length())
  })
}

///|
test "bench decode public 4k" (it : @bench.T) {
  it.bench(fn() {
    let bytes = try! decode(hex_bench_text_4k)
    it.keep(bytes.length())
  })
}

///|
test "bench decode public 64k" (it : @bench.T) {
  it.bench(fn() {
    let bytes = try! decode(hex_bench_text_64k)
    it.keep(bytes.length())
  })
}
