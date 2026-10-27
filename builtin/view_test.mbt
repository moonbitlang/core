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
test "slicing migration supports compiler-generated Unicode lexmatch captures" {
  let text = "ab😀cd"
  let from_string = lexmatch text {
    (re"😀+" as matched, before=prefix, after=suffix) =>
      (prefix.to_owned(), matched.to_owned(), suffix.to_owned())
    _ => ("", "", "")
  }
  debug_inspect(from_string, content="(\"ab\", \"😀\", \"cd\")")
  let nested = "xxab😀cdyy"[2:8]
  let from_view = lexmatch nested {
    (re"😀+" as matched, before=prefix, after=suffix) =>
      (prefix.to_owned(), matched.to_owned(), suffix.to_owned())
    _ => ("", "", "")
  }
  debug_inspect(from_view, content="(\"ab\", \"😀\", \"cd\")")
}
