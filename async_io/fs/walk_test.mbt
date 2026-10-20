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
async test "walk sequential" {
  let dirs = []
  @fs.walk("async_io/fs/test_directory/dir1", max_concurrency=1, (path, files) => {
    files.sort()
    dirs.push((path, files))
  })
  json_inspect(dirs, content=[
    ["async_io/fs/test_directory/dir1", ["file", "inner1"]],
    ["async_io/fs/test_directory/dir1/inner1", ["file", "inner2"]],
    ["async_io/fs/test_directory/dir1/inner1/inner2", ["file"]],
  ])
}

///|
async test "walk parallel" {
  @async_io.sleep(300)
  let log = StringBuilder()
  let mut i = 0
  @fs.walk("async_io/fs/test_directory/dir1", max_concurrency=2, (path, _) => {
    i = i + 1
    log.write_string("handling \{path}\n")
    @async_io.sleep(if i == 1 { 200 } else { 300 })
    log.write_string("finished handling \{path}\n")
  })
  inspect(
    log.to_string(),
    content=(
      #|handling async_io/fs/test_directory/dir1
      #|handling async_io/fs/test_directory/dir1/inner1
      #|finished handling async_io/fs/test_directory/dir1
      #|handling async_io/fs/test_directory/dir1/inner1/inner2
      #|finished handling async_io/fs/test_directory/dir1/inner1
      #|finished handling async_io/fs/test_directory/dir1/inner1/inner2
      #|
    ),
  )
}

///|
async test "walk failure" {
  let log = StringBuilder()
  debug_inspect(
    @test_util.expect_error_async <| () => {
      @fs.walk("async_io/fs/test_directory/dir1", max_concurrency=1, (path, _) => {
        log.write_string("handling \{path}\n")
        raise Failure::Failure("failure when handling directory")
      })
    },
    content=(
      #|Failure("failure when handling directory")
    ),
  )
  inspect(
    log,
    content=(
      #|handling async_io/fs/test_directory/dir1
      #|
    ),
  )
}

///|
async test "walk allow_failure" {
  let log = StringBuilder()
  @fs.walk(
    "async_io/fs/test_directory/dir1",
    allow_failure=true,
    max_concurrency=1,
    (path, _) => {
      log.write_string("handling \{path}\n")
      raise Failure::Failure("failure when handling directory")
    },
  )
  inspect(
    log,
    content=(
      #|handling async_io/fs/test_directory/dir1
      #|handling async_io/fs/test_directory/dir1/inner1
      #|handling async_io/fs/test_directory/dir1/inner1/inner2
      #|
    ),
  )
}

///|
async test "walk exclude 1" {
  let walked = []
  @fs.walk(
    "async_io/fs/test_directory/dir1",
    exclude=p => p is [.., .. "inner1"],
    (path, _) => walked.push(path),
  )
  json_inspect(walked, content=["async_io/fs/test_directory/dir1"])
}

///|
async test "walk exclude 2" {
  let walked = []
  @fs.walk("async_io/fs/test_directory/dir1", exclude=p => p is [.., '2'], (
    path,
    _,
  ) => walked.push(path))
  json_inspect(walked, content=[
    "async_io/fs/test_directory/dir1", "async_io/fs/test_directory/dir1/inner1",
  ])
}
