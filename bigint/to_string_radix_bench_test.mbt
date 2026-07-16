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
fn radix_bench_value() -> @bigint.BigInt {
  // ~4000 bits
  (@bigint.BigInt::from_string("7") << 4000) +
  @bigint.BigInt::from_string("12345678901234567890")
}

///|
test "bench bigint to_string radix=7 (4000 bits)" (it : @bench.T) {
  let v = radix_bench_value()
  it.bench(fn() { it.keep(v.to_string(radix=7)) })
}

///|
test "bench bigint to_string radix=36 (4000 bits)" (it : @bench.T) {
  let v = radix_bench_value()
  it.bench(fn() { it.keep(v.to_string(radix=36)) })
}

///|
test "bench bigint to_string radix=10 reference (4000 bits)" (it : @bench.T) {
  let v = radix_bench_value()
  it.bench(fn() { it.keep(v.to_string()) })
}
