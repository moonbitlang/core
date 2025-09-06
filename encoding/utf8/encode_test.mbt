// Copyright 2025 International Digital Economy Academy
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
test "encode" {
  let s = "abc你好👀"
  let encoded = @utf8.encode(s)
  inspect(
    encoded,
    content=(
      #|b"\x61\x62\x63\xe4\xbd\xa0\xe5\xa5\xbd\xf0\x9f\x91\x80"
    ),
  )
  let encoded_with_bom = @utf8.encode(s, bom=true)
  inspect(
    encoded_with_bom,
    content=(
      #|b"\xef\xbb\xbf\x61\x62\x63\xe4\xbd\xa0\xe5\xa5\xbd\xf0\x9f\x91\x80"
    ),
  )
}
