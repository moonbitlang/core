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
/// Builds a BigInt whose base-10 representation has exactly `digits` digits
/// (a leading 1 followed by repeated 9s), so `to_string` cost scales with the
/// requested width.
fn make_decimal(digits : Int) -> @bigint.BigInt {
  let buf = StringBuilder(size_hint=digits)
  buf.write_char('1')
  for _ in 1..<digits {
    buf.write_char('9')
  }
  @bigint.BigInt::from_string(buf.to_string())
}

///|
test "bench BigInt::to_string n=40 digits" (it : @bench.T) {
  let n = make_decimal(40)
  it.bench(fn() { it.keep(n.to_string()) })
}

///|
test "bench BigInt::to_string n=400 digits" (it : @bench.T) {
  let n = make_decimal(400)
  it.bench(fn() { it.keep(n.to_string()) })
}

///|
test "bench BigInt::to_string n=4000 digits" (it : @bench.T) {
  let n = make_decimal(4000)
  it.bench(fn() { it.keep(n.to_string()) })
}
