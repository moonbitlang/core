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
enum TestFile {
  File(String) // content of file
  Dir(Map[String, TestFile])
}

///|
async fn TestFile::instantiate(self : TestFile, path : String) -> Unit {
  match self {
    File(content) => @fs.write_text(path, content)
    Dir(files) => {
      @fs.mkdir(path)
      for name, file in files {
        file.instantiate("\{path}/\{name}")
      }
    }
  }
}

///|
async fn watch_basic_test(
  path : String,
  report_child_event~ : Bool,
) -> Array[String] {
  let log = []
  let test_dir = Dir({
    "root_file": File("abcd"),
    "inner_dir": Dir({ "inner_file": File("efgh") }),
  })
  test_dir.instantiate(path)
  defer @fs.rmdir(path, recursive=true)

  let watcher = @fs.Watcher(path, report_child_event~)
  defer watcher.close()

  async fn wait() {
    let events = @async_io.with_timeout(300, () => watcher.wait())
    log.push("watcher received change: \{Repr(events)}")
  }
  // 1. modify content of existing file at root
  log.push("writing to root file")
  @fs.write_text("\{path}/root_file", "ABCD", create_mode=OpenExisting)
  wait()

  // 2. modify content of existing file at inner directory
  log.push("writing to inner file")
  @fs.write_text(
    "\{path}/inner_dir/inner_file",
    "EFGH",
    create_mode=OpenExisting,
  )
  wait()

  // 3. create file in root directory
  {
    log.push("creating new file in root directory")
    let file = @fs.create("\{path}/root_file2")
    defer file.close()
    wait()

    // 4. modify content of newly created file at root directory
    log.push("writing to newly created root file")
    file.write(b"ABCD")
  }
  wait()

  // 5. create file in inner directory
  {
    log.push("creating new file in inner directory")
    let file = @fs.create("\{path}/inner_dir/inner_file2")
    defer file.close()
    wait()

    // 6. modify content of newly created file at inner directory
    log.push("writing to newly created inner file")
    file.write(b"EFGH")
  }
  wait()

  // 7. remove a file in root directory
  log.push("removing file in root directory")
  @fs.remove("\{path}/root_file")
  wait()

  // 8. remove a file in inner directory
  log.push("removing file in inner directory")
  @fs.remove("\{path}/inner_dir/inner_file2")
  wait()

  // 9. remove inner directory recursively
  log.push("removing inner directory")
  @fs.rmdir("\{path}/inner_dir", recursive=true)
  wait()

  // 10. create new inner directory
  log.push("creating new directory in root directory")
  @fs.mkdir("\{path}/inner_dir")
  wait()

  // 11. create new file in newly created inner directory
  {
    log.push("creating new file in inner directory")
    let file = @fs.create("\{path}/inner_dir/inner_file")
    defer file.close()
    wait()

    // 12. modify content of newly created file at newly created inner directory
    log.push("writing to newly created inner file")
    file.write(b"EFGH")
  }
  wait()
  log
}

///|
async test "watch basic" {
  let log = watch_basic_test(
    "_build/watch_basic_test",
    report_child_event=false,
  )
  inspect(
    log.join("\n"),
    content=(
      #|writing to root file
      #|watcher received change: [Modify("root_file")]
      #|writing to inner file
      #|watcher received change: [Modify("inner_dir/inner_file")]
      #|creating new file in root directory
      #|watcher received change: [Create("root_file2")]
      #|writing to newly created root file
      #|watcher received change: [Modify("root_file2")]
      #|creating new file in inner directory
      #|watcher received change: [Create("inner_dir/inner_file2")]
      #|writing to newly created inner file
      #|watcher received change: [Modify("inner_dir/inner_file2")]
      #|removing file in root directory
      #|watcher received change: [Remove("root_file")]
      #|removing file in inner directory
      #|watcher received change: [Remove("inner_dir/inner_file2")]
      #|removing inner directory
      #|watcher received change: [Remove("inner_dir")]
      #|creating new directory in root directory
      #|watcher received change: [Create("inner_dir")]
      #|creating new file in inner directory
      #|watcher received change: [Create("inner_dir/inner_file")]
      #|writing to newly created inner file
      #|watcher received change: [Modify("inner_dir/inner_file")]
    ),
  )
}

