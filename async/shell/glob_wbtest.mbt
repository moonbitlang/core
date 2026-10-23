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
/// White-box tests for the path parser.
///
/// The parser takes the platform as an argument rather than reading it from
/// the build, so Windows syntax can be checked from a Unix machine — which is
/// the only way this gets tested at all, since every filesystem test in the
/// suite is skipped on Windows.
fn parsed(
  text : String,
  windows~ : Bool,
  escapes~ : Bool = true,
) -> (String, Array[String], Bool) {
  let (root, segments, directories_only) = parse_path(text, windows~, escapes~)
  let shown = match root {
    Relative => ""
    Rooted(root) => root
    // Shown with a trailing marker so the two drive forms are visibly
    // different in these expectations.
    DriveRelative(root) => root + "|drive-relative"
    Incomplete => "|incomplete"
  }
  (shown, segments, directories_only)
}

///|
test "unix paths" {
  @debug.debug_inspect(
    parsed("a/b.mbt", windows=false),
    content=(
      #|("", ["a", "b.mbt"], false)
    ),
  )
  @debug.debug_inspect(
    parsed("/a/b.mbt", windows=false),
    content=(
      #|("/", ["a", "b.mbt"], false)
    ),
  )
  // Redundant separators collapse; a trailing one asks for directories.
  @debug.debug_inspect(
    parsed("a//b", windows=false),
    content=(
      #|("", ["a", "b"], false)
    ),
  )
  @debug.debug_inspect(
    parsed("a/b/", windows=false),
    content=(
      #|("", ["a", "b"], true)
    ),
  )
  // A path that is only separators is its root, with nothing else asked for.
  @debug.debug_inspect(
    parsed("/", windows=false),
    content=(
      #|("/", [], false)
    ),
  )
  @debug.debug_inspect(
    parsed("//", windows=false),
    content=(
      #|("/", [], false)
    ),
  )
  // An empty path is not the root.
  @debug.debug_inspect(
    parsed("", windows=false),
    content=(
      #|("", [], false)
    ),
  )
  // On Unix a backslash escapes, and an escaped separator still separates.
  @debug.debug_inspect(
    parsed("a\\/b", windows=false),
    content=(
      #|("", ["a", "b"], false)
    ),
  )
  @debug.debug_inspect(
    parsed("\\/tmp/x", windows=false),
    content=(
      #|("/", ["tmp", "x"], false)
    ),
  )
  @debug.debug_inspect(
    parsed("a\\*b", windows=false),
    content=(
      #|("", ["a\\*b"], false)
    ),
  )
  // A candidate name carries no pattern syntax: its backslash is a character.
  @debug.debug_inspect(
    parsed("a\\b", windows=false, escapes=false),
    content=(
      #|("", ["a\\b"], false)
    ),
  )
}

///|
test "windows paths" {
  // A drive is a root, whichever separator follows it.
  @debug.debug_inspect(
    parsed("C:/Windows/*", windows=true),
    content=(
      #|("C:/", ["Windows", "*"], false)
    ),
  )
  @debug.debug_inspect(
    parsed("C:\\Windows\\*", windows=true),
    content=(
      #|("C:/", ["Windows", "*"], false)
    ),
  )
  @debug.debug_inspect(
    parsed("c:/x", windows=true),
    content=(
      #|("c:/", ["x"], false)
    ),
  )
  // A bare drive is relative to that drive's own working directory.
  @debug.debug_inspect(
    parsed("C:x/y", windows=true),
    content=(
      #|("C:|drive-relative", ["x", "y"], false)
    ),
  )
  // A share is part of the root, not a pair of segments.
  @debug.debug_inspect(
    parsed("\\\\server\\share\\dir\\*", windows=true),
    content=(
      #|("//server/share/", ["dir", "*"], false)
    ),
  )
  // Redundant separators collapse inside the root as well: this is the same
  // share, not an empty share name.
  @debug.debug_inspect(
    parsed("\\\\server\\\\share\\dir", windows=true),
    content=(
      #|("//server/share/", ["dir"], false)
    ),
  )
  @debug.debug_inspect(
    parsed("//server/share/dir", windows=true),
    content=(
      #|("//server/share/", ["dir"], false)
    ),
  )
  // A bare separator is rooted on the current drive.
  @debug.debug_inspect(
    parsed("\\Windows", windows=true),
    content=(
      #|("/", ["Windows"], false)
    ),
  )
  // Relative paths still work, and a backslash is a separator rather than an
  // escape, so it cannot smuggle a metacharacter through as a literal.
  @debug.debug_inspect(
    parsed("src\\*.mbt", windows=true),
    content=(
      #|("", ["src", "*.mbt"], false)
    ),
  )
  @debug.debug_inspect(
    parsed("a\\b\\", windows=true),
    content=(
      #|("", ["a", "b"], true)
    ),
  )
}

