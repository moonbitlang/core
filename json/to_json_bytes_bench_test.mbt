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
test "bench ToJson for Bytes all byte values n=4096" (it : @bench.T) {
  let bytes = Bytes::makei(4096, i => i.to_byte())
  it.bench(fn() { it.keep(Json(bytes)) })
}

///|
test "bench ToJson for Bytes printable n=4096" (it : @bench.T) {
  let bytes = Bytes::makei(4096, i => (b'a'.to_int() + i % 26).to_byte())
  it.bench(fn() { it.keep(Json(bytes)) })
}
