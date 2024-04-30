// Copyright 2024 International Digital Economy Academy
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

// NOTE: Since the `builtin` package cannot contain test, the tests of 
// primitive type `Byte` lays in this file. Don't put other logic in this
// file.

test "from_int" {
  // [definition] pub fn Byte::from_int(v: Int) -> Byte 
  // [source] moonbit-core/builtin/byte.mbt
  for i = 0; i <= 0xff; i = i + 1 {
    let r = Byte::from_int(i).to_int();
    @assertion.assert_eq(r, i)?;
  }
}