///|
async test "watch basic with child" {
  let log = watch_basic_test(
    "_build/watch_basic_with_child_test",
    report_child_event=true,
  )
  inspect(
    log.join("\n"),
    content=(
      #|writing to root file
      #|watcher received change: [Modify("root_file")]
      #|writing to inner file
      #|watcher received change: [Modify("inner_dir/inner_file")]
      #|creating new file in root directory
      #|watcher received change: [Create("root_file2")]
      #|writing to newly created root file
      #|watcher received change: [Modify("root_file2")]
      #|creating new file in inner directory
      #|watcher received change: [Create("inner_dir/inner_file2")]
      #|writing to newly created inner file
      #|watcher received change: [Modify("inner_dir/inner_file2")]
      #|removing file in root directory
      #|watcher received change: [Remove("root_file")]
      #|removing file in inner directory
      #|watcher received change: [Remove("inner_dir/inner_file2")]
      #|removing inner directory
      #|watcher received change: [Remove("inner_dir/inner_file"), Remove("inner_dir")]
      #|creating new directory in root directory
      #|watcher received change: [Create("inner_dir")]
      #|creating new file in inner directory
      #|watcher received change: [Create("inner_dir/inner_file")]
      #|writing to newly created inner file
      #|watcher received change: [Modify("inner_dir/inner_file")]
    ),
  )
}

///|
async fn watch_rename_within_test(
  path : String,
  report_child_event~ : Bool,
) -> Array[String] {
  let log = []
  let test_dir = Dir({
    "root_file": File("abcd"),
    "inner_dir": Dir({ "inner_file": File("efgh") }),
  })
  test_dir.instantiate(path)
  defer @fs.rmdir(path, recursive=true)

  let watcher = @fs.Watcher(path, report_child_event~)
  defer watcher.close()

  async fn wait() {
    let events = @async_io.with_timeout(300, () => watcher.wait())
    log.push("watcher received change: \{Repr(events)}")
  }
  // 1. rename within the same directory
  log.push("rename: inner_dir/inner_file => inner_dir/inner_file2")
  @fs.rename("\{path}/inner_dir/inner_file", "\{path}/inner_dir/inner_file2")
  wait()

  // 2. modify file renamed within the same directory
  log.push("writing to inner_dir/inner_file2")
  @fs.write_text(
    "\{path}/inner_dir/inner_file2",
    "efgh",
    create_mode=OpenExisting,
  )
  wait()

  // 3. rename directory
  log.push("rename: inner_dir => inner_dir2")
  @fs.rename("\{path}/inner_dir", "\{path}/inner_dir2")
  wait()

  // 4. modify file within renamed directory
  log.push("writing to inner_dir2/inner_file2")
  @fs.write_text(
    "\{path}/inner_dir2/inner_file2",
    "EFGH",
    create_mode=OpenExisting,
  )
  wait()

  // 5. rename across directory, but within watched tree
  log.push("rename: inner_dir2/inner_file2 => root_file2")
  @fs.rename("\{path}/inner_dir2/inner_file2", "\{path}/root_file2")
  wait()

  // 6. modify file moved across directory but still within watched tree
  log.push("writing to root_file2")
  @fs.write_text("\{path}/root_file2", "EFGH", create_mode=OpenExisting)
  wait()

  // 7. rename file replaces existing file
  log.push("rename root_file2 to replace root_file")
  @fs.rename("\{path}/root_file2", "\{path}/root_file")
  wait()
  log
}

