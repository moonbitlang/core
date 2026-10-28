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
pub using @error {type ResolveError}

///|
/// A string wrapper providing POSIX path operations.
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
/// This follows Node `path.posix.basename`: trailing separators are ignored and
/// repeated separators are not normalized before scanning.
///
/// ```moonbit check
/// test {
///   let path : @posix.Path = "usr/local/"
///   inspect(path.basename(), content="local")
/// }
/// ```
pub fn Path::basename(path : Path) -> StringView {
  // strip all trailing separator
  let path = path.0[:].trim_end(chars="/")
  // return content after last separator
  match path.rev_split_once("/") {
    None => path
    Some((_, name)) => name
  }
}

///|
/// Returns the directory portion of the given path.
///
/// This follows Node `path.posix.dirname`: it ignores trailing separators while
/// preserving repeated separators that participate in the directory portion.
///
/// ```moonbit check
/// test {
///   let path : @posix.Path = "usr/local/"
///   inspect(path.dirname(), content="usr")
/// }
/// ```
pub fn Path::dirname(path : Path) -> Path {
  let mut path = path.0[:]
  guard !path.is_empty() else { "." }
  // strip all trailing separator
  while path is [.. rest, last_char] && last_char == '/' {
    path = rest
  }
  // return content before last separator
  match path.rev_find("/") {
    None => if path.is_empty() { "/" } else { "." }
    Some(0) => "/"
    Some(1) => if path is ['/', '/', ..] { "//" } else { path[:1].to_owned() }
    Some(idx) => path[:idx].to_owned()
  }
}

///|
/// Returns the extension of the last path component.
///
/// This follows Node `path.posix.extname` dotfile rules: a leading dot by
/// itself does not start an extension.
///
/// ```moonbit check
/// test {
///   let path : @posix.Path = "archive.tar.gz"
///   inspect(path.extname(), content=".gz")
/// }
/// ```
pub fn Path::extname(path : Path) -> StringView {
  let basename = Path::basename(path)
  if basename == "." || basename == ".." {
    return ""
  }
  match basename.rev_find(".") {
    None | Some(0) => ""
    Some(idx) => basename[idx:]
  }
}

///|
/// Returns whether the given path is absolute.
///
/// edge cases: when path is empty, return false
///
/// ```moonbit check
/// test {
///   let path1 : @posix.Path = "/usr/local/bin"
///   let path2 : @posix.Path = "usr/local/bin"
///   json_inspect(path1.is_absolute(), content=true)
///   json_inspect(path2.is_absolute(), content=false)
/// }
/// ```
pub fn Path::is_absolute(path : Path) -> Bool {
  path.0 is ['/', ..]
}

///|
/// Concatenates two path strings with `/`, then normalizes the result.
///
/// Unlike `resolve`, an absolute right-hand path does not override `lhs`.
///
/// ```mbt check
/// test {
///   assert_eq(@posix.Path::join("/usr/local", "bin"), "/usr/local/bin")
///   assert_eq(@posix.Path::join("/usr/local", "/usr"), "/usr/local/usr")
///   assert_eq(@posix.Path::join("/usr/local", ""), "/usr/local")
///   assert_eq(@posix.Path::join("", "local/bin"), "local/bin")
///   assert_eq(@posix.Path::join("", ""), ".")
/// }
/// ```
pub fn Path::join(lhs : Path, rhs : Path) -> Path {
  let lhs = lhs.0
  let rhs = rhs.0
  guard !lhs.is_empty() || !rhs.is_empty() else { "." }
  guard !lhs.is_empty() else { Path::normalize(rhs) }
  guard !rhs.is_empty() else { Path::normalize(lhs) }
  Path::normalize(lhs + "/" + rhs)
}

///|
/// Joins two paths, equivalent to `Path::join(lhs, rhs)`.
///
/// Each `/` normalizes the result using POSIX path rules.
/// Absolute right-hand paths do not replace the left-hand path.
///
/// ```mbt check
/// test {
///   let path : @posix.Path = "/usr"
///   inspect(path / "local" / "bin", content="/usr/local/bin")
/// }
/// ```
pub impl Div for Path with fn div(lhs, rhs) {
  lhs.join(rhs)
}

