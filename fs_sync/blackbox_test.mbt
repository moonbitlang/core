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
test "write_and_read" {
  let path_1 = "./fs_sync/test_1.txt"
  let path_2 = "./fs_sync/test_2.txt"
  let content_1 = "Hello, World"
  let content_2 = "Hello, MoonBit"
  @fs_sync.write_bytes_to_file!(path_1, content_1.to_bytes())
  let res_1 = @fs_sync.read_file_to_bytes!(path_1)
  inspect!(res_1.to_unchecked_string(), content=content_1)
  @fs_sync.write_string_to_file!(path_2, content_2)
  let res_2 = @fs_sync.read_file_to_string!(path_2)
  inspect!(res_2, content=content_2)
}
