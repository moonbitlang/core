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
/// Path utilities with the existing MoonBit API surface.
///
/// Behavior follows Node `node:path` for the active platform flavor. The
/// top-level package dispatches to `@path/posix` or `@path/win32` at runtime.

///|
let is_windows : Bool = @ffi.is_windows()

///|
pub using @error {type ResolveError}

///|
/// A string wrapper providing path operations.
///
/// Equality compares the underlying strings exactly, including case and
/// separators. It does not normalize paths or determine whether they refer to
/// the same filesystem entry.
pub(all) struct Path(String) derive(Eq, @debug.Debug)

///|
pub impl Show for Path with fn output(path, logger) {
  logger.write_object(path.0)
}

///|
pub impl Show for Path with fn to_string(path) {
  path.0
}

///|
/// Returns the last path component of the given path.
///
/// Trailing separators are ignored, following Node `path.basename`.
///
/// ```mbt check
/// test {
///   let path : @path.Path = "usr/local/bin"
///   inspect(path.basename(), content="bin")
/// }
/// ```
pub fn Path::basename(path : Path) -> StringView {
  if is_windows {
    @win32.Path::basename(path.0)
  } else {
    @posix.Path::basename(path.0)
  }
}

///|
/// Returns the directory portion of the path, following Node `path.dirname`.
///
/// ```mbt check
/// test {
///   let path : @path.Path = "usr/local/bin"
///   inspect(path.dirname(), content="usr/local")
/// }
/// ```
pub fn Path::dirname(path : Path) -> Path {
  if is_windows {
    @win32.Path::dirname(path.0).0
  } else {
    @posix.Path::dirname(path.0).0
  }
}

///|
/// Returns the extension of the last path component, following Node
/// `path.extname` dotfile rules.
///
/// ```mbt check
/// test {
///   let path : @path.Path = "archive.tar.gz"
///   inspect(path.extname(), content=".gz")
/// }
/// ```
pub fn Path::extname(path : Path) -> StringView {
  if is_windows {
    @win32.Path::extname(path.0)
  } else {
    @posix.Path::extname(path.0)
  }
}

///|
/// Returns whether the given path is absolute.
///
/// edge cases: when path is empty, return false
///
/// ```mbt check
/// test {
///   let path1 : @path.Path = "/usr/local/bin"
///   let path2 : @path.Path = "usr/local/bin"
///   json_inspect(path1.is_absolute(), content=true)
///   json_inspect(path2.is_absolute(), content=false)
/// }
/// ```
pub fn Path::is_absolute(path : Path) -> Bool {
  if is_windows {
    @win32.Path::is_absolute(path.0)
  } else {
    @posix.Path::is_absolute(path.0)
  }
}

///|
/// Concatenates two path strings with the active separator, then normalizes.
///
/// Absolute right-hand paths do not override `lhs`. When both inputs are empty,
/// the result is `"."`.
///
pub fn Path::join(lhs : Path, rhs : Path) -> Path {
  if is_windows {
    @win32.Path::join(lhs.0, rhs.0).0
  } else {
    Show::to_string(@posix.Path::join(lhs.0, rhs.0))
  }
}

///|
/// 1. resolve `.` by directly removing it
/// 2. resolve `..` by removing the preceding path component if exists, otherwise keep it.
/// 3. remove redundant slashes or backslashes
/// 4. preserve trailing slash or backslash
///
/// edge cases:
///   1. when path is empty, return `.`
///   2. POSIX leading `//` is normalized to `/`, following Node behavior.
///
/// See `@path/posix` and `@path/win32` for separator-specific examples.
pub fn Path::normalize(path : Path) -> Path {
  if is_windows {
    Show::to_string(@win32.Path::normalize(path.0))
  } else {
    Show::to_string(@posix.Path::normalize(path.0))
  }
}

///|
/// Returns the relative path from `base` to `path`.
///
/// property: joining `base` with the returned relative path yields
/// `@path.resolve(path)`.
///
/// edge cases:
///  1. when `@path.resolve(base) == @path.resolve(path)`, return empty string
///  2. on Windows, different roots return the resolved target path
///
/// Warning: cwd is already resolve symbolic link and normalized, but path doesn't.
///
/// See `@path/posix` and `@path/win32` for separator-specific examples.
/// Raises `ResolveError::CurrentDirectoryUnavailable` if either path needs
/// the current working directory and it cannot be determined.
pub fn Path::relative(path : Path, base~ : Path) -> Path raise ResolveError {
  if is_windows {
    @win32.Path::relative(path.0, base=base.0).0
  } else {
    @posix.Path::relative(path.0, base=base.0).0
  }
}

///|
/// 1. if path is already absolute, normalize it and remove non-root trailing separators.
/// 2. if path is relative, join current working directory and path, normalize it,
///    and remove non-root trailing separators.
///
/// Warning: cwd is already resolve symbolic link and normalized, but path doesn't.
///
/// Raises `ResolveError::CurrentDirectoryUnavailable` if the path needs the
/// current working directory and it cannot be determined.
pub fn Path::resolve(path : Path) -> Path raise ResolveError {
  if is_windows {
    Show::to_string(@win32.Path::resolve(path.0))
  } else {
    Show::to_string(@posix.Path::resolve(path.0))
  }
}

///|
/// OS platform specific path delimiter for environment variables. e.g., PATH
pub let delimiter : Char = if is_windows { ';' } else { ':' }

///|
/// OS platform specific path component separator.
pub let sep : Char = if is_windows { '\\' } else { '/' }
