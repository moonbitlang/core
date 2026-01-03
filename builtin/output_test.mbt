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
test "to_string with uncommon radices" {
  // Int radices
  inspect((123).to_string(radix=5), content="443")
  inspect((123).to_string(radix=12), content="a3")
  // Int64 radices
  inspect(123L.to_string(radix=5), content="443")
  inspect(123L.to_string(radix=12), content="a3")
}

///|
test "panic Int64::to_string invalid radix" {
  1L.to_string(radix=1) |> ignore
}
