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
test "debug" {
  debug_inspect(@posix.Path::join("a", "b"), content="Path(\"a/b\")")
}

///|
test "basename node fixtures" {
  inspect(@posix.Path::basename(""), content="")
  inspect(@posix.Path::basename("/"), content="")
  inspect(@posix.Path::basename("//"), content="")
  inspect(@posix.Path::basename("///"), content="")
  inspect(@posix.Path::basename("a"), content="a")
  inspect(@posix.Path::basename("a/"), content="a")
  inspect(@posix.Path::basename("a//"), content="a")
  inspect(@posix.Path::basename("file.txt/"), content="file.txt")
  inspect(@posix.Path::basename("/path/file.txt/"), content="file.txt")
  inspect(@posix.Path::basename("/a//b//c/"), content="c")
  inspect(@posix.Path::basename("./a"), content="a")
  inspect(@posix.Path::basename("../a"), content="a")
  inspect(@posix.Path::basename("a/."), content=".")
  inspect(@posix.Path::basename("a/.."), content="..")
}

///|
test "dirname node fixtures" {
  inspect(@posix.Path::dirname(""), content=".")
  inspect(@posix.Path::dirname("a"), content=".")
  inspect(@posix.Path::dirname("a/"), content=".")
  inspect(@posix.Path::dirname("a//"), content=".")
  inspect(@posix.Path::dirname("/"), content="/")
  inspect(@posix.Path::dirname("//"), content="/")
  inspect(@posix.Path::dirname("///"), content="/")
  inspect(@posix.Path::dirname("////"), content="/")
  inspect(@posix.Path::dirname("/a"), content="/")
  inspect(@posix.Path::dirname("//a"), content="//")
  inspect(@posix.Path::dirname("///a"), content="//")
  inspect(@posix.Path::dirname("./a"), content=".")
  inspect(@posix.Path::dirname("../a"), content="..")
  inspect(@posix.Path::dirname("a/."), content="a")
  inspect(@posix.Path::dirname("a/.."), content="a")
  inspect(@posix.Path::dirname("a//b"), content="a/")
  inspect(@posix.Path::dirname("a///b"), content="a//")
  inspect(@posix.Path::dirname("/a//b//c"), content="/a//b/")
  inspect(@posix.Path::dirname("/a//b//c/"), content="/a//b/")
}

///|
test "extname node dotfile fixtures" {
  inspect(@posix.Path::extname(""), content="")
  inspect(@posix.Path::extname("file"), content="")
  inspect(@posix.Path::extname("/path/file"), content="")
  inspect(@posix.Path::extname("project/main.mbt.md"), content=".md")
  inspect(@posix.Path::extname("file.tar.gz"), content=".gz")
  inspect(@posix.Path::extname("file.c++"), content=".c++")
  inspect(@posix.Path::extname("file.123"), content=".123")
  inspect(@posix.Path::extname("file.-"), content=".-")
  inspect(@posix.Path::extname(".hidden"), content="")
  inspect(@posix.Path::extname("/path/.hidden"), content="")
  inspect(@posix.Path::extname(".hidden.txt"), content=".txt")
  inspect(@posix.Path::extname("/path/.hidden.txt"), content=".txt")
  inspect(@posix.Path::extname("."), content="")
  inspect(@posix.Path::extname(".."), content="")
  inspect(@posix.Path::extname("./file"), content="")
  inspect(@posix.Path::extname("../file"), content="")
  inspect(@posix.Path::extname("/a/."), content="")
  inspect(@posix.Path::extname("/a/.."), content="")
  inspect(@posix.Path::extname(".txt"), content="")
  inspect(@posix.Path::extname("a.b.c"), content=".c")
  inspect(@posix.Path::extname("a."), content=".")
  inspect(@posix.Path::extname("/path/a."), content=".")
  inspect(@posix.Path::extname("file.txt/"), content=".txt")
  inspect(@posix.Path::extname("/path/file.txt/"), content=".txt")
}

