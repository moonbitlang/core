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
test "join_child_path" {
  inspect(
    join_child_path("a", "x", windows=false),
    content=(
      #|a/x
    ),
  )
  inspect(
    join_child_path("a/", "x", windows=false),
    content=(
      #|a/x
    ),
  )
  inspect(
    join_child_path("/", "x", windows=false),
    content=(
      #|/x
    ),
  )
  inspect(
    join_child_path("C:", "x", windows=false),
    content=(
      #|C:/x
    ),
  )
  inspect(
    join_child_path("a", "x", windows=true),
    content=(
      #|a/x
    ),
  )
  inspect(
    join_child_path("a\\", "x", windows=true),
    content=(
      #|a\x
    ),
  )
  inspect(
    join_child_path("C:\\", "x", windows=true),
    content=(
      #|C:\x
    ),
  )
  inspect(
    join_child_path("C:/", "x", windows=true),
    content=(
      #|C:/x
    ),
  )
  // `C:` is the current directory of drive C, `C:/x` would be in its root
  inspect(
    join_child_path("C:", "x", windows=true),
    content=(
      #|C:x
    ),
  )
}

///|
test "strip_trailing_separators" {
  fn strip(path : String, windows : Bool) -> String {
    strip_trailing_separators(path, windows~).to_owned()
  }

  inspect(
    strip("a", false),
    content=(
      #|a
    ),
  )
  inspect(
    strip("a//", false),
    content=(
      #|a
    ),
  )
  inspect(
    strip("/", false),
    content=(
      #|/
    ),
  )
  inspect(
    strip("//", false),
    content=(
      #|//
    ),
  )
  inspect(
    strip("a\\", false),
    content=(
      #|a\
    ),
  )
  inspect(
    strip("a\\/", true),
    content=(
      #|a
    ),
  )
  inspect(
    strip("\\", true),
    content=(
      #|\
    ),
  )
  inspect(
    strip("C:\\", true),
    content=(
      #|C:\
    ),
  )
  inspect(
    strip("C:/", true),
    content=(
      #|C:/
    ),
  )
  inspect(
    strip("C:", true),
    content=(
      #|C:
    ),
  )
  inspect(
    strip("\\\\?\\C:\\", true),
    content=(
      #|\\?\C:\
    ),
  )
  inspect(
    strip("\\\\server\\share\\", true),
    content=(
      #|\\server\share
    ),
  )
}
