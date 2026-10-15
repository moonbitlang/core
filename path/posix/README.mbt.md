# Path Utilities for POSIX Systems

This package provides Node-compatible POSIX path manipulation utilities. It handles paths using forward slashes (`/`) as the path separator.

## Overview

The package offers a complete set of functions for working with file paths:

- Path decomposition: `basename`, `dirname`, `extname`
- Path testing: `is_absolute`
- Path construction: `join`
- Path transformation: `normalize`, `relative`, `resolve`
- Platform constants: `sep`, `delimiter`

## Basic Path Operations

### Basename and Dirname

Extract the last component of a path or get the directory part:

```moonbit check
///|
test "basename and dirname examples" {
  // Get the last component (filename)
  let path : @posix.Path = "usr/local/bin"
  inspect(path.basename(), content="bin")
  let path : @posix.Path = "project/src/main.mbt"
  inspect(path.basename(), content="main.mbt")

  // Get the directory part
  let path : @posix.Path = "usr/local/bin"
  inspect(path.dirname(), content="usr/local")
  let path : @posix.Path = "project/src/main.mbt"
  inspect(path.dirname(), content="project/src")

  // Handle trailing slashes
  let path : @posix.Path = "usr/local/"
  inspect(path.basename(), content="local")
  inspect(path.dirname(), content="usr")
}
```

### Extension Name

Extract file extensions from paths:

```moonbit check
///|
test "extension extraction" {
  // Get file extension including the dot
  let path : @posix.Path = "document.txt"
  inspect(path.extname(), content=".txt")
  let path : @posix.Path = "archive.tar.gz"
  inspect(path.extname(), content=".gz")
  let path : @posix.Path = "project/main.mbt.md"
  inspect(path.extname(), content=".md")

  // Files without extensions
  let path : @posix.Path = "README"
  inspect(path.extname(), content="")
  let path : @posix.Path = "project/"
  inspect(path.extname(), content="")
}
```

## Path Testing

### Absolute Path Detection

Determine if a path is absolute (starts with `/`):

```moonbit check
///|
test "absolute path detection" {
  let path : @posix.Path = "/home/user"
  json_inspect(path.is_absolute(), content=true)
  let path : @posix.Path = "/usr/local/bin"
  json_inspect(path.is_absolute(), content=true)

  // Relative paths
  let path : @posix.Path = "home/user"
  json_inspect(path.is_absolute(), content=false)
  let path : @posix.Path = "../project"
  json_inspect(path.is_absolute(), content=false)
  let path : @posix.Path = ""
  json_inspect(path.is_absolute(), content=false)
}
```

## Path Construction

### Joining Paths

Combine path components with proper separator handling:

```moonbit check
///|
test "path joining" {
  let path : @posix.Path = "usr"
  inspect(path.join("local"), content="usr/local")
  let path : @posix.Path = "project"
  inspect(path.join("src"), content="project/src")
  let path : @posix.Path = "usr/"
  inspect(path.join("local"), content="usr/local")

  // Absolute right-hand paths are joined then normalized
  let path : @posix.Path = "relative"
  inspect(path.join("/absolute"), content="relative/absolute")
  let path : @posix.Path = "/"
  let path = path.join("folder").join("file.txt")
  inspect(Show::to_string(path), content="/folder/file.txt")
}
```

## Path Transformation

### Normalization

Clean up redundant components and resolve `.` and `..`:

```moonbit check
///|
test "path normalization" {
  // Remove redundant components
  let path : @posix.Path = "a/./b/../c/"
  inspect(path.normalize(), content="a/c/")
  let path : @posix.Path = "/usr/local/../bin"
  inspect(path.normalize(), content="/usr/bin")
  // Handle complex cases
  let path : @posix.Path = "/a/b/../../c/."
  inspect(path.normalize(), content="/c")
  let path : @posix.Path = "a/b/c/.."
  inspect(path.normalize(), content="a/b")
}
```

### Relative Paths

Calculate the relative path between two locations:

```moonbit check
///|
test "relative path calculation" {
  // Same directory level
  let base = "/home/user_name"
  let path : @posix.Path = "/home/user_name/proj_a"
  inspect(path.relative(base~), content="proj_a")

  // Go up one level
  let base = "/home/user_name/proj_a"
  let path : @posix.Path = "/home/user_name"
  inspect(@posix.Path::relative(base~, path), content="..")

  // Same path
  let base = "/home/user_name"
  let path : @posix.Path = "/home/user_name"
  inspect(path.relative(base~), content="")

  // Sibling directories
  let base = "/home/user_name/proj_a"
  let path : @posix.Path = "/home/user_name/proj_b"
  inspect(path.relative(base~), content="../proj_b")
}
```

### Path Resolution

Convert relative paths to absolute paths and normalize them:

```moonbit check
///|
test "path resolution" {
  // Resolve and normalize absolute paths
  let path : @posix.Path = "/a/b/../../c/."
  inspect(path.resolve(), content="/c")
  let path : @posix.Path = "/a/b/c/../../.."
  inspect(path.resolve(), content="/")

  // Note: resolve() with relative paths depends on current working directory
  // and will join with the current directory before normalizing
}
```

```mbt nocheck
///|
test {
  let path : Path = "a/b/../c"
  inspect(path.resolve(), content="/current/working/directory/a/c")
}
```

## Platform Constants

The package provides platform-specific constants:

```moonbit check
///|
test "platform constants" {
  // Path component separator
  inspect(@posix.sep, content="/")

  // Path list delimiter (for PATH environment variable)
  inspect(@posix.delimiter, content=":")
}
```

## Key Properties

The package maintains several important properties:

1. **Basename/Dirname relationship**: For most paths, joining dirname and basename gives the original path
2. **Relative/Join relationship**: joining `from` with `relative(base=from, to)` equals `resolve(to)`
3. **Idempotent normalization**: `normalize(normalize(path))` equals `normalize(path)`

## Edge Cases

The implementation handles various edge cases consistently:

- Empty paths are handled appropriately
- `normalize` preserves trailing slashes where semantically important; `resolve` removes non-root trailing slashes
- Double leading slashes (`//`) are normalized to a single root slash during normalization
- The functions follow Node `path.posix` behavior for this package's existing API surface

This makes the package reliable for real-world path manipulation in POSIX environments.
