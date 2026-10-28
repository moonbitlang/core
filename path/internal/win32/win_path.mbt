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
/// [Microsoft Naming a Volume](https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-volume)
/// [Microsoft Naming Files, Paths, and Namespaces](https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-file)
/// [Microsoft Maximum Path Length Limitation](https://learn.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation)
/// [Microsoft GetFullPathNameW](https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-getfullpathnamew)
/// [The Old New Thing: What are these environment variables like =C:?](https://devblogs.microsoft.com/oldnewthing/20100412-00/?p=14313)
priv struct WinPath {
  prefix : WinPrefix
  trailing_separator : Bool
  components : Array[StringView]
  /// Index of the root's end in the original path string (before any
  /// normalization), following Node `path.win32.parse().root`.
  root_end : Int32
} derive(@json.ToJson, Hash, Eq)

///|
/// #### Verbatim Prefix
///
/// refer to [Microsoft Win32 File Namespaces](https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-file#win32-file-namespaces)
/// > For file I/O,
/// > the "\\?\" prefix to a path string tells the Windows APIs to disable all string parsing and to send the string that follows it straight to the file system.
///
/// #### Windows Encoding
///
/// refer to [Microsoft Path Unicode Normalization](https://learn.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation)
///
/// > There is no need to perform any Unicode normalization on path and file name strings for use by the Windows file I/O API functions
/// > because the file system treats path and file names as an opaque sequence of WCHARs.
/// > Any normalization that your application requires should be performed with this in mind,
/// > external of any calls to related Windows file I/O API functions.
///
/// #### Relative Paths Cannot use Verbatim Prefix
///
/// refer to [Microsoft Verbatim restriction](https://learn.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation)
///
/// > Because you cannot use the "\\?\" prefix with a relative path,
/// > relative paths are always limited to a total of MAX_PATH characters.
///
priv enum WinPrefix {
  /// Syntax: `\`
  ///
  /// Example: `\Users\username\Documents\`
  Root
  /// Syntax: `\\?\`
  ///
  /// Example: `\\?\C:\`
  VerbatimRoot
  /// Syntax: `\\.`
  ///
  /// Example: `\\.\COM56`
  DeviceRoot
  /// Syntax: `\\<SERVER>\<SHARE>\`
  ///
  /// Example: `\\server\share\`
  UNC(hostname~ : String, shared_folder~ : String)
  /// Syntax: `<L>:\`
  ///
  /// Example: `C:\`
  ///
  /// Warning: this letter is case-insensitive.
  VolumeLetterRoot(Char)
  /// Syntax: `<L>:<rest_of_path>`
  ///
  /// Example: `C:main.mbt`
  ///
  /// A drive-relative path is resolved against the current directory of
  /// drive `<L>`, following `GetFullPathNameW`. The per-drive current
  /// directory is read from the `=<L>:` environment variable.
  ///
  /// Warning: this letter is case-insensitive.
  VolumeLetter(Char)
  None
} derive(@json.ToJson, Hash, Eq)

// In order to make code more clean,
// so we have to define many string constants to avoid escape sequences.

///|
const VerbatimPrefix : String =
  #|\\?\

///|
const ColonBackslash : String =
  #|:\

///|
const DevicePrefix : String =
  #|\\.\

///|
const UncPrefix : String =
  #|\\

///|
const BackSlash : Char = '\\'

///|
impl Show for WinPrefix with fn output(self, logger) {
  match self {
    Root => logger.write_char(BackSlash)
    VerbatimRoot => logger.write_string(VerbatimPrefix)
    DeviceRoot => logger.write_string(DevicePrefix)
    UNC(hostname~, shared_folder~) =>
      logger <+
        "\{UncPrefix}\{hostname}\{BackSlash}\{shared_folder}\{BackSlash}"
    VolumeLetterRoot(letter) => logger <+ "\{letter}\{ColonBackslash}"
    VolumeLetter(letter) => logger <+ "\{letter}:"
    None => ()
  }
}

///|
fn WinPath::output(self : WinPath, logger : &Logger) -> Unit {
  let { prefix, trailing_separator, components, .. } = self
  let mut prefix_ends_with_sep = false
  match prefix {
    Root => {
      logger.write_char(BackSlash)
      prefix_ends_with_sep = true
    }
    VerbatimRoot => {
      logger.write_string(VerbatimPrefix)
      prefix_ends_with_sep = true
    }
    DeviceRoot => {
      logger.write_string(DevicePrefix)
      prefix_ends_with_sep = true
    }
    UNC(hostname~, shared_folder~) => {
      logger <+
        "\{UncPrefix}\{hostname}\{BackSlash}\{shared_folder}\{BackSlash}"
      prefix_ends_with_sep = true
    }
    VolumeLetterRoot(letter) => {
      logger <+ "\{letter}\{ColonBackslash}"
      prefix_ends_with_sep = true
    }
    VolumeLetter(letter) => logger <+ "\{letter}:"
    None => ()
  }
  match components {
    [] =>
      match prefix {
        None | VolumeLetter(_) =>
          if trailing_separator {
            logger <+ ".\\"
          } else {
            logger.write_char('.')
          }
        _ => ()
      }
    [x, .. xs] => {
      if !prefix_ends_with_sep &&
        !(prefix is None) &&
        !(prefix is VolumeLetter(_)) {
        logger.write_char(BackSlash)
      }
      logger.write_view(x)
      for component in xs {
        logger <+ "\{BackSlash}\{component}"
      }
      if trailing_separator {
        logger.write_char(BackSlash)
      }
    }
  }
}

///|
impl Show for WinPath with fn output(self, logger) {
  WinPath::output(self, logger)
}

