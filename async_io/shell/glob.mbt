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
/// One element of a single path segment's pattern.
priv enum Item {
  Literal(Char)
  Any
  Star
  Class(Array[(Char, Char)], Bool)
}

///|
/// Where a path starts.
///
/// Keeping the root apart from the segments is what lets one representation
/// serve both platforms: everything after the root is just names, and only the
/// root knows whether it came from `/`, a drive, or a share.
priv enum Root {
  Relative
  Rooted(String)
  /// A path that names a root it does not finish, such as `\\server` with no
  /// share. It denotes no directory, so it matches nothing rather than being
  /// quietly reinterpreted as some other root.
  Incomplete
  /// `C:` with no separator: relative to that drive's own working directory,
  /// which is a different place from `C:/`. Its first name attaches with no
  /// separator between.
  DriveRelative(String)
}

///|
/// True when running on Windows.
///
/// Path syntax is the one place the two platforms genuinely disagree, so the
/// parser takes it as a parameter and the public entry points pass this. The
/// platform is read from the runtime rather than the build, because a `wasm`
/// binary runs unchanged on every host.
let native_windows : Bool = @env_util.platform is Windows

///|
/// A parsed path: where it starts, its names, and whether it ended in a
/// separator.
///
/// `windows` selects the platform's syntax rather than the host's, so the
/// parser is testable for both from either. `escapes` is false for a candidate
/// name, which carries no pattern syntax at all — a backslash in a name is one
/// of its characters.
fn parse_path(
  text : String,
  windows~ : Bool,
  escapes~ : Bool,
) -> (Root, Array[String], Bool) {
  let (root, rest) = if windows && starts_incomplete_root(text) {
    (Incomplete, "")
  } else if windows {
    match windows_root(text) {
      Some((root, rest)) =>
        if root.has_suffix("\u{0000}") {
          (DriveRelative(root[:root.length() - 1].to_owned()), rest)
        } else {
          (Rooted(root), rest)
        }
      None => (Relative, text)
    }
  } else {
    (Relative, text)
  }
  let raw = split_path(rest, windows~, escapes~)
  // On Unix a leading separator is what makes a path absolute, including an
  // escaped one, since the escape is gone by the time the name is resolved.
  let root = match root {
    Rooted(_) | DriveRelative(_) | Incomplete => root
    Relative =>
      if !text.is_empty() && raw is [first, ..] && first.is_empty() {
        Rooted("/")
      } else {
        Relative
      }
  }
  let only_separators = raw.iter().all(segment => segment.is_empty())
  // A trailing separator asks for directories only. A path that is nothing but
  // separators is just its root, with no such request attached.
  let directories_only = !only_separators &&
    raw.length() > 1 &&
    raw[raw.length() - 1].is_empty()
  let segments = []
  for segment in raw {
    if !segment.is_empty() {
      segments.push(segment)
    }
  }
  (root, segments, directories_only)
}

///|
/// Whether the text opens a share that it never completes.
///
/// `\\server` names no directory. Falling through would let the leading
/// separators be read as an ordinary root and turn it into `/server`, which is
/// somewhere else entirely.
fn starts_incomplete_root(text : String) -> Bool {
  let chars = collect_chars(text)
  fn separator(index : Int32) -> Bool {
    index < chars.length() && (chars[index] == '/' || chars[index] == '\\')
  }

  if !(separator(0) && separator(1)) {
    return false
  }
  windows_root(text) is None
}

///|
/// Recognise a Windows root: a drive, a drive-relative prefix, a UNC share, or
/// a bare separator. Returns the root and the remainder.
fn windows_root(text : String) -> (String, String)? {
  let chars = collect_chars(text)
  fn separator(index : Int32) -> Bool {
    index < chars.length() && (chars[index] == '/' || chars[index] == '\\')
  }

  fn from(index : Int32) -> String {
    let rest = StringBuilder()
    for position in index..<chars.length() {
      rest.write_char(chars[position])
    }
    rest.to_string()
  }

  // `\\server\share` — the share is part of the root, not a segment.
  if separator(0) && separator(1) {
    let mut index = 2
    let server = StringBuilder()
    while index < chars.length() && !separator(index) {
      server.write_char(chars[index])
      index = index + 1
    }
    // Redundant separators collapse inside a root too: `\\server\\share` is
    // the same share as `\\server\share`, not an empty share name.
    while separator(index) {
      index = index + 1
    }
    let share = StringBuilder()
    while index < chars.length() && !separator(index) {
      share.write_char(chars[index])
      index = index + 1
    }
    // A share needs both halves. `\\server` alone names no directory, so it is
    // not a root; treating it as one would invent `//server//`.
    if !server.to_string().is_empty() && !share.to_string().is_empty() {
      return Some(("//\{server}/\{share}/", from(index)))
    }
    return None
  }
  // `C:/...` is rooted on that drive; a bare `C:` is relative to the drive's
  // own working directory, which only the operating system knows.
  if chars.length() >= 2 &&
    chars[1] == ':' &&
    (
      (chars[0] >= 'A' && chars[0] <= 'Z') ||
      (chars[0] >= 'a' && chars[0] <= 'z')
    ) {
    if separator(2) {
      return Some(("\{chars[0]}:/", from(3)))
    }
    // Marked with a NUL, which cannot occur in a path, so the caller can tell
    // the two drive forms apart.
    return Some(("\{chars[0]}:\u{0000}", from(2)))
  }
  if separator(0) {
    return Some(("/", from(1)))
  }
  None
}

