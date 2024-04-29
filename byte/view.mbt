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

/// A logical contiguous sequence of bytes with random access by index. 
/// 
/// Note: not guaranteed to be contiguous in memory.
pub trait ByteView {
  length(Self) -> Int
  op_get(Self, Int) -> Byte
}

/// A logical contiguous sequence of bytes with random read and write by index. 
/// 
/// Note: not guaranteed to be contiguous in memory.
pub trait ByteMutView {
  length(Self) -> Int
  op_get(Self, Int) -> Byte
  op_set(Self, Int, Byte) -> Unit
}
