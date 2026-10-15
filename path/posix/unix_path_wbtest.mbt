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
test "UnixPath absolute normalization" {
  inspect(UnixPath::parse("/../folder/file"), content="/folder/file")
  inspect(UnixPath::parse("/folder/file"), content="/folder/file")
  inspect(UnixPath::parse("/"), content="/")
  inspect(UnixPath::parse("/."), content="/")
  inspect(UnixPath::parse("/./"), content="/")
  inspect(UnixPath::parse("/.."), content="/")
  inspect(UnixPath::parse("/../"), content="/")
  inspect(UnixPath::parse("/a/.."), content="/")
  inspect(UnixPath::parse("/a/../"), content="/")
  inspect(UnixPath::parse("/a/../b"), content="/b")
}

///|
test "UnixPath relative normalization" {
  inspect(UnixPath::parse(""), content=".")
  inspect(UnixPath::parse("."), content=".")
  inspect(UnixPath::parse("./"), content="./")
  inspect(UnixPath::parse("./folder/file"), content="folder/file")
  inspect(
    UnixPath::parse("containers/finger_tree"),
    content="containers/finger_tree",
  )
  inspect(
    UnixPath::parse("containers/finger_tree/finger_tree.mbt"),
    content="containers/finger_tree/finger_tree.mbt",
  )
  inspect(UnixPath::parse(".."), content="..")
  inspect(UnixPath::parse("../"), content="../")
  inspect(UnixPath::parse("a/.."), content=".")
  inspect(UnixPath::parse("a/../"), content="./")
  inspect(UnixPath::parse("../a"), content="../a")
  inspect(UnixPath::parse("a/../b"), content="b")
  inspect(UnixPath::parse("a/b/.."), content="a")
  inspect(UnixPath::parse("a/b/../"), content="a/")
  inspect(UnixPath::parse("a/b/../c"), content="a/c")
}

///|
test "UnixPath slash and trailing separator normalization" {
  inspect(UnixPath::parse("./a//b////c"), content="a/b/c")
  inspect(
    UnixPath::parse("///home/username/project"),
    content="/home/username/project",
  )
  inspect(UnixPath::parse(".//a/b//c/e////d"), content="a/b/c/e/d")
  inspect(UnixPath::parse("//"), content="/")
  inspect(UnixPath::parse("///"), content="/")
  inspect(UnixPath::parse("//a//b"), content="/a/b")
  inspect(UnixPath::parse("///a///b"), content="/a/b")
  inspect(UnixPath::parse("/folder//"), content="/folder/")
  inspect(UnixPath::parse("./a/b/c///"), content="a/b/c/")
  inspect(UnixPath::parse("./a/b/c////"), content="a/b/c/")
  inspect(UnixPath::parse("a/./"), content="a/")
  inspect(UnixPath::parse("a/b/c/"), content="a/b/c/")
  inspect(UnixPath::parse("a/./b/../c/"), content="a/c/")
}
