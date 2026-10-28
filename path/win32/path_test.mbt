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
test "Path division chains and normalizes Windows paths" {
  let path : @win32.Path = "C:/Users"
  let y : @win32.Path = "alice"
  let z : @win32.Path = "docs"
  inspect(path / y / z, content="C:\\Users\\alice\\docs")
  inspect(path / "alice" / "../docs/", content="C:\\Users\\docs\\")
  inspect(path / "\\docs", content="C:\\Users\\docs")
  inspect(path / "D:\\docs", content="C:\\Users\\D:\\docs")
  inspect(path / "", content="C:\\Users")
  inspect(@win32.Path("") / "", content=".")
  inspect(@win32.Path("") / "C:/docs", content="C:\\docs")
  inspect(
    @win32.Path("//server/share") / "docs",
    content="\\\\server\\share\\docs",
  )
}

///|
test "debug" {
  debug_inspect(@win32.Path::join("a", "b"), content="Path(\"a\\\\b\")")
}

///|
test "basename node fixtures" {
  inspect(@win32.Path::basename(""), content="")
  inspect(@win32.Path::basename("\\"), content="")
  inspect(@win32.Path::basename("\\\\"), content="")
  inspect(@win32.Path::basename("a"), content="a")
  inspect(@win32.Path::basename("\\a"), content="a")
  inspect(@win32.Path::basename("a\\"), content="a")
  inspect(@win32.Path::basename("a\\\\"), content="a")
  inspect(@win32.Path::basename("a\\b\\"), content="b")
  inspect(@win32.Path::basename("C:a"), content="a")
  inspect(@win32.Path::basename("C:\\"), content="")
  inspect(@win32.Path::basename("C:\\a"), content="a")
  inspect(@win32.Path::basename("C:\\a\\b\\"), content="b")
  inspect(@win32.Path::basename("file.txt\\"), content="file.txt")
  inspect(@win32.Path::basename("a/b"), content="b")
  inspect(@win32.Path::basename("//server/share"), content="share")
  inspect(@win32.Path::basename("//server/share/"), content="share")
  inspect(@win32.Path::basename("//server/share/file"), content="file")
  inspect(@win32.Path::basename("\\\\server\\share"), content="share")
  inspect(@win32.Path::basename("\\\\server\\share\\"), content="share")
  inspect(@win32.Path::basename("\\\\server\\share\\file"), content="file")
  inspect(
    @win32.Path::basename("\\\\server\\share\\folder\\file"),
    content="file",
  )
  inspect(@win32.Path::basename("\\\\?\\C:\\temp\\file"), content="file")
  inspect(
    @win32.Path::basename("\\\\?\\UNC\\server\\share\\file"),
    content="file",
  )
  inspect(@win32.Path::basename("C:\\Program Files\\app"), content="app")
  inspect(@win32.Path::basename("C:\\a\\."), content=".")
  inspect(@win32.Path::basename("C:\\a\\.."), content="..")
}

///|
test "basename: mixed separator" {
  inspect(@win32.Path::basename("a/b\\c"), content="c")
  inspect(@win32.Path::basename("a\\b/c"), content="c")
  inspect(@win32.Path::basename("C:a/b\\c"), content="c")
  inspect(@win32.Path::basename("C:\\a/b\\c"), content="c")
  inspect(@win32.Path::basename("//server/share\\file"), content="file")
  inspect(
    @win32.Path::basename("\\\\server/share\\folder/file"),
    content="file",
  )
  inspect(@win32.Path::basename("a/b\\c\\"), content="c")
  inspect(@win32.Path::basename("a\\b/c/"), content="c")
}

///|
test "dirname node fixtures" {
  inspect(@win32.Path::dirname(""), content=".")
  inspect(@win32.Path::dirname("a"), content=".")
  inspect(@win32.Path::dirname("a\\"), content=".")
  inspect(@win32.Path::dirname("a\\\\"), content=".")
  inspect(@win32.Path::dirname("a\\b\\"), content="a")
  inspect(@win32.Path::dirname("\\"), content="\\")
  inspect(@win32.Path::dirname("\\\\"), content="\\")
  inspect(@win32.Path::dirname("\\a"), content="\\")
  inspect(@win32.Path::dirname("\\\\a"), content="\\")
  inspect(@win32.Path::dirname("C:"), content="C:")
  inspect(@win32.Path::dirname("C:a"), content="C:")
  inspect(@win32.Path::dirname("C:\\"), content="C:\\")
  inspect(@win32.Path::dirname("C:\\a"), content="C:\\")
  inspect(@win32.Path::dirname("C:\\a\\"), content="C:\\")
  inspect(@win32.Path::dirname("C:/a/b"), content="C:/a")
  inspect(@win32.Path::dirname("a/b"), content="a")
  inspect(@win32.Path::dirname("///C:/foo"), content="///C:")
  inspect(@win32.Path::dirname("//server/share"), content="//server/share")
  inspect(@win32.Path::dirname("//server/share/"), content="//server/share/")
  inspect(
    @win32.Path::dirname("//server/share/file"),
    content="//server/share/",
  )
  inspect(
    @win32.Path::dirname("\\\\server\\share\\file"),
    content="\\\\server\\share\\",
  )
  inspect(
    @win32.Path::dirname("\\\\server\\share"),
    content="\\\\server\\share",
  )
  inspect(
    @win32.Path::dirname("\\\\server\\share\\"),
    content="\\\\server\\share\\",
  )
  inspect(
    @win32.Path::dirname("\\\\server\\share\\folder\\file"),
    content="\\\\server\\share\\folder",
  )
  inspect(
    @win32.Path::dirname("\\\\?\\C:\\temp\\file"),
    content="\\\\?\\C:\\temp",
  )
  inspect(
    @win32.Path::dirname("\\\\?\\UNC\\server\\share\\file"),
    content="\\\\?\\UNC\\server\\share",
  )
  inspect(@win32.Path::dirname(".\\a"), content=".")
  inspect(@win32.Path::dirname("..\\a"), content="..")
  inspect(@win32.Path::dirname("a\\..\\b"), content="a\\..")
  inspect(@win32.Path::dirname("C:\\a\\..\\b"), content="C:\\a\\..")
}