///|
async test "watch rename within" {
  let log = watch_rename_within_test(
    "_build/watch_rename_within_test",
    report_child_event=false,
  )
  inspect(
    log.join("\n"),
    content=(
      #|rename: inner_dir/inner_file => inner_dir/inner_file2
      #|watcher received change: [Rename(old="inner_dir/inner_file", new="inner_dir/inner_file2")]
      #|writing to inner_dir/inner_file2
      #|watcher received change: [Modify("inner_dir/inner_file2")]
      #|rename: inner_dir => inner_dir2
      #|watcher received change: [Rename(old="inner_dir", new="inner_dir2")]
      #|writing to inner_dir2/inner_file2
      #|watcher received change: [Modify("inner_dir2/inner_file2")]
      #|rename: inner_dir2/inner_file2 => root_file2
      #|watcher received change: [Rename(old="inner_dir2/inner_file2", new="root_file2")]
      #|writing to root_file2
      #|watcher received change: [Modify("root_file2")]
      #|rename root_file2 to replace root_file
      #|watcher received change: [Remove("root_file"), Rename(old="root_file2", new="root_file")]
    ),
  )
}

///|
async test "watch rename within with child" {
  let log = watch_rename_within_test(
    "_build/watch_rename_within_with_child_test",
    report_child_event=true,
  )
  inspect(
    log.join("\n"),
    content=(
      #|rename: inner_dir/inner_file => inner_dir/inner_file2
      #|watcher received change: [Rename(old="inner_dir/inner_file", new="inner_dir/inner_file2")]
      #|writing to inner_dir/inner_file2
      #|watcher received change: [Modify("inner_dir/inner_file2")]
      #|rename: inner_dir => inner_dir2
      #|watcher received change: [Rename(old="inner_dir", new="inner_dir2")]
      #|writing to inner_dir2/inner_file2
      #|watcher received change: [Modify("inner_dir2/inner_file2")]
      #|rename: inner_dir2/inner_file2 => root_file2
      #|watcher received change: [Rename(old="inner_dir2/inner_file2", new="root_file2")]
      #|writing to root_file2
      #|watcher received change: [Modify("root_file2")]
      #|rename root_file2 to replace root_file
      #|watcher received change: [Remove("root_file"), Rename(old="root_file2", new="root_file")]
    ),
  )
}

///|
async fn watch_rename_inout_test(
  base_path : String,
  report_child_event~ : Bool,
) -> Array[String] {
  let log = []
  let test_dir = Dir({
    "watched": Dir({
      "root_file": File("abcd"),
      "inner_dir": Dir({ "inner_file": File("efgh") }),
    }),
  })
  test_dir.instantiate(base_path)
  defer @fs.rmdir(base_path, recursive=true)
  let watched_path = "\{base_path}/watched"

  let watcher = @fs.Watcher(watched_path, report_child_event~)
  defer watcher.close()

  async fn wait() {
    let events = @async_io.with_timeout(300, () => watcher.wait())
    log.push("watcher received change: \{Repr(events)}")
  }
  // 1. move foreign file inside watched tree
  @fs.write_text("\{base_path}/foreign_file", "1234", create_mode=CreateNew)
  log.push("moving foreign file inside watched tree")
  @fs.rename("\{base_path}/foreign_file", "\{watched_path}/moved_in_file")
  wait()

  // 2. modify moved in file
  log.push("writing to moved_in_file")
  @fs.write_text(
    "\{watched_path}/moved_in_file",
    "5678",
    create_mode=OpenExisting,
  )
  wait()

  // 3. move foreign directory inside watched tree
  let foreign_dir = Dir({ "foreign_file": File("xyzw") })
  foreign_dir.instantiate("\{base_path}/foreign_dir")
  log.push("moving foreign directory inside watched tree")
  @fs.rename("\{base_path}/foreign_dir", "\{watched_path}/moved_in_dir")
  wait()

  // 4. modify file within moved in directory
  log.push("writing to moved_in_dir/foreign_file")
  @fs.write_text(
    "\{watched_path}/moved_in_dir/foreign_file",
    "XYZW",
    create_mode=OpenExisting,
  )
  wait()

  // 5. move file outside watched tree
  log.push("moving file outside watched tree")
  @fs.rename("\{watched_path}/moved_in_file", "\{base_path}/moved_out_file")
  wait()

  // 6. modify moved out file
  log.push("writing to moved_out_file")
  @fs.write_text(
    "\{base_path}/moved_out_file",
    "1234",
    create_mode=OpenExisting,
  )
  assert_true(@test.expect_error_async(() => wait()) is @async_io.TimeoutError)

  // 7. remove moved out file
  log.push("removing moved out file")
  @fs.remove("\{base_path}/moved_out_file")
  assert_true(@test.expect_error_async(() => wait()) is @async_io.TimeoutError)

  // 8. move directory outside watched tree
  log.push("moving directory outside watched tree")
  @fs.rename("\{watched_path}/moved_in_dir", "\{base_path}/moved_out_dir")
  wait()

  // 9. modify file inside moved out directoy
  log.push("writing to moved_out_dir/foreign_file")
  @fs.write_text(
    "\{base_path}/moved_out_dir/foreign_file",
    "xyzw",
    create_mode=OpenExisting,
  )
  assert_true(@test.expect_error_async(() => wait()) is @async_io.TimeoutError)

  // 10. remove moved out file
  log.push("removing moved out directory")
  @fs.rmdir("\{base_path}/moved_out_dir", recursive=true)
  assert_true(@test.expect_error_async(() => wait()) is @async_io.TimeoutError)

  // 11. moved in file overwrites existing file
  log.push("renaming foreign file to replace root_file")
  @fs.write_text("\{base_path}/foreign_file", "1234", create_mode=CreateNew)
  @fs.rename("\{base_path}/foreign_file", "\{watched_path}/root_file")
  wait()

  // 12. moved in directory cannot replace existing directory: forbidden by OS
  log
}

