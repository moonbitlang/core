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
pub const PI = 0x3.243F6A8885A308CA8A54

///|
///@alert deprecated "Use `PI` instead"
pub let pi = 0x3.243F6A8885A308CA8A54

///|
pub fn sin(x : Double) -> Double {
  x.sin()
}

///|
pub fn cos(x : Double) -> Double {
  x.cos()
}

///|
pub fn tan(x : Double) -> Double {
  x.tan()
}

///|
pub fn atan(x : Double) -> Double {
  x.atan()
}

///|
pub fn asin(x : Double) -> Double {
  x.asin()
}

///|
pub fn acos(x : Double) -> Double {
  x.acos()
}

///|
pub fn atan2(y : Double, x : Double) -> Double {
  y.atan2(x)
}