///|
test "extname node dotfile fixtures" {
  inspect(@win32.Path::extname(""), content="")
  inspect(@win32.Path::extname("file"), content="")
  inspect(@win32.Path::extname("C:\\path\\file"), content="")
  inspect(@win32.Path::extname("project\\main.mbt.md"), content=".md")
  inspect(@win32.Path::extname("file.tar.gz"), content=".gz")
  inspect(@win32.Path::extname("program.exe"), content=".exe")
  inspect(@win32.Path::extname("file.c++"), content=".c++")
  inspect(@win32.Path::extname("file.123"), content=".123")
  inspect(@win32.Path::extname("file.-"), content=".-")
  inspect(@win32.Path::extname(".hidden"), content="")
  inspect(@win32.Path::extname("C:\\path\\.hidden"), content="")
  inspect(@win32.Path::extname(".hidden.txt"), content=".txt")
  inspect(@win32.Path::extname("C:\\path\\.hidden.txt"), content=".txt")
  inspect(@win32.Path::extname("."), content="")
  inspect(@win32.Path::extname(".."), content="")
  inspect(@win32.Path::extname(".\\file"), content="")
  inspect(@win32.Path::extname("..\\file"), content="")
  inspect(@win32.Path::extname("C:\\a\\."), content="")
  inspect(@win32.Path::extname("C:\\a\\.."), content="")
  inspect(@win32.Path::extname(".txt"), content="")
  inspect(@win32.Path::extname("a.b.c"), content=".c")
  inspect(@win32.Path::extname("a."), content=".")
  inspect(@win32.Path::extname("C:\\path\\a."), content=".")
  inspect(@win32.Path::extname("file.txt\\"), content=".txt")
  inspect(@win32.Path::extname("C:\\path\\file.txt\\"), content=".txt")
  inspect(@win32.Path::extname("a/b.txt"), content=".txt")
  inspect(@win32.Path::extname("\\\\server\\share\\file.txt"), content=".txt")
  inspect(@win32.Path::extname("\\\\?\\C:\\temp\\file.log"), content=".log")
}

///|
test "root node fixtures" {
  inspect(@win32.Path::root(""), content="")
  inspect(@win32.Path::root("a"), content="")
  inspect(@win32.Path::root("a\\b"), content="")
  inspect(@win32.Path::root("\\"), content="\\")
  inspect(@win32.Path::root("\\\\"), content="\\")
  inspect(@win32.Path::root("\\foo\\bar"), content="\\")
  inspect(@win32.Path::root("\\\\server"), content="\\")
  inspect(@win32.Path::root("\\\\server\\share"), content="\\\\server\\share")
  inspect(
    @win32.Path::root("\\\\server\\share\\"),
    content="\\\\server\\share\\",
  )
  inspect(
    @win32.Path::root("\\\\server\\share\\file"),
    content="\\\\server\\share\\",
  )
  inspect(@win32.Path::root("//server/share"), content="//server/share")
  inspect(@win32.Path::root("C:"), content="C:")
  inspect(@win32.Path::root("C:foo"), content="C:")
  inspect(@win32.Path::root("C:\\"), content="C:\\")
  inspect(@win32.Path::root("C:\\foo"), content="C:\\")
  inspect(@win32.Path::root("C:/foo"), content="C:/")
  inspect(@win32.Path::root("\\\\?\\C:\\"), content="\\\\?\\C:\\")
  inspect(@win32.Path::root("\\\\?\\C:\\foo"), content="\\\\?\\C:\\")
  inspect(@win32.Path::root("\\\\?\\foo\\bar"), content="\\\\?\\foo\\")
  inspect(@win32.Path::root("\\\\?\\foo"), content="\\\\?\\foo")
  inspect(
    @win32.Path::root("\\\\?\\UNC\\server\\share\\file"),
    content="\\\\?\\UNC\\",
  )
  inspect(
    @win32.Path::root("\\\\?\\UNC\\server\\share"),
    content="\\\\?\\UNC\\",
  )
  inspect(
    @win32.Path::root("\\\\?\\Volume{abc}\\file"),
    content="\\\\?\\Volume{abc}\\",
  )
  inspect(@win32.Path::root("\\\\.\\COM1"), content="\\\\.\\COM1")
}

///|
test "is_absolute node fixtures" {
  json_inspect(@win32.Path::is_absolute(""), content=false)
  json_inspect(@win32.Path::is_absolute(" "), content=false)
  json_inspect(@win32.Path::is_absolute("  \\"), content=false)
  json_inspect(@win32.Path::is_absolute("\\"), content=true)
  json_inspect(@win32.Path::is_absolute("\\\\"), content=true)
  json_inspect(@win32.Path::is_absolute("/foo"), content=true)
  json_inspect(@win32.Path::is_absolute("foo/bar"), content=false)
  json_inspect(@win32.Path::is_absolute("C:"), content=false)
  json_inspect(@win32.Path::is_absolute("C:temp"), content=false)
  json_inspect(@win32.Path::is_absolute("C:temp\\file"), content=false)
  json_inspect(@win32.Path::is_absolute("C:\\"), content=true)
  json_inspect(@win32.Path::is_absolute("C:\\temp"), content=true)
  json_inspect(@win32.Path::is_absolute("C:/temp"), content=true)
  json_inspect(@win32.Path::is_absolute("c:/temp"), content=true)
  json_inspect(@win32.Path::is_absolute("\\\\server\\share"), content=true)
  json_inspect(@win32.Path::is_absolute("//server/share"), content=true)
  json_inspect(@win32.Path::is_absolute("\\\\?\\C:\\"), content=true)
  json_inspect(@win32.Path::is_absolute("\\\\?\\C:\\temp"), content=true)
  json_inspect(
    @win32.Path::is_absolute("\\\\?\\UNC\\server\\share"),
    content=true,
  )
  json_inspect(
    @win32.Path::is_absolute("\\\\?\\UNC\\server\\share\\file"),
    content=true,
  )
  json_inspect(@win32.Path::is_absolute("\\\\.\\COM1"), content=true)
  json_inspect(@win32.Path::is_absolute("\\\\.\\PhysicalDrive0"), content=true)
  json_inspect(
    @win32.Path::is_absolute(
      "\\\\?\\Volume{12345678-1234-1234-1234-1234567890ab}\\",
    ),
    content=true,
  )
  json_inspect(@win32.Path::is_absolute("."), content=false)
  json_inspect(@win32.Path::is_absolute(".."), content=false)
  json_inspect(@win32.Path::is_absolute(".\\"), content=false)
  json_inspect(@win32.Path::is_absolute("..\\"), content=false)
  json_inspect(@win32.Path::is_absolute("\\."), content=true)
  json_inspect(@win32.Path::is_absolute("\\.."), content=true)
}

