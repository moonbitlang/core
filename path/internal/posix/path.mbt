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
/// Returns the last path component of the given path.
///
/// This follows Node `path.posix.basename`: trailing separators are ignored and
/// repeated separators are not normalized before scanning.
///
/// ```moonbit check
/// test {
///   let path : String = "usr/local/"
///   inspect(@posix.basename(path), content="local")
/// }
/// ```
pub fn basename(path : String) -> StringView {
  // strip all trailing separator
  let path = path[:].trim_end(chars="/")
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
///   let path : String = "usr/local/"
///   inspect(@posix.dirname(path), content="usr")
/// }
/// ```
pub fn dirname(path : String) -> String {
  let mut path = path[:]
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
///   let path : String = "archive.tar.gz"
///   inspect(@posix.extname(path), content=".gz")
/// }
/// ```
pub fn extname(path : String) -> StringView {
  let basename = basename(path)
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
///   let path1 : String = "/usr/local/bin"
///   let path2 : String = "usr/local/bin"
///   json_inspect(@posix.is_absolute(path1), content=true)
///   json_inspect(@posix.is_absolute(path2), content=false)
/// }
/// ```
pub fn is_absolute(path : String) -> Bool {
  path is ['/', ..]
}

///|
/// Concatenates two path strings with `/`, then normalizes the result.
///
/// Unlike `resolve`, an absolute right-hand path does not override `lhs`.
///
/// ```mbt check
/// test {
///   assert_eq(@posix.join("/usr/local", "bin"), "/usr/local/bin")
///   assert_eq(@posix.join("/usr/local", "/usr"), "/usr/local/usr")
///   assert_eq(@posix.join("/usr/local", ""), "/usr/local")
///   assert_eq(@posix.join("", "local/bin"), "local/bin")
///   assert_eq(@posix.join("", ""), ".")
/// }
/// ```
pub fn join(lhs : String, rhs : String) -> String {
  guard !lhs.is_empty() || !rhs.is_empty() else { "." }
  guard !lhs.is_empty() else { normalize(rhs) }
  guard !rhs.is_empty() else { normalize(lhs) }
  normalize(lhs + "/" + rhs)
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
///   let path : String = "/usr//local/../bin/"
///   inspect(@posix.normalize(path), content="/usr/bin/")
/// }
/// ```
pub fn normalize(path : String) -> String {
  Show::to_string(UnixPath::parse(path))
}

///|
fn trim_resolved_trailing_separators(path : String) -> String {
  let mut raw = path[:]
  while raw is [.. rest, last_char] && last_char == '/' && !rest.is_empty() {
    raw = rest
  }
  raw.to_owned()
}

///|
/// Returns the relative path from `base` to `path`.
///
/// property: joining `base` with the returned relative path yields
/// `resolve(path)`.
///
/// edge cases:
///  1. when `resolve(base) == resolve(path)`, return empty string
///  2. when `base` and `path` have different prefixes, return empty string
///
/// Warning: cwd is already resolve symbolic link and normalized, but path doesn't.
///
/// ```moonbit check
/// test {
///   let base : String = "/usr/local/bin"
///   let path : String = "/usr/local/share/doc"
///   inspect(@posix.relative(path, base~), content="../share/doc")
/// }
/// ```
///
/// Raises `ResolveError::CurrentDirectoryUnavailable` if either path is
/// relative and the current working directory cannot be determined.
pub fn relative(path : String, base~ : String) -> String raise ResolveError {
  relative_with_current_dir(path, base~, @env.current_dir)
}

///|
fn relative_with_current_dir(
  path : String,
  base~ : String,
  current_dir : () -> String?,
) -> String raise ResolveError {
  let from = UnixPath::parse(resolve_with_current_dir(base, current_dir))
  let to = UnixPath::parse(resolve_with_current_dir(path, current_dir))
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
pub fn resolve(path : String) -> String raise ResolveError {
  resolve_with_current_dir(path, @env.current_dir)
}

///|
fn resolve_with_current_dir(
  path : String,
  current_dir : () -> String?,
) -> String raise ResolveError {
  let resolved = {
    guard !is_absolute(path) else { normalize(path) }
    guard current_dir() is Some(cwd) else { raise CurrentDirectoryUnavailable }
    join(cwd, path) |> normalize
  }
  trim_resolved_trailing_separators(resolved)
}

///|
/// OS platform specific path delimiter for environment variables. e.g., PATH
pub let delimiter : Char = ':'

///|
/// OS platform specific path component separator.
pub let sep : Char = '/'