///|
/// Split on separators, leaving escapes intact for the segment parser.
///
/// `/` separates on both platforms. A backslash separates on Windows, where it
/// is the native separator, and escapes on Unix, where it is not. An escaped
/// separator is still a separator: a shell resolves `a\/b` as the path `a/b`,
/// because the escape is gone by the time the name is looked up.
fn split_path(path : String, windows~ : Bool, escapes~ : Bool) -> Array[String] {
  let chars = collect_chars(path)
  let segments = []
  let current = StringBuilder()
  let mut index = 0
  while index < chars.length() {
    let char = chars[index]
    if char == '\\' && windows {
      segments.push(current.to_string())
      current.reset()
      index = index + 1
    } else if char == '\\' && escapes && index + 1 < chars.length() {
      if chars[index + 1] == '/' {
        segments.push(current.to_string())
        current.reset()
      } else {
        // Keep the escape so the segment parser can resolve it.
        current.write_char('\\')
        current.write_char(chars[index + 1])
      }
      index = index + 2
    } else if char == '/' {
      segments.push(current.to_string())
      current.reset()
      index = index + 1
    } else {
      current.write_char(char)
      index = index + 1
    }
  }
  segments.push(current.to_string())
  segments
}

///|
/// Whether a directory entry is hidden from `*` and `**`.
fn is_hidden(name : String) -> Bool {
  name.has_prefix(".")
}

///|
/// Match one path segment, where `*` and `?` cannot cross a `/`.
fn match_segment(pattern : String, name : String) -> Bool {
  let items = parse_segment(pattern)
  // A leading `.` is only ever matched literally, so `*` skips hidden entries.
  if is_hidden(name) && !(items is [Literal('.'), ..]) {
    return false
  }
  match_items(items, collect_chars(name))
}

///|
fn collect_chars(text : String) -> Array[Char] {
  let chars = []
  for char in text {
    chars.push(char)
  }
  chars
}

///|
/// Parse one segment into its elements, resolving escapes and classes once.
fn parse_segment(pattern : String) -> Array[Item] {
  let chars = collect_chars(pattern)
  let items = []
  let mut index = 0
  while index < chars.length() {
    match chars[index] {
      '\\' =>
        if index + 1 < chars.length() {
          items.push(Literal(chars[index + 1]))
          index = index + 2
        } else {
          // A trailing backslash is itself.
          items.push(Literal('\\'))
          index = index + 1
        }
      '?' => {
        items.push(Any)
        index = index + 1
      }
      '*' => {
        // Collapse runs, so `***` costs no more than `*`.
        if !(items is [.., Star]) {
          items.push(Star)
        }
        index = index + 1
      }
      '[' =>
        match parse_class(chars, index + 1) {
          Some((members, negated, next)) => {
            items.push(Class(members, negated))
            index = next
          }
          // An unterminated `[` is a literal, as a shell treats it.
          None => {
            items.push(Literal('['))
            index = index + 1
          }
        }
      char => {
        items.push(Literal(char))
        index = index + 1
      }
    }
  }
  items
}