///|
async test "watch rename inout test" {
  let log = watch_rename_inout_test(
    "_build/watch_rename_inout_test",
    report_child_event=false,
  )
  inspect(
    log.join("\n"),
    content=(
      #|moving foreign file inside watched tree
      #|watcher received change: [Create("moved_in_file")]
      #|writing to moved_in_file
      #|watcher received change: [Modify("moved_in_file")]
      #|moving foreign directory inside watched tree
      #|watcher received change: [Create("moved_in_dir")]
      #|writing to moved_in_dir/foreign_file
      #|watcher received change: [Modify("moved_in_dir/foreign_file")]
      #|moving file outside watched tree
      #|watcher received change: [Remove("moved_in_file")]
      #|writing to moved_out_file
      #|removing moved out file
      #|moving directory outside watched tree
      #|watcher received change: [Remove("moved_in_dir")]
      #|writing to moved_out_dir/foreign_file
      #|removing moved out directory
      #|renaming foreign file to replace root_file
      #|watcher received change: [Remove("root_file"), Create("root_file")]
    ),
  )
}

///|
async test "watch rename inout with child test" {
  let log = watch_rename_inout_test(
    "_build/watch_rename_inout_with_child_test",
    report_child_event=true,
  )
  inspect(
    log.join("\n"),
    content=(
      #|moving foreign file inside watched tree
      #|watcher received change: [Create("moved_in_file")]
      #|writing to moved_in_file
      #|watcher received change: [Modify("moved_in_file")]
      #|moving foreign directory inside watched tree
      #|watcher received change: [Create("moved_in_dir"), Create("moved_in_dir/foreign_file")]
      #|writing to moved_in_dir/foreign_file
      #|watcher received change: [Modify("moved_in_dir/foreign_file")]
      #|moving file outside watched tree
      #|watcher received change: [Remove("moved_in_file")]
      #|writing to moved_out_file
      #|removing moved out file
      #|moving directory outside watched tree
      #|watcher received change: [Remove("moved_in_dir/foreign_file"), Remove("moved_in_dir")]
      #|writing to moved_out_dir/foreign_file
      #|removing moved out directory
      #|renaming foreign file to replace root_file
      #|watcher received change: [Remove("root_file"), Create("root_file")]
    ),
  )
}

