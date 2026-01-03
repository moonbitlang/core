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
enum JsonPath {
  Root
  Key(JsonPath, mut key~ : String)
  Index(JsonPath, mut index~ : Int)
} derive(Eq)

///|
pub fn JsonPath::add_index(self : JsonPath, index : Int) -> JsonPath {
  Index(self, index~)
}

///|
pub fn JsonPath::add_key(self : JsonPath, key : String) -> JsonPath {
  Key(self, key~)
}

///|
pub impl Show for JsonPath with output(self, logger) {
  // Helper to write a JSON Pointer token without intermediate allocations
  fn write_token(logger : &Logger, token : String) -> Unit {
    if !token.contains_any(chars="~/") {
      logger.write_string(token)
      return
    }
    for ch in token.iter() {
      match ch {
        '~' => logger.write_string("~0")
        '/' => logger.write_string("~1")
        _ => logger.write_char(ch)
      }
    }
  }

  // Recursively build the JSON Pointer string
  fn build_path(path : JsonPath, logger : &Logger) -> Unit {
    match path {
      Root => ()
      Key(parent, key~) => {
        build_path(parent, logger)
        logger.write_char('/')
        write_token(logger, key)
      }
      Index(parent, index~) => {
        build_path(parent, logger)
        logger.write_char('/')
        logger.write_object(index)
      }
    }
  }

  build_path(self, logger)
}

///|
pub impl ToJson for JsonPath with to_json(self) {
  String(self.to_string())
}

///|
test "show JsonPath - JSON Pointer format" {
  // Test root path
  @builtin.inspect(Root, content="")

  // Test simple key access
  @builtin.inspect(Root.add_key("foo"), content="/foo")

  // Test simple array index
  @builtin.inspect(Root.add_index(0), content="/0")

  // Test mixed path
  let path : JsonPath = Key(Index(Root, index=0), key="foo")
  @builtin.inspect(path, content="/0/foo")
  @builtin.inspect(path.add_index(1), content="/0/foo/1")
  @builtin.inspect(path.add_key("bar"), content="/0/foo/bar")

  // Test complex paths
  @builtin.inspect(
    Root.add_key("foo").add_key("foo1").add_index(2),
    content="/foo/foo1/2",
  )
  @builtin.inspect(Root.add_key("foo").add_key("foo1"), content="/foo/foo1")
  @builtin.inspect(
    Root.add_key("foo").add_key("foo1").add_index(2).add_key("bar"),
    content="/foo/foo1/2/bar",
  )
  @builtin.inspect(
    Root.add_key("foo").add_key("foo1").add_index(2).add_key("bar").add_index(3),
    content="/foo/foo1/2/bar/3",
  )
  @builtin.inspect(
    Root
    .add_key("foo")
    .add_key("foo1")
    .add_index(2)
    .add_key("bar")
    .add_index(3)
    .add_key("baz"),
    content="/foo/foo1/2/bar/3/baz",
  )
  @builtin.inspect(
    Root.add_key("foo").add_key("foo1").add_index(2).add_index(3).add_index(4),
    content="/foo/foo1/2/3/4",
  )
}

///|
test "show JsonPath - special characters escaping" {
  // Test tilde escaping (~ becomes ~0)
  @builtin.inspect(Root.add_key("foo~bar"), content="/foo~0bar")
  @builtin.inspect(Root.add_key("foo~~bar~~"), content="/foo~0~0bar~0~0")

  // Test slash escaping (/ becomes ~1)
  @builtin.inspect(Root.add_key("foo/bar"), content="/foo~1bar")
  @builtin.inspect(Root.add_key("foo//bar//"), content="/foo~1~1bar~1~1")

  // Test both special characters
  @builtin.inspect(Root.add_key("foo~/bar"), content="/foo~0~1bar")
  @builtin.inspect(Root.add_key("~foo/bar~"), content="/~0foo~1bar~0")

  // Test complex path with special characters
  @builtin.inspect(
    Root.add_key("a/b").add_key("c~d").add_index(0).add_key("e~/f"),
    content="/a~1b/c~0d/0/e~0~1f",
  )

  // Test empty string key
  @builtin.inspect(Root.add_key(""), content="/")

  // Test key with only special characters
  @builtin.inspect(Root.add_key("~/"), content="/~0~1")
}

///|
test "show JsonPath - RFC 6901 compliance examples" {
  // Examples from RFC 6901
  // ""           // the whole document
  @builtin.inspect(Root, content="")

  // "/foo"       ["bar", "baz"]
  @builtin.inspect(Root.add_key("foo"), content="/foo")

  // "/foo/0"     "bar"
  @builtin.inspect(Root.add_key("foo").add_index(0), content="/foo/0")

  // "/"          "value"  (empty string key)
  @builtin.inspect(Root.add_key(""), content="/")

  // "/a~1b"      1  (key is "a/b")
  @builtin.inspect(Root.add_key("a/b"), content="/a~1b")

  // "/c%d"       2  (key is "c%d", % doesn't need escaping)
  @builtin.inspect(Root.add_key("c%d"), content="/c%d")

  // "/e^f"       3  (key is "e^f", ^ doesn't need escaping)
  @builtin.inspect(Root.add_key("e^f"), content="/e^f")

  // "/g|h"       4  (key is "g|h", | doesn't need escaping)
  @builtin.inspect(Root.add_key("g|h"), content="/g|h")

  // "/i\\j"      5  (key is "i\j", \ doesn't need escaping)
  @builtin.inspect(Root.add_key("i\\j"), content="/i\\j")

  // "/k\"l"      6  (key is "k"l", " doesn't need escaping)
  @builtin.inspect(Root.add_key("k\"l"), content="/k\"l")

  // "/ "         7  (key is " ", space doesn't need escaping)
  @builtin.inspect(Root.add_key(" "), content="/ ")

  // "/m~0n"      8  (key is "m~n")
  @builtin.inspect(Root.add_key("m~n"), content="/m~0n")
}
