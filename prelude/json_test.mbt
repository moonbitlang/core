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
priv struct JsonRecord {
  count : Int32
} derive(ToJson)

///|
test "JSON remains available through the prelude" {
  let value : Json = Json(JsonRecord::{ count: 42, })
  json_inspect(value, content={ "count": 42 })
  assert_true(value is { "count": 42, .. })
  inspect(null.stringify(), content="null")
  debug_inspect(value, content="Object({ \"count\": Number(42) })")
}
