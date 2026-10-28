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

// This package imports only the public path facade, without inheriting its
// dependencies as path/path_test.mbt does. An internal owner for ResolveError
// must not silently become available through the test package's imports.

///|
test "construct, raise, and catch errors through the public path alias" {
  fn fail_path() -> Unit raise @path.ResolveError {
    raise CurrentDirectoryUnavailable
  }
  let failure : () -> Unit raise = () => fail_path()
  try failure() catch {
    @path.ResolveError::CurrentDirectoryUnavailable => ()
    _ => fail("expected public path error")
  } noraise {
    _ => fail("expected an error")
  }
}

///|
test "public Path operations require no internal imports" {
  let path : @path.Path = "a"
  let joined : @path.Path = path / "b" / "../c.txt"
  let expected = if @path.sep == '/' { "a/c.txt" } else { "a\\c.txt" }
  inspect(joined.to_string(), content=expected)
  inspect(joined.basename(), content="c.txt")
  inspect(joined.dirname(), content="a")
  inspect(joined.extname(), content=".txt")
  inspect(joined == path.join("c.txt"), content="true")
  inspect(joined.is_absolute(), content="false")
  let resolve : (@path.Path) -> @path.Path raise @path.ResolveError = @path.Path::resolve
  let relative : (@path.Path, @path.Path) -> @path.Path raise @path.ResolveError = (
    path,
    base,
  ) => path.relative(base~)
  let root : @path.Path = if @path.sep == '/' { "/" } else { "C:\\" }
  let absolute = root / "a" / ".." / "b"
  inspect(resolve(absolute) == root / "b", content="true")
  inspect(absolute.normalize() == root / "b", content="true")
  inspect(relative(absolute, root), content="b")
}
