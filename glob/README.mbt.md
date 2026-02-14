# Glob Package

Pattern matching with glob expressions for file paths and strings.

## Overview

The `glob` package provides powerful pattern matching capabilities using glob syntax, commonly used in file path matching, `.gitignore` files, and shell wildcards.

## Features

- **`*`** - Matches zero or more characters (excluding `/`)
- **`?`** - Matches exactly one character (excluding `/`)
- **`[abc]`** - Matches one character from the set
- **`[a-z]`** - Matches one character in the range
- **`[!abc]`** or **`[^abc]`** - Matches one character NOT in the set
- **`{a,b,c}`** - Matches any of the comma-separated alternatives
- **`**`** - Matches zero or more path segments (including `/`)
- **`\`** - Escapes special characters

## Usage

### Basic Wildcards

```moonbit
///|
test "basic wildcards" {
  // * matches zero or more characters
  inspect(@glob.is_match("*.txt", "hello.txt"), content="true")
  inspect(@glob.is_match("file*", "filename"), content="true")
  inspect(@glob.is_match("*test*", "unittest"), content="true")

  // ? matches exactly one character
  inspect(@glob.is_match("?.txt", "a.txt"), content="true")
  inspect(@glob.is_match("file?.log", "file1.log"), content="true")
  inspect(@glob.is_match("test??", "test01"), content="true")
}
```

### Character Classes

```moonbit
///|
test "character classes" {
  // Match specific characters
  inspect(@glob.is_match("[abc].txt", "a.txt"), content="true")
  inspect(@glob.is_match("[abc].txt", "b.txt"), content="true")

  // Match ranges
  inspect(@glob.is_match("file[0-9].log", "file5.log"), content="true")
  inspect(@glob.is_match("[a-zA-Z]", "x"), content="true")

  // Negation
  inspect(@glob.is_match("file[!0-9].txt", "fileA.txt"), content="true")
  inspect(@glob.is_match("[^abc]", "d"), content="true")
}
```

### Brace Expansion

```moonbit
///|
test "brace expansion" {
  // Match alternatives
  inspect(@glob.is_match("{jpg,png,gif}", "png"), content="true")
  inspect(@glob.is_match("file.{txt,md,rs}", "file.md"), content="true")

  // Combine with wildcards
  inspect(@glob.is_match("*.{js,ts}", "app.js"), content="true")
  inspect(@glob.is_match("test-{a,b,c}*", "test-b-final"), content="true")
}
```

### Recursive Patterns with `**`

```moonbit
///|
test "recursive patterns" {
  // Match any depth of directories
  inspect(@glob.is_match("**/*.txt", "file.txt"), content="true")
  inspect(@glob.is_match("**/*.txt", "dir/file.txt"), content="true")
  inspect(@glob.is_match("**/*.txt", "a/b/c/file.txt"), content="true")

  // Prefix patterns
  inspect(@glob.is_match("src/**", "src/main.rs"), content="true")
  inspect(@glob.is_match("src/**", "src/lib/util.rs"), content="true")

  // Complex nested patterns
  inspect(
    @glob.is_match("src/**/test/*.rs", "src/test/unit.rs"),
    content="true",
  )
  inspect(
    @glob.is_match("src/**/test/*.rs", "src/foo/bar/test/integration.rs"),
    content="true",
  )
}
```

### Escape Special Characters

```moonbit
///|
test "escape special characters" {
  // Escape wildcards to match literally
  inspect(@glob.is_match("\\*.txt", "*.txt"), content="true")
  inspect(@glob.is_match("\\?", "?"), content="true")
  inspect(@glob.is_match("file\\[1\\].txt", "file[1].txt"), content="true")
}
```

## Real-World Examples

### Gitignore-Style Patterns

```moonbit
///|
test "gitignore patterns" {
  // Log files
  inspect(@glob.is_match("*.log", "debug.log"), content="true")

  // Dependencies
  inspect(
    @glob.is_match("node_modules/**", "node_modules/pkg/index.js"),
    content="true",
  )

  // Build artifacts
  inspect(@glob.is_match("build/**/*.js", "build/dist/app.js"), content="true")

  // System files
  inspect(@glob.is_match("**/.DS_Store", "src/.DS_Store"), content="true")
}
```

### File Type Matching

```moonbit
///|
test "file types" {
  let image_pattern = "*.{jpg,jpeg,png,gif,webp}"
  inspect(@glob.is_match(image_pattern, "photo.jpg"), content="true")
  inspect(@glob.is_match(image_pattern, "image.png"), content="true")
  inspect(@glob.is_match(image_pattern, "graphic.gif"), content="true")
  let source_pattern = "**/*.{rs,mbt,toml}"
  inspect(@glob.is_match(source_pattern, "src/main.rs"), content="true")
  inspect(@glob.is_match(source_pattern, "lib/util.mbt"), content="true")
  inspect(@glob.is_match(source_pattern, "Cargo.toml"), content="true")
}
```

### Path Filtering

```moonbit
///|
test "path filtering" {
  let test_files = "**/{test,tests}/**/*.{rs,mbt}"
  inspect(@glob.is_match(test_files, "test/unit.rs"), content="true")
  inspect(@glob.is_match(test_files, "tests/integration.mbt"), content="true")
  inspect(@glob.is_match(test_files, "src/tests/helper.rs"), content="true")
  inspect(@glob.is_match(test_files, "src/main.rs"), content="false")
}
```

## API Reference

### `is_match`

```moonbit no-check
pub fn is_match(pattern : String, text : String) -> Bool
```

Matches a string against a glob pattern.

**Parameters:**
- `pattern`: The glob pattern to match against
- `text`: The string to test

**Returns:**
- `true` if the text matches the pattern, `false` otherwise

**Example:**
```moonbit
///|
test "is_match examples" {
  inspect(@glob.is_match("*.txt", "readme.txt"), content="true")
  inspect(@glob.is_match("file[0-9].log", "file5.log"), content="true")
  inspect(@glob.is_match("**/*.rs", "src/main.rs"), content="true")
}
```

## Pattern Behavior Notes

### Path Separator Handling

- `*` and `?` do **not** match the path separator `/`
- `**` is specifically designed to match across directory boundaries
- Use `**` when you need to match nested paths

```moonbit
///|
test "path separator behavior" {
  // * does not cross directory boundaries
  inspect(@glob.is_match("*", "foo/bar"), content="false")
  inspect(@glob.is_match("foo*", "foo/bar"), content="false")

  // ** matches directory boundaries
  inspect(@glob.is_match("**", "foo/bar"), content="true")
  inspect(@glob.is_match("**/bar", "foo/bar"), content="true")
}
```

### Brace Expansion Requirements

- Braces must contain at least one comma to be treated as expansion
- `{abc}` is treated as a literal string, not an expansion
- Empty alternatives are allowed: `{a,,c}` matches `a`, empty string, or `c`

```moonbit
///|
test "brace expansion rules" {
  // Valid expansions (contain comma)
  inspect(@glob.is_match("{a,b}", "a"), content="true")
  inspect(@glob.is_match("{txt,md}", "txt"), content="true")

  // Not an expansion (no comma) - treated as literal
  inspect(@glob.is_match("{abc}", "{abc}"), content="true")
  inspect(@glob.is_match("{abc}", "abc"), content="false")
}
```

## Performance Considerations

- The implementation uses recursive backtracking
- Complex patterns with many wildcards or alternatives may be slower
- For simple literal matching, consider using string equality instead

## License

Apache License 2.0
