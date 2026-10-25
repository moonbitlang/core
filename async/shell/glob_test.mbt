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
/// Read from the runtime, not the build: glob's platform behaviour is a
/// runtime question, because a `wasm` binary runs unchanged on every host.
fn not_windows() -> Bool {
  !(@env_util.platform is Windows)
}

///|
/// Build a tree of real files and real directories under `root`.
///
/// Note the shape: creating `a.mbt` as a directory by accident would let a
/// later existence check pass, so files are created as files and only their
/// parents as directories.
async fn make_tree(root : String, files : Array[String]) -> Unit {
  for file in files {
    if file.rev_find("/") is Some(index) {
      let directory = "\{root}/\{file[:index].to_owned()}"
      if !@fs.exists(directory) {
        @fs.mkdir(directory, recursive=true)
      }
    }
    @fs.write_binary("\{root}/\{file}", b"")
  }
}

///|
async test "expansion finds what is on disk and nothing else" {
  let root = @fs.tmpdir(prefix="shell-glob")
  make_tree(root, [
    "a.mbt", "b.mbt", "c.txt", ".hidden.mbt", "src/d.mbt", "src/e.txt", "src/deep/f.mbt",
  ])
  // One segment, and hidden entries stay hidden.
  assert_eq(@shell.glob("*.mbt", cwd=root), ["a.mbt", "b.mbt"])
  assert_eq(@shell.glob(".*.mbt", cwd=root), [".hidden.mbt"])
  // A literal segment needs no search.
  assert_eq(@shell.glob("src/d.mbt", cwd=root), ["src/d.mbt"])
  assert_eq(@shell.glob("src/*.txt", cwd=root), ["src/e.txt"])
  // `**` spans any number of directories, including none.
  assert_eq(@shell.glob("**/*.mbt", cwd=root), [
    "a.mbt", "b.mbt", "src/d.mbt", "src/deep/f.mbt",
  ])
  // A terminal `**` yields files as well as directories, and never repeats a
  // path even when two globstars could both reach it.
  assert_eq(@shell.glob("**", cwd=root), [
    "a.mbt", "b.mbt", "c.txt", "src", "src/d.mbt", "src/deep", "src/deep/f.mbt",
    "src/e.txt",
  ])
  assert_eq(@shell.glob("**/**/f.mbt", cwd=root), ["src/deep/f.mbt"])
  // A trailing slash asks for directories only, and is kept.
  assert_eq(@shell.glob("*/", cwd=root), ["src/"])
  // Nothing matched is an empty result, not the pattern.
  assert_eq(@shell.glob("*.rs", cwd=root), [])
  assert_eq(@shell.glob("nope/*.mbt", cwd=root), [])
  // An absolute pattern is spelled from its own root. The result uses `/`
  // between segments on both platforms, so normalise the fixture root for
  // the comparison.
  let spelled_root = root.replace_all(old="\\", new="/")
  assert_eq(@shell.glob("\{spelled_root}/*.txt"), ["\{spelled_root}/c.txt"])
  @fs.rmdir(root, recursive=true)
}

///|
async test "matches come back in code-unit order, not by length" {
  let root = @fs.tmpdir(prefix="shell-glob-order")
  // No case differences here: macOS is case-insensitive by default, so
  // "B.txt" and "b.txt" would be one file there and two on Linux.
  make_tree(root, ["b.txt", "ab.txt", "aaa.txt"])
  // `Array::sort` on strings orders by length first, which would have put
  // "b.txt" first. A shell does not, and neither does this.
  assert_eq(@shell.glob("*.txt", cwd=root), ["aaa.txt", "ab.txt", "b.txt"])
  @fs.rmdir(root, recursive=true)
}

///|
async test "a name with spaces expands as one literal path" {
  let root = @fs.tmpdir(prefix="shell-glob-space")
  make_tree(root, ["od d.txt", "plain.txt"])
  assert_eq(@shell.glob("*.txt", cwd=root), ["od d.txt", "plain.txt"])
  assert_eq(@shell.glob("od *", cwd=root), ["od d.txt"])
  @fs.rmdir(root, recursive=true)
}