///|
test "join node fixtures" {
  inspect(@win32.Path::join("a", "b"), content="a\\b")
  inspect(@win32.Path::join("a", "\\b"), content="a\\b")
  inspect(@win32.Path::join("C:\\a", "D:\\b"), content="C:\\a\\D:\\b")
  inspect(@win32.Path::join("lhs", "C:rhs"), content="lhs\\C:rhs")
  inspect(@win32.Path::join("C:lhs", "C:rhs"), content="C:lhs\\C:rhs")
  inspect(@win32.Path::join("C:lhs", "D:rhs"), content="C:lhs\\D:rhs")
  inspect(@win32.Path::join("", ""), content=".")
  inspect(@win32.Path::join("a", ""), content="a")
  inspect(@win32.Path::join("", "b"), content="b")
  inspect(@win32.Path::join("", "C:\\abs"), content="C:\\abs")
  inspect(@win32.Path::join("a", "b/c"), content="a\\b\\c")
  inspect(@win32.Path::join("a\\", "b\\c"), content="a\\b\\c")
  inspect(@win32.Path::join("a\\\\", "b"), content="a\\b")
  inspect(@win32.Path::join("a", ".\\b"), content="a\\b")
  inspect(@win32.Path::join("a", "..\\b"), content="b")
  inspect(@win32.Path::join(".\\a", "b"), content="a\\b")
  inspect(@win32.Path::join("..\\a", "b"), content="..\\a\\b")
  inspect(@win32.Path::join("C:", "temp"), content="C:\\temp")
  inspect(@win32.Path::join("C:\\", "temp"), content="C:\\temp")
  inspect(@win32.Path::join("C:\\folder", "temp"), content="C:\\folder\\temp")
  inspect(@win32.Path::join("C:folder", "temp"), content="C:folder\\temp")
  inspect(
    @win32.Path::join("\\\\server1\\share1", "\\\\server2\\share2"),
    content="\\\\server1\\share1\\server2\\share2",
  )
  inspect(
    @win32.Path::join("//server/share", "folder"),
    content="\\\\server\\share\\folder",
  )
  inspect(@win32.Path::join("\\", "a"), content="\\a")
  inspect(@win32.Path::join("\\", "\\a"), content="\\a")
  inspect(@win32.Path::join("\\\\", "a"), content="\\a")
  inspect(@win32.Path::join("a\\b", "..\\c"), content="a\\c")
  inspect(@win32.Path::join("C:\\a\\b", "..\\c"), content="C:\\a\\c")
  inspect(@win32.Path::join("C:\\temp", "CON"), content="C:\\temp\\CON")
  inspect(@win32.Path::join("C:\\temp", "PRN.txt"), content="C:\\temp\\PRN.txt")
  inspect(@win32.Path::join("a", "C:"), content=".\\a\\C:")
  inspect(@win32.Path::join("a", "C:\\b"), content=".\\a\\C:\\b")
}

