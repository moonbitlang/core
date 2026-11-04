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
async test "timestamp for path" {
  // Windows may avoid updating access time eagerly, so keep the POSIX-style
  // atime/mtime/ctime assertions to non-Windows hosts. Wasm learns that host
  // platform at runtime instead of through MoonBit target cfg.
  if @event_loop.platform is Windows {
    return
  }
  let path = "/tmp/timestamp_test"
  @fs.write_text(path, "abcd", sync=Full)
  defer @fs.remove(path)
  let mtime_1 = @fs.mtime(path)
  let ctime_1 = @fs.ctime(path)
  @async.sleep(600)
  @fs.write_text(path, "1234", create_mode=OpenExisting, sync=Full)
  let atime_2 = @fs.atime(path)
  let mtime_2 = @fs.mtime(path)
  let ctime_2 = @fs.ctime(path)
  assert_true((mtime_2 - mtime_1).msec() > 500)
  assert_true((ctime_2 - ctime_1).msec() > 500)
  @async.sleep(600)
  inspect(@fs.read_text(path, sync_timestamp=true), content="1234")
  let atime_3 = @fs.atime(path)
  let mtime_3 = @fs.mtime(path)
  let ctime_3 = @fs.ctime(path)
  assert_true((atime_3 - atime_2).msec() > 500)
  @debug.assert_eq(mtime_3, mtime_2)
  @debug.assert_eq(ctime_3, ctime_2)
  @async.sleep(600)
  @fs.chmod(path, 0o666)
  let mtime_4 = @fs.mtime(path)
  let ctime_4 = @fs.ctime(path)
  @debug.assert_eq(mtime_4, mtime_3)
  assert_true((ctime_4 - ctime_3).msec() > 500)
}

///|
// `atime` is not reliable on Windows, so this keeps Windows coverage to mtime.
// Wasm learns the host platform at runtime instead of through MoonBit target cfg.
async test "mtime for path" {
  if !(@event_loop.platform is Windows) {
    return
  }
  let path = "_build/timestamp_test"
  @fs.write_text(path, "abcd", sync=Full)
  defer @fs.remove(path)
  let mtime_1 = @fs.mtime(path)
  let ctime_1 = @fs.ctime(path)
  @async.sleep(600)
  @fs.write_text(path, "1234", create_mode=OpenExisting, sync=Full)
  let mtime_2 = @fs.mtime(path)
  let ctime_2 = @fs.ctime(path)
  assert_true((mtime_2 - mtime_1).msec() > 500)
  assert_true((ctime_2 - ctime_1).msec() > 500)
}

///|
async test "timestamp for opened file" {
  // Windows may avoid updating access time eagerly, so keep the POSIX-style
  // atime/mtime/ctime assertions to non-Windows hosts. Wasm learns that host
  // platform at runtime instead of through MoonBit target cfg.
  if @event_loop.platform is Windows {
    return
  }
  let path = "/tmp/opened_file_timestamp_test"
  @fs.write_text(path, "abcd", sync=Full)
  defer @fs.remove(path)
  let file = @fs.open(path, mode=ReadWrite, sync=Full)
  defer file.close()
  let mtime_1 = file.mtime()
  let ctime_1 = file.mtime()
  @async.sleep(600)
  file.write_at(b"1234", position=0)
  let atime_2 = file.atime()
  let mtime_2 = file.mtime()
  let ctime_2 = file.mtime()
  assert_true((mtime_2 - mtime_1).msec() > 500)
  assert_true((ctime_2 - ctime_1).msec() > 500)
  @async.sleep(600)
  inspect(file.text.read_all(), content="1234")
  file.sync()
  let atime_3 = file.atime()
  let mtime_3 = file.mtime()
  let ctime_3 = file.mtime()
  assert_true((atime_3 - atime_2).msec() > 500)
  @debug.assert_eq(mtime_3, mtime_2)
  @debug.assert_eq(ctime_3, ctime_2)
  @async.sleep(600)
  @fs.chmod(path, 0o666)
  let mtime_4 = @fs.mtime(path)
  let ctime_4 = @fs.ctime(path)
  @debug.assert_eq(mtime_4, mtime_3)
  assert_true((ctime_4 - ctime_3).msec() > 500)
}

///|
// `atime` is not reliable on Windows, so this keeps Windows coverage to mtime.
// Wasm learns the host platform at runtime instead of through MoonBit target cfg.
async test "mtime for opened file" {
  if !(@event_loop.platform is Windows) {
    return
  }
  let path = "_build/opened_file_timestamp_test"
  @fs.write_text(path, "abcd", sync=Full)
  defer @fs.remove(path)
  let file = @fs.open(path, mode=ReadWrite, sync=Full)
  defer file.close()
  let mtime_1 = file.mtime()
  let ctime_1 = file.mtime()
  @async.sleep(600)
  file.write_at(b"1234", position=0)
  let mtime_2 = file.mtime()
  let ctime_2 = file.mtime()
  assert_true((mtime_2 - mtime_1).msec() > 500)
  assert_true((ctime_2 - ctime_1).msec() > 500)
}

///|
async test "Timestamp promotes equal, compare, hash and sub" {
  let path = "_build/timestamp_promotion_test"
  @fs.write_text(path, "abcd", sync=Full)
  defer @fs.remove(path)
  let a = @fs.mtime(path)
  let b = @fs.mtime(path)
  let eq : (@fs.Timestamp, @fs.Timestamp) -> Bool = @fs.Timestamp::equal
  let cmp : (@fs.Timestamp, @fs.Timestamp) -> Int32 = @fs.Timestamp::compare
  let hash : (@fs.Timestamp) -> Int32 = @fs.Timestamp::hash
  let sub : (@fs.Timestamp, @fs.Timestamp) -> @fs.Timestamp = @fs.Timestamp::sub
  inspect(eq(a, b), content="true")
  inspect(cmp(a, b), content="0")
  // `Hash` agrees with `Eq`, so timestamps can key a `Map`
  inspect(hash(a) == b.hash(), content="true")
  let seen : Map[@fs.Timestamp, Int32] = Map([])
  seen[a] = 1
  inspect(seen.get(b) == Some(1), content="true")
  let zero = sub(a, b)
  inspect(zero.sec(), content="0")
  inspect(zero.nsec(), content="0")
  inspect(a.sub(b).equal(zero), content="true")
  inspect(zero.compare(a) < 0, content="true")
}
