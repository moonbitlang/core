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
test "bench BytesView Compare equal n=1000000" (it : @bench.T) {
  let left = Bytes::makei(1000000, i => i.to_byte())[:]
  let right = Bytes::makei(1000000, i => i.to_byte())[:]
  it.bench(fn() { it.keep(left.compare(right)) })
}

///|
test "bench BytesView Compare last-diff n=1000000" (it : @bench.T) {
  let left = Bytes::makei(1000000, i => i.to_byte())[:]
  let right = Bytes::makei(1000000, i => {
      if i == 999999 {
        b'\xff'
      } else {
        i.to_byte()
      }
    })[:]
  it.bench(fn() { it.keep(left.compare(right)) })
}
