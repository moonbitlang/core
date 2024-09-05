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

pub impl[A : FromJson, B : FromJson] FromJson for (A, B) with from_json!(
  json,
  path
) {
  FromJson::from_json!(json, path)
}

pub impl[A : FromJson, B : FromJson, C : FromJson] FromJson for (A, B, C) with from_json!(
  json,
  path
) {
  FromJson::from_json!(json, path)
}

pub impl[A : FromJson, B : FromJson, C : FromJson, D : FromJson] FromJson for (
  A,
  B,
  C,
  D,
) with from_json!(json, path) {
  FromJson::from_json!(json, path)
}

pub impl[A : FromJson, B : FromJson, C : FromJson, D : FromJson, E : FromJson] FromJson for (
  A,
  B,
  C,
  D,
  E,
) with from_json!(json, path) {
  FromJson::from_json!(json, path)
}

pub impl[A : FromJson, B : FromJson, C : FromJson, D : FromJson, E : FromJson, F : FromJson] FromJson for (
  A,
  B,
  C,
  D,
  E,
  F,
) with from_json!(json, path) {
  FromJson::from_json!(json, path)
}

pub impl[A : FromJson, B : FromJson, C : FromJson, D : FromJson, E : FromJson, F : FromJson, G : FromJson] FromJson for (
  A,
  B,
  C,
  D,
  E,
  F,
  G,
) with from_json!(json, path) {
  FromJson::from_json!(json, path)
}
