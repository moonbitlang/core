# Internal Windows Path Implementation

This internal package implements string operations for `@path.Path`.
Applications should import `moonbitlang/core/path`.

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
  let path : String = "C:\\Users\\user"
  inspect(@win32.basename(path), content="user")
  let path : String = "project\\src\\main.mbt"
  inspect(@win32.basename(path), content="main.mbt")

  // Get the directory part
  let path : String = "C:\\Users\\user"
  inspect(@win32.dirname(path), content="C:\\Users")
  let path : String = "project\\src\\main.mbt"
  inspect(@win32.dirname(path), content="project\\src")

  // Handle trailing backslashes
  let path : String = "C:\\Users\\"
  inspect(@win32.basename(path), content="Users")
  inspect(@win32.dirname(path), content="C:\\")
}
```

### Extension Name

Extract file extensions from paths:

```moonbit check
///|
test "extension extraction" {
  // Get file extension including the dot
  let path : String = "document.txt"
  inspect(@win32.extname(path), content=".txt")
  let path : String = "archive.tar.gz"
  inspect(@win32.extname(path), content=".gz")
  let path : String = "project\\main.mbt.md"
  inspect(@win32.extname(path), content=".md")
  // Files without extensions
  let path : String = "README"
  inspect(@win32.extname(path), content="")
  let path : String = "project\\"
  inspect(@win32.extname(path), content="")
}
```

## Path Testing

### Absolute Path Detection

Windows has various types of absolute paths. The function correctly identifies them all:

```moonbit check
///|
test "absolute path detection" {
  // Standard drive letter paths
  let path : String = "C:\\"
  json_inspect(@win32.is_absolute(path), content=true)
  let path : String = "D:\\folder\\file"
  json_inspect(@win32.is_absolute(path), content=true)
  // UNC paths (network shares)
  let path : String = "\\\\server\\share\\file"
  json_inspect(@win32.is_absolute(path), content=true)
  // Verbatim UNC paths
  let path : String = "\\\\?\\UNC\\server\\share\\file"
  json_inspect(@win32.is_absolute(path), content=true)
  // Verbatim drive letter paths
  let path : String = "\\\\?\\C:\\file"
  json_inspect(@win32.is_absolute(path), content=true)
  // Volume GUID paths
  let path : String = "\\\\?\\Volume{12345678-1234-1234-1234-1234567890ab}\\file"
  json_inspect(@win32.is_absolute(path), content=true)
  // Device namespace paths
  let path : String = "\\\\.\\COM56"
  json_inspect(@win32.is_absolute(path), content=true)
  // Verbatim symlink paths
  let path : String = "\\\\?\\GLOBALROOT\\file"
  json_inspect(@win32.is_absolute(path), content=true)
  // Relative paths
  let path : String = "C:folder\\file" // Drive-relative
  json_inspect(@win32.is_absolute(path), content=false)
  let path : String = "Users\\user"
  json_inspect(@win32.is_absolute(path), content=false)
  let path : String = ""
  json_inspect(@win32.is_absolute(path), content=false)
}
```

## Path Construction

### Joining Paths

Combine path components with proper separator handling:

```moonbit check
///|
test "path joining" {
  // Basic joining
  let path : String = "Users"
  inspect(@win32.join(path, "user"), content="Users\\user")
  let path : String = "project"
  inspect(@win32.join(path, "src"), content="project\\src")
  // Handle trailing backslashes
  let path : String = "Users\\"
  inspect(@win32.join(path, "user"), content="Users\\user")
  // Absolute right-hand paths are joined then normalized
  let path : String = "relative"
  inspect(@win32.join(path, "\\absolute"), content="relative\\absolute")
  let path : String = "C:\\"
  inspect(
    @win32.join(@win32.join(path, "folder"), "file.txt"),
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
  let path : String = "a\\.\\b\\..\\c\\"
  inspect(@win32.normalize(path), content="a\\c\\")
  let path : String = "C:\\Users\\..\\Windows"
  inspect(@win32.normalize(path), content="C:\\Windows")
  // Handle complex cases
  let path : String = "\\a\\b\\..\\..\\c\\."
  inspect(@win32.normalize(path), content="\\c")
  let path : String = "a\\b\\c\\.."
  inspect(@win32.normalize(path), content="a\\b")
}
```

### Relative Paths

Calculate the relative path between two Windows locations:

```moonbit check
///|
test "relative path calculation" {
  // Same directory level
  let base = "C:\\Users\\user_name"
  let path : String = "C:\\Users\\user_name\\proj_a"
  // inspect(path)
  inspect(@win32.relative(path, base~), content="proj_a")

  // Go up one level
  let base = "C:\\Users\\user_name\\proj_a"
  let path : String = "C:\\Users\\user_name"
  inspect(@win32.relative(path, base~), content="..")
  // Same path
  let base = "C:\\Users\\user_name"
  let path : String = "C:\\Users\\user_name"
  inspect(@win32.relative(path, base~), content="")

  // Sibling directories
  let base = "C:\\Users\\user_name\\proj_a"
  let path : String = "C:\\Users\\user_name\\proj_b"
  inspect(@win32.relative(path, base~), content="..\\proj_b")
}
```

### Path Resolution

Convert relative paths to absolute paths and normalize them:

`resolve` and `relative` raise `ResolveError::CurrentDirectoryUnavailable`
when they need the current working directory and it cannot be determined.
Fully qualified drive, UNC, verbatim, and device paths can be resolved without
a current working directory. `relative` likewise needs no current working
directory when both inputs are fully qualified. Drive-less rooted paths such
as `\file` still need the current working directory to determine their drive
or UNC share.

```moonbit check
///|
test "path resolution" {
  // Resolve and normalize absolute paths
  let path : String = "C:\\Users\\..\\Windows\\System32"
  inspect(@win32.resolve(path), content="C:\\Windows\\System32")
  let path : String = "C:\\a\\b\\c\\..\\..\\.."
  inspect(@win32.resolve(path), content="C:\\")

  // Note: resolve() with relative paths depends on current working directory
  // and will join with the current directory before normalizing
}
```

```mbt nocheck
///|
test {
  let path : String = "a\\b\\..\\c"
  inspect(@win32.resolve(path), content="C:\\current\\working\\directory\\a\\c")
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
- `relative` compares names using Unicode default string lowercasing, including
  contextual Greek sigma and expanding `İ` to `i` plus a combining dot. This
  does not change `Path` equality, which compares the original strings exactly.

This makes the package reliable for real-world path manipulation in Windows environments, handling the complexity of Windows path formats while providing a clean, consistent API.