///|
async test "adjacent globstars do not explode on a deep tree" {
  let root = @fs.tmpdir(prefix="shell-glob-deep")
  // Twenty nested directories. Exploring every way of splitting this path
  // between the globstars would be combinatorial; visiting each place in the
  // tree once per place in the pattern is not.
  let deep = "a/a/a/a/a/a/a/a/a/a/a/a/a/a/a/a/a/a/a/a"
  make_tree(root, ["\{deep}/target.mbt"])
  assert_eq(@shell.glob("**/**/**/**/target.mbt", cwd=root), [
    "\{deep}/target.mbt",
  ])
  // The same pattern for a name that is not there has to finish too.
  assert_eq(@shell.glob("**/**/**/**/missing.mbt", cwd=root), [])
  @fs.rmdir(root, recursive=true)
}

///|
async test "a symlink loop does not trap the walker" {
  // Symbolic links are a Unix fixture: creating one on Windows needs a
  // privilege ordinary CI runners do not hold.
  if not_windows() {
    let root = @fs.tmpdir(prefix="shell-glob-loop")
    make_tree(root, ["deep/inner/target.mbt"])
    // A link pointing back at an ancestor: following it would never terminate.
    @fs.symlink(target=root, "\{root}/deep/loop")
    assert_eq(@shell.glob("**/*.mbt", cwd=root), ["deep/inner/target.mbt"])
    @fs.rmdir(root, recursive=true)
  }
}

///|
async test "a dangling or self-referential link still matches" {
  if not_windows() {
    let root = @fs.tmpdir(prefix="shell-glob-link")
    make_tree(root, ["real.txt"])
    @fs.symlink(target="nowhere.txt", "\{root}/dangling.txt")
    @fs.symlink(target="self.txt", "\{root}/self.txt")
    // A glob matches the directory entry, so a link that resolves to nothing
    // is still a match, and one that points at itself must not raise `ELOOP`.
    assert_eq(@shell.glob("*.txt", cwd=root), [
      "dangling.txt", "real.txt", "self.txt",
    ])
    @fs.rmdir(root, recursive=true)
  }
}

///|
async test "windows expansion is case-insensitive and accepts backslashes" {
  if !not_windows() {
    let root = @fs.tmpdir(prefix="shell-glob-win")
    make_tree(root, ["c.txt", "src/d.mbt"])
    // The filesystem does not distinguish case, so neither does matching.
    assert_eq(@shell.glob("*.TXT", cwd=root), ["c.txt"])
    // A backslash separates; the result is spelled with `/`, from the
    // pattern's own spelling of each matched segment.
    assert_eq(@shell.glob("src\\*.mbt", cwd=root), ["src/d.mbt"])
    @fs.rmdir(root, recursive=true)
  }
}

///|
async test "a pattern of only separators is the root" {
  if not_windows() {
    assert_eq(@shell.glob("/"), ["/"])
    assert_eq(@shell.glob("//"), ["/"])
    assert_eq(@shell.glob("///"), ["/"])
  } else {
    // On Windows, `//` opens a share it never completes — `\\server\share`
    // territory — so it names no directory and expands to nothing.
    assert_eq(@shell.glob("//"), [])
    assert_eq(@shell.glob("///"), [])
  }
}

///|
async test "an empty pattern matches nothing and is not the root" {
  assert_eq(@shell.glob(""), [])
  assert_eq(@shell.glob("", cwd="src"), [])
}

///|
async test "an embedded NUL is rejected, not truncated" {
  // A C-string filesystem API would see only "moon.mod" — a file that
  // exists — and report a name the caller never spelled.
  try @shell.glob("moon.mod\u{0000}.bak") |> ignore catch {
    err =>
      debug_inspect(
        err,
        content=(
          #|NulByte("glob pattern")
        ),
      )
  } noraise {
    _ => fail("expected an embedded NUL to raise")
  }
  try @shell.glob("*", cwd="src\u{0000}decoy") |> ignore catch {
    err =>
      debug_inspect(
        err,
        content=(
          #|NulByte("glob working directory")
        ),
      )
  } noraise {
    _ => fail("expected an embedded NUL to raise")
  }
}

///|
async test "an escaped leading separator is still absolute" {
  // Escapes exist only where a backslash is not the path separator.
  if not_windows() {
    let root = @fs.tmpdir(prefix="shell-glob-abs")
    make_tree(root, ["tmp/decoy.txt"])
    // `\/tmp` denotes `/tmp`, so this must not search `<root>/tmp`.
    assert_false(@shell.glob("\\/tmp/*", cwd=root).contains("tmp/decoy.txt"))
    @fs.rmdir(root, recursive=true)
  }
}
