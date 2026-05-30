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
/// Creates a 128-bit vector value from its low and high 64-bit lanes.
pub fn make(lo : UInt64, hi : UInt64) -> V128 = "%v128.make"

///|
/// Returns the low 64-bit lane of a 128-bit vector value.
pub fn lo(value : V128) -> UInt64 = "%v128.lo"

///|
/// Returns the high 64-bit lane of a 128-bit vector value.
pub fn hi(value : V128) -> UInt64 = "%v128.hi"