///|
test "normalize node fixtures" {
  inspect(@win32.Path::normalize(""), content=".")
  inspect(@win32.Path::normalize("."), content=".")
  inspect(@win32.Path::normalize(".\\"), content=".\\")
  inspect(@win32.Path::normalize("a\\."), content="a")
  inspect(@win32.Path::normalize("a\\.\\b"), content="a\\b")
  inspect(@win32.Path::normalize(".\\a"), content="a")
  inspect(@win32.Path::normalize(".\\a\\"), content="a\\")
  inspect(@win32.Path::normalize(".."), content="..")
  inspect(@win32.Path::normalize("..\\"), content="..\\")
  inspect(@win32.Path::normalize("a\\.."), content=".")
  inspect(@win32.Path::normalize("a\\..\\"), content=".\\")
  inspect(@win32.Path::normalize("..\\a"), content="..\\a")
  inspect(@win32.Path::normalize("a\\..\\b"), content="b")
  inspect(@win32.Path::normalize("a\\b\\.."), content="a")
  inspect(@win32.Path::normalize("a\\b\\..\\"), content="a\\")
  inspect(@win32.Path::normalize("a\\b\\..\\c"), content="a\\c")
  inspect(@win32.Path::normalize("a\\\\b"), content="a\\b")
  inspect(@win32.Path::normalize("a\\\\\\b"), content="a\\b")
  inspect(@win32.Path::normalize("a/b//c"), content="a\\b\\c")
  inspect(@win32.Path::normalize("a\\b\\c\\"), content="a\\b\\c\\")
  inspect(@win32.Path::normalize("a\\.\\b\\..\\c\\"), content="a\\c\\")
  inspect(@win32.Path::normalize("C:\\.\\temp"), content="C:\\temp")
  inspect(@win32.Path::normalize("C:\\..\\temp"), content="C:\\temp")
  inspect(@win32.Path::normalize("C:\\folder\\..\\temp"), content="C:\\temp")
  inspect(@win32.Path::normalize("C:temp\\.\\file"), content="C:temp\\file")
  inspect(@win32.Path::normalize("\\."), content="\\")
  inspect(@win32.Path::normalize("\\./"), content="\\")
  inspect(@win32.Path::normalize("\\.."), content="\\")
  inspect(@win32.Path::normalize("\\..\\"), content="\\")
  inspect(@win32.Path::normalize("\\a\\.."), content="\\")
  inspect(@win32.Path::normalize("\\a\\..\\"), content="\\")
  inspect(@win32.Path::normalize("\\a\\..\\b"), content="\\b")
  inspect(@win32.Path::normalize("///server/share"), content="\\server\\share")
  inspect(
    @win32.Path::normalize("\\\\server\\share\\.\\folder"),
    content="\\\\server\\share\\folder",
  )
  inspect(
    @win32.Path::normalize("\\\\server\\share\\folder\\..\\file"),
    content="\\\\server\\share\\file",
  )
  inspect(
    @win32.Path::normalize("//server/share//folder"),
    content="\\\\server\\share\\folder",
  )
  inspect(@win32.Path::normalize(".\\.hidden"), content=".hidden")
  inspect(@win32.Path::normalize("a\\.\\.hidden"), content="a\\.hidden")
  inspect(@win32.Path::normalize("a\\..\\..hidden"), content="..hidden")
  inspect(
    @win32.Path::normalize("\\\\?\\C:\\temp\\.\\file"),
    content="\\\\?\\C:\\temp\\file",
  )
  inspect(
    @win32.Path::normalize("\\\\?\\UNC\\server\\share\\folder\\..\\file"),
    content="\\\\?\\UNC\\server\\share\\file",
  )
  inspect(
    @win32.Path::normalize("\\\\?\\UNC\\server\\share\\.."),
    content="\\\\?\\UNC\\server",
  )
  inspect(
    @win32.Path::normalize("\\\\?\\UNC\\server\\share\\folder\\.."),
    content="\\\\?\\UNC\\server\\share",
  )
  inspect(@win32.Path::normalize("\\\\?\\foo\\.."), content="\\\\?\\")
  inspect(@win32.Path::normalize("\\\\?\\foo\\bar\\.."), content="\\\\?\\foo")
  inspect(@win32.Path::normalize("\\\\.\\COM1\\.."), content="\\\\.\\")
  inspect(@win32.Path::normalize("\\\\.\\COM1\\bar\\.."), content="\\\\.\\COM1")
  inspect(@win32.Path::normalize("\\\\?\\Volume{abc}\\.."), content="\\\\?\\")
  inspect(
    @win32.Path::normalize("\\\\?\\Volume{abc}\\bar\\.."),
    content="\\\\?\\Volume{abc}",
  )
  inspect(@win32.Path::normalize("\\\\?\\C:\\foo\\.."), content="\\\\?\\C:")
  inspect(@win32.Path::normalize("\\\\?\\C:\\.."), content="\\\\?\\")
  inspect(
    @win32.Path::normalize("\\\\?\\UNC\\server\\"),
    content="\\\\?\\UNC\\server\\",
  )
  inspect(@win32.Path::normalize("C:\\temp\\CON"), content="C:\\temp\\CON")
  inspect(
    @win32.Path::normalize("C:\\temp\\PRN.txt"),
    content="C:\\temp\\PRN.txt",
  )
  inspect(@win32.Path::normalize("a\\C:"), content=".\\a\\C:")
  inspect(@win32.Path::normalize("a\\C:\\b"), content=".\\a\\C:\\b")
  inspect(
    @win32.Path::normalize("foo\\bar\\D:\\baz"),
    content=".\\foo\\bar\\D:\\baz",
  )
}

///|
test "relative node fixtures" {
  inspect(
    @win32.Path::relative(base="C:\\Users\\user", "C:\\Users\\user\\proj"),
    content="proj",
  )
  inspect(
    @win32.Path::relative(base="C:\\Users\\user\\proj", "C:\\Users\\user"),
    content="..",
  )
  inspect(
    @win32.Path::relative(base="C:\\Users\\user", "C:\\Users\\user"),
    content="",
  )
  inspect(@win32.Path::relative(base="C:\\a\\b", "C:\\a\\.\\b"), content="")
  inspect(@win32.Path::relative(base="C:\\a\\b", "C:\\a\\c\\..\\b"), content="")
  inspect(
    @win32.Path::relative(base="C:\\temp", "D:\\temp"),
    content="D:\\temp",
  )
  inspect(
    @win32.Path::relative(base="C:\\Users", "D:\\Files"),
    content="D:\\Files",
  )
  inspect(@win32.Path::relative(base="C:\\", "C:\\Users"), content="Users")
  inspect(@win32.Path::relative(base="C:\\Users", "C:\\"), content="..")
  inspect(
    @win32.Path::relative(base="C:\\a\\b\\c\\d", "C:\\a\\b\\e\\f"),
    content="..\\..\\e\\f",
  )
  inspect(
    @win32.Path::relative(base="C:\\a\\b\\c\\d\\e", "C:\\a\\f"),
    content="..\\..\\..\\..\\f",
  )
  inspect(
    @win32.Path::relative(base="C:\\Users\\.config", "C:\\Users\\.local"),
    content="..\\.local",
  )
  inspect(
    @win32.Path::relative(base="C:\\Users", "C:\\Users\\.hidden"),
    content=".hidden",
  )
  inspect(
    @win32.Path::relative(base="C:\\Users\\user", "C:\\Users\\user\\."),
    content="",
  )
  inspect(
    @win32.Path::relative(base="C:\\Users\\user\\.", "C:\\Users\\user"),
    content="",
  )
  inspect(
    @win32.Path::relative(base="C:\\Users\\user", "C:\\Users\\user\\.."),
    content="..",
  )
  inspect(
    @win32.Path::relative(
      base="\\\\server\\share\\folder1",
      "\\\\server\\share\\folder2",
    ),
    content="..\\folder2",
  )
  inspect(
    @win32.Path::relative(base="c:\\temp", "C:\\temp\\file"),
    content="file",
  )
  inspect(@win32.Path::relative(base="C:\\Ä", "C:\\ä"), content="")
  inspect(
    @win32.Path::relative(base="\\\\server\\share", "\\\\server\\other\\file"),
    content="..\\other\\file",
  )
  inspect(
    @win32.Path::relative(
      base="\\\\server\\share\\folder",
      "\\\\server\\other\\file",
    ),
    content="..\\..\\other\\file",
  )
  inspect(
    @win32.Path::relative(base="\\\\server1\\share", "\\\\server2\\share\\file"),
    content="\\\\server2\\share\\file",
  )
  inspect(
    @win32.Path::relative(
      base="\\\\?\\UNC\\server\\share",
      "\\\\?\\UNC\\server\\other\\file",
    ),
    content="..\\other\\file",
  )
  inspect(@win32.Path::relative(base="C:\\a", "C:\\b"), content="..\\b")
  inspect(
    @win32.Path::relative(base="C:\\a\\b", "C:\\c\\d"),
    content="..\\..\\c\\d",
  )
  inspect(@win32.Path::relative(base="C:\\a\\b", "C:\\a\\c"), content="..\\c")
}

