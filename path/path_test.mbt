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
test "catch ResolveError through public re-exports" {
  // Construct and raise the error using only the public package aliases.
  // Erase its type to Error so the catch also checks runtime type identity.
  fn fail_path() -> Unit raise @path.ResolveError {
    raise CurrentDirectoryUnavailable
  }
  fn fail_posix() -> Unit raise @posix.ResolveError {
    raise CurrentDirectoryUnavailable
  }
  fn fail_win32() -> Unit raise @win32.ResolveError {
    raise CurrentDirectoryUnavailable
  }
  let failures : Array[() -> Unit raise] = [
    () => fail_path(),
    () => fail_posix(),
    () => fail_win32(),
  ]
  let handled : Array[String] = []
  for failure in failures {
    try failure() catch {
      @path.ResolveError::CurrentDirectoryUnavailable => handled.push("path")
      _ => fail("expected the public path ResolveError")
    } noraise {
      _ => fail("expected a resolution error")
    }
    try failure() catch {
      @posix.ResolveError::CurrentDirectoryUnavailable => handled.push("posix")
      _ => fail("expected the public posix ResolveError")
    } noraise {
      _ => fail("expected a resolution error")
    }
    try failure() catch {
      @win32.ResolveError::CurrentDirectoryUnavailable => handled.push("win32")
      _ => fail("expected the public win32 ResolveError")
    } noraise {
      _ => fail("expected a resolution error")
    }
  }
  debug_inspect(
    handled,
    content=(
      #|[
      #|  "path",
      #|  "posix",
      #|  "win32",
      #|  "path",
      #|  "posix",
      #|  "win32",
      #|  "path",
      #|  "posix",
      #|  "win32",
      #|]
    ),
  )
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
test "Path division chains with platform join semantics" {
  let path : @path.Path = "a"
  let y : @path.Path = "b"
  let z : @path.Path = "c"
  let divide = @path.Path::div
  inspect(path / y / z == path.join(y).join(z), content="true")
  inspect(path / "b" / "../c" == path.join("c"), content="true")
  inspect(path / "/b" == path.join("/b"), content="true")
  inspect(divide(path, y) == path / y, content="true")
  inspect(path.div(y) == path / y, content="true")
  inspect((@path.Path("") / "").to_string(), content=".")
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
