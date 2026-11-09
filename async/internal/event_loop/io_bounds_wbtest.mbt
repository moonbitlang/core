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
test "panic check_io_buf_range rejects an offset past the end" {
  check_io_buf_range(2, 1, 2, "test")
}

///|
test "panic check_io_buf_range rejects a negative length" {
  check_io_buf_range(2, 0, -1, "test")
}

///|
test "check_io_buf_range accepts an exact fit" {
  check_io_buf_range(2, 1, 1, "test")
}
