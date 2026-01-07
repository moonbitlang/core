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
}

///|
test "SourceLocRepr::parse/unicode" {
  // Chinese characters in path and filename
  inspect(
    SourceLocRepr::parse("@path/to/pkg:/中文路径/中文文件.mbt:1:1-2:2").to_json_string(),
    content=(
      #|{"pkg":"path/to/pkg","filename":"/中文路径/中文文件.mbt","start_line":1,"start_column":1,"end_line":2,"end_column":2}
    ),
  )
  // Japanese characters
  inspect(
    SourceLocRepr::parse("@pkg:日本語ファイル.mbt:10:5-20:15").to_json_string(),
    content=(
      #|{"pkg":"pkg","filename":"日本語ファイル.mbt","start_line":10,"start_column":5,"end_line":20,"end_column":15}
    ),
  )
  // Emoji in filename
  inspect(
    SourceLocRepr::parse("@pkg:test_🎉.mbt:1:1-1:10").to_json_string(),
    content=(
      #|{"pkg":"pkg","filename":"test_🎉.mbt","start_line":1,"start_column":1,"end_line":1,"end_column":10}
    ),
  )
}

///|
test "SourceLocRepr::parse/colons_in_filename" {
  // Filename containing colons (edge case for parsing)
  inspect(
    SourceLocRepr::parse("@pkg:dir:123/sub:file.mbt:10:20-30:40").to_json_string(),
    content=(
      #|{"pkg":"pkg","filename":"dir:123/sub:file.mbt","start_line":10,"start_column":20,"end_line":30,"end_column":40}
    ),
  )
  // Multiple colons in filename path
  inspect(
    SourceLocRepr::parse("@pkg:a:b:c:file.mbt:1:2-3:4").to_json_string(),
    content=(
      #|{"pkg":"pkg","filename":"a:b:c:file.mbt","start_line":1,"start_column":2,"end_line":3,"end_column":4}
    ),
  )
}

///|
test "SourceLocRepr::parse/large_numbers" {
  // Large line and column numbers
  inspect(
    SourceLocRepr::parse("@pkg:file.mbt:99999:88888-77777:66666").to_json_string(),
    content=(
      #|{"pkg":"pkg","filename":"file.mbt","start_line":99999,"start_column":88888,"end_line":77777,"end_column":66666}
    ),
  )
  // Single digit numbers
  inspect(
    SourceLocRepr::parse("@pkg:f.mbt:0:0-0:0").to_json_string(),
    content=(
      #|{"pkg":"pkg","filename":"f.mbt","start_line":0,"start_column":0,"end_line":0,"end_column":0}
    ),
  )
}

///|
test "SourceLocRepr::parse/complex_paths" {
  // Deep nested package path
  inspect(
    SourceLocRepr::parse("@a/b/c/d/e/f:file.mbt:1:1-2:2").to_json_string(),
    content=(
      #|{"pkg":"a/b/c/d/e/f","filename":"file.mbt","start_line":1,"start_column":1,"end_line":2,"end_column":2}
    ),
  )
  // Filename with deep directory structure
  inspect(
    SourceLocRepr::parse("@pkg:src/internal/impl/module/file.mbt:5:10-15:20").to_json_string(),
    content=(
      #|{"pkg":"pkg","filename":"src/internal/impl/module/file.mbt","start_line":5,"start_column":10,"end_line":15,"end_column":20}
    ),
  )
  // Windows-style path (backslashes)
  inspect(
    SourceLocRepr::parse("@pkg:src\\internal\\file.mbt:1:1-2:2").to_json_string(),
    content=(
      #|{"pkg":"pkg","filename":"src\\internal\\file.mbt","start_line":1,"start_column":1,"end_line":2,"end_column":2}
    ),
  )
}

///|
test "SourceLocRepr::parse/special_filenames" {
  // Filename with dots
  inspect(
    SourceLocRepr::parse("@pkg:file.test.spec.mbt:1:1-2:2").to_json_string(),
    content=(
      #|{"pkg":"pkg","filename":"file.test.spec.mbt","start_line":1,"start_column":1,"end_line":2,"end_column":2}
    ),
  )
  // Filename with underscores and dashes
  inspect(
    SourceLocRepr::parse("@pkg:my_test-file_v2.mbt:100:200-300:400").to_json_string(),
    content=(
      #|{"pkg":"pkg","filename":"my_test-file_v2.mbt","start_line":100,"start_column":200,"end_line":300,"end_column":400}
    ),
  )
  // Single character filename
  inspect(
    SourceLocRepr::parse("@pkg:a.mbt:1:1-1:1").to_json_string(),
    content=(
      #|{"pkg":"pkg","filename":"a.mbt","start_line":1,"start_column":1,"end_line":1,"end_column":1}
    ),
  )
}

