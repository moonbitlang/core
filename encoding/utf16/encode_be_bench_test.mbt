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
test "bench big endian encoding keeps the entire result" (it : @bench.T) {
  for length in [7, 8, 17, 100000] {
    let text = "---" + String::make(length, '中') + "+++"
    let view = text[3:3 + length]
    it.bench(name="BE n=\{length}", fn() {
      it.keep(@utf16.encode(view, endianness=Big))
    })
  }
}
