// Copyright 2025 International Digital Economy Academy
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
type! StringError String

///|
type! IntError Int

test {
  let v : Array[Error] = [StringError("x"), IntError(1)]
  let buf = StringBuilder::new()
  for i in v {
    match i {
      StringError(s) => buf.write_string(s)
      IntError(i) =>
        // assert_eq!(i, 1)
        buf.write_object(i)
      _ => abort("impossible")
    }
  }
  @json.inspect!(buf.to_string(), content="x1")
}