///|
async test "watch horizontal swap" {
  @async_io.with_task_group(group => {
    let path = "_build/watch_swap_test"
    let test_dir = Dir({ "file1": File("abcd"), "file2": File("efgh") })
    test_dir.instantiate(path)
    group.add_defer(() => {
      @async_io.protect_from_cancel(() => @fs.rmdir(path, recursive=true))
    })
    let watcher = @fs.Watcher(path)
    defer watcher.close()
    @fs.rename("\{path}/file1", "\{path}/tmp")
    @fs.rename("\{path}/file2", "\{path}/file1")
    @fs.rename("\{path}/tmp", "\{path}/file2")
    @async_io.sleep(10)
    let events = @async_io.with_timeout(1000, () => watcher.wait())
    @debug.assert_eq(events, [
      Remove("file2"),
      Remove("file1"),
      Create("file2"),
      Create("file1"),
    ]) catch {
      _ =>
        @debug.assert_eq(events, [
          Remove("file1"),
          Remove("file2"),
          Create("file1"),
          Create("file2"),
        ])
    }
  })
}

///|
async fn watch_vertical_swap_test(
  path : String,
  report_child_event~ : Bool,
) -> Array[String] {
  let log = []
  @async_io.with_task_group(group => {
    let test_dir = Dir({
      "outer": Dir({
        "file": File("abcd"),
        "inner": Dir({ "file": File("efgh") }),
      }),
    })
    test_dir.instantiate(path)
    group.add_defer(() => {
      @async_io.protect_from_cancel(() => @fs.rmdir(path, recursive=true))
    })
    let watcher = @fs.Watcher(path, report_child_event~)
    defer watcher.close()
    log.push("performing vertical swapping")
    @fs.rename("\{path}/outer/inner", "\{path}/tmp")
    @fs.rename("\{path}/outer", "\{path}/tmp/inner")
    @fs.rename("\{path}/tmp", "\{path}/outer")
    @async_io.sleep(10)
    let events = @async_io.with_timeout(1000, () => watcher.wait())
    log.push("watcher received change: \{Repr(events)}")
    log.push("modifying previous outer file")
    @fs.write_text("\{path}/outer/inner/file", "ABCD", create_mode=OpenExisting)
    let events = @async_io.with_timeout(1000, () => watcher.wait())
    log.push("watcher received change: \{Repr(events)}")
    log.push("modifying previous inner file")
    @fs.write_text("\{path}/outer/file", "EFGH", create_mode=OpenExisting)
    let events = @async_io.with_timeout(1000, () => watcher.wait())
    log.push("watcher received change: \{Repr(events)}")
  })
  log
}

///|
async test "watch vertical swap" {
  let log = watch_vertical_swap_test(
    "_build/watch_vertical_swap_test",
    report_child_event=false,
  )
  inspect(
    log.join("\n"),
    content=(
      #|performing vertical swapping
      #|watcher received change: [Remove("outer"), Create("outer")]
      #|modifying previous outer file
      #|watcher received change: [Modify("outer/inner/file")]
      #|modifying previous inner file
      #|watcher received change: [Modify("outer/file")]
    ),
  )
}

///|
async test "watch vertical swap with child" {
  let log = watch_vertical_swap_test(
    "_build/watch_vertical_swap_with_child_test",
    report_child_event=true,
  )
  inspect(
    log.join("\n"),
    content=(
      #|performing vertical swapping
      #|watcher received change: [
      #|  Remove("outer"),
      #|  Create("outer"),
      #|  Create("outer/file"),
      #|  Create("outer/inner"),
      #|  Create("outer/inner/file"),
      #|]
      #|modifying previous outer file
      #|watcher received change: [Modify("outer/inner/file")]
      #|modifying previous inner file
      #|watcher received change: [Modify("outer/file")]
    ),
  )
}

