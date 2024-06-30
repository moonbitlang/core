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

test "array_as_view" {
  inspect([1, 2, 3][..].length(), content="3")?
}

test "view_as_view" {
  inspect([1, 2, 3][..][..].length(), content="3")?
}

test "op_get" {
  inspect([1, 2, 3][..][1], content="2")?
  inspect([1, 2, 3][..][2], content="3")?
}

test "op_set" {
  let v = [1, 2, 3][..]
  inspect(v[1], content="2")?
  v[1] = 4
  inspect(v[1], content="4")?
}

test "swap" {
  let v = [1, 2, 3][..]
  inspect(v[1], content="2")?
  v.swap(1, 2)
  inspect(v[1], content="3")?
}

test "panic array_as_view_start_index_error" {
  [1, 2, 3].op_as_view(start=-1, end=0) |> ignore
}

test "panic array_as_view_start_index_error" {
  [1, 2, 3].op_as_view(start=-1, end=0) |> ignore
}

test "panic array_as_view_end_index_error" {
  [1, 2, 3].op_as_view(start=0, end=-1) |> ignore
}

test "panic array_as_view_end_index_error" {
  [1, 2, 3].op_as_view(start=0, end=-1) |> ignore
}

test "panic array_as_view_length_index_error" {
  [1, 2, 3].op_as_view(start=0, end=4) |> ignore
}

test "panic view_as_view_start_index_error" {
  [1, 2, 3][..].op_as_view(start=-1, end=0) |> ignore
}

test "panic view_as_view_start_index_error" {
  [1, 2, 3][..].op_as_view(start=-1, end=0) |> ignore
}

test "panic view_as_view_end_index_error" {
  [1, 2, 3][..].op_as_view(start=0, end=-1) |> ignore
}

test "panic view_as_view_end_index_error" {
  [1, 2, 3][..].op_as_view(start=0, end=-1) |> ignore
}

test "panic view_as_view_length_index_error" {
  [1, 2, 3][..].op_as_view(start=0, end=4) |> ignore
}

test "panic array_as_view_get_index_error" {
  [1, 2, 3][..][5] |> ignore
}

test "panic array_as_view_set_index_error" {
  [1, 2, 3][..][5] = 0
}

test "panic array_as_view_swap_index_error" {
  [1, 2, 3][..].swap(1, 9)
}
