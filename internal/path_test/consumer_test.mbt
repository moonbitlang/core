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

// This package imports only the public path facades, without inheriting their
// dependencies as path/path_test.mbt does. An internal owner for ResolveError
// must not silently become available through the test package's imports.

///|
test "construct, raise, and catch errors through public path aliases" {
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
  let mut handled = 0
  for failure in failures {
    try failure() catch {
      @path.ResolveError::CurrentDirectoryUnavailable => handled += 1
      _ => fail("expected public path error")
    } noraise {
      _ => fail("expected an error")
    }
    try failure() catch {
      @posix.ResolveError::CurrentDirectoryUnavailable => handled += 1
      _ => fail("expected public posix error")
    } noraise {
      _ => fail("expected an error")
    }
    try failure() catch {
      @win32.ResolveError::CurrentDirectoryUnavailable => handled += 1
      _ => fail("expected public win32 error")
    } noraise {
      _ => fail("expected an error")
    }
  }
  inspect(handled, content="9")
}

///|
test "resolve signatures share the public error type" {
  let resolve_posix : (@posix.Path) -> @posix.Path raise @path.ResolveError = @posix.Path::resolve
  let resolve_win32 : (@win32.Path) -> @win32.Path raise @path.ResolveError = @win32.Path::resolve
  inspect(resolve_posix("/a/../b"), content="/b")
  inspect(resolve_win32("C:\\a\\..\\b"), content="C:\\b")
}
