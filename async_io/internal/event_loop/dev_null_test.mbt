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
#cfg(any(target="native", target="wasm"))
async test "/dev/null" {
  if @event_loop.platform is Windows {
    return
  }
  let file = @fs.open("/dev/null", mode=ReadWrite)
  defer file.close()
  assert_eq(file.kind(), CharDevice)
  file.write(Bytes::make(1024, 0))
  assert_eq(file.text.read_all(), "")
}