///|
/// Read a `[...]` class starting just past the `[`, returning its members,
/// whether it is negated, and the index after the closing `]`.
fn parse_class(
  chars : Array[Char],
  start : Int32,
) -> (Array[(Char, Char)], Bool, Int32)? {
  let mut index = start
  let negated = index < chars.length() &&
    (chars[index] == '!' || chars[index] == '^')
  if negated {
    index = index + 1
  }
  let members = []
  // A `]` in the first position is a literal member, not the terminator.
  if index < chars.length() && chars[index] == ']' {
    members.push((']', ']'))
    index = index + 1
  }
  while index < chars.length() {
    if chars[index] == ']' {
      return Some((members, negated, index + 1))
    }
    // A backslash inside a class makes the next character a plain member, so
    // `[a\-c]` is the three characters and not the range `a` to `c`.
    let (low, after_low) = if chars[index] == '\\' && index + 1 < chars.length() {
      (chars[index + 1], index + 2)
    } else {
      (chars[index], index + 1)
    }
    // Only an escaped `-` is prevented from forming a range; escaping an
    // endpoint, as in `[\a-c]`, leaves the range intact, as a shell has it.
    if after_low + 1 < chars.length() &&
      chars[after_low] == '-' &&
      chars[after_low + 1] != ']' {
      let (high, after_high) = if chars[after_low + 1] == '\\' &&
        after_low + 2 < chars.length() {
        (chars[after_low + 2], after_low + 3)
      } else {
        (chars[after_low + 1], after_low + 2)
      }
      // A reversed range such as `[z-a]` matches nothing, as in a shell.
      if low <= high {
        members.push((low, high))
      }
      index = after_high
    } else {
      members.push((low, low))
      index = after_low
    }
  }
  None
}

///|
/// Match a parsed segment against a name.
///
/// Iterative with one backtrack point, so `*a*a*…` against a long name stays
/// quadratic in the worst case rather than exponential, and nothing recurses.
fn match_items(items : Array[Item], name : Array[Char]) -> Bool {
  let mut item_index = 0
  let mut name_index = 0
  let mut star = -1
  let mut retry_at = 0
  while name_index < name.length() {
    if item_index < items.length() &&
      item_matches(items[item_index], name[name_index]) {
      item_index = item_index + 1
      name_index = name_index + 1
    } else if item_index < items.length() && items[item_index] is Star {
      star = item_index
      retry_at = name_index
      item_index = item_index + 1
    } else if star >= 0 {
      retry_at = retry_at + 1
      name_index = retry_at
      item_index = star + 1
    } else {
      return false
    }
  }
  while item_index < items.length() && items[item_index] is Star {
    item_index = item_index + 1
  }
  item_index >= items.length()
}

///|
fn item_matches(item : Item, candidate : Char) -> Bool {
  match item {
    Literal(char) => same_char(char, candidate)
    Any => true
    Star => false
    // Negation applies once, to the answer: folding case around it would make
    // `[!a-z]` match every letter, since one casing is always outside a range.
    Class(members, negated) => in_members(members, candidate) != negated
  }
}

///|
/// Whether two characters are the same name character.
///
/// Windows filesystems do not distinguish case, so neither does matching there.
/// Only ASCII is folded: the rest of Unicode needs real case folding, which
/// this does not attempt.
fn same_char(left : Char, right : Char) -> Bool {
  left == right || (native_windows && flip_case(left) == right)
}

///|
fn in_members(members : Array[(Char, Char)], candidate : Char) -> Bool {
  if in_ranges(members, candidate) {
    return true
  }
  if native_windows {
    let flipped = flip_case(candidate)
    if flipped != candidate && in_ranges(members, flipped) {
      return true
    }
  }
  false
}

///|
fn in_ranges(members : Array[(Char, Char)], candidate : Char) -> Bool {
  for range in members {
    if candidate >= range.0 && candidate <= range.1 {
      return true
    }
  }
  false
}

