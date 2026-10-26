# File System API (`@moonbitlang/core/async/fs`)

Asynchronous file system operations for MoonBit. This package provides comprehensive APIs for working with files, directories, and file metadata.

## Table of Contents

- [File Operations](#file-operations)
  - [Opening and Creating Files](#opening-and-creating-files)
  - [Reading Files](#reading-files)
  - [Writing Files](#writing-files)
  - [File Seeking](#file-seeking)
- [Directory Operations](#directory-operations)
  - [Creating Directories](#creating-directories)
  - [Reading Directories](#reading-directories)
  - [Walking Directory Trees](#walking-directory-trees)
  - [Removing Directories](#removing-directories)
- [File Watching](#file-watching)
- [File Metadata](#file-metadata)
  - [File Kind](#file-kind)
  - [Timestamps](#timestamps)
  - [File Permissions](#file-permissions)
- [Path Operations](#path-operations)
- [Types Reference](#types-reference)

## File Operations

### Opening and Creating Files

The `open` function provides flexible file opening with various modes and options:

```moonbit check
///|
#cfg(target="native")
async test "open file for reading" {
  let test_file = "_build/test_open_read.txt"
  @fs.write_text(test_file, "Hello, MoonBit!")
  defer @fs.remove(test_file)
  let file = @fs.open(test_file, mode=ReadOnly)
  defer file.close()
  let content = file.text.read_all()
  inspect(content, content="Hello, MoonBit!")
}

///|
#cfg(target="native")
async test "open file for writing" {
  let test_file = "_build/test_open_write.txt"
  let file = @fs.open(test_file, mode=WriteOnly, create_mode=CreateOrTruncate)
  defer @fs.remove(test_file)
  defer file.close()
  file.text.write("Hello, World!")
}

///|
#cfg(target="native")
async test "open with append mode" {
  let test_file = "_build/test_append.txt"
  // Create initial file
  @fs.write_text(test_file, "First line\n")
  defer @fs.remove(test_file)

  // Append to existing file
  {
    let file = @fs.open(test_file, mode=WriteOnly, append=true)
    defer file.close()
    file.text.write("Second line\n")
  }
  let content = @fs.read_text(test_file)
  inspect(content, content="First line\nSecond line\n")
}
```

When `append=true`, sequential writes through the `@io.BinaryWriter` interface
always append to the current end of the file, even if another process extends
the file after it is opened. Append mode does not change read behavior, and
random-access writes with `write_at` are not supported on append-mode files.

The `create` function is a convenience wrapper for creating new files:

```moonbit check
///|
#cfg(target="native")
async test "create new file" {
  let test_file = "_build/test_create.txt"
  let file = @fs.create(test_file)
  defer @fs.remove(test_file)
  {
    defer file.close()
    file.write(b"New file content")
  }
  let exists = @fs.exists(test_file)
  inspect(exists, content="true")
}
```

### Reading Files

Use `read_text` for UTF-8 text, `read_binary` for raw bytes, or open a `File`
and use its binary reader methods (or its `.text` UTF-8 view):

```moonbit check
///|
#cfg(target="native")
async test "read_text - read an entire UTF-8 file" {
  let test_file = "_build/test_read_text.txt"
  @fs.write_text(test_file, "Hello, MoonBit!")
  defer @fs.remove(test_file)
  let content = @fs.read_text(test_file)
  inspect(content, content="Hello, MoonBit!")
}

///|
#cfg(target="native")
async test "read in chunks using File" {
  let test_file = "_build/test_chunk_read.txt"
  @fs.write_binary(test_file, b"0123456789")
  defer @fs.remove(test_file)
  let file = @fs.open(test_file, mode=ReadOnly)
  defer file.close()
  let buf = FixedArray::make(5, b'0')
  let n = file.read_into(buf)
  inspect(n, content="5")
  inspect(@utf8.decode(buf.unsafe_reinterpret_as_bytes()), content="01234")
}

///|
#cfg(target="native")
async test "read_all from file" {
  let test_file = "_build/test_read_all.txt"
  @fs.write_binary(test_file, b"Complete content")
  defer @fs.remove(test_file)
  let file = @fs.open(test_file, mode=ReadOnly)
  defer file.close()
  let data = file.read_all()
  inspect(@utf8.decode(data), content="Complete content")
}

///|
#cfg(target="native")
async test "read_exactly specific bytes" {
  let test_file = "_build/test_read_exact.txt"
  @fs.write_binary(test_file, b"1234567890")
  defer @fs.remove(test_file)
  let file = @fs.open(test_file, mode=ReadOnly)
  defer file.close()
  let bytes = file.read_exactly(5)
  inspect(@utf8.decode(bytes), content="12345")
}
```

`File` implements `@io.BinaryReader`, so its direct reader methods operate on
bytes. Use `file.text` when the file should be decoded as UTF-8 text. The read
stream position is independent of the write stream position.

### Writing Files

Use `write_binary` for bytes, `write_text` for UTF-8 text, or write through an
open `File` (and its `.text` view):

```moonbit check
///|
#cfg(target="native")
async test "write_binary - write an entire file" {
  let test_file = "_build/test_write.txt"
  @fs.write_binary(test_file, b"File content")
  defer @fs.remove(test_file)
  let content = @fs.read_binary(test_file)
  inspect(@utf8.decode(content), content="File content")
}

///|
#cfg(target="native")
async test "write with sync modes" {
  let test_file = "_build/test_sync.txt"
  // Write with data sync
  @fs.write_text(test_file, "Synced data", sync=Data)
  defer @fs.remove(test_file)
  let content = @fs.read_text(test_file)
  inspect(content, content="Synced data")
}

///|
#cfg(target="native")
async test "write using File methods" {
  let test_file = "_build/test_file_write.txt"
  let file = @fs.create(test_file)
  defer @fs.remove(test_file)
  {
    defer file.close()
    file.text.write("Line 1\n")
    file.text.write("Line 2\n")
  }
  let content = @fs.read_text(test_file)
  inspect(content, content="Line 1\nLine 2\n")
}

///|
#cfg(target="native")
async test "write bytes through File" {
  let test_file = "_build/test_binary_write.txt"
  let file = @fs.create(test_file)
  defer @fs.remove(test_file)
  defer file.close()
  file.write(b"Binary data")
}
```

Sequential writes through the `@io.BinaryWriter` interface write a byte stream
starting at offset `0` by default. The write stream position is independent of
the read stream position. For files opened with `append=true`, sequential writes
append to the end of the file instead.

### Random access on files

Read and write file from specified position:

```moonbit check
///|
#cfg(target="native")
async test "read at specific position" {
  let test_file = "_build/read_at_test.txt"
  @fs.write_binary(test_file, b"0123456789")
  defer @fs.remove(test_file)
  let file = @fs.open(test_file, mode=ReadOnly)
  defer file.close()

  // read 3 bytes at position 5
  json_inspect(file.read_exactly_at(3, position=5), content="567")

  // use `read_at` to handle EOF robustly
  let buf = FixedArray::make(10, b'\x00')
  let n = file.read_at(buf, position=5)
  inspect(n, content="5")
  json_inspect(buf.unsafe_reinterpret_as_bytes()[:n], content="56789")
}

///|
#cfg(target="native")
async test "write at specific position" {
  let test_file = "_build/write_at_test.txt"
  let file = @fs.open(test_file, mode=WriteOnly, create_mode=CreateOrTruncate)
  defer @fs.remove(test_file)
  {
    defer file.close()
    file.write(b"abcdef")
    file.write_at(b"CD", position=2)
  }

  // read 3 bytes at position 5
  inspect(@fs.read_text(test_file), content="abCDef")
}

///|
#cfg(target="native")
async test "size - get file size" {
  let test_file = "_build/test_size.txt"
  @fs.write_binary(test_file, b"Hello")
  defer @fs.remove(test_file)
  let file = @fs.open(test_file, mode=ReadOnly)
  defer file.close()
  let size = file.size()
  inspect(size, content="5")
}
```

Some important notes when using `read_at` and `write_at`:

- only seekable files (i.e. regular files or block devices) support `read_at` and `write_at`. Calling `read_at` and `write_at` on unsupported file types result in error
- `read_at` and `write_at` does not modify the cursor for reading/writing the file as a stream
- `read_at` always read as much as possible. When its return value is smaller than requested length, it always indicates EOF
- `write_at` is forbidden on files opened with `append=true`; use sequential writes to append data

## Directory Operations

### Creating Directories

```moonbit check
///|
#cfg(target="native")
async test "mkdir - create directory" {
  let dir_path = "_build/test_mkdir"
  @fs.mkdir(dir_path, permission=0o755)
  defer @fs.rmdir(dir_path)
  let exists = @fs.exists(dir_path)
  inspect(exists, content="true")
}

///|
#cfg(target="native")
async test "mkdir - create with custom permissions" {
  let dir_path = "_build/test_mkdir_perm"
  @fs.mkdir(dir_path, permission=0o700)
  defer @fs.rmdir(dir_path)
  let kind = @fs.kind(dir_path)
  debug_inspect(kind, content="Directory")
}
```

### Reading Directories

```moonbit check
///|
#cfg(target="native")
async test "readdir - read directory entries" {
  let dir_path = "_build/test_readdir"
  @fs.mkdir(dir_path, permission=0o755)
  defer @fs.rmdir(dir_path, recursive=true)
  @fs.write_binary("\{dir_path}/test1.txt", b"")
  @fs.write_binary("\{dir_path}/test2.txt", b"")
  let entries = @fs.readdir(
    dir_path,
    include_hidden=false,
    include_special=false,
  )
  // avoid platform inconsistent ordering
  entries.sort()
  json_inspect(entries, content=["test1.txt", "test2.txt"])
}

///|
#cfg(target="native")
async test "readdir with sorting" {
  let dir_path = "_build/test_readdir_sort"
  @fs.mkdir(dir_path, permission=0o755)
  defer @fs.rmdir(dir_path, recursive=true)
  @fs.write_binary("\{dir_path}/c.txt", b"")
  @fs.write_binary("\{dir_path}/a.txt", b"")
  @fs.write_binary("\{dir_path}/b.txt", b"")
  let entries = @fs.readdir(dir_path, sort=true)
  json_inspect(entries, content=["a.txt", "b.txt", "c.txt"])
}

///|
#cfg(target="native")
async test "opendir and Directory::read_all" {
  let dir_path = "_build/test_opendir"
  @fs.mkdir(dir_path, permission=0o755)
  defer @fs.rmdir(dir_path, recursive=true)
  @fs.write_binary("\{dir_path}/file1.txt", b"test")
  @fs.write_binary("\{dir_path}/file2.txt", b"test")
  let dir = @fs.opendir(dir_path)
  defer dir.close()
  let entries = dir
    .read_all(include_hidden=false, include_special=false)
    ..sort()
  json_inspect(entries, content=["file1.txt", "file2.txt"])
}
```

### Walking Directory Trees

Recursively traverse directory hierarchies:

```moonbit check
///|
#cfg(target="native")
async test "walk directory tree" {
  let base = "_build/test_walk"
  @fs.mkdir(base)
  defer @fs.rmdir(base, recursive=true)
  @fs.mkdir("\{base}/sub1")
  @fs.mkdir("\{base}/sub2")
  @fs.write_binary("\{base}/file.txt", b"")
  @fs.write_binary("\{base}/sub1/file1.txt", b"")
  let visited : Ref[Int32] = Ref(0)
  @fs.walk(base, fn(_path, _files) { visited.val = visited.val + 1 })
  inspect(visited.val >= 3, content="true")
}

///|
#cfg(target="native")
async test "walk with max_concurrency" {
  let base = "_build/test_walk_concurrency"
  @fs.mkdir(base, permission=0o755)
  defer @fs.rmdir(base, recursive=true)
  @fs.mkdir("\{base}/dir1", permission=0o755)
  @fs.mkdir("\{base}/dir2", permission=0o755)
  let count : Ref[Int32] = Ref(0)
  @fs.walk(
    base,
    fn(_path, _files) { count.val = count.val + 1 },
    max_concurrency=1,
  )
  inspect(count.val >= 3, content="true")
}
```

### Removing Directories

```moonbit check
///|
#cfg(target="native")
async test "rmdir - remove empty directory" {
  let dir_path = "_build/test_rmdir"
  @fs.mkdir(dir_path)
  @fs.rmdir(dir_path)
  let exists = @fs.exists(dir_path)
  inspect(exists, content="false")
}

///|
#cfg(target="native")
async test "rmdir recursive - remove directory tree" {
  let base = "_build/test_rmdir_recursive"
  @fs.mkdir(base)
  @fs.mkdir("\{base}/subdir")
  @fs.write_binary("\{base}/file.txt", b"test")
  @fs.write_binary("\{base}/subdir/nested.txt", b"test")
  @fs.rmdir(base, recursive=true)
  let exists = @fs.exists(base)
  inspect(exists, content="false")
}
```

## File Metadata

### File Kind

Determine the type of file system entries:

```moonbit check
///|
#cfg(target="native")
async test "kind - regular file" {
  let test_file = "_build/test_kind_file.txt"
  @fs.write_binary(test_file, b"test")
  defer @fs.remove(test_file)
  let kind = @fs.kind(test_file)
  debug_inspect(kind, content="Regular")
}

///|
#cfg(target="native")
async test "kind - directory" {
  let dir_path = "_build/test_kind_dir"
  @fs.mkdir(dir_path, permission=0o755)
  defer @fs.rmdir(dir_path)
  let kind = @fs.kind(dir_path)
  debug_inspect(kind, content="Directory")
}

///|
#cfg(target="native")
async test "File::kind method" {
  let test_file = "_build/test_file_kind.txt"
  @fs.write_binary(test_file, b"test")
  defer @fs.remove(test_file)
  let file = @fs.open(test_file, mode=ReadOnly)
  defer file.close()
  let kind = file.kind()
  debug_inspect(kind, content="Regular")
}
```

### Timestamps

Access file timestamps (atime, mtime, ctime):

```moonbit check
///|
#cfg(all(target="native", not(platform="windows")))
async test "atime - access time" {
  let test_file = "_build/test_atime.txt"
  @fs.write_binary(test_file, b"test")
  defer @fs.remove(test_file)
  let ts = @fs.atime(test_file)
  inspect(ts.sec() > 0, content="true")
  inspect(ts.nsec() >= 0, content="true")
}

///|
#cfg(target="native")
async test "mtime - modification time" {
  let test_file = "_build/test_mtime.txt"
  @fs.write_binary(test_file, b"test")
  defer @fs.remove(test_file)
  let ts = @fs.mtime(test_file)
  inspect(ts.sec() > 0, content="true")
  inspect(ts.nsec() >= 0, content="true")
}

///|
#cfg(target="native")
async test "ctime - status change time" {
  let test_file = "_build/test_ctime.txt"
  @fs.write_binary(test_file, b"test")
  defer @fs.remove(test_file)
  let ts = @fs.ctime(test_file)
  inspect(ts.sec() > 0, content="true")
  inspect(ts.nsec() >= 0, content="true")
}

///|
#cfg(target="native")
async test "File timestamp methods" {
  let test_file = "_build/test_file_times.txt"
  @fs.write_binary(test_file, b"test")
  defer @fs.remove(test_file)
  let file = @fs.open(test_file, mode=ReadOnly)
  defer file.close()
  let atime = file.atime()
  let mtime = file.mtime()
  let ctime = file.ctime()
  inspect(atime.sec() > 0, content="true")
  inspect(mtime.sec() > 0, content="true")
  inspect(ctime.sec() > 0, content="true")
}
```

### File Permissions

Check file access permissions:

```moonbit check
///|
#cfg(target="native")
async test "exists - check file existence" {
  let test_file = "_build/test_exists.txt"
  @fs.write_binary(test_file, b"test")
  defer @fs.remove(test_file)
  let exists = @fs.exists(test_file)
  inspect(exists, content="true")
}

///|
#cfg(target="native")
async test "exists - non-existent file" {
  let exists = @fs.exists("nonexistent_file_xyz.txt")
  inspect(exists, content="false")
}

///|
#cfg(target="native")
async test "can_read - check read permission" {
  let test_file = "_build/test_can_read.txt"
  @fs.write_binary(test_file, b"test")
  defer @fs.remove(test_file)
  let can_read = @fs.can_read(test_file)
  inspect(can_read, content="true")
}

///|
#cfg(target="native")
async test "can_write - check write permission" {
  let test_file = "_build/test_can_write.txt"
  @fs.write_binary(test_file, b"test")
  defer @fs.remove(test_file)
  let can_write = @fs.can_write(test_file)
  inspect(can_write, content="true")
}

///|
#cfg(target="native")
async test "can_execute - check execute permission" {
  let test_file = "_build/test_can_execute.txt"
  @fs.write_binary(test_file, b"test", create_mode=CreateNew, permission=0o755)
  defer @fs.remove(test_file)
  let can_execute = @fs.can_execute(test_file)
  inspect(can_execute, content="true")
}
```

### File Size
```moonbit nocheck
///|
#cfg(target="native")
async test "get file size by path" {
  let test_file = "_build/test_size_by_path.txt"
  @fs.write_binary(test_file, b"Hello")
  inspect(@fs.file_size(test_file), content="5")
}
```


## Path Operations

```moonbit check
///|
#cfg(target="native")
async test "realpath - resolve absolute path" {
  let test_dir = "_build/test_realpath"
  @fs.mkdir(test_dir)
  defer @fs.rmdir(test_dir)
  let real_path = @fs.realpath(test_dir)
  guard! @env.current_dir() is Some(cwd)
  assert_true(real_path.has_prefix(cwd))
  inspect(
    // replace `\\` with `/` for Windows
    real_path[cwd.length():].replace_all(old="\\", new="/"),
    content="/_build/test_realpath",
  )
}
```

## File Removal

```moonbit check
///|
#cfg(target="native")
async test "remove - delete file" {
  let test_file = "_build/test_remove.txt"
  @fs.write_binary(test_file, b"test")
  defer (if @fs.exists(test_file) { @fs.remove(test_file) })
  @fs.remove(test_file)
  let exists = @fs.exists(test_file)
  inspect(exists, content="false")
}
```

## File Watching

`Watcher` watches a directory tree recursively and reports file system changes as
[`FsEvent`](#fsevent) values. Events use paths relative to the watched directory,
with `/` as the path separator. New files and directories are added to the
watched tree automatically, and removed entries are unwatched automatically.
Calling `.wait()` on the watcher will block and wait until the watched tree has changed
since the last `.wait()` or `.wait_any()` call.
A list of events describing the net changes on the watched tree
since the last query will be returned.
Note that events returned by `.wait()` report net change rather than detailed transaction.
So for example a create event followed by a remove event on the same location will cancel each other.
If the user only cares about when the watched tree change,
and does not care about the detailed list of changes,
`.wait_any()` can be used, which is slightly faster than `.wait()`.

The watcher performs aggresive global rename detection using the physical identity of files.
There are several cases where the watcher will not report rename event though:

- renaming of directories are only reported as `Rename` when the renaming happen within the same parent directory
- some rename sequences cannot be serialized as binary `Rename`, such as swapping two files

In these cases, the rename will be split into separated `Remove` and `Create` events.

The following options are available on watcher creation:

- File system notifications are often delivered in bursts, so the watcher
  debounces changes by default. The debounce behavior can be configured by the
  `debounce_timeout` and `max_debounce_delay` options on watcher creation.
  The watcher will wait until no event happens for `debounce_timeout` milliseconds
  before reporting any events, but the total wait time will never exceed
  `max_debounce_delay` milliseconds.
- `ignored_paths`, if present, can be used to filter out paths that the user don't want to watch.
  When a file or directory is going to be watched, its path
  (relative to root of watched tree, using `/` as path separator, always without trailing `/`)
  will be supplied to `ignored_paths`.
  If `ignored_paths` return `true`, the file or directory will be ignored.
  When a directory is ignored, all files/directories within it are also ignored.
  So to ignore a single directory,
  `ignored_paths` only need to handle paths of the files inside that ignored directory.
- When a create/remove event is reported for a directory:
  + if `report_child_event=true`, respective create/remove events will be emitted
    for everything inside that directory.
    This mode is useful if tracking the exact list of files in desirable.
  + If `report_child_event=false` (the default),
    only a single event for the directory itself will be emitted,
    making the watcher less noisy
- If `report_event_on_init=true` (`false` by default),
  the first `wait` call will return immediately after watcher creation,
  reporting events describing the initial structure of the watched directory.
  This is useful for keeping the knowledge of the caller in sync with the watcher.
  Note that you probably want to set `report_child_event=true` as well in this case.

```moonbit nocheck
///|
#cfg(target="native")
async fn watch_project_sources() -> Unit {
  let watcher = @fs.Watcher("src", ignored_paths=path => {
    path.has_prefix("_build/")
  })
  defer watcher.close()
  while watcher.wait() is events {
    debug(events)
  }
}
```

## Types Reference

### FileKind

Represents the type of a file system entry:

- `Regular` - Regular file
- `Directory` - Directory
- `SymLink` - Symbolic link
- `Socket` - Unix socket
- `Pipe` - Named pipe (FIFO)
- `BlockDevice` - Block device
- `CharDevice` - Character device
- `Unknown` - Unknown file type

### Mode

File opening mode:

- `ReadOnly` - Open for reading only
- `WriteOnly` - Open for writing only
- `ReadWrite` - Open for both reading and writing

### SyncMode

Data synchronization mode:

- `NoSync` - No synchronization (default)
- `Data` - Sync data and essential metadata (like file size)
- `Full` - Sync all data and metadata

### SeekMode

How to interpret seek offsets:

- `FromStart` - Absolute offset from start of file
- `FromEnd` - Offset relative to end of file
- `Relative` - Offset relative to current position

### File

Main file handle type. Methods include:
- `fd()` - Get file descriptor
- `close()` - Close file
- `read_into()` - Read data into a caller-provided buffer
- `read()` - Read and return the next chunk of bytes
- `read_all()` - Read entire file content
- `read_exactly()` - Read exact number of bytes
- `write()` - Write data
- `text` - UTF-8 text reader/writer view over the same file streams
- `read_at()` - Read file at specified position
- `read_exact_at()` - Read exect number of bytes at specified position
- `write_at()` - Write file at specified position
- `size()` - Get file size
- `kind()` - Get file kind
- `atime()`, `mtime()`, `ctime()` - Get timestamps

### Directory

Directory handle for reading directory entries:
- `close()` - Close directory
- `read_all()` - Read all entries

### FsEvent

`FsEvent` describes a net change reported by `Watcher::wait`.
All paths are relative to the watched directory and use `/` as the path separator.

- `Modify(path)` reports that the regular file at `path` has been modified.
- `Create(path)` reports that a file or directory now exists at `path`.
- `Remove(path)` reports that the file or directory at `path` has been removed.
- `Rename(old~, new~)` reports that a file or directory moved from `old` to `new`.

## Best Practices

1. **Always close files**: Use `defer file.close()` after opening files
2. **Use appropriate sync modes**: `NoSync` for performance, `Data` or `Full` for durability
3. **Handle permissions**: Specify appropriate UNIX permissions (e.g., `0o644` for files, `0o755` for directories)
4. **Check existence**: Use `exists()` before performing operations on files
5. **Use convenience functions**: `read_binary()`/`write_binary()` and `read_text()`/`write_text()` are simpler for common cases
6. **Walk with limits**: Use `max_concurrency` parameter when walking large directory trees

## Error Handling

All async file operations can raise errors. Use proper error handling:

```moonbit check
///|
#cfg(target="native")
async test "error handling example" {
  @test.assert_raise_async(() => @fs.read_binary("nonexistent.txt"))
}
```

For more examples and detailed usage, see the individual test files in this package.
