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
/// Returns a decimal string of exactly `digits` digits with a non-repeating
/// pattern and a non-zero leading digit.
fn decimal_digits(digits : Int) -> String {
  guard digits >= 1 else { abort("decimal_digits: digits must be >= 1") }
  let buf = StringBuilder(size_hint=digits)
  buf.write_char('7')
  for i in 1..<digits {
    buf.write_char(Int::unsafe_to_char('0' + (i * 7 + i / 13) % 10))
  }
  buf.to_string()
}

///|
test "bench BigInt::from_string n=19 digits" (it : @bench.T) {
  let s = decimal_digits(19)
  it.bench(fn() { it.keep(@bigint.BigInt::from_string(s)) })
}

///|
test "bench BigInt::from_string n=40 digits" (it : @bench.T) {
  let s = decimal_digits(40)
  it.bench(fn() { it.keep(@bigint.BigInt::from_string(s)) })
}

///|
test "bench BigInt::from_string n=400 digits" (it : @bench.T) {
  let s = decimal_digits(400)
  it.bench(fn() { it.keep(@bigint.BigInt::from_string(s)) })
}

///|
test "bench BigInt::from_string n=4000 digits" (it : @bench.T) {
  let s = decimal_digits(4000)
  it.bench(fn() { it.keep(@bigint.BigInt::from_string(s)) })
}

///|
test "bench BigInt::from_string n=20000 digits" (it : @bench.T) {
  let s = decimal_digits(20000)
  it.bench(fn() { it.keep(@bigint.BigInt::from_string(s)) })
}
