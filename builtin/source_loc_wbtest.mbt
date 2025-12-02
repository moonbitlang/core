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
test "SourceLocRepr::parse" {
  inspect(
    SourceLocRepr::parse("file.mbt:1:1-2:2").to_json_string(),
    content=(
      #|"file.mbt:1:1-2:2"
    ),
  )
  inspect(
    SourceLocRepr::parse("/path/to/file.mbt:1:1-2:2").to_json_string(),
    content=(
      #|"/path/to/file.mbt:1:1-2:2"
    ),
  )
  inspect(
    SourceLocRepr::parse("/中文路径/中文文件.mbt:1:1-2:2").to_json_string(),
    content=(
      #|"/中文路径/中文文件.mbt:1:1-2:2"
    ),
  )
  inspect(
    SourceLocRepr::parse("@pkg:file.mbt:1:1-2:2").to_json_string(),
    content=(
      #|{"pkg":"pkg","filename":"file.mbt","start_line":1,"start_column":1,"end_line":2,"end_column":2}
    ),
  )
  inspect(
    SourceLocRepr::parse("@path/to/pkg:/path/to/file.mbt:1:1-2:2").to_json_string(),
    content=(
      #|{"pkg":"path/to/pkg","filename":"/path/to/file.mbt","start_line":1,"start_column":1,"end_line":2,"end_column":2}
    ),
  )
  inspect(
    SourceLocRepr::parse("@path/to/pkg:/中文路径/中文文件.mbt:1:1-2:2").to_json_string(),
    content=(
      #|{"pkg":"path/to/pkg","filename":"/中文路径/中文文件.mbt","start_line":1,"start_column":1,"end_line":2,"end_column":2}
    ),
  )
  inspect(
    SourceLocRepr::parse("@file.mbt:1:1-2:2").to_json_string(),
    content=(
      #|"@file.mbt:1:1-2:2"
    ),
  )
}
