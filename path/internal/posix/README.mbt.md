# Internal POSIX Path Implementation

This internal package implements string operations for `@path.Path`.
Applications should import `moonbitlang/core/path`.

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
  let path : String = "usr/local/bin"
  inspect(@posix.basename(path), content="bin")
  let path : String = "project/src/main.mbt"
  inspect(@posix.basename(path), content="main.mbt")

  // Get the directory part
  let path : String = "usr/local/bin"
  inspect(@posix.dirname(path), content="usr/local")
  let path : String = "project/src/main.mbt"
  inspect(@posix.dirname(path), content="project/src")

  // Handle trailing slashes
  let path : String = "usr/local/"
  inspect(@posix.basename(path), content="local")
  inspect(@posix.dirname(path), content="usr")
}
```

### Extension Name

Extract file extensions from paths:

```moonbit check
///|
test "extension extraction" {
  // Get file extension including the dot
  let path : String = "document.txt"
  inspect(@posix.extname(path), content=".txt")
  let path : String = "archive.tar.gz"
  inspect(@posix.extname(path), content=".gz")
  let path : String = "project/main.mbt.md"
  inspect(@posix.extname(path), content=".md")

  // Files without extensions
  let path : String = "README"
  inspect(@posix.extname(path), content="")
  let path : String = "project/"
  inspect(@posix.extname(path), content="")
}
```

## Path Testing

### Absolute Path Detection

Determine if a path is absolute (starts with `/`):

```moonbit check
///|
test "absolute path detection" {
  let path : String = "/home/user"
  json_inspect(@posix.is_absolute(path), content=true)
  let path : String = "/usr/local/bin"
  json_inspect(@posix.is_absolute(path), content=true)

  // Relative paths
  let path : String = "home/user"
  json_inspect(@posix.is_absolute(path), content=false)
  let path : String = "../project"
  json_inspect(@posix.is_absolute(path), content=false)
  let path : String = ""
  json_inspect(@posix.is_absolute(path), content=false)
}
```

## Path Construction

### Joining Paths

Combine path components with proper separator handling:

```moonbit check
///|
test "path joining" {
  let path : String = "usr"
  inspect(@posix.join(path, "local"), content="usr/local")
  let path : String = "project"
  inspect(@posix.join(path, "src"), content="project/src")
  let path : String = "usr/"
  inspect(@posix.join(path, "local"), content="usr/local")

  // Absolute right-hand paths are joined then normalized
  let path : String = "relative"
  inspect(@posix.join(path, "/absolute"), content="relative/absolute")
  let path : String = "/"
  let path = @posix.join(@posix.join(path, "folder"), "file.txt")
  inspect(path, content="/folder/file.txt")
}
```

## Path Transformation

### Normalization

Clean up redundant components and resolve `.` and `..`:

```moonbit check
///|
test "path normalization" {
  // Remove redundant components
  let path : String = "a/./b/../c/"
  inspect(@posix.normalize(path), content="a/c/")
  let path : String = "/usr/local/../bin"
  inspect(@posix.normalize(path), content="/usr/bin")
  // Handle complex cases
  let path : String = "/a/b/../../c/."
  inspect(@posix.normalize(path), content="/c")
  let path : String = "a/b/c/.."
  inspect(@posix.normalize(path), content="a/b")
}
```

### Relative Paths

Calculate the relative path between two locations:

```moonbit check
///|
test "relative path calculation" {
  // Same directory level
  let base = "/home/user_name"
  let path : String = "/home/user_name/proj_a"
  inspect(@posix.relative(path, base~), content="proj_a")

  // Go up one level
  let base = "/home/user_name/proj_a"
  let path : String = "/home/user_name"
  inspect(@posix.relative(base~, path), content="..")

  // Same path
  let base = "/home/user_name"
  let path : String = "/home/user_name"
  inspect(@posix.relative(path, base~), content="")

  // Sibling directories
  let base = "/home/user_name/proj_a"
  let path : String = "/home/user_name/proj_b"
  inspect(@posix.relative(path, base~), content="../proj_b")
}
```

### Path Resolution

Convert relative paths to absolute paths and normalize them:

`resolve` and `relative` raise `ResolveError::CurrentDirectoryUnavailable`
when they need the current working directory and it cannot be determined.
Absolute paths can be resolved without a current working directory; likewise,
`relative` needs no current working directory when both paths are absolute.
On Windows, the current working directory is converted to POSIX syntax:
backslashes become `/` and the drive indicator is removed (for example,
`C:\work` becomes `/work`).

```moonbit check
///|
test "path resolution" {
  // Resolve and normalize absolute paths
  let path : String = "/a/b/../../c/."
  inspect(@posix.resolve(path), content="/c")
  let path : String = "/a/b/c/../../.."
  inspect(@posix.resolve(path), content="/")

  // Note: resolve() with relative paths depends on current working directory
  // and will join with the current directory before normalizing
}
```

```mbt nocheck
///|
test {
  let path : String = "a/b/../c"
  inspect(@posix.resolve(path), content="/current/working/directory/a/c")
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