///|
/// Expand a glob pattern against the filesystem.
///
/// Returns the paths that exist and match, in code-unit order and without
/// duplicates, spelled from the same root the pattern used: relative to `cwd`
/// for a relative pattern, and from `/`, a drive, or a share for a rooted one.
/// Redundant separators collapse, and a trailing separator is kept and
/// restricts the result to directories, as a shell does. A pattern that matches
/// nothing returns an empty array rather than the pattern itself, which is the
/// one place this deliberately differs from a shell.
///
/// Hidden entries are reached only by a pattern with a literal leading `.`, and
/// `.` and `..` are never produced by a wildcard — though a pattern may name
/// them, so `../*` reaches the parent. Confining an expansion to a subtree is
/// the sandbox policy's job, not this function's. A pattern or `cwd`
/// containing an embedded NUL raises, exactly as `Cmd` rejects one in process
/// metadata: no filename can contain it, and a C-string filesystem API would
/// otherwise see a truncated path.
///
/// Symbolic links to directories are not descended by `**`, which is what keeps
/// a link pointing at an ancestor from looping forever; a component named
/// explicitly resolves links normally. A directory that cannot be read is
/// skipped rather than failing the whole expansion — but cancellation is never
/// mistaken for an unreadable directory, so a cancelled expansion stops instead
/// of returning a partial result as though it were complete.
///
/// The pattern language is the one a shell uses for filenames, and nothing
/// else: `*` matches any run of characters within one path segment, `?`
/// matches one such character, `[abc]` and `[a-z]` match a character from a
/// set, `[!abc]` and `[^abc]` match one outside it, and `**` as a whole
/// segment matches any number of segments including none. Everything else is
/// literal already. On Unix a backslash makes the next character literal; on
/// Windows it is the path separator instead, and matching folds case the way
/// the filesystem does — ASCII only, as full Unicode case folding is
/// deliberately out of scope.
///
/// # Example
/// ```mbt check
/// async test {
///   let sources = @shell.glob("*.mbt", cwd="async_io/shell")
///   assert_true(sources.contains("glob.mbt"))
///   assert_true(sources.contains("execute.mbt"))
/// }
/// ```
pub async fn glob(pattern : String, cwd~ : String = ".") -> Array[String] {
  // No filename can contain a NUL, and a C-string filesystem API would see a
  // truncated path — matching something the caller did not spell. Reject it
  // up front, exactly as `Cmd` does for process metadata.
  if pattern.contains("\u{0000}") {
    raise ShellError::NulByte("glob pattern")
  }
  if cwd.contains("\u{0000}") {
    raise ShellError::NulByte("glob working directory")
  }
  let (root, segments, directories_only) = parse_path(
    pattern,
    windows=native_windows,
    escapes=!native_windows,
  )
  // A drive-relative root attaches its first name directly: `C:` and `x`
  // together are `C:x`, which is not the same place as `C:/x`.
  let (base, prefix, drive_relative) = match root {
    Rooted(root) => (root, root, false)
    DriveRelative(root) => (root, root, true)
    Relative => (cwd, "", false)
    // Nothing is under a root that was never finished.
    Incomplete => return []
  }
  let found = []
  let seen = Map([])
  let visited = Map([])
  expand(
    base, prefix, segments, 0, directories_only, drive_relative, found, seen, visited,
  )
  checkpoint()
  found.sort_by(compare_code_units)
  found
}

///|
/// Compare two strings by code unit, then by length.
///
/// `Array::sort` on strings orders by length first, which would list
/// "plain.txt" before "od d*name.txt". A shell does not.
fn compare_code_units(left : String, right : String) -> Int32 {
  let shared = if left.length() < right.length() {
    left.length()
  } else {
    right.length()
  }
  for index in 0..<shared {
    if left[index] != right[index] {
      return if left[index] < right[index] { -1 } else { 1 }
    }
  }
  left.length() - right.length()
}

///|
/// Walk one pattern segment at a time, reading only the directories a segment
/// actually requires.
///
/// `base` is where to look on disk and `prefix` is how to spell what is found.
/// They differ whenever `cwd` is not the process's own directory, so every
/// filesystem call uses `base` and every recorded result `prefix`.
async fn expand(
  base : String,
  prefix : String,
  segments : Array[String],
  index : Int32,
  directories_only : Bool,
  attach_directly : Bool,
  found : Array[String],
  seen : Map[String, Unit],
  visited : Map[String, Unit],
) -> Unit {
  // Cancellation has to stop the walk rather than be read as one more
  // unreadable directory. Checking the flag is not enough on its own, because
  // a filesystem call can also return normally while the run is cancelled.
  checkpoint()
  // Two `**` in one pattern can reach the same directory at the same point in
  // the pattern by many different routes. Without this, `**/**/x` on a deep
  // tree explores every way of splitting the path between the globstars, which
  // is combinatorial even when nothing matches. A state is a place in the tree
  // paired with a place in the pattern; visiting one twice can only repeat work.
  let state = "\{index}\u{0000}\{base}"
  if visited.contains(state) {
    return
  }
  visited[state] = ()
  if index >= segments.length() {
    if !prefix.is_empty() &&
      !seen.contains(prefix) &&
      entry_exists(base) &&
      (!directories_only || is_directory(base)) {
      seen[prefix] = ()
      found.push(if directories_only { prefix + "/" } else { prefix })
    }
    return
  }
  let segment = segments[index]
  if segment == "**" {
    // `**` matches no segments at all, then every visible entry in turn.
    expand(
      base,
      prefix,
      segments,
      index + 1,
      directories_only,
      attach_directly,
      found,
      seen,
      visited,
    )
    for entry in read_directory(base) {
      // A large flat directory is a long stretch of pure computation, so the
      // check belongs in the loop and not only between states.
      checkpoint()
      if !is_hidden(entry) {
        let child_base = attach(base, entry, attach_directly)
        let child_prefix = attach(prefix, entry, attach_directly)
        if is_real_directory(child_base) {
          expand(
            child_base, child_prefix, segments, index, directories_only, false, found,
            seen, visited,
          )
        } else if index + 1 == segments.length() {
          // A trailing `**` may also end on something that is not a directory,
          // so it yields ordinary files too.
          expand(
            child_base,
            child_prefix,
            segments,
            index + 1,
            directories_only,
            false,
            found,
            seen,
            visited,
          )
        }
      }
    }
  } else if is_literal_segment(segment) {
    // Nothing to search: descend directly and let the final check decide.
    let literal = unescape(segment)
    let child = attach(base, literal, attach_directly)
    if index + 1 == segments.length() || is_directory(child) {
      expand(
        child,
        attach(prefix, literal, attach_directly),
        segments,
        index + 1,
        directories_only,
        false,
        found,
        seen,
        visited,
      )
    }
  } else {
    for entry in read_directory(base) {
      checkpoint()
      if match_segment(segment, entry) {
        let child = attach(base, entry, attach_directly)
        if index + 1 == segments.length() || is_directory(child) {
          expand(
            child,
            attach(prefix, entry, attach_directly),
            segments,
            index + 1,
            directories_only,
            false,
            found,
            seen,
            visited,
          )
        }
      }
    }
  }
}

