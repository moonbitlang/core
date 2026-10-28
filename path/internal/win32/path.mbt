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
fn is_win_sep(ch : Char) -> Bool {
  ch == '\\' || ch == '/'
}

///|
fn last_win_sep(path : StringView) -> Int32? {
  match (path.rev_find("/"), path.rev_find("\\")) {
    (None, None) => None
    (Some(idx), None) | (None, Some(idx)) => Some(idx)
    (Some(lidx), Some(ridx)) => Some(@cmp.maximum(lidx, ridx))
  }
}

///|
fn is_drive_relative(path : String) -> Bool {
  start_with_win_drive(path) && (path.length() == 2 || !is_win_sep_at(path, 2))
}

///|
/// Resolves the current directory of a drive-relative path, following
/// `GetFullPathNameW`: a drive-relative path such as `C:main.mbt` is relative
/// to the current directory of drive `C`, not to the process current
/// directory.
///
/// Windows stores the per-drive current directory in a hidden environment
/// variable named `=<L>:` (e.g. `=C:`), which a process inherits and updates
/// as the drive's current directory changes. When the variable is absent
/// (e.g. set by another process, or constructed by `SetCurrentDirectory`
/// semantics without one), `fallback_cwd` is used instead.
///
/// See [The Old New Thing: What are these environment variables like
/// =C:?](https://devblogs.microsoft.com/oldnewthing/20100412-00/?p=14313)
fn current_dir_for_drive_with_cwd(
  device : StringView,
  fallback_cwd : String,
) -> String {
  let device = device.to_owned()
  let cwd = @env.get_env_var("=\{device}").unwrap_or(fallback_cwd)
  if start_with_win_drive(cwd) &&
    !cwd[0:2].equal_ignore_ascii_case(device) &&
    cwd.length() > 2 &&
    is_win_sep_at(cwd, 2) {
    "\{device}\\"
  } else if !start_with_win_drive(cwd) &&
    cwd.length() > 0 &&
    is_win_sep_at(cwd, 0) {
    "\{device}\{cwd}"
  } else if !start_with_win_drive(cwd) {
    "\{device}\\\{cwd}"
  } else {
    cwd
  }
}

///|
/// Returns the last path component of the given path.
///
/// This follows Node `path.win32.basename`: both `/` and `\` are separators,
/// trailing separators are ignored, and root-only paths return an empty name.
///
/// ```moonbit check
/// test {
///   let path : String = "usr\\local\\"
///   inspect(@win32.basename(path), content="local")
/// }
/// ```
pub fn basename(path : String) -> StringView {
  // strip win drive
  let mut path = path[:]
  if start_with_win_drive(path) {
    path = path[2:]
  }
  // strip all trailing separator
  let path = path.trim_end(chars="/\\")
  // return content after last separator
  match last_win_sep(path) {
    None => path
    Some(idx) => path[idx + 1:]
  }
}

///|
/// Returns the directory portion of the given path.
///
/// This follows Node `path.win32.dirname`: both separators are recognized and
/// the returned directory preserves the original separator spelling.
///
/// ```moonbit check
/// test {
///   let path : String = "usr\\local\\"
///   inspect(@win32.dirname(path), content="usr")
/// }
/// ```
pub fn dirname(path : String) -> String {
  let raw = path
  guard !raw.is_empty() else { "." }
  let root_end = WinPath::parse(raw).root_end
  guard root_end < raw.length() else { raw }
  let mut path = raw[:]
  // strip all trailing separator outside the root
  while path.length() > root_end &&
        path is [.. rest, last_char] &&
        is_win_sep(last_char) {
    path = rest
  }
  if path.length() <= root_end {
    raw[0:root_end].to_owned()
  } else {
    match last_win_sep(path) {
      None => if root_end > 0 { raw[0:root_end].to_owned() } else { "." }
      Some(idx) =>
        if idx < root_end {
          raw[0:root_end].to_owned()
        } else {
          raw[0:idx].to_owned()
        }
    }
  }
}

///|
/// Returns the extension of the last path component.
///
/// This follows Node `path.win32.extname` dotfile rules.
///
/// ```moonbit check
/// test {
///   let path : String = "archive.tar.gz"
///   inspect(@win32.extname(path), content=".gz")
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
///   let path1 : String = "C:\\Program Files\\App"
///   let path2 : String = "Program Files\\App"
///   json_inspect(@win32.is_absolute(path1), content=true)
///   json_inspect(@win32.is_absolute(path2), content=false)
/// }
/// ```
pub fn is_absolute(path : String) -> Bool {
  match WinPath::parse(path).prefix {
    Root | VerbatimRoot | DeviceRoot | UNC(_) | VolumeLetterRoot(_) => true
    _ => false
  }
}