///|
/// 1. resolve `.` by directly removing it
/// 2. resolve `..` by removing the preceding path component if exists, otherwise keep it.
/// 3. remove redundant slashes
/// 4. preserve trailing slash
///
/// edge cases:
///   1. when path is empty, return `.`
///   2. leading `//` is normalized to `/`, following Node `path.posix`.
///
/// ```moonbit check
/// test {
///   let path : @posix.Path = "/usr//local/../bin/"
///   inspect(path.normalize(), content="/usr/bin/")
/// }
/// ```
pub fn Path::normalize(path : Path) -> Path {
  Show::to_string(UnixPath::parse(path.0))
}

///|
fn trim_resolved_trailing_separators(path : Path) -> Path {
  let mut raw = path.0[:]
  while raw is [.. rest, last_char] && last_char == '/' && !rest.is_empty() {
    raw = rest
  }
  Path(raw.to_owned())
}

///|
/// Returns the relative path from `base` to `path`.
///
/// property: joining `base` with the returned relative path yields
/// `@path.resolve(path)`.
///
/// edge cases:
///  1. when `@path.resolve(base) == @path.resolve(path)`, return empty string
///  2. when `base` and `path` have different prefixes, return empty string
///
/// Warning: cwd is already resolve symbolic link and normalized, but path doesn't.
///
/// ```moonbit check
/// test {
///   let base : @posix.Path = "/usr/local/bin"
///   let path : @posix.Path = "/usr/local/share/doc"
///   inspect(path.relative(base~), content="../share/doc")
/// }
/// ```
///
/// Raises `ResolveError::CurrentDirectoryUnavailable` if either path is
/// relative and the current working directory cannot be determined.
pub fn Path::relative(path : Path, base~ : Path) -> Path raise ResolveError {
  relative_with_current_dir(path, base~, @env.current_dir)
}

///|
fn relative_with_current_dir(
  path : Path,
  base~ : Path,
  current_dir : () -> String?,
) -> Path raise ResolveError {
  let from = UnixPath::parse(resolve_with_current_dir(base, current_dir).0)
  let to = UnixPath::parse(resolve_with_current_dir(path, current_dir).0)
  guard from.prefix == to.prefix else { "" }
  let mut common = 0
  let limit = @cmp.minimum(from.components.length(), to.components.length())
  while common < limit && from.components[common] == to.components[common] {
    common += 1
  }
  let components : Array[StringView] = [
    ..(Array::make(from.components.length() - common, "..") : Array[StringView]),
    ..to.components[common:],
  ]
  guard !components.is_empty() else { "" }
  Show::to_string(UnixPath::{
    prefix: None,
    trailing_separator: false,
    components,
  })
}

///|
/// 1. if path is already absolute, normalize it and remove non-root trailing separators.
/// 2. if path is relative, join current working directory and path, normalize it,
///    and remove non-root trailing separators.
///
/// Warning: cwd is already resolve symbolic link and normalized, but path doesn't.
///
/// Raises `ResolveError::CurrentDirectoryUnavailable` if the path is relative
/// and the current working directory cannot be determined.
pub fn Path::resolve(path : Path) -> Path raise ResolveError {
  resolve_with_current_dir(path, @env.current_dir)
}

///|
fn resolve_with_current_dir(
  path : Path,
  current_dir : () -> String?,
) -> Path raise ResolveError {
  let resolved = {
    guard !Path::is_absolute(path) else { Path::normalize(path) }
    guard current_dir() is Some(cwd) else { raise CurrentDirectoryUnavailable }
    Path::join(cwd, path) |> Path::normalize
  }
  trim_resolved_trailing_separators(resolved)
}

///|
/// OS platform specific path delimiter for environment variables. e.g., PATH
pub let delimiter : Char = ':'

///|
/// OS platform specific path component separator.
pub let sep : Char = '/'