///|
/// Stop the walk if the run has been cancelled.
///
/// `pause` is a suspension point, so a cancelled coroutine raises there rather
/// than returning. That is how cancellation is surfaced without naming the
/// runtime's private error type.
async fn checkpoint() -> Unit {
  if @async_io.is_being_cancelled() {
    @async_io.pause()
  }
}

///|
/// Join a name onto a path, or attach it directly for a drive-relative root.
fn attach(prefix : String, entry : String, directly : Bool) -> String {
  if directly {
    prefix + entry
  } else {
    join(prefix, entry)
  }
}

///|
fn join(prefix : String, entry : String) -> String {
  if prefix.is_empty() || prefix.has_suffix("/") {
    prefix + entry
  } else {
    prefix + "/" + entry
  }
}

///|
/// Whether a segment has no metacharacters, so it needs no directory listing.
fn is_literal_segment(segment : String) -> Bool {
  for item in parse_segment(segment) {
    if !(item is Literal(_)) {
      return false
    }
  }
  true
}

///|
/// Resolve a literal segment's escapes to the name it actually denotes.
fn unescape(segment : String) -> String {
  let text = StringBuilder()
  for item in parse_segment(segment) {
    if item is Literal(char) {
      text.write_char(char)
    }
  }
  text.to_string()
}

///|
/// List a directory, treating one that cannot be read as empty.
///
/// `.` and `..` are not produced: a wildcard should match names, not the two
/// entries every directory has. A pattern may still name them.
async fn read_directory(path : String) -> Array[String] {
  @fs.readdir(path, include_hidden=true) catch {
    _ => []
  }
}

///|
/// Whether a directory entry exists, without resolving a symbolic link.
///
/// A glob matches the entry a directory holds, so a dangling link still
/// matches, and a link pointing at itself must not raise `ELOOP` here.
async fn entry_exists(path : String) -> Bool {
  try @fs.kind(path, follow_symlink=false) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
/// Whether the path is a directory and not a symbolic link to one.
///
/// Only `**` uses this. Declining to descend links is what stops a link
/// pointing at an ancestor from making a recursive walk run forever, and it is
/// what a shell's globstar does.
async fn is_real_directory(path : String) -> Bool {
  (@fs.kind(path, follow_symlink=false) is Directory) catch {
    _ => false
  }
}

///|
/// Whether the path is a directory, resolving a symbolic link to one.
///
/// This is what an explicitly named or wildcard-matched component uses: naming
/// `/var/log/*` has to work where `/var` is a link, exactly as it does in a
/// shell.
async fn is_directory(path : String) -> Bool {
  (@fs.kind(path) is Directory) catch {
    _ => false
  }
}

///|
/// Swap the case of an ASCII letter, leaving everything else alone.
fn flip_case(candidate : Char) -> Char {
  if candidate >= 'a' && candidate <= 'z' {
    (candidate.to_int() - 32).unsafe_to_char()
  } else if candidate >= 'A' && candidate <= 'Z' {
    (candidate.to_int() + 32).unsafe_to_char()
  } else {
    candidate
  }
}
