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
test "bench StringBuilder full convert reset 4096" (it : @bench.T) {
  it.bench(() => {
    let builder = StringBuilder(size_hint=8)
    for _ in 0..<4096 {
      builder.write_string("abcdefgh")
      it.keep(builder.to_string())
      builder.reset()
    }
  })
}

///|
test "bench StringBuilder partial convert reset 4096" (it : @bench.T) {
  it.bench(() => {
    let builder = StringBuilder(size_hint=16)
    for _ in 0..<4096 {
      builder.write_string("abcdefgh")
      it.keep(builder.to_string())
      builder.reset()
    }
  })
}

///|
test "bench StringBuilder write reset without conversion 4096" (it : @bench.T) {
  it.bench(() => {
    let builder = StringBuilder(size_hint=8)
    for _ in 0..<4096 {
      builder.write_string("abcdefgh")
      it.keep(builder)
      builder.reset()
    }
  })
}
