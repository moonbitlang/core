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

enum JsonPath {
  Root
  Key(JsonPath, mut ~key : String)
  Index(JsonPath, mut ~index : Int)
} derive(Eq)

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

fn update_key_inplace(self : JsonPath, key : String) -> Unit {
  match self {
    Key(_) as k => k.key = key
    _ => abort("the variant is not Key")
  }
}

fn update_index_inplace(self : JsonPath, index : Int) -> Unit {
  match self {
    Index(_) as i => i.index = index
    _ => abort("the variant is not Index")
  }
}

pub fn push_index(self : JsonPath, index : Int) -> JsonPath {
  match self {
    Root => Index(self, ~index)
    Index(p, ~index) => Index(p.push_index(index), ~index)
    Key(p, ~key) => Index(p.push_key(key), ~index)
  }
}

pub fn push_key(self : JsonPath, key : String) -> JsonPath {
  match self {
    Root => Key(self, ~key)
    Key(p, ~key) => Key(p.push_key(key), ~key)
    Index(p, ~index) => Key(p.push_index(index), ~key)
  }
}

test "show JsonPath" {
  let path = Key(Index(Root, index=0), key="foo")
  inspect!(path, content="$[0].foo")
}
