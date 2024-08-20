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
  Key(JsonPath, String)
  Index(JsonPath, Int)
} derive(Eq)

pub fn output(self : JsonPath, logger : Logger) -> Unit {
  match self {
    Root => logger.write_string("$")
    Key(p, k) => logger..write_object(p)..write_string(".").write_string(k)
    Index(p, i) =>
      logger
      ..write_object(p)
      ..write_string("[")
      ..write_object(i)
      .write_string("]")
  }
}

test "show JsonPath" {
  let path = Key(Index(Root, 0), "foo")
  inspect!(path, content="$[0].foo")
}
