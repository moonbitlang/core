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
let decode_lossy_ascii_input : Bytes = Bytes::make(1000000, b'a')

///|
let decode_lossy_invalid_input : Bytes = Bytes::make(1000000, b'\xff')

///|
let decode_lossy_mixed_input : Bytes = @utf8.encode("a©中😀").repeat(100000)

///|
test "bench decode_lossy ASCII n=1000000" (it : @bench.T) {
  it.bench(fn() { it.keep(@utf8.decode_lossy(decode_lossy_ascii_input)) })
}

///|
test "bench decode_lossy invalid n=1000000" (it : @bench.T) {
  it.bench(fn() { it.keep(@utf8.decode_lossy(decode_lossy_invalid_input)) })
}

///|
test "bench decode_lossy mixed n=1000000" (it : @bench.T) {
  it.bench(fn() { it.keep(@utf8.decode_lossy(decode_lossy_mixed_input)) })
}
