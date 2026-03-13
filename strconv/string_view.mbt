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
/// Returns the accumulated value, the slice left, and the number of digits consumed.
/// It ignores underscore and stops when a non-digit character is found.
fn[T] StringView::fold_digits(
  self : Self,
  init : T,
  f : (Int, T) -> T,
) -> (Self, T, Int) {
  for str = self, ret = init, len = 0; str is [ch, .. rest]; {
    if ch is ('0'..='9') {
      continue rest, f(ch.to_int() - '0', ret), len + 1
    } else if ch != '_' {
      break (str, ret, len)
    }
    continue rest, ret, len
  } nobreak {
    (str, ret, len)
  }
}
