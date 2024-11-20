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

///|
pub fn trunc(self : Double) -> Double = "Math" "trunc"

///|
pub fn ceil(self : Double) -> Double = "Math" "ceil"

///|
pub fn floor(self : Double) -> Double = "Math" "floor"

///|
// Round to nearest, ties to Even
pub extern "js" fn round(self : Double) -> Double =
  #| (num) => {
  #|   const floor = Math.floor(num);
  #|   const diff = num - floor;
  #|   if (diff > 0.5) {
  #|     return floor + 1;
  #|   } else if (diff < 0.5) {
  #|     return floor;
  #|   } else if (floor % 2 === 0) {
  #|     return floor;
  #|   } else {
  #|     return floor + 1;
  #|   }
  #| }
