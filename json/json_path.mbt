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
/// The current location of a JSON decode, rendered as a JSON Pointer.
///
/// A context passed to `FromJson::from_json` is temporary: collection decoders
/// may reuse its nodes for later elements. Call `copy()` before retaining a
/// context, including one returned by `add_key` or `add_index`. Copying also
/// snapshots every ancestor, so nested locations remain stable.
///
/// Use `error(message)` to create an error with a stable location. `JsonPath`
/// remains an alias for compatibility with existing decoders.
#alias(JsonPath, deprecated)
#derive(Eq)
enum DecodeContext {
  Root
  Key(DecodeContext, mut key~ : String)
  Index(DecodeContext, mut index~ : Int32)
}

///|
/// Copies this location and all its ancestors into an independent snapshot.
/// The snapshot may be retained after decoding continues or finishes.
pub fn DecodeContext::copy(self : DecodeContext) -> DecodeContext {
  match self {
    Root => Root
    Key(parent, key~) => Key(parent.copy(), key~)
    Index(parent, index~) => Index(parent.copy(), index~)
  }
}

///|
/// Creates a decode error with an independent snapshot of the current location.
/// Prefer this over constructing `JsonDecodeError` with a temporary context.
pub fn DecodeContext::error(
  self : DecodeContext,
  message : String,
) -> JsonDecodeError {
  JsonDecodeError((self.copy(), message))
}

///|
/// Creates a child context for an array index, sharing this context as its parent.
/// Call `copy()` to retain the resulting location independently of decoding.
pub fn DecodeContext::add_index(
  self : DecodeContext,
  index : Int32,
) -> DecodeContext {
  Index(self, index~)
}

///|
/// Creates a child context for an object key, sharing this context as its parent.
/// Call `copy()` to retain the resulting location independently of decoding.
pub fn DecodeContext::add_key(
  self : DecodeContext,
  key : String,
) -> DecodeContext {
  Key(self, key~)
}

///|
pub impl Show for DecodeContext with fn output(self, logger) {
  // Helper to write a JSON Pointer token without intermediate allocations
  fn write_token(logger : &Logger, token : String) -> Unit {
    if !token.contains_any(chars="~/") {
      logger.write_string(token)
      return
    }
    for ch in token {
      match ch {
        '~' => logger <+ "~0"
        '/' => logger <+ "~1"
        _ => logger.write_char(ch)
      }
    }
  }

  // Recursively build the JSON Pointer string
  fn build_path(path : DecodeContext, logger : &Logger) -> Unit {
    match path {
      Root => ()
      Key(parent, key~) =>
        logger <+
          "\{cb => build_path(parent, cb)}/\{cb => write_token(cb, key)}"
      Index(parent, index~) =>
        logger <+
          "\{cb => build_path(parent, cb)}/\{cb => cb.write_object(index)}"
    }
  }

  build_path(self, logger)
}

///|
pub impl ToJson for DecodeContext with fn to_json(self) {
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
  let path : DecodeContext = Key(Index(Root, index=0), key="foo")
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
