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

// Regression test for moonbitlang/core#4052 — the js `to_octets` ran its
// zero shortcut before validating the requested length, silently
// returning b"" for `0N.to_octets(length=0)` while the documented
// contract (and every other target) panics on a non-positive length.

///|
test "panic to_octets of zero rejects non-positive length" {
  // documented contract: non-positive length panics on every target
  // (the js implementation used to return b"" here)
  let _ = 0N.to_octets(length=0)
}

///|
test "to_octets of zero still pads positive lengths" {
  inspect(0N.to_octets(), content="b\"\\x00\"")
  inspect(0N.to_octets(length=3), content="b\"\\x00\\x00\\x00\"")
}