///|
test "is_absolute edge cases" {
  json_inspect(@posix.Path::is_absolute(""), content=false)
  json_inspect(@posix.Path::is_absolute(" "), content=false)
  json_inspect(@posix.Path::is_absolute("  /"), content=false)
  json_inspect(@posix.Path::is_absolute("/"), content=true)
  json_inspect(@posix.Path::is_absolute("//"), content=true)
  json_inspect(@posix.Path::is_absolute("///"), content=true)
  json_inspect(@posix.Path::is_absolute("/a"), content=true)
  json_inspect(@posix.Path::is_absolute("/a/b"), content=true)
  json_inspect(@posix.Path::is_absolute("a"), content=false)
  json_inspect(@posix.Path::is_absolute("./a"), content=false)
  json_inspect(@posix.Path::is_absolute("../a"), content=false)
  json_inspect(@posix.Path::is_absolute("a/b"), content=false)
  json_inspect(@posix.Path::is_absolute("a/../b"), content=false)
  json_inspect(@posix.Path::is_absolute("."), content=false)
  json_inspect(@posix.Path::is_absolute(".."), content=false)
  json_inspect(@posix.Path::is_absolute("./"), content=false)
  json_inspect(@posix.Path::is_absolute("../"), content=false)
  json_inspect(@posix.Path::is_absolute("/."), content=true)
  json_inspect(@posix.Path::is_absolute("/.."), content=true)
}

///|
test "join node fixtures" {
  inspect(@posix.Path::join("a", "b"), content="a/b")
  inspect(@posix.Path::join("a", "/b"), content="a/b")
  inspect(@posix.Path::join("/a", "/b"), content="/a/b")
  inspect(@posix.Path::join("a", "../b"), content="b")
  inspect(@posix.Path::join("a", "./b"), content="a/b")
  inspect(@posix.Path::join("./a", "b"), content="a/b")
  inspect(@posix.Path::join("../a", "b"), content="../a/b")
  inspect(@posix.Path::join("", ""), content=".")
  inspect(@posix.Path::join("a", ""), content="a")
  inspect(@posix.Path::join("", "b"), content="b")
  inspect(@posix.Path::join("", "/abs"), content="/abs")
  inspect(@posix.Path::join("a//", "b"), content="a/b")
  inspect(@posix.Path::join("a///", "b"), content="a/b")
  inspect(@posix.Path::join("a//b", "c"), content="a/b/c")
  inspect(@posix.Path::join("a", "b//c"), content="a/b/c")
  inspect(@posix.Path::join("/", "a"), content="/a")
  inspect(@posix.Path::join("/", "/a"), content="/a")
  inspect(@posix.Path::join("//", "a"), content="/a")
  inspect(@posix.Path::join("a/b", "../c"), content="a/c")
  inspect(@posix.Path::join("/a/b", "../c"), content="/a/c")
  inspect(@posix.Path::join("a", ".hidden"), content="a/.hidden")
}