///|
fn is_win_sep_at(path : StringView, index : Int32) -> Bool {
  path.get_char(index) is Some(ch) && is_win_sep(ch)
}

///|
fn start_with_win_drive(path : StringView) -> Bool {
  path is [ch, ':', ..] && ch.is_ascii_alphabetic()
}

///|
fn skip_win_separators(path : StringView, start : Int32) -> Int32 {
  let mut index = start
  while index < path.length() && is_win_sep_at(path, index) {
    index += 1
  }
  index
}

///|
fn find_next_win_sep(path : StringView, start : Int32) -> Int32? {
  for i in start..<path.length() {
    guard is_win_sep_at(path, i) else { continue }
    return Some(i)
  }
  None
}

///|
fn push_windows_component(
  components : Array[StringView],
  component : StringView,
  allow_above_root~ : Bool,
) -> Unit {
  match component {
    "." => ()
    ".." =>
      match components.pop() {
        Some("..") => {
          components.push("..")
          if allow_above_root {
            components.push("..")
          }
        }
        None => if allow_above_root { components.push("..") }
        Some(_) => ()
      }
    _ => components.push(component)
  }
}

///|
fn parse_windows_components(
  path : StringView,
  start : Int32,
  allow_above_root~ : Bool,
) -> Array[StringView] {
  let components : Array[StringView] = []
  path[start:]
  .replace_all(old="/", new="\\")
  .split("\\")
  .filter(fn(component) { !component.is_empty() })
  .each(fn(component) {
    push_windows_component(components, component, allow_above_root~)
  })
  components
}

///|
fn parse_verbatim_prefixed_path(
  path : StringView,
  trailing_separator : Bool,
) -> WinPath? {
  guard path.length() >= 4 && path.get_char(2) == Some('?') else { return None }
  guard is_win_sep_at(path, 3) else { return None }
  let marker_end = 4
  let components = parse_windows_components(
    path,
    marker_end,
    allow_above_root=false,
  )
  let root_end = component_root_end(path, marker_end)
  Some({ prefix: VerbatimRoot, trailing_separator, components, root_end, })
}

///|
fn parse_device_prefixed_path(
  path : StringView,
  trailing_separator : Bool,
) -> WinPath? {
  guard path.length() >= 4 && path.get_char(2) == Some('.') else { return None }
  guard is_win_sep_at(path, 3) else { return None }
  let part_start = 4
  let components = parse_windows_components(
    path,
    part_start,
    allow_above_root=false,
  )
  let root_end = component_root_end(path, part_start)
  Some({ prefix: DeviceRoot, trailing_separator, components, root_end, })
}

///|
fn component_root_end(path : StringView, start : Int32) -> Int32 {
  match find_next_win_sep(path, start) {
    None => path.length()
    Some(index) => index + 1
  }
}

///|
fn parse_unc_path(path : StringView, trailing_separator : Bool) -> WinPath? {
  guard path.length() <= 2 || !is_win_sep_at(path, 2) else { return None }
  let hostname_start = 2
  guard hostname_start < path.length() else { return None }
  match find_next_win_sep(path, hostname_start) {
    Some(hostname_end) => {
      let share_start = skip_win_separators(path, hostname_end)
      guard share_start < path.length() else { return None }
      let share_end = match find_next_win_sep(path, share_start) {
        Some(index) => index
        _ => path.length()
      }
      let root_end = share_end + (if share_end < path.length() { 1 } else { 0 })
      let component_start = {
        guard share_end < path.length() else { path.length() }
        skip_win_separators(path, share_end)
      }
      let components = parse_windows_components(
        path,
        component_start,
        allow_above_root=false,
      )
      Some({
        prefix: UNC(
          hostname=path[hostname_start:hostname_end].to_owned(),
          shared_folder=path[share_start:share_end].to_owned(),
        ),
        trailing_separator,
        components,
        root_end,
      })
    }
    _ => None
  }
}

///|
fn WinPath::parse(path : StringView) -> WinPath {
  let trailing_separator = path.length() > 0 &&
    is_win_sep_at(path, path.length() - 1)
  guard path.length() >= 2 && is_win_sep_at(path, 0) && is_win_sep_at(path, 1) else {
    return parse_drive_root_relative(path, trailing_separator)
  }
  match () {
    _ if parse_verbatim_prefixed_path(path, trailing_separator) is Some(parsed) =>
      parsed
    _ if parse_device_prefixed_path(path, trailing_separator) is Some(parsed) =>
      parsed
    _ if parse_unc_path(path, trailing_separator) is Some(parsed) => parsed
    _ => parse_drive_root_relative(path, trailing_separator)
  }
}

///|
fn parse_drive_root_relative(
  path : StringView,
  trailing_separator : Bool,
) -> WinPath {
  if start_with_win_drive(path) {
    let letter = path[0:1].get_char(0).unwrap()
    guard path.length() > 2 && is_win_sep_at(path, 2) else {
      let components = parse_windows_components(path, 2, allow_above_root=true)
      return {
        prefix: VolumeLetter(letter),
        trailing_separator,
        components,
        root_end: 2,
      }
    }
    let components = parse_windows_components(
      path,
      skip_win_separators(path, 2),
      allow_above_root=false,
    )
    return {
      prefix: VolumeLetterRoot(letter),
      trailing_separator,
      components,
      root_end: 3,
    }
  }
  guard path.length() > 0 && is_win_sep_at(path, 0) else {
    let components = parse_windows_components(path, 0, allow_above_root=true)
    return { prefix: None, trailing_separator, components, root_end: 0, }
  }
  let components = parse_windows_components(
    path,
    skip_win_separators(path, 0),
    allow_above_root=false,
  )
  { prefix: Root, trailing_separator, components, root_end: 1, }
}
