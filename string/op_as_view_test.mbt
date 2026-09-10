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
test "String::op_as_view with positive indices" {
  let s = "hello world"

  // Test basic ranges
  let view1 = s[0:5]
  inspect(view1, content="hello")
  let view2 = s[6:]
  inspect(view2, content="world")

  // Test with default start (0)
  let view3 = s[:5]
  inspect(view3, content="hello")

  // Test with default end (length of string)
  let view4 = s[6:]
  inspect(view4, content="world")

  // Test entire string
  let view5 = s[:]
  inspect(view5, content="hello world")

  // Test empty range
  let view6 = s[5:5]
  inspect(view6, content="")
}

///|
test "String::op_as_view with negative indices" {
  let s = "hello world"
  inspect(s[-5:], content="hello world")
  inspect(s[:-6], content="")
  inspect(s[-5:-1], content="")
  inspect(s[6:-1], content="")
}

///|
test "View::op_as_view with positive indices" {
  let s = "hello world"
  let view = s[:]

  // Test basic subviews
  let subview1 = view[0:5]
  inspect(subview1, content="hello")
  let subview2 = view[6:11]
  inspect(subview2, content="world")

  // Test with default start (0)
  let subview3 = view[:5]
  inspect(subview3, content="hello")

  // Test with default end (length of view)
  let subview4 = view[6:]
  inspect(subview4, content="world")

  // Test empty range
  let subview5 = view[5:5]
  inspect(subview5, content="")
}

///|
test "View::op_as_view with negative indices" {
  let view = "hello world"[1:5]
  inspect(view[-5:], content="ello")
  inspect(view[:-6], content="")
  inspect(view[-5:-1], content="")
}

///|
test "View::op_as_view with nested views" {
  let s = "hello world"
  let view1 = s.exact_view(start=0, end=11)
  inspect(view1, content="hello world")
  let view2 = view1.exact_view(start=0, end=5)
  inspect(view2, content="hello")
  let view3 = view2.exact_view(start=1, end=4)
  inspect(view3, content="ell")

  inspect(view3[-3:100], content="ell")
}