///|
test "relative unicode case folding" {
  inspect(@win32.Path::relative(base="C:\\Α", "C:\\α"), content="")
  inspect(@win32.Path::relative(base="C:\\А", "C:\\а"), content="")
  inspect(@win32.Path::relative(base="C:\\Š", "C:\\š"), content="")
  inspect(@win32.Path::relative(base="C:\\K", "C:\\k"), content="")
  inspect(@win32.Path::relative(base="C:\\𐐀", "C:\\𐐨"), content="")
  inspect(@win32.Path::relative(base="C:\\Α", "C:\\Β"), content="..\\Β")
}

///|
test "resolve absolute fixtures" {
  inspect(@win32.Path::resolve("C:\\a\\.\\b"), content="C:\\a\\b")
  inspect(@win32.Path::resolve("C:\\a\\..\\b"), content="C:\\b")
  inspect(@win32.Path::resolve("C:\\a\\b\\..\\..\\c"), content="C:\\c")
  inspect(@win32.Path::resolve("C:\\a\\..\\b\\c"), content="C:\\b\\c")
  inspect(
    @win32.Path::resolve("\\\\server\\share\\.\\file"),
    content="\\\\server\\share\\file",
  )
  inspect(
    @win32.Path::resolve("\\\\?\\C:\\temp\\.\\file"),
    content="\\\\?\\C:\\temp\\file",
  )
}

///|
test "resolve drops trailing separators except regular roots" {
  inspect(@win32.Path::resolve("C:\\a\\"), content="C:\\a")
  inspect(@win32.Path::resolve("C:\\a\\b\\"), content="C:\\a\\b")
  inspect(
    @win32.Path::resolve("\\\\server\\share\\file\\"),
    content="\\\\server\\share\\file",
  )
  inspect(@win32.Path::resolve("\\\\?\\C:\\temp\\"), content="\\\\?\\C:\\temp")
  inspect(
    @win32.Path::resolve("\\\\?\\UNC\\server\\share\\file\\"),
    content="\\\\?\\UNC\\server\\share\\file",
  )
  inspect(@win32.Path::resolve("\\\\?\\C:\\"), content="\\\\?\\C:")
  inspect(
    @win32.Path::resolve("\\\\?\\UNC\\server\\share\\"),
    content="\\\\?\\UNC\\server\\share",
  )
  inspect(
    @win32.Path::resolve("\\\\?\\UNC\\server\\"),
    content="\\\\?\\UNC\\server",
  )
  inspect(@win32.Path::resolve("\\\\.\\COM1\\"), content="\\\\.\\COM1")
  inspect(@win32.Path::resolve("C:\\"), content="C:\\")
  inspect(
    @win32.Path::resolve("\\\\server\\share\\"),
    content="\\\\server\\share\\",
  )
}

///|
fn test_is_win_sep_at(path : String, index : Int32) -> Bool {
  match path.get_char(index) {
    Some('\\' | '/') => true
    _ => false
  }
}

///|
fn test_has_win_drive(path : String) -> Bool {
  if path.length() < 2 || path.get_char(1) != Some(':') {
    false
  } else {
    match path.get_char(0) {
      Some(ch) => ch.is_ascii_alphabetic()
      _ => false
    }
  }
}

///|
fn test_current_dir_for_drive(drive : String) -> @win32.Path {
  let cwd = @env.current_dir().unwrap()
  if test_has_win_drive(cwd) &&
    !cwd[0:2].equal_ignore_ascii_case(drive) &&
    cwd.length() > 2 &&
    test_is_win_sep_at(cwd, 2) {
    @win32.Path::normalize(drive + "\\")
  } else if !test_has_win_drive(cwd) &&
    cwd.length() > 0 &&
    test_is_win_sep_at(cwd, 0) {
    @win32.Path::normalize(drive + cwd)
  } else if !test_has_win_drive(cwd) {
    @win32.Path::normalize(drive + "\\" + cwd)
  } else {
    @win32.Path::normalize(cwd)
  }
}

///|
test "resolve drive-relative paths from current directory" {
  let c_cwd = test_current_dir_for_drive("C:")
  inspect(@win32.Path::resolve("C:"), content=Show::to_string(c_cwd))
  inspect(@win32.Path::resolve("C:."), content=Show::to_string(c_cwd))
  inspect(@win32.Path::resolve("C:a"), content=Show::to_string(c_cwd.join("a")))
  inspect(
    @win32.Path::resolve("C:a\\..\\b"),
    content=Show::to_string(c_cwd.join("b")),
  )
  inspect(
    @win32.Path::resolve("D:a"),
    content=Show::to_string(test_current_dir_for_drive("D:").join("a")),
  )
}

///|
test "constants and separators" {
  inspect(@win32.delimiter, content=";")
  inspect(@win32.sep, content="\\")
}

///|
test "basename extreme" {
  inspect(@win32.Path::basename("a\\/"), content="a")
  inspect(@win32.Path::basename("a/\\"), content="a")
  inspect(@win32.Path::basename("a\\\\/"), content="a")
  inspect(@win32.Path::basename("a///"), content="a")
  inspect(@win32.Path::basename("\\\\?\\C:\\"), content="C:")
  inspect(@win32.Path::basename("\\\\?\\C:"), content="C:")
  inspect(@win32.Path::basename("\\\\?\\"), content="?")
  inspect(@win32.Path::basename("\\\\.\\"), content=".")
  inspect(@win32.Path::basename("\\\\.\\COM1"), content="COM1")
  inspect(@win32.Path::basename("C:a\\/b"), content="b")
  inspect(@win32.Path::basename("C:\\a\\//b"), content="b")
  inspect(@win32.Path::basename("//server\\share/"), content="share")
  inspect(@win32.Path::basename("\\\\server//share"), content="share")
  inspect(@win32.Path::basename(" \\\\a\\b "), content="b ")
  inspect(@win32.Path::basename("C:\\\\"), content="")
  inspect(@win32.Path::basename("C:\\\\\\"), content="")
  inspect(@win32.Path::basename("C:\\a\\b."), content="b.")
  inspect(@win32.Path::basename("C:\\a\\b.."), content="b..")
  inspect(@win32.Path::basename("C:\\a\\.."), content="..")
  inspect(@win32.Path::basename("C:\\a\\."), content=".")
  inspect(@win32.Path::basename("C:\\目录\\文件.txt"), content="文件.txt")
  inspect(@win32.Path::basename("C:\\a\\😀.txt"), content="😀.txt")
  inspect(@win32.Path::basename("a\tb"), content="a\tb")
  inspect(@win32.Path::basename("a b\\c d"), content="c d")
  inspect(@win32.Path::basename("C:\\a\\b\\c.."), content="c..")
  inspect(@win32.Path::basename("C:a\\b\\.."), content="..")
  inspect(@win32.Path::basename("a\\b\\..\\"), content="..")
}

