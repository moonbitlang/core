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
test "basename node fixtures" {
  inspect(@posix.basename(""), content="")
  inspect(@posix.basename("/"), content="")
  inspect(@posix.basename("//"), content="")
  inspect(@posix.basename("///"), content="")
  inspect(@posix.basename("a"), content="a")
  inspect(@posix.basename("a/"), content="a")
  inspect(@posix.basename("a//"), content="a")
  inspect(@posix.basename("file.txt/"), content="file.txt")
  inspect(@posix.basename("/path/file.txt/"), content="file.txt")
  inspect(@posix.basename("/a//b//c/"), content="c")
  inspect(@posix.basename("./a"), content="a")
  inspect(@posix.basename("../a"), content="a")
  inspect(@posix.basename("a/."), content=".")
  inspect(@posix.basename("a/.."), content="..")
}

///|
test "dirname node fixtures" {
  inspect(@posix.dirname(""), content=".")
  inspect(@posix.dirname("a"), content=".")
  inspect(@posix.dirname("a/"), content=".")
  inspect(@posix.dirname("a//"), content=".")
  inspect(@posix.dirname("/"), content="/")
  inspect(@posix.dirname("//"), content="/")
  inspect(@posix.dirname("///"), content="/")
  inspect(@posix.dirname("////"), content="/")
  inspect(@posix.dirname("/a"), content="/")
  inspect(@posix.dirname("//a"), content="//")
  inspect(@posix.dirname("///a"), content="//")
  inspect(@posix.dirname("./a"), content=".")
  inspect(@posix.dirname("../a"), content="..")
  inspect(@posix.dirname("a/."), content="a")
  inspect(@posix.dirname("a/.."), content="a")
  inspect(@posix.dirname("a//b"), content="a/")
  inspect(@posix.dirname("a///b"), content="a//")
  inspect(@posix.dirname("/a//b//c"), content="/a//b/")
  inspect(@posix.dirname("/a//b//c/"), content="/a//b/")
}

///|
test "extname node dotfile fixtures" {
  inspect(@posix.extname(""), content="")
  inspect(@posix.extname("file"), content="")
  inspect(@posix.extname("/path/file"), content="")
  inspect(@posix.extname("project/main.mbt.md"), content=".md")
  inspect(@posix.extname("file.tar.gz"), content=".gz")
  inspect(@posix.extname("file.c++"), content=".c++")
  inspect(@posix.extname("file.123"), content=".123")
  inspect(@posix.extname("file.-"), content=".-")
  inspect(@posix.extname(".hidden"), content="")
  inspect(@posix.extname("/path/.hidden"), content="")
  inspect(@posix.extname(".hidden.txt"), content=".txt")
  inspect(@posix.extname("/path/.hidden.txt"), content=".txt")
  inspect(@posix.extname("."), content="")
  inspect(@posix.extname(".."), content="")
  inspect(@posix.extname("./file"), content="")
  inspect(@posix.extname("../file"), content="")
  inspect(@posix.extname("/a/."), content="")
  inspect(@posix.extname("/a/.."), content="")
  inspect(@posix.extname(".txt"), content="")
  inspect(@posix.extname("a.b.c"), content=".c")
  inspect(@posix.extname("a."), content=".")
  inspect(@posix.extname("/path/a."), content=".")
  inspect(@posix.extname("file.txt/"), content=".txt")
  inspect(@posix.extname("/path/file.txt/"), content=".txt")
}

///|
test "is_absolute edge cases" {
  json_inspect(@posix.is_absolute(""), content=false)
  json_inspect(@posix.is_absolute(" "), content=false)
  json_inspect(@posix.is_absolute("  /"), content=false)
  json_inspect(@posix.is_absolute("/"), content=true)
  json_inspect(@posix.is_absolute("//"), content=true)
  json_inspect(@posix.is_absolute("///"), content=true)
  json_inspect(@posix.is_absolute("/a"), content=true)
  json_inspect(@posix.is_absolute("/a/b"), content=true)
  json_inspect(@posix.is_absolute("a"), content=false)
  json_inspect(@posix.is_absolute("./a"), content=false)
  json_inspect(@posix.is_absolute("../a"), content=false)
  json_inspect(@posix.is_absolute("a/b"), content=false)
  json_inspect(@posix.is_absolute("a/../b"), content=false)
  json_inspect(@posix.is_absolute("."), content=false)
  json_inspect(@posix.is_absolute(".."), content=false)
  json_inspect(@posix.is_absolute("./"), content=false)
  json_inspect(@posix.is_absolute("../"), content=false)
  json_inspect(@posix.is_absolute("/."), content=true)
  json_inspect(@posix.is_absolute("/.."), content=true)
}

