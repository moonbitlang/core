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
test "encode" {
  inspect(@base64.encode(b""), content="")
  inspect(@base64.encode(b"f"), content="Zg==")
  inspect(@base64.encode(b"fo"), content="Zm8=")
  inspect(@base64.encode(b"foo"), content="Zm9v")
  inspect(@base64.encode(b"f", padding=false), content="Zg")
  inspect(@base64.encode(b"fo", padding=false), content="Zm8")
  inspect(@base64.encode(b"foo", padding=false), content="Zm9v")
}