///|
test "dirname extreme" {
  inspect(@win32.Path::dirname("a\\/"), content=".")
  inspect(@win32.Path::dirname("a/\\"), content=".")
  inspect(@win32.Path::dirname("a\\\\/"), content=".")
  inspect(@win32.Path::dirname("a///"), content=".")
  inspect(@win32.Path::dirname("\\\\?\\C:\\"), content="\\\\?\\C:\\")
  inspect(@win32.Path::dirname("\\\\?\\C:"), content="\\\\?\\C:")
  inspect(@win32.Path::dirname("\\\\?\\C:\\.."), content="\\\\?\\C:\\")
  inspect(
    @win32.Path::dirname("\\\\?\\C:\\temp\\..\\file"),
    content="\\\\?\\C:\\temp\\..",
  )
  inspect(
    @win32.Path::dirname("\\\\?\\UNC\\server\\.."),
    content="\\\\?\\UNC\\server",
  )
  inspect(
    @win32.Path::dirname("\\\\?\\UNC\\server\\share\\.."),
    content="\\\\?\\UNC\\server\\share",
  )
  // Node treats a bare `\\?\`/`\\.\` prefix as a UNC path with hostname
  // `?`/`.`; keep the full prefix instead.
  inspect(@win32.Path::dirname("\\\\?\\"), content="\\\\?\\")
  inspect(@win32.Path::dirname("\\\\.\\"), content="\\\\.\\")
  inspect(@win32.Path::dirname("\\\\.\\COM1"), content="\\\\.\\COM1")
  inspect(@win32.Path::dirname("C:a\\/b"), content="C:a\\")
  inspect(@win32.Path::dirname("C:\\a\\//b"), content="C:\\a\\/")
  inspect(@win32.Path::dirname("//server\\share/"), content="//server\\share/")
  inspect(
    @win32.Path::dirname("\\\\server//share"),
    content="\\\\server//share",
  )
  inspect(@win32.Path::dirname(" \\\\a\\b "), content=" \\\\a")
  inspect(@win32.Path::dirname("C:\\\\"), content="C:\\")
  inspect(@win32.Path::dirname("C:\\\\\\"), content="C:\\")
  inspect(@win32.Path::dirname("C:\\a\\b."), content="C:\\a")
  inspect(@win32.Path::dirname("C:\\a\\b.."), content="C:\\a")
  inspect(@win32.Path::dirname("C:\\a\\.."), content="C:\\a")
  inspect(@win32.Path::dirname("C:\\a\\."), content="C:\\a")
  inspect(@win32.Path::dirname("C:\\目录\\文件.txt"), content="C:\\目录")
  inspect(@win32.Path::dirname("C:\\a\\😀.txt"), content="C:\\a")
  inspect(@win32.Path::dirname("a\tb"), content=".")
  inspect(@win32.Path::dirname("a b\\c d"), content="a b")
  inspect(@win32.Path::dirname("///"), content="/")
  inspect(@win32.Path::dirname("////"), content="/")
  inspect(@win32.Path::dirname("\\\\\\"), content="\\")
  inspect(@win32.Path::dirname("\\\\server"), content="\\")
  inspect(@win32.Path::dirname("\\\\server\\"), content="\\")
  inspect(
    @win32.Path::dirname("\\\\server\\share\\.."),
    content="\\\\server\\share\\",
  )
  inspect(@win32.Path::dirname("C:\\a\\b\\c\\..\\"), content="C:\\a\\b\\c")
  inspect(@win32.Path::dirname("C:\\a\\b\\c.."), content="C:\\a\\b")
  inspect(@win32.Path::dirname("C:a\\b\\.."), content="C:a\\b")
  inspect(
    @win32.Path::dirname("\\\\server\\share\\folder\\..\\"),
    content="\\\\server\\share\\folder",
  )
}

///|
test "extname extreme" {
  inspect(@win32.Path::extname("a\\/"), content="")
  inspect(@win32.Path::extname("C:\\a\\b.."), content=".")
  inspect(@win32.Path::extname("C:\\a\\b."), content=".")
  inspect(@win32.Path::extname("C:\\a\\.."), content="")
  inspect(@win32.Path::extname("C:\\a\\."), content="")
  inspect(@win32.Path::extname("C:\\a\\.hidden"), content="")
  inspect(@win32.Path::extname("C:\\a\\..hidden"), content=".hidden")
  inspect(@win32.Path::extname(".."), content="")
  inspect(@win32.Path::extname("..."), content=".")
  inspect(@win32.Path::extname("C:\\目录\\文件.txt"), content=".txt")
  inspect(@win32.Path::extname("C:\\a\\😀.txt"), content=".txt")
  inspect(@win32.Path::extname("C:\\a\\b.tar.gz"), content=".gz")
  inspect(@win32.Path::extname("a b\\c d.txt"), content=".txt")
  inspect(@win32.Path::extname("C:\\a\\b.txt\\"), content=".txt")
  inspect(@win32.Path::extname("\\\\?\\C:\\a\\b.c"), content=".c")
  inspect(@win32.Path::extname("C:\\a\\.\\b.c"), content=".c")
  inspect(@win32.Path::extname("C:\\a\\..\\b."), content=".")
  inspect(@win32.Path::extname("a.b\\c"), content="")
  inspect(@win32.Path::extname("C:\\a\\b\\"), content="")
  inspect(@win32.Path::extname("C:\\a\\b\\c.txt\\\\"), content=".txt")
}