///|
test "incomplete windows roots are not roots" {
  // A share needs a server and a share name. Half of one names nowhere, and
  // must not fall through to the current drive's root as `/server`.
  @debug.debug_inspect(
    parsed("\\\\server", windows=true),
    content=(
      #|("|incomplete", [], false)
    ),
  )
  @debug.debug_inspect(
    parsed("\\\\server\\", windows=true),
    content=(
      #|("|incomplete", [], false)
    ),
  )
  // A drive letter is one letter followed by a colon, nothing else.
  @debug.debug_inspect(
    parsed("ab:/x", windows=true),
    content=(
      #|("", ["ab:", "x"], false)
    ),
  )
}

///|
/// Match a pattern's segments against a name's segments.
///
/// `**` is the only segment that can consume more than one, so it is the only
/// place alternatives arise. This walks them with a single backtrack point
/// rather than recursing, so a pattern with many `**` cannot blow up: each
/// mismatch resumes from the most recent `**` and advances it by one segment.
fn match_segments(pattern : Array[String], name : Array[String]) -> Bool {
  let mut pattern_index = 0
  let mut name_index = 0
  let mut star = -1
  let mut retry_at = 0
  for ;; {
    if name_index < name.length() &&
      pattern_index < pattern.length() &&
      pattern[pattern_index] != "**" &&
      match_segment(pattern[pattern_index], name[name_index]) {
      pattern_index = pattern_index + 1
      name_index = name_index + 1
    } else if pattern_index < pattern.length() && pattern[pattern_index] == "**" {
      star = pattern_index
      retry_at = name_index
      pattern_index = pattern_index + 1
    } else if star >= 0 &&
      retry_at < name.length() &&
      // `**` never reaches a hidden segment either.
      !is_hidden(name[retry_at]) {
      retry_at = retry_at + 1
      name_index = retry_at
      pattern_index = star + 1
    } else {
      break
    }
    if name_index >= name.length() && pattern_index >= pattern.length() {
      return true
    }
  }
  // Trailing `**` may match nothing at all.
  while pattern_index < pattern.length() && pattern[pattern_index] == "**" {
    pattern_index = pattern_index + 1
  }
  pattern_index >= pattern.length() && name_index >= name.length()
}

///|
/// Whether two roots name the same place.
///
/// Windows does not distinguish the case of a drive letter or a share name,
/// so `C:/` and `c:/` are one root there. An incomplete root, such as
/// `\\server` with no share, names no place at all, so it is the same as
/// nothing — not even another incomplete root.
fn same_root(left : Root, right : Root) -> Bool {
  match (left, right) {
    (Relative, Relative) => true
    (Incomplete, _) | (_, Incomplete) => false
    (Rooted(left), Rooted(right))
    | (DriveRelative(left), DriveRelative(right)) =>
      if native_windows {
        // Compared code unit by code unit: only ASCII case is folded, and a
        // surrogate half compares exactly, so a share name containing a
        // non-BMP character is ordinary data rather than a crash.
        left.length() == right.length() &&
        (for index in 0..<left.length() {
          if !same_code_unit(left[index], right[index]) {
            break false
          }
        } nobreak {
          true
        })
      } else {
        left == right
      }
    _ => false
  }
}

