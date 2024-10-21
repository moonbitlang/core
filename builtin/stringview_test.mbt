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

test "string_as_view" {
  inspect!("123"[:].length(), content="3")
}

test "view_as_view" {
  inspect!("123"[:][:].length(), content="3")
}

test "op_get" {
  inspect!("123"[:][1], content="'2'")
  inspect!("123"[:][2], content="'3'")
}

test "panic string_as_view_start_index_error" {
  "123"[-1:0] |> ignore
}

test "panic string_as_view_start_index_error" {
  "123"[-1:0] |> ignore
}

test "panic string_as_view_end_index_error" {
  "123"[0:-1] |> ignore
}

test "panic string_as_view_end_index_error" {
  "123"[0:-1] |> ignore
}

test "panic string_as_view_length_index_error" {
  "123"[0:4] |> ignore
}

test "panic view_as_view_start_index_error" {
  "123"[:][-1:0] |> ignore
}

test "panic view_as_view_start_index_error" {
  "123"[:][-1:0] |> ignore
}

test "panic view_as_view_end_index_error" {
  "123"[:][0:-1] |> ignore
}

test "panic view_as_view_end_index_error" {
  "123"[:][0:-1] |> ignore
}

test "panic view_as_view_length_index_error" {
  "123"[:][0:4] |> ignore
}

test "panic string_as_view_get_index_error" {
  "123"[:][5] |> ignore
}

test "iter" {
  let string = "012345678910"
  inspect!(
    string[:].iter().to_string(),
    content="['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '1', '0']",
  )
  inspect!(
    string[5:].iter().to_string(),
    content="['5', '6', '7', '8', '9', '1', '0']",
  )
  inspect!(string[5:9].iter().to_string(), content="['5', '6', '7', '8']")
}