///|
test "root extreme" {
  // Node returns `\` for bare `\\?\`/`\\.\` prefixes (it parses them as a
  // UNC host); keep the full prefix instead.
  inspect(@win32.Path::root("\\\\?\\"), content="\\\\?\\")
  inspect(@win32.Path::root("\\\\.\\"), content="\\\\.\\")
  inspect(@win32.Path::root("\\\\?\\C:"), content="\\\\?\\C:")
  inspect(@win32.Path::root("\\\\?\\C:\\"), content="\\\\?\\C:\\")
  inspect(@win32.Path::root("\\\\.\\COM1"), content="\\\\.\\COM1")
  inspect(@win32.Path::root("///"), content="/")
  inspect(@win32.Path::root("////"), content="/")
  inspect(@win32.Path::root("\\\\\\"), content="\\")
  inspect(@win32.Path::root("C:\\\\"), content="C:\\")
  inspect(@win32.Path::root("C:\\\\\\"), content="C:\\")
  inspect(@win32.Path::root("\\\\server"), content="\\")
  inspect(@win32.Path::root("\\\\server\\"), content="\\")
  inspect(@win32.Path::root("\\\\server\\share"), content="\\\\server\\share")
  inspect(
    @win32.Path::root("\\\\server\\share\\"),
    content="\\\\server\\share\\",
  )
  inspect(@win32.Path::root("c:/temp"), content="c:/")
  inspect(@win32.Path::root("\\\\?\\UNC"), content="\\\\?\\UNC")
  inspect(@win32.Path::root("\\\\?\\UNC\\server"), content="\\\\?\\UNC\\")
  inspect(
    @win32.Path::root("\\\\?\\UNC\\server\\share\\file"),
    content="\\\\?\\UNC\\",
  )
}

///|
test "is_absolute extreme" {
  json_inspect(@win32.Path::is_absolute("\\\\?\\"), content=true)
  json_inspect(@win32.Path::is_absolute("\\\\.\\"), content=true)
  json_inspect(@win32.Path::is_absolute("///"), content=true)
  json_inspect(@win32.Path::is_absolute("////"), content=true)
  json_inspect(@win32.Path::is_absolute("\\\\\\"), content=true)
  json_inspect(@win32.Path::is_absolute("C:\\\\"), content=true)
  json_inspect(@win32.Path::is_absolute("C:\\\\\\"), content=true)
  json_inspect(@win32.Path::is_absolute("c:/temp"), content=true)
  json_inspect(@win32.Path::is_absolute(" \\\\a"), content=false)
  json_inspect(@win32.Path::is_absolute("a\\\\"), content=false)
  json_inspect(@win32.Path::is_absolute("\\\\?\\C:"), content=true)
  json_inspect(@win32.Path::is_absolute("\\\\?\\C:\\"), content=true)
  json_inspect(@win32.Path::is_absolute("\\\\server"), content=true)
  json_inspect(@win32.Path::is_absolute("\\\\server\\"), content=true)
}

///|
test "normalize extreme" {
  inspect(@win32.Path::normalize("a\\..\\..\\.."), content="..\\..")
  inspect(@win32.Path::normalize("..\\..\\a"), content="..\\..\\a")
  inspect(@win32.Path::normalize("C:\\a\\..\\..\\b"), content="C:\\b")
  inspect(@win32.Path::normalize("C:.."), content="C:..")
  inspect(@win32.Path::normalize("C:."), content="C:.")
  inspect(@win32.Path::normalize("C:..\\..\\a"), content="C:..\\..\\a")
  inspect(@win32.Path::normalize("C:\\..\\.."), content="C:\\")
  inspect(@win32.Path::normalize("\\..\\.."), content="\\")
  inspect(@win32.Path::normalize(".\\.."), content="..")
  inspect(@win32.Path::normalize("..\\."), content="..")
  inspect(@win32.Path::normalize("a\\\\..\\b"), content="b")
  inspect(@win32.Path::normalize("..\\a\\.."), content="..")
  inspect(@win32.Path::normalize("C:\\a\\\\.."), content="C:\\")
  inspect(@win32.Path::normalize("C:\\a\\..\\.."), content="C:\\")
  inspect(
    @win32.Path::normalize("\\\\server\\share\\..\\..\\.."),
    content="\\\\server\\share\\",
  )
  inspect(
    @win32.Path::normalize("\\\\server\\..\\.."),
    content="\\\\server\\..\\",
  )
  inspect(
    @win32.Path::normalize("\\\\?\\C:\\temp\\..\\file"),
    content="\\\\?\\C:\\file",
  )
  inspect(
    @win32.Path::normalize("\\\\?\\UNC\\server\\share\\..\\.."),
    content="\\\\?\\UNC",
  )
  inspect(
    @win32.Path::normalize("\\\\?\\UNC\\server\\.."),
    content="\\\\?\\UNC",
  )
  inspect(@win32.Path::normalize("\\\\?\\..\\a"), content="\\\\?\\a")
  inspect(@win32.Path::normalize("\\\\.\\..\\a"), content="\\\\.\\a")
  inspect(@win32.Path::normalize("\\\\.\\COM1\\..\\..\\a"), content="\\\\.\\a")
  // Node normalizes bare `\\?\`/`\\.\` prefixes into `\?\`/`\`; keep the
  // full prefix instead.
  inspect(@win32.Path::normalize("\\\\?\\"), content="\\\\?\\")
  inspect(@win32.Path::normalize("\\\\.\\"), content="\\\\.\\")
  inspect(@win32.Path::normalize("//"), content="\\")
  inspect(@win32.Path::normalize("///"), content="\\")
  inspect(@win32.Path::normalize("////"), content="\\")
  inspect(@win32.Path::normalize("\\\\\\"), content="\\")
  inspect(@win32.Path::normalize("C:\\\\"), content="C:\\")
  inspect(@win32.Path::normalize("C:\\\\\\"), content="C:\\")
  inspect(@win32.Path::normalize("C::\\foo"), content="C::\\foo")
  inspect(@win32.Path::normalize("a:b"), content="a:b")
  inspect(@win32.Path::normalize("a::b"), content="a::b")
  inspect(@win32.Path::normalize("C::"), content="C::")
  inspect(
    @win32.Path::normalize("\\\\server\\share\\"),
    content="\\\\server\\share\\",
  )
  inspect(@win32.Path::normalize("\\\\?\\C:"), content="\\\\?\\C:")
  inspect(@win32.Path::normalize("C:a\\..\\.."), content="C:..")
  inspect(@win32.Path::normalize("C:a\\..\\b"), content="C:b")
  inspect(@win32.Path::normalize("\\\\?\\C:\\.."), content="\\\\?\\")
  inspect(@win32.Path::normalize("..."), content="...")
  inspect(@win32.Path::normalize("...."), content="....")
  inspect(@win32.Path::normalize("C:\\...\\a"), content="C:\\...\\a")
  inspect(@win32.Path::normalize("C:\\a\\...\\b"), content="C:\\a\\...\\b")
  inspect(@win32.Path::normalize("C:\\a\\b\\c\\..\\"), content="C:\\a\\b\\")
  inspect(
    @win32.Path::normalize("\\\\server\\share\\folder\\..\\"),
    content="\\\\server\\share\\",
  )
  inspect(@win32.Path::normalize("C:\\a\\"), content="C:\\a\\")
  inspect(@win32.Path::normalize("C:\\\\a\\\\"), content="C:\\a\\")
  inspect(@win32.Path::normalize("a\\b\\..\\"), content="a\\")
  inspect(@win32.Path::normalize("C:\\a\\b\\c.."), content="C:\\a\\b\\c..")
  inspect(@win32.Path::normalize("C:a\\b\\.."), content="C:a")
}

