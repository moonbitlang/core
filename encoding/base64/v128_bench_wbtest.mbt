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

// Vector-versus-scalar benchmarks. Both variants are measured inside one
// binary so the comparison is immune to the code-layout drift that separate
// baseline and patched builds suffer from on this hardware.

///|
let bench_input_64 : Bytes = sample_bytes(64)

///|
let bench_input_1k : Bytes = sample_bytes(1024)

///|
let bench_input_64k : Bytes = sample_bytes(65536)

///|
let bench_text_64 : String = encode_scalar(bench_input_64)

///|
let bench_text_1k : String = encode_scalar(bench_input_1k)

///|
let bench_text_64k : String = encode_scalar(bench_input_64k)

///|
test "bench encode scalar n=64" (it : @bench.T) {
  it.bench(fn() { it.keep(encode_scalar(bench_input_64).length()) })
}

///|
test "bench encode v128 n=64" (it : @bench.T) {
  it.bench(fn() { it.keep(encode(bench_input_64).length()) })
}

///|
test "bench encode scalar n=1024" (it : @bench.T) {
  it.bench(fn() { it.keep(encode_scalar(bench_input_1k).length()) })
}

///|
test "bench encode v128 n=1024" (it : @bench.T) {
  it.bench(fn() { it.keep(encode(bench_input_1k).length()) })
}

///|
test "bench encode scalar n=65536" (it : @bench.T) {
  it.bench(fn() { it.keep(encode_scalar(bench_input_64k).length()) })
}

///|
test "bench encode v128 n=65536" (it : @bench.T) {
  it.bench(fn() { it.keep(encode(bench_input_64k).length()) })
}

///|
test "bench decode scalar n=64" (it : @bench.T) {
  it.bench(fn() {
    it.keep((decode_scalar(bench_text_64, false) catch { _ => b"" }).length())
  })
}

///|
test "bench decode v128 n=64" (it : @bench.T) {
  it.bench(fn() { it.keep((decode(bench_text_64) catch { _ => b"" }).length()) })
}

///|
test "bench decode scalar n=1024" (it : @bench.T) {
  it.bench(fn() {
    it.keep((decode_scalar(bench_text_1k, false) catch { _ => b"" }).length())
  })
}

///|
test "bench decode v128 n=1024" (it : @bench.T) {
  it.bench(fn() { it.keep((decode(bench_text_1k) catch { _ => b"" }).length()) })
}

///|
test "bench decode scalar n=65536" (it : @bench.T) {
  it.bench(fn() {
    it.keep((decode_scalar(bench_text_64k, false) catch { _ => b"" }).length())
  })
}

///|
test "bench decode v128 n=65536" (it : @bench.T) {
  it.bench(fn() {
    it.keep((decode(bench_text_64k) catch { _ => b"" }).length())
  })
}
