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
test "WinPath verbatim prefixes" {
  inspect(
    WinPath::parse("\\\\?\\GLOBALROOT\\file"),
    content="\\\\?\\GLOBALROOT\\file",
  )
  inspect(
    WinPath::parse("\\\\?\\GLOBALROOT\\folder\\"),
    content="\\\\?\\GLOBALROOT\\folder\\",
  )
  inspect(WinPath::parse("\\\\?\\GLOBALROOT"), content="\\\\?\\GLOBALROOT")
  inspect(
    WinPath::parse("\\\\?\\UNC\\server\\share\\file"),
    content="\\\\?\\UNC\\server\\share\\file",
  )
  inspect(
    WinPath::parse("\\\\?\\UNC\\server\\share\\folder\\"),
    content="\\\\?\\UNC\\server\\share\\folder\\",
  )
  inspect(
    WinPath::parse("\\\\?\\UNC\\server\\share"),
    content="\\\\?\\UNC\\server\\share",
  )
  inspect(
    WinPath::parse("\\\\?\\UNC\\server\\"),
    content="\\\\?\\UNC\\server\\",
  )
  inspect(WinPath::parse("\\\\?\\C:\\file"), content="\\\\?\\C:\\file")
  inspect(WinPath::parse("\\\\?\\C:\\folder\\"), content="\\\\?\\C:\\folder\\")
  inspect(WinPath::parse("\\\\?\\C:"), content="\\\\?\\C:")
}

///|
test "WinPath device and UNC prefixes" {
  inspect(WinPath::parse("\\\\.\\COM56\\file"), content="\\\\.\\COM56\\file")
  inspect(
    WinPath::parse("\\\\.\\COM56\\folder\\"),
    content="\\\\.\\COM56\\folder\\",
  )
  inspect(WinPath::parse("\\\\.\\COM56"), content="\\\\.\\COM56")
  inspect(
    WinPath::parse("\\\\server\\share\\file"),
    content="\\\\server\\share\\file",
  )
  inspect(
    WinPath::parse("\\\\server\\share\\folder\\"),
    content="\\\\server\\share\\folder\\",
  )
  inspect(WinPath::parse("\\\\server\\share"), content="\\\\server\\share\\")
  inspect(
    WinPath::parse("//server/share//folder"),
    content="\\\\server\\share\\folder",
  )
}

///|
test "WinPath drive and rooted paths" {
  inspect(WinPath::parse("C:\\"), content="C:\\")
  inspect(WinPath::parse("C:\\file"), content="C:\\file")
  inspect(WinPath::parse("C:\\folder\\"), content="C:\\folder\\")
  inspect(WinPath::parse("C:\\..\\..\\c\\.."), content="C:\\")
  inspect(WinPath::parse("C:main.mbt"), content="C:main.mbt")
  inspect(WinPath::parse("C:temp\\.\\file"), content="C:temp\\file")
  inspect(
    WinPath::parse("C:.\\..\\dir\\..\\main.mbt"),
    content="C:..\\main.mbt",
  )
  inspect(WinPath::parse("\\folder\\file"), content="\\folder\\file")
  inspect(WinPath::parse("\\..\\folder\\file"), content="\\folder\\file")
}

///|
test "WinPath relative normalization" {
  inspect(WinPath::parse(""), content=".")
  inspect(WinPath::parse("."), content=".")
  inspect(WinPath::parse(".\\"), content=".\\")
  inspect(WinPath::parse(".\\folder\\file"), content="folder\\file")
  inspect(
    WinPath::parse("containers\\finger_tree"),
    content="containers\\finger_tree",
  )
  inspect(
    WinPath::parse("containers\\finger_tree\\finger_tree.mbt"),
    content="containers\\finger_tree\\finger_tree.mbt",
  )
  inspect(WinPath::parse(".."), content="..")
  inspect(WinPath::parse("..\\"), content="..\\")
  inspect(WinPath::parse("a\\.."), content=".")
  inspect(WinPath::parse("a\\..\\"), content=".\\")
  inspect(WinPath::parse("..\\a"), content="..\\a")
  inspect(WinPath::parse("a\\..\\b"), content="b")
  inspect(WinPath::parse("a\\b\\.."), content="a")
  inspect(WinPath::parse("a\\b\\..\\"), content="a\\")
  inspect(WinPath::parse("a\\b\\..\\c"), content="a\\c")
  inspect(WinPath::parse(".\\a\\b\\.\\c\\..\\d\\..\\.."), content="a")
}

///|
test "WinPath separator and trailing normalization" {
  inspect(WinPath::parse(".\\a\\\\b\\\\\\\\c"), content="a\\b\\c")
  inspect(WinPath::parse("C:\\\\\\\\a\\b"), content="C:\\a\\b")
  inspect(WinPath::parse(".\\\\\\a\\b\\c\\\\e"), content="a\\b\\c\\e")
  inspect(WinPath::parse("a/b//c"), content="a\\b\\c")
  inspect(WinPath::parse("C:\\folder\\\\"), content="C:\\folder\\")
  inspect(WinPath::parse(".\\a\\b\\c\\\\\\"), content="a\\b\\c\\")
  inspect(WinPath::parse("a\\b\\c\\"), content="a\\b\\c\\")
  inspect(WinPath::parse("a\\.\\b\\..\\c\\"), content="a\\c\\")
}

///|
test "WinPath reserved-looking names are path components" {
  inspect(WinPath::parse("C:\\temp\\CON"), content="C:\\temp\\CON")
  inspect(WinPath::parse("C:\\temp\\PRN.txt"), content="C:\\temp\\PRN.txt")
  inspect(
    WinPath::parse("C:\\temp\\question?mark"),
    content="C:\\temp\\question?mark",
  )
  inspect(WinPath::parse("C:\\temp\\star*name"), content="C:\\temp\\star*name")
}

