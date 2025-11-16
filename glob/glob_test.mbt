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
test "wildcard *" {
  // Basic wildcard matching
  inspect(@glob.is_match("*", ""), content="true")
  inspect(@glob.is_match("*", "anything"), content="true")
  inspect(@glob.is_match("*.txt", "file.txt"), content="true")
  inspect(@glob.is_match("*.txt", "file.md"), content="false")
  inspect(@glob.is_match("file*", "filename"), content="true")
  inspect(@glob.is_match("file*", "file"), content="true")
  inspect(@glob.is_match("*file", "myfile"), content="true")
  inspect(@glob.is_match("*file", "file"), content="true")
  inspect(@glob.is_match("*file*", "myfilename"), content="true")

  // Multiple wildcards
  inspect(@glob.is_match("*.*.txt", "file.backup.txt"), content="true")
  inspect(@glob.is_match("*.*.txt", "file.txt"), content="false")
  inspect(@glob.is_match("a*b*c", "abc"), content="true")
  inspect(@glob.is_match("a*b*c", "aXbYc"), content="true")
  inspect(@glob.is_match("a*b*c", "aXYbZc"), content="true")

  // Wildcard should not match path separator
  inspect(@glob.is_match("*", "foo/bar"), content="false")
  inspect(@glob.is_match("foo*", "foo/bar"), content="false")
}

///|
test "question mark ?" {
  // Basic single character matching
  inspect(@glob.is_match("?", "a"), content="true")
  inspect(@glob.is_match("?", "X"), content="true")
  inspect(@glob.is_match("?", ""), content="false")
  inspect(@glob.is_match("?", "ab"), content="false")
  inspect(@glob.is_match("?.txt", "a.txt"), content="true")
  inspect(@glob.is_match("?.txt", "ab.txt"), content="false")
  inspect(@glob.is_match("file?.txt", "file1.txt"), content="true")
  inspect(@glob.is_match("file?.txt", "fileA.txt"), content="true")
  inspect(@glob.is_match("file?.txt", "file12.txt"), content="false")

  // Multiple question marks
  inspect(@glob.is_match("???", "abc"), content="true")
  inspect(@glob.is_match("???", "ab"), content="false")
  inspect(@glob.is_match("f??", "foo"), content="true")

  // Question mark should not match path separator
  inspect(@glob.is_match("?", "/"), content="false")
  inspect(@glob.is_match("foo?bar", "foo/bar"), content="false")
}

///|
test "character class []" {
  // Basic character sets
  inspect(@glob.is_match("[abc]", "a"), content="true")
  inspect(@glob.is_match("[abc]", "b"), content="true")
  inspect(@glob.is_match("[abc]", "c"), content="true")
  inspect(@glob.is_match("[abc]", "d"), content="false")
  inspect(@glob.is_match("[abc]", ""), content="false")

  // Character ranges
  inspect(@glob.is_match("[a-z]", "a"), content="true")
  inspect(@glob.is_match("[a-z]", "m"), content="true")
  inspect(@glob.is_match("[a-z]", "z"), content="true")
  inspect(@glob.is_match("[a-z]", "A"), content="false")
  inspect(@glob.is_match("[0-9]", "5"), content="true")
  inspect(@glob.is_match("[0-9]", "a"), content="false")

  // Multiple ranges
  inspect(@glob.is_match("[a-zA-Z]", "a"), content="true")
  inspect(@glob.is_match("[a-zA-Z]", "Z"), content="true")
  inspect(@glob.is_match("[a-zA-Z0-9]", "5"), content="true")

  // In filenames
  inspect(@glob.is_match("file[0-9].txt", "file5.txt"), content="true")
  inspect(@glob.is_match("file[0-9].txt", "fileA.txt"), content="false")
  inspect(@glob.is_match("test[abc].log", "testa.log"), content="true")
  inspect(@glob.is_match("test[abc].log", "testd.log"), content="false")
}

///|
test "negated character class [!...] [^...]" {
  // Negation with !
  inspect(@glob.is_match("[!abc]", "d"), content="true")
  inspect(@glob.is_match("[!abc]", "a"), content="false")
  inspect(@glob.is_match("[!0-9]", "a"), content="true")
  inspect(@glob.is_match("[!0-9]", "5"), content="false")

  // Negation with ^
  inspect(@glob.is_match("[^abc]", "d"), content="true")
  inspect(@glob.is_match("[^abc]", "a"), content="false")
  inspect(@glob.is_match("[^0-9]", "a"), content="true")
  inspect(@glob.is_match("[^0-9]", "5"), content="false")

  // In filenames
  inspect(@glob.is_match("file[!0-9].txt", "fileA.txt"), content="true")
  inspect(@glob.is_match("file[!0-9].txt", "file5.txt"), content="false")
}

