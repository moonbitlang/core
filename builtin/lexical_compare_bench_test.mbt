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
let lc_equal_a : Bytes = Bytes::makei(256, i => (i % 251).to_byte())

///|
let lc_equal_b : Bytes = Bytes::makei(256, i => (i % 251).to_byte())

///|
// Identical except the last byte: full common-prefix scan.
let lc_prefix_a : Bytes = Bytes::makei(256, i => (i % 251).to_byte())

///|
let lc_prefix_b : Bytes = Bytes::makei(256, i => {
  if i == 255 {
    b'\xff'
  } else {
    (i % 251).to_byte()
  }
})

///|
// Differ at byte 1: early-exit regression guard.
let lc_early_a : Bytes = Bytes::makei(256, _ => b'a')

///|
let lc_early_b : Bytes = Bytes::makei(256, i => if i == 1 { b'b' } else { b'a' })

///|
test "bench lexical_compare equal n=256" (it : @bench.T) {
  it.bench(fn() { it.keep(lc_equal_a.lexical_compare(lc_equal_b)) })
}

///|
test "bench lexical_compare common-prefix n=256" (it : @bench.T) {
  it.bench(fn() { it.keep(lc_prefix_a.lexical_compare(lc_prefix_b)) })
}

///|
test "bench lexical_compare early-diff n=256" (it : @bench.T) {
  it.bench(fn() { it.keep(lc_early_a.lexical_compare(lc_early_b)) })
}
