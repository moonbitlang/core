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
test "SourceLocRepr::parse/basic" {
  inspect(
    SourceLocRepr::parse("file.mbt:1:1-2:2@mod").to_json_string(),
    content=(
      #|{"filename":"file.mbt","start_line":1,"start_column":1,"end_line":2,"end_column":2}
    ),
  )
  inspect(
    SourceLocRepr::parse("path/to/file.mbt:1:1-2:2@path/to/mod").to_json_string(),
    content=(
      #|{"filename":"path/to/file.mbt","start_line":1,"start_column":1,"end_line":2,"end_column":2}
    ),
  )
}

///|
test "SourceLocRepr::parse/unicode" {
  // Chinese characters in path and filename
  inspect(
    SourceLocRepr::parse("中文路径/中文文件.mbt:1:1-2:2@path/to/mod").to_json_string(),
    content=(
      #|{"filename":"中文路径/中文文件.mbt","start_line":1,"start_column":1,"end_line":2,"end_column":2}
    ),
  )
  // Japanese characters
  inspect(
    SourceLocRepr::parse("日本語ファイル.mbt:10:5-20:15@mod").to_json_string(),
    content=(
      #|{"filename":"日本語ファイル.mbt","start_line":10,"start_column":5,"end_line":20,"end_column":15}
    ),
  )
  // Emoji in filename
  inspect(
    SourceLocRepr::parse("test_🎉.mbt:1:1-1:10@mod").to_json_string(),
    content=(
      #|{"filename":"test_🎉.mbt","start_line":1,"start_column":1,"end_line":1,"end_column":10}
    ),
  )
}

///|
test "SourceLocRepr::parse/colons_in_filename" {
  // Filename containing colons (edge case for parsing)
  inspect(
    SourceLocRepr::parse("dir:123/sub:file.mbt:10:20-30:40@mod").to_json_string(),
    content=(
      #|{"filename":"dir:123/sub:file.mbt","start_line":10,"start_column":20,"end_line":30,"end_column":40}
    ),
  )
  // Multiple colons in filename path
  inspect(
    SourceLocRepr::parse("a:b:c:file.mbt:1:2-3:4@mod").to_json_string(),
    content=(
      #|{"filename":"a:b:c:file.mbt","start_line":1,"start_column":2,"end_line":3,"end_column":4}
    ),
  )
}

///|
test "SourceLocRepr::parse/large_numbers" {
  // Large line and column numbers
  inspect(
    SourceLocRepr::parse("file.mbt:99999:88888-77777:66666@mod").to_json_string(),
    content=(
      #|{"filename":"file.mbt","start_line":99999,"start_column":88888,"end_line":77777,"end_column":66666}
    ),
  )
  // Single digit numbers
  inspect(
    SourceLocRepr::parse("f.mbt:0:0-0:0@mod").to_json_string(),
    content=(
      #|{"filename":"f.mbt","start_line":0,"start_column":0,"end_line":0,"end_column":0}
    ),
  )
}

///|
test "SourceLocRepr::parse/complex_paths" {
  // Deep nested package path
  inspect(
    SourceLocRepr::parse("file.mbt:1:1-2:2@a/b/c/d/e/f").to_json_string(),
    content=(
      #|{"filename":"file.mbt","start_line":1,"start_column":1,"end_line":2,"end_column":2}
    ),
  )
  // Filename with deep directory structure
  inspect(
    SourceLocRepr::parse("src/internal/impl/module/file.mbt:5:10-15:20@mod").to_json_string(),
    content=(
      #|{"filename":"src/internal/impl/module/file.mbt","start_line":5,"start_column":10,"end_line":15,"end_column":20}
    ),
  )
  // Windows-style path (backslashes)
  inspect(
    SourceLocRepr::parse("src\\internal\\file.mbt:1:1-2:2@mod").to_json_string(),
    content=(
      #|{"filename":"src\\internal\\file.mbt","start_line":1,"start_column":1,"end_line":2,"end_column":2}
    ),
  )
}

///|
test "SourceLocRepr::parse/special_filenames" {
  // Filename with dots
  inspect(
    SourceLocRepr::parse("file.test.spec.mbt:1:1-2:2@mod").to_json_string(),
    content=(
      #|{"filename":"file.test.spec.mbt","start_line":1,"start_column":1,"end_line":2,"end_column":2}
    ),
  )
  // Filename with underscores and dashes
  inspect(
    SourceLocRepr::parse("my_test-file_v2.mbt:100:200-300:400@mod").to_json_string(),
    content=(
      #|{"filename":"my_test-file_v2.mbt","start_line":100,"start_column":200,"end_line":300,"end_column":400}
    ),
  )
  // Single character filename
  inspect(
    SourceLocRepr::parse("a.mbt:1:1-1:1@mod").to_json_string(),
    content=(
      #|{"filename":"a.mbt","start_line":1,"start_column":1,"end_line":1,"end_column":1}
    ),
  )
}
