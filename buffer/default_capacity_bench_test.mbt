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
/// Benchmarks for buffers built without a capacity, where the first few
/// growth steps dominate. Each run allocates a fresh buffer on purpose.
test "bench Buffer default empty" (it : @bench.T) {
  it.bench(() => it.keep(@buffer.Buffer()))
}

///|
test "bench Buffer default 16 bytes" (it : @bench.T) {
  it.bench(() => {
    let buf = @buffer.Buffer()
    for i in 0..<16 {
      buf.write_byte(i.to_byte())
    }
    it.keep(buf.contents())
  })
}

///|
test "bench Buffer default 4 uint32" (it : @bench.T) {
  it.bench(() => {
    let buf = @buffer.Buffer()
    for i in 0..<4 {
      buf.write_uint_le(i.reinterpret_as_uint())
    }
    it.keep(buf.contents())
  })
}

///|
test "bench Buffer default 64 bytes" (it : @bench.T) {
  it.bench(() => {
    let buf = @buffer.Buffer()
    for i in 0..<64 {
      buf.write_byte(i.to_byte())
    }
    it.keep(buf.contents())
  })
}