///|
test "SourceLocRepr::to_string/standard_format" {
  // Standard moonbitlang/core format with package
  inspect(
    SourceLocRepr::parse(
      "@moonbitlang/core/builtin:source_loc_wbtest.mbt:1:1-2:2",
    ),
    content="builtin/source_loc_wbtest.mbt:1:1-2:2@moonbitlang/core",
  )
  // Two-level module without package
  inspect(
    SourceLocRepr::parse("@module/root:file.mbt:1:1-2:2"),
    content="file.mbt:1:1-2:2@module/root",
  )
  // Two-level module with nested package
  inspect(
    SourceLocRepr::parse("@module/root/internal/package:file.mbt:1:1-2:2"),
    content="internal/package/file.mbt:1:1-2:2@module/root",
  )
}

///|
test "SourceLocRepr::to_string/no_module_separator" {
  // Package name without slash (should use whole pkg as module_name)
  inspect(
    SourceLocRepr::parse("@bad_module_name:file.mbt:1:1-2:2"),
    content="file.mbt:1:1-2:2@bad_module_name",
  )
  // Single word package
  inspect(
    SourceLocRepr::parse("@builtin:test.mbt:10:20-30:40"),
    content="test.mbt:10:20-30:40@builtin",
  )
}

///|
test "SourceLocRepr::to_string/deep_nested_packages" {
  // Very deep nested package path
  inspect(
    SourceLocRepr::parse("@org/repo/a/b/c/d/e:file.mbt:1:1-2:2"),
    content="a/b/c/d/e/file.mbt:1:1-2:2@org/repo",
  )
  // Multiple levels in package
  inspect(
    SourceLocRepr::parse(
      "@user/project/src/internal/utils:helper.mbt:5:10-15:20",
    ),
    content="src/internal/utils/helper.mbt:5:10-15:20@user/project",
  )
}

///|
test "SourceLocRepr::to_string/special_module_names" {
  // Module name with numbers
  inspect(
    SourceLocRepr::parse("@user123/repo456:test.mbt:1:1-2:2"),
    content="test.mbt:1:1-2:2@user123/repo456",
  )
  // Module name with underscores
  inspect(
    SourceLocRepr::parse("@my_org/my_repo/my_pkg:my_file.mbt:1:1-2:2"),
    content="my_pkg/my_file.mbt:1:1-2:2@my_org/my_repo",
  )
  // Module name with dashes
  inspect(
    SourceLocRepr::parse("@my-org/my-repo/my-pkg:my-file.mbt:1:1-2:2"),
    content="my-pkg/my-file.mbt:1:1-2:2@my-org/my-repo",
  )
}

///|
test "SourceLocRepr::to_string/with_paths_in_filename" {
  // Filename with directory path
  inspect(
    SourceLocRepr::parse("@org/repo/pkg:src/internal/file.mbt:1:1-2:2"),
    content="pkg/src/internal/file.mbt:1:1-2:2@org/repo",
  )
  // Absolute path in filename
  inspect(
    SourceLocRepr::parse("@org/repo:/home/user/project/file.mbt:1:1-2:2"),
    content="/home/user/project/file.mbt:1:1-2:2@org/repo",
  )
}

///|
test "SourceLocRepr::to_string/unicode_content" {
  // Unicode in package and filename
  inspect(
    SourceLocRepr::parse(
      "@中文组织/中文仓库/中文包:中文文件.mbt:1:1-2:2",
    ),
    content="中文包/中文文件.mbt:1:1-2:2@中文组织/中文仓库",
  )
}

///|
test "SourceLocRepr::to_string/edge_cases" {
  // Empty package part after module (just module/root/)
  inspect(
    SourceLocRepr::parse("@a/b/:file.mbt:1:1-2:2"),
    content="/file.mbt:1:1-2:2@a/b",
  )
  // Very long line/column numbers
  inspect(
    SourceLocRepr::parse(
      "@moonbitlang/core/json:parser.mbt:12345:67890-98765:43210",
    ),
    content="json/parser.mbt:12345:67890-98765:43210@moonbitlang/core",
  )
}