///|
async test "watch ignored path" {
  let log = []
  let path = "_build/watch_ignored_path_test"
  let test_dir = Dir({
    "ignored": Dir({ "file": File("abcd") }),
    "normal": Dir({ "file": File("efgh") }),
  })
  test_dir.instantiate(path)
  defer @fs.rmdir(path, recursive=true)

  let watcher = @fs.Watcher(path, ignored_paths=path => path is "ignored")
  defer watcher.close()

  async fn wait() {
    let events = @async_io.with_timeout(300, () => watcher.wait())
    log.push("watcher received change: \{Repr(events)}")
  }

  // 1. modify file in ignored path
  log.push("writing to ignored/file")
  @fs.write_text("\{path}/ignored/file", "ABCD", create_mode=OpenExisting)
  assert_true(@test.expect_error_async(() => wait()) is @async_io.TimeoutError)

  // 2. modify file in normal path
  log.push("writing to normal/file")
  @fs.write_text("\{path}/normal/file", "EFGH", create_mode=OpenExisting)
  wait()

  // 3. create file in ignored directory
  {
    log.push("creating new file in ignored directory")
    let file = @fs.create("\{path}/ignored/file2")
    defer file.close()
    assert_true(
      @test.expect_error_async(() => wait()) is @async_io.TimeoutError,
    )

    // 4. modify content of newly created file at ignored directory
    log.push("writing to newly created file in ignored directory")
    file.write(b"ABCD")
  }
  assert_true(@test.expect_error_async(() => wait()) is @async_io.TimeoutError)

  // 5. create file in normal directory
  {
    log.push("creating new file in normal directory")
    let file = @fs.create("\{path}/normal/file2")
    defer file.close()
    wait()

    // 6. modify content of newly created file at normal directory
    log.push("writing to newly created file in normal directory")
    file.write(b"EFGH")
  }
  wait()

  // 7. remove a file in ignored directory
  log.push("removing file in ignored directory")
  @fs.remove("\{path}/ignored/file")
  assert_true(@test.expect_error_async(() => wait()) is @async_io.TimeoutError)

  // 8. remove a file in normal directory
  log.push("removing file in normal directory")
  @fs.remove("\{path}/normal/file")
  wait()

  // 9. remove ignored directory
  log.push("removing ignored directory")
  @fs.rmdir("\{path}/ignored", recursive=true)
  assert_true(@test.expect_error_async(() => wait()) is @async_io.TimeoutError)

  // 10. remove normal directory
  log.push("removing normal directory")
  @fs.rmdir("\{path}/normal", recursive=true)
  wait()

  // 11. re-create directory at ignored path
  log.push("re-creating directory at ignored path")
  @fs.mkdir("\{path}/ignored")
  assert_true(@test.expect_error_async(() => wait()) is @async_io.TimeoutError)

  // 12. create new file in re-created ignored path
  {
    log.push("creating new file in re-created directory at ignored path")
    let file = @fs.create("\{path}/ignored/file")
    defer file.close()
    assert_true(
      @test.expect_error_async(() => wait()) is @async_io.TimeoutError,
    )

    // 13. create new file in re-created ignored path
    log.push("writing to newly created file in ignored directory")
    file.write(b"ABCD")
  }
  assert_true(@test.expect_error_async(() => wait()) is @async_io.TimeoutError)

  // 14. re-create directory at normal path
  log.push("re-creating directory at normal path")
  @fs.mkdir("\{path}/normal")
  wait()

  // 15. create new file in re-created normal path
  {
    log.push("creating new file in re-created directory at normal path")
    let file = @fs.create("\{path}/normal/file")
    defer file.close()
    wait()

    // 16. create new file in re-created normal path
    log.push("writing to newly created file in normal directory")
    file.write(b"EFGH")
  }
  wait()
  inspect(
    log.join("\n"),
    content=(
      #|writing to ignored/file
      #|writing to normal/file
      #|watcher received change: [Modify("normal/file")]
      #|creating new file in ignored directory
      #|writing to newly created file in ignored directory
      #|creating new file in normal directory
      #|watcher received change: [Create("normal/file2")]
      #|writing to newly created file in normal directory
      #|watcher received change: [Modify("normal/file2")]
      #|removing file in ignored directory
      #|removing file in normal directory
      #|watcher received change: [Remove("normal/file")]
      #|removing ignored directory
      #|removing normal directory
      #|watcher received change: [Remove("normal")]
      #|re-creating directory at ignored path
      #|creating new file in re-created directory at ignored path
      #|writing to newly created file in ignored directory
      #|re-creating directory at normal path
      #|watcher received change: [Create("normal")]
      #|creating new file in re-created directory at normal path
      #|watcher received change: [Create("normal/file")]
      #|writing to newly created file in normal directory
      #|watcher received change: [Modify("normal/file")]
    ),
  )
}

