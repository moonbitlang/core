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

test "shift_index" {
  let s = "ac😭🤣de"
  let i = Index::zero()
  inspect!(i, content="Index(0)")
  inspect!(shift_index(s, i, 0), content="Index(0)")
  inspect!(shift_index(s, i, 1), content="Index(1)")
  inspect!(shift_index(s, i, 2), content="Index(2)")
  inspect!(shift_index(s, i, 3), content="Index(4)")
  inspect!(shift_index(s, i, 4), content="Index(6)")
  inspect!(shift_index(s, i, 5), content="Index(7)")
  inspect!(shift_index(s, i, 6), content="Index(8)")
}

test "shift_index negative index" {
  let s = "ab😭🤣ef"
  let i = shift_index(s, Index::zero(), 6)
  inspect!(i, content="Index(8)")
  inspect!(shift_index(s, i, 0), content="Index(8)")
  inspect!(shift_index(s, i, -1), content="Index(7)")
  inspect!(shift_index(s, i, -2), content="Index(6)")
  inspect!(shift_index(s, i, -3), content="Index(4)")
  inspect!(shift_index(s, i, -4), content="Index(2)")
  inspect!(shift_index(s, i, -5), content="Index(1)")
  inspect!(shift_index(s, i, -6), content="Index(0)")
}

test "codepoint_at" {
  let s = "ab😭🤣ef"
  let i0 = Index::zero()
  let i3 = shift_index(s, i0, 3)
  let i5 = shift_index(s, i0, 5)
  inspect!(s.codepoint_at(i0), content="'a'")
  inspect!(s.codepoint_at(i3), content="'🤣'")
  inspect!(s.codepoint_at(i5), content="'f'")
}

test "as_view" {
  let s = "ab😭🤣ef"
  let i0 = Index::zero()
  let i3 = shift_index(s, i0, 3)
  let v1 = s.as_view(start=i0, end=i3)
  inspect!(v1, content="ab😭")
  let v2 = s.as_view(start=i3)
  inspect!(v2, content="🤣ef")
  let v3 = s.as_view(end=i3)
  inspect!(v3, content="ab😭")
  let v4 = s.as_view()
  inspect!(v4, content="ab😭🤣ef")
}

test "panic shift_index" {
  let s = "ac😭🤣de"
  let i = Index::zero()
  let _ = shift_index(s, i, 7)

}

test "panic shift_index negative index" {
  let s = "ac😭🤣de"
  let i = shift_index(s, Index::zero(), 6)
  let _ = shift_index(s, i, -7)

}
