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
test "bench Hash for Bytes (small)" (it : @bench.T) {
  let data = Bytes::make(16, 0xAB)
  it.bench(fn() { it.keep(Hash::hash(data)) })
}

///|
test "bench Hash for Bytes (medium)" (it : @bench.T) {
  let data = Bytes::make(256, 0xAB)
  it.bench(fn() { it.keep(Hash::hash(data)) })
}

///|
test "bench Hash for Bytes (large)" (it : @bench.T) {
  let data = Bytes::make(4096, 0xAB)
  it.bench(fn() { it.keep(Hash::hash(data)) })
}

///|
test "bench Hash for BytesView (small)" (it : @bench.T) {
  let data = Bytes::make(16, 0xAB)
  let view = data.view()
  it.bench(fn() { it.keep(Hash::hash(view)) })
}

///|
test "bench Hash for BytesView (medium)" (it : @bench.T) {
  let data = Bytes::make(256, 0xAB)
  let view = data.view()
  it.bench(fn() { it.keep(Hash::hash(view)) })
}

///|
test "bench Hash for BytesView (large)" (it : @bench.T) {
  let data = Bytes::make(4096, 0xAB)
  let view = data.view()
  it.bench(fn() { it.keep(Hash::hash(view)) })
}
