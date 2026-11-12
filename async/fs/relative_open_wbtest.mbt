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
test "relative open filename validation" {
  fn check(path : StringView) -> StringView raise {
    validate_relative_open_filename(
      path,
      context="relative open filename validation",
    )
  }
  match @event_loop.platform {
    Linux | MacOS => {
      inspect(check("file"), content="file")
      inspect(check("a/b//c/"), content="a/b/c")
      inspect(check("./a/b/./c"), content="a/b/c")
      inspect(
        @test.expect_error(() => check("../a")),
        content=(
          #|Failure(relative open filename validation: relative open does not support `..`)
        ),
      )
      inspect(
        @test.expect_error(() => check("a/../b")),
        content=(
          #|Failure(relative open filename validation: relative open does not support `..`)
        ),
      )
      inspect(
        @test.expect_error(() => check("a/b/..")),
        content=(
          #|Failure(relative open filename validation: relative open does not support `..`)
        ),
      )
      inspect(
        @test.expect_error(() => check("/a/b")),
        content=(
          #|Failure(relative open filename validation: relative open does not support absolute path)
        ),
      )
    }
    Windows => {
      inspect(check("file"), content="file")
      inspect(check("a\\b//c\\"), content="a\\b\\c")
      inspect(check("./a/b\\./c"), content="a\\b\\c")
      inspect(
        @test.expect_error(() => check("../a")),
        content=(
          #|Failure(relative open filename validation: relative open does not support `..`)
        ),
      )
      inspect(
        @test.expect_error(() => check("a/../b")),
        content=(
          #|Failure(relative open filename validation: relative open does not support `..`)
        ),
      )
      inspect(
        @test.expect_error(() => check("a/b/..")),
        content=(
          #|Failure(relative open filename validation: relative open does not support `..`)
        ),
      )
      inspect(
        @test.expect_error(() => check("\\a\\b")),
        content=(
          #|Failure(relative open filename validation: relative open does not support absolute path)
        ),
      )
      inspect(
        @test.expect_error(() => check("C:\\a\\b")),
        content=(
          #|Failure(relative open filename validation: relative open does not support absolute path)
        ),
      )
      inspect(
        @test.expect_error(() => check("C:/a/b")),
        content=(
          #|Failure(relative open filename validation: relative open does not support absolute path)
        ),
      )
      inspect(
        @test.expect_error(() => check("C:a/b")),
        content=(
          #|Failure(relative open filename validation: relative open does not support absolute path)
        ),
      )
      inspect(
        @test.expect_error(() => check("\\\\UNC\\machine\\a")),
        content=(
          #|Failure(relative open filename validation: relative open does not support absolute path)
        ),
      )
      inspect(
        @test.expect_error(() => check("\\\\.\\local_device")),
        content=(
          #|Failure(relative open filename validation: relative open does not support absolute path)
        ),
      )
      inspect(
        @test.expect_error(() => check("\\\\?\\root_local_device")),
        content=(
          #|Failure(relative open filename validation: relative open does not support absolute path)
        ),
      )
    }
    @event_loop.Platform::.. => ()
  }
}