///|
async test "watch init event" {
  let test_dir = Dir({
    "root_file": File("abcd"),
    "inner_dir": Dir({ "inner_file": File("efgh") }),
  })
  let path = "_build/watch_init_event_test"
  test_dir.instantiate(path)
  defer @fs.rmdir(path, recursive=true)

  let watcher = @fs.Watcher(
    path,
    report_event_on_init=true,
    report_child_event=true,
  )
  defer watcher.close()
  debug_inspect(
    @async_io.with_timeout(1000, () => watcher.wait()),
    content=(
      #|[
      #|  Create("inner_dir"),
      #|  Create("inner_dir/inner_file"),
      #|  Create("root_file"),
      #|]
    ),
  )
}

///|
async test "watch debounce" {
  let test_dir = Dir({
    "watched": Dir({ "file": File("abcd"), "another_file": File("xyzw") }),
  })
  let path = "_build/watch_debounce_test"
  let watched_path = "\{path}/watched"
  test_dir.instantiate(path)
  defer @fs.rmdir(path, recursive=true)

  let log = StringBuilder()
  @async_io.with_task_group <| group => {
    let watcher = @fs.Watcher(
      watched_path,
      debounce_timeout=400,
      max_debounce_delay=600,
    )
    group.spawn_bg(no_wait=true) <| () => {
      defer watcher.close()
      for ;; {
        let events = watcher.wait()
        log.write("watcher received: \{Repr(events)}\n")
      }
    }

    // 1. multiple events happen within debounce interval
    log.write("rename happen within debounce interval\n")
    @fs.rename("\{watched_path}/file", "\{path}/file")
    @async_io.sleep(100)
    @fs.rename("\{path}/file", "\{watched_path}/file2")
    @async_io.sleep(600)

    // 2. exceed debounce interval
    log.write("rename longer than debounce interval\n")
    @fs.rename("\{watched_path}/file2", "\{path}/file")
    @async_io.sleep(600)
    @fs.rename("\{path}/file", "\{watched_path}/file")
    @async_io.sleep(600)

    // 3. exceed max interval
    log.write("rename exceed max debounce delay\n")
    @fs.rename("\{watched_path}/file", "\{path}/file")
    let start = @async_io.now()
    // Refresh the watcher with other events until max debounce delay exceeds
    while @async_io.now() - start < 650 {
      @async_io.sleep(200)
      // If we are too close to the deadline, don't perform refreshing,
      // to avoid an extra modification event from appearing in the result
      if @async_io.now() - start < 550 {
        @fs.write_text("\{watched_path}/another_file", "1234", sync=Full)
      }
    }
    @fs.rename("\{path}/file", "\{watched_path}/file2")
    @async_io.sleep(600)
  }
  inspect(
    log,
    content=(
      #|rename happen within debounce interval
      #|watcher received: [Rename(old="file", new="file2")]
      #|rename longer than debounce interval
      #|watcher received: [Remove("file2")]
      #|watcher received: [Create("file")]
      #|rename exceed max debounce delay
      #|watcher received: [Modify("another_file"), Remove("file")]
      #|watcher received: [Create("file2")]
      #|
    ),
  )
}
