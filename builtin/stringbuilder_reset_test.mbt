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
test "StringBuilder reset without keeping capacity preserves snapshots" {
  let builder = StringBuilder(size_hint=3)
  builder.write_string("a😀")
  let full = builder.to_string()
  builder.reset(keep_capacity=false)
  inspect(builder.is_empty(), content="true")
  inspect(builder.to_string(), content="")
  builder.reset(keep_capacity=false)
  builder.write_string("hello😀")
  let grown = builder.to_string()
  builder.reset(keep_capacity=true)
  builder.write_string("xy")
  let partial = builder.to_string()
  builder.reset(keep_capacity=false)
  builder.write_char('漢')
  inspect(full, content="a😀")
  inspect(grown, content="hello😀")
  inspect(partial, content="xy")
  inspect(builder.to_string(), content="漢")
}
