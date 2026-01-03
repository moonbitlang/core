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
#deprecated("Use `PI` instead")
pub let pi = 0x3.243F6A8885A308CA8A54

///|
#deprecated("Use @cmp.maximum instead")
pub fn[T : Compare] maximum(x : T, y : T) -> T {
  if x > y {
    x
  } else {
    y
  }
}

///|
#deprecated("Use @cmp.minimum instead")
pub fn[T : Compare] minimum(x : T, y : T) -> T {
  if x > y {
    y
  } else {
    x
  }
}
