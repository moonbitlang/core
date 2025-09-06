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
test "array_as_view" {
  inspect([1, 2, 3][:].length(), content="3")
}

///|
test "view_as_view" {
  inspect([1, 2, 3][:][:].length(), content="3")
}

///|
test "op_get" {
  inspect([1, 2, 3][:][1], content="2")
  inspect([1, 2, 3][:][2], content="3")
}

///|
test "negative index1" {
  let arr = [1, 2, 3]
  let view = arr[-1:]
  inspect(view, content="[3]")
  let view = arr[-2:]
  inspect(view, content="[2, 3]")
  let view = arr[-3:]
  inspect(view, content="[1, 2, 3]")
  let view = arr[:-1]
  inspect(view, content="[1, 2]")
  let view = arr[:-2]
  inspect(view, content="[1]")
  let view = arr[:-3]
  inspect(view, content="[]")
  let view = arr[-3:-3]
  inspect(view, content="[]")
  let view = arr[-3:-2]
  inspect(view, content="[1]")
  let view = arr[-3:-1]
  inspect(view, content="[1, 2]")
  let view = arr[-3:0]
  inspect(view, content="[]")
  let view = arr[-3:1]
  inspect(view, content="[1]")
  let view = arr[-3:2]
  inspect(view, content="[1, 2]")
  let view = arr[-3:3]
  inspect(view, content="[1, 2, 3]")
}

///|
test "negative index2" {
  let arr = [0, 1, 2, 3, 4][1:4]
  let view = arr[-1:]
  inspect(view, content="[3]")
  let view = arr[-2:]
  inspect(view, content="[2, 3]")
  let view = arr[-3:]
  inspect(view, content="[1, 2, 3]")
  let view = arr[:-1]
  inspect(view, content="[1, 2]")
  let view = arr[:-2]
  inspect(view, content="[1]")
  let view = arr[:-3]
  inspect(view, content="[]")
  let view = arr[-3:-3]
  inspect(view, content="[]")
  let view = arr[-3:-2]
  inspect(view, content="[1]")
  let view = arr[-3:-1]
  inspect(view, content="[1, 2]")
  let view = arr[-3:0]
  inspect(view, content="[]")
  let view = arr[-3:1]
  inspect(view, content="[1]")
  let view = arr[-3:2]
  inspect(view, content="[1, 2]")
  let view = arr[-3:3]
  inspect(view, content="[1, 2, 3]")
}

///|
test "panic negative index1" {
  let arr = [1, 2, 3]
  let _ = arr[-4:]

}

///|
test "panic negative index2" {
  let arr = [1, 2, 3]
  let _ = arr[:-4]

}

///|
test "panic negative index3" {
  let arr = [1, 2, 3]
  let _ = arr[-1:-2]

}

///|
test "panic negative index4" {
  let arr = [1, 2, 3]
  let _ = arr[-1:-3]

}

///|
test "panic negative index5" {
  let arr = [1, 2, 3][:]
  let _ = arr[-4:]

}

///|
test "panic negative index6" {
  let arr = [1, 2, 3][:]
  let _ = arr[:-4]

}

///|
test "panic negative index7" {
  let arr = [1, 2, 3][:]
  let _ = arr[-1:-2]

}

///|
test "panic negative index8" {
  let arr = [1, 2, 3][:]
  let _ = arr[-1:-3]

}