///|
test "join extreme" {
  inspect(
    @win32.Path::join("\\\\?\\C:\\temp", "file"),
    content="\\\\?\\C:\\temp\\file",
  )
  inspect(
    @win32.Path::join("\\\\?\\C:\\temp", "\\file"),
    content="\\\\?\\C:\\temp\\file",
  )
  inspect(
    @win32.Path::join("\\\\server\\share", "\\file"),
    content="\\\\server\\share\\file",
  )
  inspect(@win32.Path::join("C:", ""), content="C:.")
  inspect(@win32.Path::join("C:", "a"), content="C:\\a")
  inspect(@win32.Path::join("C:\\", ""), content="C:\\")
  inspect(
    @win32.Path::join("\\\\server\\share", ""),
    content="\\\\server\\share\\",
  )
  inspect(@win32.Path::join("C:temp", "C:sub"), content="C:temp\\C:sub")
  inspect(@win32.Path::join("\\\\?\\C:\\temp", ""), content="\\\\?\\C:\\temp")
  inspect(@win32.Path::join("C:\\a", ".."), content="C:\\")
  inspect(@win32.Path::join("..", "b"), content="..\\b")
  inspect(@win32.Path::join("C:", "C:"), content="C:\\C:")
  inspect(@win32.Path::join("\\\\?\\", "a"), content="\\\\?\\a")
  inspect(
    @win32.Path::join("\\\\server\\share", "..\\..\\a"),
    content="\\\\server\\share\\a",
  )
  inspect(
    @win32.Path::join("\\\\?\\C:\\temp\\", "\\file"),
    content="\\\\?\\C:\\temp\\file",
  )
  inspect(@win32.Path::join("a", "C:"), content=".\\a\\C:")
  inspect(@win32.Path::join("", "C:"), content="C:.")
}

///|
test "relative extreme" {
  inspect(@win32.Path::relative(base="C:\\Foo", "C:\\foo\\bar"), content="bar")
  inspect(@win32.Path::relative(base="C:\\a\\b", "C:\\a\\b\\c\\.."), content="")
  inspect(@win32.Path::relative(base="C:/a/b", "C:\\a\\b"), content="")
  inspect(@win32.Path::relative(base="C:\\a", "c:\\b\\c"), content="..\\b\\c")
  inspect(@win32.Path::relative(base="C:\\A\\B", "c:\\a\\B\\c"), content="c")
  inspect(
    @win32.Path::relative(base="\\\\server\\share", "\\\\server\\share"),
    content="",
  )
  inspect(@win32.Path::relative(base="C:\\a\\..\\b", "C:\\b\\c"), content="c")
  inspect(
    @win32.Path::relative(base="\\\\server\\share\\a", "\\\\server\\share\\b"),
    content="..\\b",
  )
  inspect(@win32.Path::relative(base="C:\\", "C:\\"), content="")
  inspect(@win32.Path::relative(base="C:\\a", "C:\\a"), content="")
  inspect(
    @win32.Path::relative(base="\\\\server\\share\\", "\\\\server\\share\\a"),
    content="a",
  )
  inspect(@win32.Path::relative(base="C:\\a\\b\\c", "C:\\a\\b\\c"), content="")
  inspect(@win32.Path::relative(base="C:\\ä", "C:\\Ä\\x"), content="x")
  inspect(
    @win32.Path::relative(base="\\\\?\\C:\\a", "\\\\?\\C:\\a\\b"),
    content="b",
  )
  inspect(
    @win32.Path::relative(base="\\\\?\\C:\\a", "C:\\a\\b"),
    content="C:\\a\\b",
  )
  inspect(@win32.Path::relative(base="C:\\ABC", "C:\\AB"), content="..\\AB")
  inspect(@win32.Path::relative(base="C:\\AB", "C:\\ABC"), content="..\\ABC")
  inspect(@win32.Path::relative(base="C:\\a\\bX", "C:\\a\\b"), content="..\\b")
  inspect(@win32.Path::relative(base="C:\\a\\b", "C:\\a\\bX"), content="..\\bX")
  inspect(@win32.Path::relative(base="c:\\a\\B", "C:\\a\\b\\x"), content="x")
  inspect(@win32.Path::relative(base="C:\\a", "c:\\a\\b"), content="b")
  inspect(
    @win32.Path::relative(base="\\\\server\\share", "\\\\server\\share\\a"),
    content="a",
  )
  inspect(@win32.Path::relative(base="C:\\ab", "c:\\a"), content="..\\a")
}