///|
/// Returns the root of the given path, following Node `path.win32.parse().root`.
///
/// The root keeps the input's separator spelling and includes the trailing
/// separator for rooted paths (e.g. `C:\`, `\\server\share\`, `\\?\C:\`).
/// A path without a root returns an empty string.
///
/// edge cases:
///   1. when path is empty or relative, return `""`
///   2. bare `\\` and UNC host without share return `\`, following Node
///
/// ```moonbit check
/// test {
///   let path : String = "C:\\foo\\bar"
///   inspect(@win32.root(path), content="C:\\")
///   let path : String = "\\\\server\\share\\file"
///   inspect(@win32.root(path), content="\\\\server\\share\\")
/// }
/// ```
pub fn root(path : String) -> StringView {
  path[:WinPath::parse(path).root_end]
}

///|
/// Concatenates two path strings with `\`, then normalizes the result.
///
/// Absolute right-hand paths and different-drive paths do not override `lhs`.
///
/// ```moonbit check
/// test {
///   let path1 : String = "C::\\Program Files"
///   let path2 : String = "App"
///   inspect(@win32.join(path1, path2), content="C::\\Program Files\\App")
/// }
/// ```
pub fn join(lhs : String, rhs : String) -> String {
  guard !lhs.is_empty() || !rhs.is_empty() else { "." }
  guard !lhs.is_empty() else { normalize(rhs) }
  guard !rhs.is_empty() else { normalize(lhs) }
  normalize(lhs + "\\" + rhs)
}

///|
/// 1. resolve `.` by directly removing it
/// 2. resolve `..` by removing the preceding path component if exists, otherwise keep it.
/// 3. remove redundant backslashes
/// 4. preserve trailing slash or backslash
///
/// edge cases:
///   1. when path is empty, return `.`
///
/// ```moonbit check
/// test {
///   let path : String = "C:\\usr\\\\local\\..\\bin\\"
///   inspect(@win32.normalize(path), content="C:\\usr\\bin\\")
///
///   let rooted_path : String = "/usr//local/../bin/"
///   inspect(@win32.normalize(rooted_path), content="\\usr\\bin\\")
/// }
/// ```
pub fn normalize(path : String) -> String {
  let raw = path
  let parsed = WinPath::parse(raw)
  let normalized = Show::to_string(parsed)
  if needs_normalize_drive_guard(raw, normalized, parsed) {
    ".\\\{normalized}"
  } else {
    normalized
  }
}

///|
fn needs_normalize_drive_guard(
  raw : String,
  normalized : String,
  parsed : WinPath,
) -> Bool {
  guard parsed.prefix is None && raw.contains_char(':') else { return false }
  if start_with_win_drive(normalized) {
    return true
  }
  for i in 0..<raw.length() {
    guard raw.get_char(i) == Some(':') &&
      (i == raw.length() - 1 || is_win_sep_at(raw, i + 1)) else {
      continue
    }
    return true
  }
  false
}

///|
fn is_regular_win_root(path : WinPath) -> Bool {
  guard path.components.is_empty() else { false }
  match path.prefix {
    Root | VolumeLetterRoot(_) | UNC(_) => true
    _ => false
  }
}