///|
/// Whether two UTF-16 code units are the same root character, folding only
/// ASCII case.
fn same_code_unit(left : UInt16, right : UInt16) -> Bool {
  left == right || flip_case_unit(left) == right
}

///|
/// Swap the case of an ASCII letter code unit, leaving everything else alone.
fn flip_case_unit(unit : UInt16) -> UInt16 {
  let code = unit.to_int()
  if code >= 'a' && code <= 'z' {
    (code - 32).to_uint16()
  } else if code >= 'A' && code <= 'Z' {
    (code + 32).to_uint16()
  } else {
    unit
  }
}

///|
/// Whether `name` matches the glob `pattern`, comparing strings only.
///
/// This is `glob`'s pattern language as a pure predicate, kept for the
/// matcher's own tests. It is deliberately not public: for filtering names
/// already in hand, the language's `str =~ regex` is the more general tool,
/// and a filesystem-independent glob predicate would belong in a dedicated
/// pattern package rather than a process one.
fn glob_matches(pattern : String, name : String) -> Bool {
  let (pattern_root, pattern_segments, pattern_directory) = parse_path(
    pattern,
    windows=native_windows,
    escapes=!native_windows,
  )
  let (name_root, name_segments, name_directory) = parse_path(
    name,
    windows=native_windows,
    escapes=false,
  )
  // A trailing separator is part of what a path says: `a/` asks for a
  // directory and `a` does not, so the two do not match each other.
  same_root(pattern_root, name_root) &&
  pattern_directory == name_directory &&
  match_segments(pattern_segments, name_segments)
}

///|
test "the matcher is a shell's filename language and nothing more" {
  // `*` and `?` stay inside one segment.
  assert_true(glob_matches("*.mbt", "cmd.mbt"))
  assert_false(glob_matches("*.mbt", "cmd.mbti"))
  assert_false(glob_matches("*.mbt", "src/cmd.mbt"))
  assert_true(glob_matches("src/*.mbt", "src/cmd.mbt"))
  assert_true(glob_matches("c?d.mbt", "cmd.mbt"))
  assert_false(glob_matches("c?d.mbt", "cd.mbt"))
  assert_false(glob_matches("?", "/"))
  // Character classes, ranges, and negation.
  assert_true(glob_matches("[abc].mbt", "b.mbt"))
  assert_false(glob_matches("[abc].mbt", "d.mbt"))
  assert_true(glob_matches("[a-z]*.mbt", "cmd.mbt"))
  // Windows filesystems do not distinguish case, so this only holds elsewhere.
  if !native_windows {
    assert_false(glob_matches("[a-z]*.mbt", "Cmd.mbt"))
  }
  assert_true(glob_matches("[!0-9]*", "cmd"))
  assert_false(glob_matches("[!0-9]*", "9cmd"))
  // A negated class must stay negated: folding case around the negation
  // instead of inside it would let every letter through, on either platform.
  assert_false(glob_matches("[!a-z]", "q"))
  assert_true(glob_matches("[!a-z]", "4"))
  // `Q` is outside `a-z` only where case is significant. Windows CI checks the
  // other half of this.
  @test.assert_eq(glob_matches("[!a-z]", "Q"), !native_windows)
  assert_true(glob_matches("[^0-9]*", "cmd"))
  // A `]` first in the class is a member; an unclosed `[` is a literal; a
  // reversed range matches nothing.
  assert_true(glob_matches("[]a]", "]"))
  assert_true(glob_matches("[abc", "[abc"))
  assert_false(glob_matches("[z-a]", "b"))
  // A backslash makes the next character literal — on Unix. On Windows it is
  // the path separator, so `\*` is a rooted pattern there rather than an
  // escaped one, and none of this applies.
  if !native_windows {
    assert_true(glob_matches("\\*", "*"))
    assert_false(glob_matches("\\*", "anything"))
    assert_true(glob_matches("a\\?c", "a?c"))
    assert_false(glob_matches("a\\?c", "abc"))
    assert_true(glob_matches("\\[abc]", "[abc]"))
  } else {
    // A backslash separates, so this names a root and one segment.
    assert_true(glob_matches("\\*", "/anything"))
    // An unfinished share prefix names no directory at all, so it matches
    // nothing — not even itself.
    assert_false(glob_matches("\\\\server", "\\\\server"))
    assert_false(glob_matches("\\\\server", "\\\\other"))
  }
  // Everything else is literal, including shell operators.
  assert_true(glob_matches("a b.mbt", "a b.mbt"))
  assert_true(glob_matches("$(echo x)", "$(echo x)"))
}

