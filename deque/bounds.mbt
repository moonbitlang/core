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
/// Aborts with the standard "index out of bounds" diagnostic.
///
/// Marked `#inline(never)` so the cold message-formatting path stays out of the
/// checked accessor bodies (`Deque::at` / `Deque::set`), keeping them small
/// enough for the C/LLVM backend to inline while preserving the exact message.
#inline(never)
fn[T] index_out_of_bounds(len : Int, index : Int) -> T {
  abort(
    "index out of bounds: the len is from 0 to \{len} but the index is \{index}",
  )
}
