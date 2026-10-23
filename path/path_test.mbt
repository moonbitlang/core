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
test "platform packages share ResolveError" {
  let resolve_posix : (@posix.Path) -> @posix.Path raise @path.ResolveError = @posix.Path::resolve
  let resolve_win32 : (@win32.Path) -> @win32.Path raise @path.ResolveError = @win32.Path::resolve
  inspect(resolve_posix("/a/../b"), content="/b")
  inspect(resolve_win32("C:\\a\\..\\b"), content="C:\\b")
  let error = @posix.ResolveError::CurrentDirectoryUnavailable
  let error : @win32.ResolveError = error
  debug_inspect(error, content="CurrentDirectoryUnavailable")
}

///|
test "debug" {
  let path : @path.Path = "a/b"
  debug_inspect(path, content="Path(\"a/b\")")
}

///|
test "Path::to_string" {
  let path : @path.Path = "a/b"
  inspect(path.to_string(), content="a/b")
}

///|
test "node-compatible top-level dispatch smoke" {
  if @path.sep == '/' {
    inspect(@path.Path::join("a", "/b"), content="a/b")
    inspect(@path.Path::normalize(""), content=".")
    inspect(@path.Path::extname(".hidden"), content="")
  } else {
    inspect(@path.Path::join("a", "\\b"), content="a\\b")
    inspect(@path.Path::normalize(""), content=".")
    inspect(@path.Path::extname(".hidden"), content="")
  }
}