///|
test "globstar spans segments, including none, and skips hidden ones" {
  assert_true(glob_matches("src/**/*.mbt", "src/cmd.mbt"))
  assert_true(glob_matches("src/**/*.mbt", "src/a/b/cmd.mbt"))
  assert_true(glob_matches("**", "a/b/c"))
  assert_true(glob_matches("**", "file"))
  assert_true(glob_matches("**/x", "x"))
  assert_true(glob_matches("**/x", "a/b/x"))
  assert_false(glob_matches("src/**/*.mbt", "other/cmd.mbt"))
  // Adjacent globstars are not an error and do not change the meaning.
  assert_true(glob_matches("**/**/x", "a/x"))
  assert_true(glob_matches("**/**/x", "x"))
  // Hidden segments are out of reach of `**`, as they are of `*`.
  assert_false(glob_matches("**", ".git"))
  assert_false(glob_matches("**/*.mbt", ".git/cmd.mbt"))
  assert_true(glob_matches(".*/**", ".git/objects"))
}

///|
test "a pathological pattern does not take exponential time" {
  // The classic blow-up for a naive matcher: many stars separated by a
  // character that keeps forcing it to try another split.
  let pattern = "*a*a*a*a*a*a*a*a*a*a*a*a*b"
  let name = "a".repeat(200)
  assert_false(glob_matches(pattern, name))
  assert_true(glob_matches(pattern, name + "b"))
}

///|
test "escapes survive splitting and character classes" {
  // Escapes are a Unix-only idea: a backslash separates on Windows, so there
  // is nothing there to escape with.
  if !native_windows {
    // An escaped separator is still a separator, as a shell resolves it.
    assert_true(glob_matches("cmd\\/smoke/main.mbt", "cmd/smoke/main.mbt"))
    // Inside a class, a backslash makes the next character a plain member, so
    // this is the three characters and not the range `a` to `c`.
    assert_true(glob_matches("[a\\-c]", "-"))
    assert_true(glob_matches("[a\\-c]", "a"))
    assert_true(glob_matches("[a\\-c]", "c"))
    assert_false(glob_matches("[a\\-c]", "b"))
    assert_true(glob_matches("[\\]]", "]"))
  }
  // An unescaped range behaves as one everywhere.
  assert_true(glob_matches("[a-c]", "b"))
}

///|
test "a candidate is a path, not a pattern" {
  if !native_windows {
    // The backslash in the name is one of its characters, so this name has a
    // single component called `dir\file` and does not match two components.
    assert_false(glob_matches("dir/file", "dir\\/file"))
    assert_true(glob_matches("dir\\/file", "dir/file"))
    // Escaping an endpoint leaves the range intact; escaping the `-` does not.
    assert_true(glob_matches("[\\a-c]", "b"))
    assert_false(glob_matches("[a\\-c]", "b"))
  } else {
    // On Windows the backslash separates, so both spellings are the same path.
    assert_true(glob_matches("dir/file", "dir\\file"))
  }
}

///|
test "a trailing separator is part of what a path says" {
  // `a/` asks for a directory and `a` does not, so neither matches the other.
  assert_false(glob_matches("*/", "file"))
  assert_false(glob_matches("a", "a/"))
  assert_true(glob_matches("*/", "dir/"))
  assert_true(glob_matches("a/", "a/"))
}
