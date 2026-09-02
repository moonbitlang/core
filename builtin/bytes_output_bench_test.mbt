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
let bytes_output_binary : Bytes = Bytes::makei(100000, i => i.to_byte())

///|
test "bench Bytes Show binary n=100000" (it : @bench.T) {
  it.bench(fn() { it.keep(bytes_output_binary.to_string()) })
}

///|
test "bench Bytes ToJson binary n=100000" (it : @bench.T) {
  it.bench(fn() { it.keep(@json.to_json(bytes_output_binary)) })
}
