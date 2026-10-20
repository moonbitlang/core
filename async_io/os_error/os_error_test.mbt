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
async test "NotFound" {
  let err = @test_util.expect_error_async <| () => {
    @fs.open("does_not_exist", mode=ReadOnly)
  }
  match err {
    @os_error.OsError(NotFound, ..) => ()
    err => fail("incorrect error: \{err}")
  }
}

///|
async test "AlreadyExists" {
  let err = @test_util.expect_error_async <| () => {
    @fs.mkdir("async_io", permission=0o755)
  }
  match err {
    @os_error.OsError(AlreadyExists, ..) => ()
    err => fail("incorrect error: \{err}")
  }
}