///|
test "normalize node fixtures" {
  inspect(@posix.Path::normalize(""), content=".")
  inspect(@posix.Path::normalize("."), content=".")
  inspect(@posix.Path::normalize("./"), content="./")
  inspect(@posix.Path::normalize("a/."), content="a")
  inspect(@posix.Path::normalize("a/./"), content="a/")
  inspect(@posix.Path::normalize("./a"), content="a")
  inspect(@posix.Path::normalize("./a/"), content="a/")
  inspect(@posix.Path::normalize("a/./b"), content="a/b")
  inspect(@posix.Path::normalize(".."), content="..")
  inspect(@posix.Path::normalize("../"), content="../")
  inspect(@posix.Path::normalize("a/.."), content=".")
  inspect(@posix.Path::normalize("a/../"), content="./")
  inspect(@posix.Path::normalize("../a"), content="../a")
  inspect(@posix.Path::normalize("a/../b"), content="b")
  inspect(@posix.Path::normalize("a/b/.."), content="a")
  inspect(@posix.Path::normalize("a/b/../"), content="a/")
  inspect(@posix.Path::normalize("a/b/../c"), content="a/c")
  inspect(@posix.Path::normalize("a//b"), content="a/b")
  inspect(@posix.Path::normalize("a///b"), content="a/b")
  inspect(@posix.Path::normalize("//a//b"), content="/a/b")
  inspect(@posix.Path::normalize("///a///b"), content="/a/b")
  inspect(@posix.Path::normalize("//"), content="/")
  inspect(@posix.Path::normalize("///"), content="/")
  inspect(@posix.Path::normalize("/."), content="/")
  inspect(@posix.Path::normalize("/./"), content="/")
  inspect(@posix.Path::normalize("/.."), content="/")
  inspect(@posix.Path::normalize("/../"), content="/")
  inspect(@posix.Path::normalize("/a/.."), content="/")
  inspect(@posix.Path::normalize("/a/../"), content="/")
  inspect(@posix.Path::normalize("/a/../b"), content="/b")
  inspect(@posix.Path::normalize("a/b/c/"), content="a/b/c/")
  inspect(@posix.Path::normalize("a/./b/../c/"), content="a/c/")
  inspect(@posix.Path::normalize("a/b/../../../c"), content="../c")
  inspect(@posix.Path::normalize("./.hidden"), content=".hidden")
  inspect(@posix.Path::normalize("a/./.hidden"), content="a/.hidden")
  inspect(@posix.Path::normalize("a/../.hidden"), content=".hidden")
}

///|
test "relative node fixtures" {
  inspect(
    @posix.Path::relative(base="/home/user", "/home/user/proj"),
    content="proj",
  )
  inspect(
    @posix.Path::relative(base="/home/user/proj", "/home/user"),
    content="..",
  )
  inspect(@posix.Path::relative(base="/home/user", "/home/user"), content="")
  inspect(@posix.Path::relative(base="/a/b", "/a/./b"), content="")
  inspect(@posix.Path::relative(base="/a/b", "/a/c/../b"), content="")
  inspect(@posix.Path::relative(base="/", "/home"), content="home")
  inspect(@posix.Path::relative(base="/home", "/"), content="..")
  inspect(
    @posix.Path::relative(base="/a/b/c/d", "/a/b/e/f"),
    content="../../e/f",
  )
  inspect(
    @posix.Path::relative(base="/a/b/c/d/e", "/a/f"),
    content="../../../../f",
  )
  inspect(
    @posix.Path::relative(base="/home/.config", "/home/.local"),
    content="../.local",
  )
  inspect(
    @posix.Path::relative(base="/home", "/home/.hidden"),
    content=".hidden",
  )
  inspect(@posix.Path::relative(base="/home/user", "/home/user/."), content="")
  inspect(@posix.Path::relative(base="/home/user/.", "/home/user"), content="")
  inspect(
    @posix.Path::relative(base="/home/user", "/home/user/.."),
    content="..",
  )
  inspect(@posix.Path::relative(base="/a/b/c", "/a/b/c/../d"), content="../d")
  inspect(@posix.Path::relative(base="/a/b/c/../d", "/a/b/c"), content="../c")
}

///|
test "resolve absolute fixtures" {
  inspect(@posix.Path::resolve("/a/../b/c"), content="/b/c")
  inspect(@posix.Path::resolve("/a/b/c/../../.."), content="/")
  inspect(@posix.Path::resolve("/a/./b/c"), content="/a/b/c")
  inspect(@posix.Path::resolve("/a/b/../../c"), content="/c")
}

///|
test "resolve drops trailing separators except root" {
  inspect(@posix.Path::resolve("/foo/"), content="/foo")
  inspect(@posix.Path::resolve("/foo/bar/"), content="/foo/bar")
  inspect(@posix.Path::resolve("/foo//bar//"), content="/foo/bar")
  inspect(@posix.Path::resolve("/"), content="/")
  inspect(@posix.Path::resolve("//"), content="/")
  inspect(@posix.Path::resolve("///"), content="/")
}

///|
test "constants and separators" {
  inspect(@posix.delimiter, content=":")
  inspect(@posix.sep, content="/")
}
