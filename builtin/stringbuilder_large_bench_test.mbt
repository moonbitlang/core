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
let stringbuilder_large_sizes : Array[(Int, Int)] = [
  (1 * 1024 * 1024, 512 * 1024),
  (8 * 1024 * 1024, 4 * 1024 * 1024),
  (32 * 1024 * 1024, 16 * 1024 * 1024),
]

///|
test "bench StringBuilder reserve 1 MiB" (it : @bench.T) {
  let (bytes, _) = stringbuilder_large_sizes[0]
  it.bench(fn() { it.keep(StringBuilder(size_hint=bytes)) })
}

///|
test "bench StringBuilder reserve 8 MiB" (it : @bench.T) {
  let (bytes, _) = stringbuilder_large_sizes[1]
  it.bench(fn() { it.keep(StringBuilder(size_hint=bytes)) })
}

///|
test "bench StringBuilder reserve 32 MiB" (it : @bench.T) {
  let (bytes, _) = stringbuilder_large_sizes[2]
  it.bench(fn() { it.keep(StringBuilder(size_hint=bytes)) })
}

///|
test "bench StringBuilder build 1 MiB" (it : @bench.T) {
  let (bytes, units) = stringbuilder_large_sizes[0]
  let source = String::make(units, 'x')
  it.bench(fn() {
    let builder = StringBuilder(size_hint=bytes)
    builder.write_string(source)
    it.keep(builder.to_string())
  })
}

///|
test "bench StringBuilder build 8 MiB" (it : @bench.T) {
  let (bytes, units) = stringbuilder_large_sizes[1]
  let source = String::make(units, 'x')
  it.bench(fn() {
    let builder = StringBuilder(size_hint=bytes)
    builder.write_string(source)
    it.keep(builder.to_string())
  })
}

///|
test "bench StringBuilder build 32 MiB" (it : @bench.T) {
  let (bytes, units) = stringbuilder_large_sizes[2]
  let source = String::make(units, 'x')
  it.bench(fn() {
    let builder = StringBuilder(size_hint=bytes)
    builder.write_string(source)
    it.keep(builder.to_string())
  })
}