///|
fn trim_resolved_trailing_separators(path : String) -> String {
  let parsed = WinPath::parse(path)
  guard !is_regular_win_root(parsed) else { path }
  let mut raw = path[:]
  while raw is [.. rest, last_char] && is_win_sep(last_char) && !rest.is_empty() {
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
///  2. when the resolved paths have no common root boundary, return the resolved target path
///
/// Warning: cwd is already resolve symbolic link and normalized, but path doesn't.
///
/// ```moonbit check
/// test {
///   let path : String = "C:\\Users\\Alice\\Documents\\Project"
///   let base : String = "C:\\Users\\Alice"
///   inspect(@win32.relative(path, base~), content="Documents\\Project")
///
///   let base : String = "/usr/local/bin"
///   let path : String = "/usr/local/share/doc"
///   inspect(@win32.relative(path, base~), content="..\\share\\doc")
/// }
/// ```
///
/// Raises `ResolveError::CurrentDirectoryUnavailable` if either path needs
/// the current working directory and it cannot be determined.
pub fn relative(path : String, base~ : String) -> String raise ResolveError {
  relative_with_current_dir(path, base~, @env.current_dir)
}

///|
fn relative_with_current_dir(
  path : String,
  base~ : String,
  current_dir : () -> String?,
) -> String raise ResolveError {
  let resolved_from = resolve_with_current_dir(base, current_dir)
  let resolved_to = resolve_with_current_dir(path, current_dir)
  relative_resolved_paths(resolved_from, resolved_to)
}

///|
fn win_string_equal_ignore_case(left : StringView, right : StringView) -> Bool {
  left == right || @unicode.lowercase(left) == @unicode.lowercase(right)
}

///|
fn split_win_parts(path : StringView) -> Array[StringView] {
  let parts : Array[StringView] = []
  let mut start = 0
  let mut i = 0
  while path.get_char(i) is Some(ch) {
    if is_win_sep(ch) {
      if start < i {
        parts.push(path[start:i])
      }
      i = skip_win_separators(path, i)
      start = i
    } else {
      i += ch.utf16_len()
    }
  }
  if start < i {
    parts.push(path[start:i])
  }
  parts
}

///|
fn relative_resolved_paths(from_orig : String, to_orig : String) -> String {
  if from_orig == to_orig || win_string_equal_ignore_case(from_orig, to_orig) {
    return ""
  }
  let from_parts = split_win_parts(from_orig)
  let to_parts = split_win_parts(to_orig)
  if from_parts.is_empty() ||
    to_parts.is_empty() ||
    !win_string_equal_ignore_case(from_parts[0], to_parts[0]) {
    return to_orig
  }
  let mut common = 0
  let limit = @cmp.minimum(from_parts.length(), to_parts.length())
  while common < limit &&
        win_string_equal_ignore_case(from_parts[common], to_parts[common]) {
    common += 1
  }
  let components : Array[StringView] = [
    ..(Array::make(from_parts.length() - common, "..") : Array[StringView]),
    ..to_parts[common:],
  ]
  guard !components.is_empty() else { "" }
  let builder = StringBuilder()
  for i in 0..<components.length() {
    if i > 0 {
      builder.write_char('\\')
    }
    builder.write_stringview(components[i])
  }
  builder.to_string()
}

///|
/// 1. if path is fully rooted (drive root, UNC, verbatim, or device root),
///    normalize it and remove trailing separators except regular roots.
/// 2. if path is drive-less rooted, resolve it against the current drive or
///    UNC share when cwd provides one, then normalize it and remove trailing
///    separators except regular roots.
/// 3. if path is drive-relative, resolve it against that drive's current directory
///    (read from the `=<L>:` environment variable, following `GetFullPathNameW`),
///    then normalize it and remove trailing separators except regular roots.
/// 4. if path is otherwise relative, join current working directory and path,
///    then normalize it and remove trailing separators except regular roots.
///
/// Warning: cwd is already resolve symbolic link and normalized, but path doesn't.
///
/// Raises `ResolveError::CurrentDirectoryUnavailable` if the path needs the
/// current working directory and it cannot be determined.
pub fn resolve(path : String) -> String raise ResolveError {
  resolve_with_current_dir(path, @env.current_dir)
}

///|
fn resolve_with_current_dir(
  path : String,
  current_dir : () -> String?,
) -> String raise ResolveError {
  match WinPath::parse(path).prefix {
    VolumeLetterRoot(_) | UNC(_) | VerbatimRoot | DeviceRoot =>
      trim_resolved_trailing_separators(normalize(path))
    _ => {
      guard current_dir() is Some(cwd) else {
        raise CurrentDirectoryUnavailable
      }
      resolve_with_cwd(path, cwd)
    }
  }
}

///|
fn cwd_device_for_drive_less_rooted_path(cwd : String) -> String? {
  match WinPath::parse(cwd).prefix {
    VolumeLetterRoot(_) => Some(cwd[0:2].to_owned())
    UNC(hostname~, shared_folder~) => Some("\\\\\{hostname}\\\{shared_folder}")
    _ => None
  }
}

///|
fn resolve_with_cwd(path : String, cwd : String) -> String {
  let raw_path = path
  let parsed = WinPath::parse(raw_path)
  let resolved = match parsed.prefix {
    Root =>
      match cwd_device_for_drive_less_rooted_path(cwd) {
        Some(device) => normalize("\{device}\{raw_path}")
        None => normalize(path)
      }
    VolumeLetterRoot(_) | UNC(_) | VerbatimRoot | DeviceRoot => normalize(path)
    _ =>
      if is_drive_relative(raw_path) {
        let base = normalize(current_dir_for_drive_with_cwd(raw_path[0:2], cwd))
        let tail = raw_path[2:]
        if tail.is_empty() {
          base
        } else {
          join(base, tail.to_owned())
        }
      } else {
        join(cwd, path)
      }
  }
  trim_resolved_trailing_separators(resolved)
}

///|
/// OS platform specific path delimiter for environment variables. e.g., PATH
pub let delimiter : Char = ';'

///|
/// OS platform specific path component separator.
pub let sep : Char = '\\'
