# Path Utilities for Windows Systems

This package provides Node-compatible Windows path manipulation utilities. It handles paths using backslashes (`\`) as the output separator and accepts both `/` and `\` as input separators.

## Overview

The package offers a complete set of functions for working with Windows file paths:

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
  let path : @win32.Path = "C:\\Users\\user"
  inspect(path.basename(), content="user")
  let path : @win32.Path = "project\\src\\main.mbt"
  inspect(path.basename(), content="main.mbt")

  // Get the directory part
  let path : @win32.Path = "C:\\Users\\user"
  inspect(path.dirname(), content="C:\\Users")
  let path : @win32.Path = "project\\src\\main.mbt"
  inspect(path.dirname(), content="project\\src")

  // Handle trailing backslashes
  let path : @win32.Path = "C:\\Users\\"
  inspect(path.basename(), content="Users")
  inspect(path.dirname(), content="C:\\")
}
```

### Extension Name

Extract file extensions from paths:

```moonbit check
///|
test "extension extraction" {
  // Get file extension including the dot
  let path : @win32.Path = "document.txt"
  inspect(path.extname(), content=".txt")
  let path : @win32.Path = "archive.tar.gz"
  inspect(path.extname(), content=".gz")
  let path : @win32.Path = "project\\main.mbt.md"
  inspect(path.extname(), content=".md")
  // Files without extensions
  let path : @win32.Path = "README"
  inspect(path.extname(), content="")
  let path : @win32.Path = "project\\"
  inspect(path.extname(), content="")
}
```

## Path Testing

### Absolute Path Detection

Windows has various types of absolute paths. The function correctly identifies them all:

```moonbit check
///|
test "absolute path detection" {
  // Standard drive letter paths
  let path : @win32.Path = "C:\\"
  json_inspect(path.is_absolute(), content=true)
  let path : @win32.Path = "D:\\folder\\file"
  json_inspect(path.is_absolute(), content=true)
  // UNC paths (network shares)
  let path : @win32.Path = "\\\\server\\share\\file"
  json_inspect(path.is_absolute(), content=true)
  // Verbatim UNC paths
  let path : @win32.Path = "\\\\?\\UNC\\server\\share\\file"
  json_inspect(path.is_absolute(), content=true)
  // Verbatim drive letter paths
  let path : @win32.Path = "\\\\?\\C:\\file"
  json_inspect(path.is_absolute(), content=true)
  // Volume GUID paths
  let path : @win32.Path = "\\\\?\\Volume{12345678-1234-1234-1234-1234567890ab}\\file"
  json_inspect(path.is_absolute(), content=true)
  // Device namespace paths
  let path : @win32.Path = "\\\\.\\COM56"
  json_inspect(path.is_absolute(), content=true)
  // Verbatim symlink paths
  let path : @win32.Path = "\\\\?\\GLOBALROOT\\file"
  json_inspect(path.is_absolute(), content=true)
  // Relative paths
  let path : @win32.Path = "C:folder\\file" // Drive-relative
  json_inspect(path.is_absolute(), content=false)
  let path : @win32.Path = "Users\\user"
  json_inspect(path.is_absolute(), content=false)
  let path : @win32.Path = ""
  json_inspect(path.is_absolute(), content=false)
}
```

## Path Construction

### Joining Paths

Combine path components with proper separator handling:

```moonbit check
///|
test "path joining" {
  // Basic joining
  let path : @win32.Path = "Users"
  inspect(path.join("user"), content="Users\\user")
  let path : @win32.Path = "project"
  inspect(path.join("src"), content="project\\src")
  // Handle trailing backslashes
  let path : @win32.Path = "Users\\"
  inspect(path.join("user"), content="Users\\user")
  // Absolute right-hand paths are joined then normalized
  let path : @win32.Path = "relative"
  inspect(path.join("\\absolute"), content="relative\\absolute")
  let path : @win32.Path = "C:\\"
  inspect(
    Show::to_string(path.join("folder").join("file.txt")),
    content="C:\\folder\\file.txt",
  )
}
```

## Path Transformation

### Normalization

Clean up redundant components and resolve `.` and `..`:

```moonbit check
///|
test "path normalization" {
  // Remove redundant components
  let path : @win32.Path = "a\\.\\b\\..\\c\\"
  inspect(path.normalize(), content="a\\c\\")
  let path : @win32.Path = "C:\\Users\\..\\Windows"
  inspect(path.normalize(), content="C:\\Windows")
  // Handle complex cases
  let path : @win32.Path = "\\a\\b\\..\\..\\c\\."
  inspect(path.normalize(), content="\\c")
  let path : @win32.Path = "a\\b\\c\\.."
  inspect(path.normalize(), content="a\\b")
}
```

### Relative Paths

Calculate the relative path between two Windows locations:

```moonbit check
///|
test "relative path calculation" {
  // Same directory level
  let base = "C:\\Users\\user_name"
  let path : @win32.Path = "C:\\Users\\user_name\\proj_a"
  // inspect(path)
  inspect(path.relative(base~), content="proj_a")

  // Go up one level
  let base = "C:\\Users\\user_name\\proj_a"
  let path : @win32.Path = "C:\\Users\\user_name"
  inspect(path.relative(base~), content="..")
  // Same path
  let base = "C:\\Users\\user_name"
  let path : @win32.Path = "C:\\Users\\user_name"
  inspect(path.relative(base~), content="")

  // Sibling directories
  let base = "C:\\Users\\user_name\\proj_a"
  let path : @win32.Path = "C:\\Users\\user_name\\proj_b"
  inspect(path.relative(base~), content="..\\proj_b")
}
```

### Path Resolution

Convert relative paths to absolute paths and normalize them:

```moonbit check
///|
test "path resolution" {
  // Resolve and normalize absolute paths
  let path : @win32.Path = "C:\\Users\\..\\Windows\\System32"
  inspect(path.resolve(), content="C:\\Windows\\System32")
  let path : @win32.Path = "C:\\a\\b\\c\\..\\..\\.."
  inspect(path.resolve(), content="C:\\")

  // Note: resolve() with relative paths depends on current working directory
  // and will join with the current directory before normalizing
}
```

```mbt nocheck
///|
test {
  let path : Path = "a\\b\\..\\c"
  inspect(path.resolve(), content="C:\\current\\working\\directory\\a\\c")
}
```



## Platform Constants

The package provides Windows-specific constants:

```moonbit check
///|
test "platform constants" {
  // Path component separator
  inspect(@win32.sep, content="\\")

  // Path list delimiter (for PATH environment variable)
  inspect(@win32.delimiter, content=";")
}
```

## Windows Path Types

Windows supports several types of absolute paths:

1. **Drive Letter Paths**: `C:\folder\file`
2. **UNC Paths**: `\\server\share\file` (network shares)
3. **Verbatim Paths**: `\\?\C:\file` (bypass path processing)
4. **Verbatim UNC**: `\\?\UNC\server\share\file`
5. **Volume GUID**: `\\?\Volume{guid}\file`
6. **Device Paths**: `\\.\device`
7. **Symlink Paths**: `\\?\GLOBALROOT\file`

The `is_absolute` function correctly identifies all these formats.

## Key Properties

The package maintains several important properties:

1. **Basename/Dirname relationship**: For most paths, joining dirname and basename gives the original path
2. **Relative/Join relationship**: joining `from` with `relative(base=from, to)` equals `resolve(to)`
3. **Idempotent normalization**: `normalize(normalize(path))` equals `normalize(path)`

## Edge Cases

The implementation handles various Windows-specific edge cases:

- Drive-relative paths (`C:folder`) are treated as relative, not absolute
- Empty paths return appropriate default values
- `normalize` preserves trailing separators where semantically important; `resolve` removes trailing separators except regular roots
- All Windows path prefix types are properly recognized
- The functions follow Node `path.win32` behavior for this package's existing API surface

This makes the package reliable for real-world path manipulation in Windows environments, handling the complexity of Windows path formats while providing a clean, consistent API.