///|
test "resolve with Windows cwd anchors drive-less rooted paths" {
  inspect(
    resolve_with_cwd("\\foo", "C:\\Users\\alice\\project"),
    content="C:\\foo",
  )
  inspect(resolve_with_cwd("/", "C:\\Users\\alice\\project"), content="C:\\")
  inspect(resolve_with_cwd("\\", "C:\\Users\\alice\\project"), content="C:\\")
  inspect(
    resolve_with_cwd("\\a\\..\\b\\c", "C:\\Users\\alice\\project"),
    content="C:\\b\\c",
  )
  inspect(
    resolve_with_cwd(
      "\\Users\\..\\Windows\\System32", "C:\\Users\\alice\\project",
    ),
    content="C:\\Windows\\System32",
  )
  inspect(
    resolve_with_cwd("\\\\server\\share\\.\\file", "C:\\Users\\alice\\project"),
    content="\\\\server\\share\\file",
  )
  inspect(resolve_with_cwd("\\foo", "/home/alice/project"), content="\\foo")
  let unc_cwd = "\\\\server\\share\\dir"
  inspect(resolve_with_cwd("\\foo", unc_cwd), content="\\\\server\\share\\foo")
  inspect(resolve_with_cwd("/", unc_cwd), content="\\\\server\\share\\")
  inspect(
    resolve_with_cwd("\\foo\\..\\bar", unc_cwd),
    content="\\\\server\\share\\bar",
  )
  inspect(
    resolve_with_cwd("\\foo", "\\\\server\\share"),
    content="\\\\server\\share\\foo",
  )
}

///|
test "resolve drive-relative against cwd on another drive" {
  inspect(resolve_with_cwd("C:", "D:\\a\\x\\x"), content="C:\\")
  inspect(resolve_with_cwd("C:a", "D:\\a\\x\\x"), content="C:\\a")
  inspect(resolve_with_cwd("C:a\\..\\b", "D:\\a\\x\\x"), content="C:\\b")
}

///|
fn relative_with_cwd(base : Path, path : Path, cwd : String) -> Path {
  let resolved_from = resolve_with_cwd(base, cwd)
  let resolved_to = resolve_with_cwd(path, cwd)
  relative_resolved_paths(resolved_from.0, resolved_to.0)
}

///|
test "relative with Windows cwd anchors drive-less rooted paths" {
  let cwd = "C:\\Users\\alice\\project"
  inspect(relative_with_cwd("\\a", "\\b", cwd), content="..\\b")
  inspect(relative_with_cwd("/a/b", "/c/d", cwd), content="..\\..\\c\\d")
  inspect(relative_with_cwd("/a/b", "/a/c", cwd), content="..\\c")
  inspect(
    relative_with_cwd("\\a", "\\b", "\\\\server\\share\\dir"),
    content="..\\b",
  )
}

///|
test "relative with Windows cwd extreme" {
  let cwd = "C:\\Users\\alice\\project"
  inspect(relative_with_cwd("C:\\a\\b", "C:\\a\\c", cwd), content="..\\c")
  inspect(relative_with_cwd("C:\\a\\b\\c", "C:\\a\\b", cwd), content="..")
  inspect(relative_with_cwd("C:\\ABC", "C:\\AB", cwd), content="..\\AB")
  inspect(relative_with_cwd("C:\\AB", "C:\\ABC", cwd), content="..\\ABC")
  inspect(relative_with_cwd("C:\\a\\bX", "C:\\a\\b", cwd), content="..\\b")
  inspect(relative_with_cwd("C:\\a\\b", "C:\\a\\bX", cwd), content="..\\bX")
  inspect(relative_with_cwd("c:\\a\\B", "C:\\a\\b\\x", cwd), content="x")
  inspect(relative_with_cwd("C:\\a", "c:\\a\\b", cwd), content="b")
  inspect(
    relative_with_cwd("\\\\server\\share", "\\\\server\\share\\a", cwd),
    content="a",
  )
  inspect(relative_with_cwd("C:\\a\\b", "C:\\a\\b", cwd), content="")
}

///|
test "WinPath parse extreme" {
  // bare verbatim/device prefixes keep the full prefix, unlike Node which
  // parses them as a UNC host
  inspect(WinPath::parse("\\\\?\\"), content="\\\\?\\")
  inspect(WinPath::parse("\\\\.\\"), content="\\\\.\\")
  inspect(WinPath::parse("\\\\?\\UNC\\server\\.."), content="\\\\?\\UNC")
  inspect(WinPath::parse("\\\\.\\COM1\\..\\..\\a"), content="\\\\.\\a")
  inspect(WinPath::parse("C:a\\b\\.."), content="C:a")
  inspect(WinPath::parse("C:..\\..\\a"), content="C:..\\..\\a")
  inspect(WinPath::parse("a\\b\\..\\"), content="a\\")
  inspect(WinPath::parse("..\\..\\a"), content="..\\..\\a")
  inspect(WinPath::parse("\\\\\\a"), content="\\a")
  inspect(WinPath::parse("////a"), content="\\a")
  inspect(WinPath::parse("C:\\\\a\\\\"), content="C:\\a\\")
  inspect(
    WinPath::parse("\\\\?\\C:\\temp\\..\\file"),
    content="\\\\?\\C:\\file",
  )
  inspect(
    WinPath::parse("\\\\server\\share\\folder\\..\\.."),
    content="\\\\server\\share\\",
  )
  inspect(WinPath::parse("\\\\server\\..\\.."), content="\\\\server\\..\\")
  inspect(WinPath::parse("a::b"), content="a::b")
  inspect(WinPath::parse("C:\\a\\b.."), content="C:\\a\\b..")
}
