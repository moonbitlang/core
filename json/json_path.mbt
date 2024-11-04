// Copyright 2024 International Digital Economy Academy
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
  Key(JsonPath, mut ~key : String)
  Index(JsonPath, mut ~index : Int)
} derive(Eq)

///|
pub fn add_index(self : JsonPath, index : Int) -> JsonPath {
  Index(self, ~index)
}

///|
pub fn add_key(self : JsonPath, key : String) -> JsonPath {
  Key(self, ~key)
}

///|
pub fn output(self : JsonPath, logger : Logger) -> Unit {
  match self {
    Root => logger.write_string("$")
    Key(p, ~key) => logger..write_object(p)..write_string(".").write_string(key)
    Index(p, ~index) =>
      logger
      ..write_object(p)
      ..write_string("[")
      ..write_object(index)
      .write_string("]")
  }
}

///|
fn update_key_inplace(self : JsonPath, key : String) -> Unit {
  match self {
    Key(_) as k => k.key = key
    _ => abort("the variant is not Key")
  }
}

///|
fn update_index_inplace(self : JsonPath, index : Int) -> Unit {
  match self {
    Index(_) as i => i.index = index
    _ => abort("the variant is not Index")
  }
}

test "show JsonPath" {
  let path = Key(Index(Root, index=0), key="foo")
  @builtin.inspect!(path, content="$[0].foo")
  @builtin.inspect!(path.add_index(1), content="$[0].foo[1]")
  @builtin.inspect!(path.add_key("bar"), content="$[0].foo.bar")
  @builtin.inspect!(
    Root.add_key("foo").add_key("foo1").add_index(2),
    content="$.foo.foo1[2]",
  )
  @builtin.inspect!(Root.add_key("foo").add_key("foo1"), content="$.foo.foo1")
  @builtin.inspect!(
    Root.add_key("foo").add_key("foo1").add_index(2).add_key("bar"),
    content="$.foo.foo1[2].bar",
  )
  @builtin.inspect!(
    Root.add_key("foo").add_key("foo1").add_index(2).add_key("bar").add_index(3),
    content="$.foo.foo1[2].bar[3]",
  )
  @builtin.inspect!(
    Root
    .add_key("foo")
    .add_key("foo1")
    .add_index(2)
    .add_key("bar")
    .add_index(3)
    .add_key("baz"),
    content="$.foo.foo1[2].bar[3].baz",
  )
  @builtin.inspect!(
    Root.add_key("foo").add_key("foo1").add_index(2).add_index(3).add_index(4),
    content="$.foo.foo1[2][3][4]",
  )
}
