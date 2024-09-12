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

struct StringView {
  buf : Ref[String]
  start : Int
  len : Int
}

pub fn length(self : StringView) -> Int {
  self.len
}

pub fn op_get(self : StringView, index : Int) -> Char {
  if index >= self.len {
    let len = self.len
    abort(
      "index out of bounds: the len is from 0 to \{len} but the index is \{index}",
    )
  }
  self.buf.val[self.start + index]
}

pub fn op_as_view(self : String, ~start : Int, ~end? : Int) -> StringView {
  let len = self.length()
  let end = match end {
    None => len
    Some(end) => end
  }
  guard start >= 0 && start <= end && end <= len else {
    abort("View start index out of bounds")
  }
  StringView::{ buf: { val: self }, start, len: end - start }
}

pub fn op_as_view(self : StringView, ~start : Int, ~end? : Int) -> StringView {
  let len = self.len
  let end = match end {
    None => len
    Some(end) => end
  }
  guard start >= 0 && start <= end && end <= len else {
    abort("View start index out of bounds")
  }
  StringView::{ buf: self.buf, start: self.start + start, len: end - start }
}

pub fn iter(self : StringView) -> Iter[Char] {
  Iter::new(
    fn(yield) {
      for i = 0; i < self.len; i = i + 1 {
        let v = self[i]
        guard let IterContinue = yield(v) else { x => break x }

      } else {
        IterContinue
      }
    },
  )
}
