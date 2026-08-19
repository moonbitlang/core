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
fn from_octets_bench_data(len : Int) -> Bytes {
  Bytes::makei(len, i => ((i * 37 + 11) & 0xff).to_byte())
}

///|
test "bench BigInt::from_octets n=64" (it : @bench.T) {
  let data = from_octets_bench_data(64)
  it.bench(fn() { it.keep(@bigint.BigInt::from_octets(data)) })
}

///|
test "bench BigInt::from_octets n=1024" (it : @bench.T) {
  let data = from_octets_bench_data(1024)
  it.bench(fn() { it.keep(@bigint.BigInt::from_octets(data)) })
}