///|
test "brace expansion {}" {
  // Basic alternatives
  inspect(@glob.is_match("{a,b,c}", "a"), content="true")
  inspect(@glob.is_match("{a,b,c}", "b"), content="true")
  inspect(@glob.is_match("{a,b,c}", "c"), content="true")
  inspect(@glob.is_match("{a,b,c}", "d"), content="false")

  // In filenames
  inspect(@glob.is_match("file.{txt,md,rs}", "file.txt"), content="true")
  inspect(@glob.is_match("file.{txt,md,rs}", "file.md"), content="true")
  inspect(@glob.is_match("file.{txt,md,rs}", "file.rs"), content="true")
  inspect(@glob.is_match("file.{txt,md,rs}", "file.py"), content="false")

  // Multi-character alternatives
  inspect(@glob.is_match("{hello,world}", "hello"), content="true")
  inspect(@glob.is_match("{hello,world}", "world"), content="true")
  inspect(@glob.is_match("{hello,world}", "helloworld"), content="false")

  // With wildcards
  inspect(@glob.is_match("{*.txt,*.md}", "file.txt"), content="true")
  inspect(@glob.is_match("{*.txt,*.md}", "file.md"), content="true")
  inspect(@glob.is_match("{*.txt,*.md}", "file.rs"), content="false")
}

///|
test "double star **" {
  // Match any path segments
  inspect(@glob.is_match("**", ""), content="true")
  inspect(@glob.is_match("**", "foo"), content="true")
  inspect(@glob.is_match("**", "foo/bar"), content="true")
  inspect(@glob.is_match("**", "foo/bar/baz"), content="true")

  // With directory separator
  inspect(@glob.is_match("**/test", "test"), content="true")
  inspect(@glob.is_match("**/test", "foo/test"), content="true")
  inspect(@glob.is_match("**/test", "foo/bar/test"), content="true")
  inspect(@glob.is_match("**/test", "foo/bar/baz/test"), content="true")
  inspect(@glob.is_match("**/test", "test/foo"), content="false")

  // Pattern after **
  inspect(@glob.is_match("**/*.txt", "file.txt"), content="true")
  inspect(@glob.is_match("**/*.txt", "foo/file.txt"), content="true")
  inspect(@glob.is_match("**/*.txt", "foo/bar/file.txt"), content="true")
  inspect(@glob.is_match("**/*.txt", "foo/bar/file.md"), content="false")

  // Pattern before **
  inspect(@glob.is_match("src/**", "src/file.txt"), content="true")
  inspect(@glob.is_match("src/**", "src/foo/bar.txt"), content="true")
  inspect(@glob.is_match("src/**", "src/foo/bar/baz.txt"), content="true")
  inspect(@glob.is_match("src/**", "test/file.txt"), content="false")

  // Pattern on both sides
  inspect(
    @glob.is_match("src/**/test/*.txt", "src/test/file.txt"),
    content="true",
  )
  inspect(
    @glob.is_match("src/**/test/*.txt", "src/foo/test/file.txt"),
    content="true",
  )
  inspect(
    @glob.is_match("src/**/test/*.txt", "src/foo/bar/test/file.txt"),
    content="true",
  )
  inspect(
    @glob.is_match("src/**/test/*.txt", "src/foo/bar/test/file.md"),
    content="false",
  )
  inspect(@glob.is_match("src/**/test/*.txt", "test/file.txt"), content="false")
}

///|
test "escape sequences \\" {
  // Escape special characters
  inspect(@glob.is_match("\\*", "*"), content="true")
  inspect(@glob.is_match("\\*", "anything"), content="false")
  inspect(@glob.is_match("\\?", "?"), content="true")
  inspect(@glob.is_match("\\?", "a"), content="false")
  inspect(@glob.is_match("\\[", "["), content="true")
  inspect(@glob.is_match("\\]", "]"), content="true")
  inspect(@glob.is_match("\\{", "{"), content="true")
  inspect(@glob.is_match("\\}", "}"), content="true")

  // In filenames
  inspect(@glob.is_match("file\\*.txt", "file*.txt"), content="true")
  inspect(@glob.is_match("file\\*.txt", "filename.txt"), content="false")
}

