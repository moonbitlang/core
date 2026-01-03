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
  // let s = "hello world"

  // Test negative indices from end
  // let view1 =   s.charcodes(start=-5)
  // inspect(view1, content="world")
  // let view2 = s.charcodes(end=-6)
  // inspect(view2, content="hello")
  // let view3 = s.charcodes(start=-5,end=-1)
  // inspect(view3, content="worl")

  // Test combining positive and negative indices
  // let view4 = s.charcodes(start=0,end=-6)
  // inspect(view4, content="hello")
  // let view5 = s.charcodes(start=6,end=-1)
  // inspect(view5, content="worl")
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
// test "View::op_as_view with negative indices" {
//   let s = "hello world"
//   let view = s[:]

//   // Test negative indices from end
//   let subview1 = view[-5:]
//   inspect(subview1, content="world")
//   let subview2 = view[:-6]
//   inspect(subview2, content="hello")
//   let subview3 = view[-5:-1]
//   inspect(subview3, content="worl")
// }

///|
test "View::op_as_view with nested views" {
  let s = "hello world"
  let view1 = s.view(start_offset=0, end_offset=11)
  inspect(view1, content="hello world")
  let view2 = view1.view(start_offset=0, end_offset=5)
  inspect(view2, content="hello")
  let view3 = view2.view(start_offset=1, end_offset=4)
  inspect(view3, content="ell")

  // Test with negative indices in nested views
  // let view4 = view2.charcodes(start=-3)
  // inspect(view4, content="llo")
}