///|
test "join node fixtures" {
  inspect(@posix.join("a", "b"), content="a/b")
  inspect(@posix.join("a", "/b"), content="a/b")
  inspect(@posix.join("/a", "/b"), content="/a/b")
  inspect(@posix.join("a", "../b"), content="b")
  inspect(@posix.join("a", "./b"), content="a/b")
  inspect(@posix.join("./a", "b"), content="a/b")
  inspect(@posix.join("../a", "b"), content="../a/b")
  inspect(@posix.join("", ""), content=".")
  inspect(@posix.join("a", ""), content="a")
  inspect(@posix.join("", "b"), content="b")
  inspect(@posix.join("", "/abs"), content="/abs")
  inspect(@posix.join("a//", "b"), content="a/b")
  inspect(@posix.join("a///", "b"), content="a/b")
  inspect(@posix.join("a//b", "c"), content="a/b/c")
  inspect(@posix.join("a", "b//c"), content="a/b/c")
  inspect(@posix.join("/", "a"), content="/a")
  inspect(@posix.join("/", "/a"), content="/a")
  inspect(@posix.join("//", "a"), content="/a")
  inspect(@posix.join("a/b", "../c"), content="a/c")
  inspect(@posix.join("/a/b", "../c"), content="/a/c")
  inspect(@posix.join("a", ".hidden"), content="a/.hidden")
}

///|
test "normalize node fixtures" {
  inspect(@posix.normalize(""), content=".")
  inspect(@posix.normalize("."), content=".")
  inspect(@posix.normalize("./"), content="./")
  inspect(@posix.normalize("a/."), content="a")
  inspect(@posix.normalize("a/./"), content="a/")
  inspect(@posix.normalize("./a"), content="a")
  inspect(@posix.normalize("./a/"), content="a/")
  inspect(@posix.normalize("a/./b"), content="a/b")
  inspect(@posix.normalize(".."), content="..")
  inspect(@posix.normalize("../"), content="../")
  inspect(@posix.normalize("a/.."), content=".")
  inspect(@posix.normalize("a/../"), content="./")
  inspect(@posix.normalize("../a"), content="../a")
  inspect(@posix.normalize("a/../b"), content="b")
  inspect(@posix.normalize("a/b/.."), content="a")
  inspect(@posix.normalize("a/b/../"), content="a/")
  inspect(@posix.normalize("a/b/../c"), content="a/c")
  inspect(@posix.normalize("a//b"), content="a/b")
  inspect(@posix.normalize("a///b"), content="a/b")
  inspect(@posix.normalize("//a//b"), content="/a/b")
  inspect(@posix.normalize("///a///b"), content="/a/b")
  inspect(@posix.normalize("//"), content="/")
  inspect(@posix.normalize("///"), content="/")
  inspect(@posix.normalize("/."), content="/")
  inspect(@posix.normalize("/./"), content="/")
  inspect(@posix.normalize("/.."), content="/")
  inspect(@posix.normalize("/../"), content="/")
  inspect(@posix.normalize("/a/.."), content="/")
  inspect(@posix.normalize("/a/../"), content="/")
  inspect(@posix.normalize("/a/../b"), content="/b")
  inspect(@posix.normalize("a/b/c/"), content="a/b/c/")
  inspect(@posix.normalize("a/./b/../c/"), content="a/c/")
  inspect(@posix.normalize("a/b/../../../c"), content="../c")
  inspect(@posix.normalize("./.hidden"), content=".hidden")
  inspect(@posix.normalize("a/./.hidden"), content="a/.hidden")
  inspect(@posix.normalize("a/../.hidden"), content=".hidden")
}

///|
test "relative node fixtures" {
  inspect(@posix.relative(base="/home/user", "/home/user/proj"), content="proj")
  inspect(@posix.relative(base="/home/user/proj", "/home/user"), content="..")
  inspect(@posix.relative(base="/home/user", "/home/user"), content="")
  inspect(@posix.relative(base="/a/b", "/a/./b"), content="")
  inspect(@posix.relative(base="/a/b", "/a/c/../b"), content="")
  inspect(@posix.relative(base="/", "/home"), content="home")
  inspect(@posix.relative(base="/home", "/"), content="..")
  inspect(@posix.relative(base="/a/b/c/d", "/a/b/e/f"), content="../../e/f")
  inspect(@posix.relative(base="/a/b/c/d/e", "/a/f"), content="../../../../f")
  inspect(
    @posix.relative(base="/home/.config", "/home/.local"),
    content="../.local",
  )
  inspect(@posix.relative(base="/home", "/home/.hidden"), content=".hidden")
  inspect(@posix.relative(base="/home/user", "/home/user/."), content="")
  inspect(@posix.relative(base="/home/user/.", "/home/user"), content="")
  inspect(@posix.relative(base="/home/user", "/home/user/.."), content="..")
  inspect(@posix.relative(base="/a/b/c", "/a/b/c/../d"), content="../d")
  inspect(@posix.relative(base="/a/b/c/../d", "/a/b/c"), content="../c")
}

///|
test "resolve absolute fixtures" {
  inspect(@posix.resolve("/a/../b/c"), content="/b/c")
  inspect(@posix.resolve("/a/b/c/../../.."), content="/")
  inspect(@posix.resolve("/a/./b/c"), content="/a/b/c")
  inspect(@posix.resolve("/a/b/../../c"), content="/c")
}

///|
test "resolve drops trailing separators except root" {
  inspect(@posix.resolve("/foo/"), content="/foo")
  inspect(@posix.resolve("/foo/bar/"), content="/foo/bar")
  inspect(@posix.resolve("/foo//bar//"), content="/foo/bar")
  inspect(@posix.resolve("/"), content="/")
  inspect(@posix.resolve("//"), content="/")
  inspect(@posix.resolve("///"), content="/")
}

///|
test "constants and separators" {
  inspect(@posix.delimiter, content=":")
  inspect(@posix.sep, content="/")
}