///|
test "complex patterns" {
  // Combining multiple features
  inspect(@glob.is_match("src/**/*.{js,ts}", "src/index.js"), content="true")
  inspect(
    @glob.is_match("src/**/*.{js,ts}", "src/utils/helper.ts"),
    content="true",
  )
  inspect(
    @glob.is_match("src/**/*.{js,ts}", "src/deep/nested/file.js"),
    content="true",
  )
  inspect(@glob.is_match("src/**/*.{js,ts}", "src/file.md"), content="false")
  inspect(@glob.is_match("test_[0-9]*.{txt,log}", "test_1.txt"), content="true")
  inspect(
    @glob.is_match("test_[0-9]*.{txt,log}", "test_5abc.log"),
    content="true",
  )
  inspect(
    @glob.is_match("test_[0-9]*.{txt,log}", "test_a.txt"),
    content="false",
  )
  inspect(@glob.is_match("**/{src,test}/*.rs", "src/main.rs"), content="true")
  inspect(@glob.is_match("**/{src,test}/*.rs", "test/test.rs"), content="true")
  inspect(
    @glob.is_match("**/{src,test}/*.rs", "foo/src/lib.rs"),
    content="true",
  )
  inspect(
    @glob.is_match("**/{src,test}/*.rs", "foo/bar/src/mod.rs"),
    content="true",
  )
  inspect(@glob.is_match("**/{src,test}/*.rs", "docs/file.rs"), content="false")
}

///|
test "edge cases" {
  // Empty pattern and text
  inspect(@glob.is_match("", ""), content="true")
  inspect(@glob.is_match("", "text"), content="false")
  inspect(@glob.is_match("pattern", ""), content="false")

  // Only wildcards
  inspect(@glob.is_match("***", "anything"), content="true")
  inspect(@glob.is_match("???", "abc"), content="true")
  inspect(@glob.is_match("???", "ab"), content="false")

  // Invalid brace expansion (single item, no comma)
  inspect(@glob.is_match("{abc}", "{abc}"), content="true")
  inspect(@glob.is_match("{abc}", "abc"), content="false")

  // Literal braces
  inspect(@glob.is_match("\\{a,b\\}", "{a,b}"), content="true")
}

///|
test "real world patterns" {
  // Common gitignore-style patterns
  inspect(@glob.is_match("*.log", "debug.log"), content="true")
  inspect(@glob.is_match("*.log", "error.log"), content="true")
  inspect(@glob.is_match("*.log", "app.txt"), content="false")
  inspect(
    @glob.is_match("node_modules/**", "node_modules/package/index.js"),
    content="true",
  )
  inspect(
    @glob.is_match("node_modules/**", "node_modules/foo/bar/baz.js"),
    content="true",
  )
  inspect(@glob.is_match("build/**/*.js", "build/dist/app.js"), content="true")
  inspect(
    @glob.is_match("build/**/*.js", "build/dist/vendor/lib.js"),
    content="true",
  )
  inspect(@glob.is_match("build/**/*.js", "src/app.js"), content="false")

  // Common shell patterns
  inspect(@glob.is_match("*.{jpg,jpeg,png,gif}", "photo.jpg"), content="true")
  inspect(@glob.is_match("*.{jpg,jpeg,png,gif}", "image.png"), content="true")
  inspect(
    @glob.is_match("*.{jpg,jpeg,png,gif}", "document.pdf"),
    content="false",
  )
  inspect(@glob.is_match("test-[0-9]*.txt", "test-001.txt"), content="true")
  inspect(
    @glob.is_match("test-[0-9]*.txt", "test-99-final.txt"),
    content="true",
  )
  inspect(@glob.is_match("test-[0-9]*.txt", "test-abc.txt"), content="false")

  // Path matching
  inspect(@glob.is_match("**/README.md", "README.md"), content="true")
  inspect(@glob.is_match("**/README.md", "docs/README.md"), content="true")
  inspect(
    @glob.is_match("**/README.md", "project/docs/api/README.md"),
    content="true",
  )
  inspect(@glob.is_match("**/README.md", "README.txt"), content="false")
}

///|
test "literal character matching" {
  // Basic literals
  inspect(@glob.is_match("hello", "hello"), content="true")
  inspect(@glob.is_match("hello", "Hello"), content="false")
  inspect(@glob.is_match("hello", "world"), content="false")
  inspect(@glob.is_match("test.txt", "test.txt"), content="true")
  inspect(@glob.is_match("test.txt", "test.md"), content="false")

  // With path separators
  inspect(@glob.is_match("foo/bar", "foo/bar"), content="true")
  inspect(@glob.is_match("foo/bar", "foo/baz"), content="false")
  inspect(@glob.is_match("foo/bar/baz", "foo/bar/baz"), content="true")
}
