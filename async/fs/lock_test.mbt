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
let lock_file_prog : @async.Lazy[String] = Lazy(() => {
  @test_util.build_test_program("lock_file")
})

///|
enum LockEvent {
  Acquire
  Release
} derive(Debug)

///|
async fn run_lock_file_prog(
  group : @async.TaskGroup,
  file : String,
  lock : @fs.Lock,
  duration~ : Int32 = 500,
) -> (@async.Queue[Unit], @async.Queue[LockEvent]) {
  let prog = lock_file_prog.wait()
  let lock_kind = if lock is Exclusive { "-exclusive" } else { "-shared" }
  let lock_proc = @process.spawn(
    group,
    prog,
    stdin=@process.write_to_process(),
    stdout=@process.read_from_process(),
    [file, "-duration", duration.to_string(), lock_kind],
  )
  let input = @async.Queue(kind=Unbounded)
  let queue = @async.Queue(kind=Unbounded)
  group.spawn_bg(no_wait=true) <| () => {
    defer lock_proc.stdin.close()
    while input.get() is _ {
      lock_proc.stdin.write(b"step\n")
    }
  }
  group.spawn_bg() <| () => {
    defer lock_proc.stdout.close()
    while lock_proc.stdout.text.read_until("\n") is Some(line) {
      match line {
        "acquired lock" => queue.put(Acquire)
        "released lock" => queue.put(Release)
        msg => raise Failure("invalid output from lock file program: \{msg}")
      }
    }
    queue.close()
  }
  (input, queue)
}

///|
#callsite(autofill(loc))
fn @fs.File::assert_can_lock(
  file : @fs.File,
  kind : @fs.Lock,
  loc~ : SourceLoc,
) -> Unit raise {
  let result = file.try_lock(kind)
  if result {
    file.unlock()
  }
  assert_true(result, loc~)
}

///|
#callsite(autofill(loc))
fn @fs.File::assert_cannot_lock(
  file : @fs.File,
  kind : @fs.Lock,
  loc~ : SourceLoc,
) -> Unit raise {
  let result = file.try_lock(kind)
  if result {
    file.unlock()
  }
  assert_false(result, loc~)
}

///|
async test "flock exclusive vs exclusive" {
  let file_name = "_build/flock_ex_ex"
  @async.with_task_group() <| group => {
    let file = @fs.open(file_name, create_mode=CreateOrTruncate, mode=ReadWrite)
    defer file.close()
    group.add_defer(() => @fs.remove(file_name))
    let (input, events) = run_lock_file_prog(group, file_name, Exclusive)
    input.put(()) // lock
    debug_inspect(events.get(), content="Acquire")
    file.assert_cannot_lock(Exclusive)
    @async.sleep(200)
    file.assert_cannot_lock(Exclusive)
    input.put(()) // unlock
    debug_inspect(events.get(), content="Release")
    file.assert_can_lock(Exclusive)
  }
}

///|
async test "flock exclusive vs exclusive blocking" {
  let file_name = "_build/flock_ex_ex_blocking"
  @async.with_task_group() <| group => {
    let file = @fs.open(file_name, create_mode=CreateOrTruncate, mode=ReadWrite)
    defer file.close()
    group.add_defer(() => @fs.remove(file_name))
    let (input, events) = run_lock_file_prog(group, file_name, Exclusive)
    input.put(()) // lock
    debug_inspect(events.get(), content="Acquire")
    let mut released = false
    group.spawn_bg() <| () => {
      @async.sleep(200)
      released = true
      input.put(()) // unlock
    }
    file.lock(Exclusive)
    defer file.unlock()
    assert_true(released)
  }
}

///|
async test "flock shared vs exclusive" {
  let file_name = "_build/flock_sh_ex"
  @async.with_task_group() <| group => {
    let file = @fs.open(file_name, create_mode=CreateOrTruncate, mode=ReadWrite)
    defer file.close()
    group.add_defer(() => @fs.remove(file_name))
    let (input, events) = run_lock_file_prog(group, file_name, Shared)
    input.put(()) // lock
    debug_inspect(events.get(), content="Acquire")
    file.assert_cannot_lock(Exclusive)
    @async.sleep(200)
    file.assert_cannot_lock(Exclusive)
    input.put(()) // unlock
    debug_inspect(events.get(), content="Release")
    file.assert_can_lock(Exclusive)
  }
}

///|
async test "flock shared vs exclusive blocking" {
  let file_name = "_build/flock_sh_ex_blocking"
  @async.with_task_group() <| group => {
    let file = @fs.open(file_name, create_mode=CreateOrTruncate, mode=ReadWrite)
    defer file.close()
    group.add_defer(() => @fs.remove(file_name))
    let (input, events) = run_lock_file_prog(group, file_name, Shared)
    input.put(()) // lock
    debug_inspect(events.get(), content="Acquire")
    let mut released = false
    group.spawn_bg() <| () => {
      @async.sleep(200)
      released = true
      input.put(()) // unlock
    }
    file.lock(Exclusive)
    defer file.unlock()
    assert_true(released)
  }
}

///|
async test "flock exclusive vs shared" {
  let file_name = "_build/flock_ex_sh"
  @async.with_task_group() <| group => {
    let file = @fs.open(file_name, create_mode=CreateOrTruncate, mode=ReadWrite)
    defer file.close()
    group.add_defer(() => @fs.remove(file_name))
    let (input, events) = run_lock_file_prog(group, file_name, Exclusive)
    input.put(()) // lock
    debug_inspect(events.get(), content="Acquire")
    file.assert_cannot_lock(Shared)
    @async.sleep(200)
    file.assert_cannot_lock(Shared)
    input.put(()) // unlock
    debug_inspect(events.get(), content="Release")
    file.assert_can_lock(Shared)
  }
}

///|
async test "flock exclusive vs shared blocking" {
  let file_name = "_build/flock_ex_sh_blocking"
  @async.with_task_group() <| group => {
    let file = @fs.open(file_name, create_mode=CreateOrTruncate, mode=ReadWrite)
    defer file.close()
    group.add_defer(() => @fs.remove(file_name))
    let (input, events) = run_lock_file_prog(group, file_name, Exclusive)
    input.put(()) // lock
    debug_inspect(events.get(), content="Acquire")
    let mut released = false
    group.spawn_bg() <| () => {
      @async.sleep(200)
      released = true
      input.put(()) // unlock
    }
    file.lock(Shared)
    defer file.unlock()
    assert_true(released)
  }
}

///|
async test "flock shared vs shared" {
  let file_name = "_build/flock_sh_sh"
  @async.with_task_group() <| group => {
    let file = @fs.open(file_name, create_mode=CreateOrTruncate, mode=ReadWrite)
    defer file.close()
    group.add_defer(() => @fs.remove(file_name))
    let (input, events) = run_lock_file_prog(group, file_name, Shared)
    input.put(()) // lock
    debug_inspect(events.get(), content="Acquire")
    file.assert_can_lock(Shared)
    debug_inspect(events.try_get(), content="None")
    input.put(()) // unlock
  }
}

///|
async test "flock shared vs shared blocking" {
  let file_name = "_build/flock_sh_sh_blocking"
  @async.with_task_group() <| group => {
    let file = @fs.open(file_name, create_mode=CreateOrTruncate, mode=ReadWrite)
    defer file.close()
    group.add_defer(() => @fs.remove(file_name))
    let (input, events) = run_lock_file_prog(group, file_name, Shared)
    input.put(()) // lock
    debug_inspect(events.get(), content="Acquire")
    file.lock(Shared)
    defer file.unlock()
    debug_inspect(events.try_get(), content="None")
    input.put(()) // unlock
  }
}

///|
async test "flock shared vs shared vs exclusive" {
  let file_name = "_build/flock_sh_sh_ex"
  @async.with_task_group() <| group => {
    let file = @fs.open(file_name, create_mode=CreateOrTruncate, mode=ReadWrite)
    defer file.close()
    group.add_defer(() => @fs.remove(file_name))
    let (input1, events1) = run_lock_file_prog(group, file_name, Shared)
    input1.put(()) // lock
    debug_inspect(events1.get(), content="Acquire")
    file.assert_cannot_lock(Exclusive)
    let (input2, events2) = run_lock_file_prog(group, file_name, Shared)
    input2.put(()) // lock
    debug_inspect(events2.get(), content="Acquire")
    file.assert_cannot_lock(Exclusive)
    @async.sleep(200)
    input1.put(()) // unlock
    debug_inspect(events1.get(), content="Release")
    debug_inspect(events2.try_get(), content="None")
    file.assert_cannot_lock(Exclusive)
    input2.put(())
    debug_inspect(events2.get(), content="Release")
    file.assert_can_lock(Exclusive)
  }
}

///|
async test "flock shared vs shared vs exclusive blocking" {
  let file_name = "_build/flock_sh_sh_ex_blocking"
  @async.with_task_group() <| group => {
    let file = @fs.open(file_name, create_mode=CreateOrTruncate, mode=ReadWrite)
    defer file.close()
    group.add_defer(() => @fs.remove(file_name))
    let (input1, events1) = run_lock_file_prog(group, file_name, Shared)
    input1.put(()) // lock
    debug_inspect(events1.get(), content="Acquire")
    let (input2, events2) = run_lock_file_prog(group, file_name, Shared)
    input2.put(()) // lock
    debug_inspect(events2.get(), content="Acquire")
    let mut child1_released = false
    group.spawn_bg() <| () => {
      @async.sleep(200)
      child1_released = true
      input1.put(()) // unlock
    }
    let mut child2_released = false
    group.spawn_bg() <| () => {
      @async.sleep(200)
      child2_released = true
      input2.put(()) // unlock
    }
    file.lock(Exclusive)
    defer file.unlock()
    assert_true(child1_released)
    assert_true(child2_released)
  }
}

///|
async test "flock cancelled" {
  let file_name = "_build/flock_cancel"
  @async.with_task_group() <| group => {
    let file = @fs.open(file_name, create_mode=CreateOrTruncate, mode=ReadWrite)
    defer file.close()
    group.add_defer(() => @fs.remove(file_name))
    let (input, events) = run_lock_file_prog(group, file_name, Exclusive)
    input.put(()) // lock
    debug_inspect(events.get(), content="Acquire")
    debug_inspect(
      @async.with_timeout_opt(100, () => {
        file.lock(Exclusive)
        file.unlock()
      }),
      content="None",
    )
    input.put(()) // unlock
  }
}

///|
async test "flock advisory" {
  let file_name = "_build/flock_advisory"
  @async.with_task_group() <| group => {
    @fs.write_text(file_name, "abcd")
    let file = @fs.open(file_name, mode=ReadWrite)
    defer file.close()
    group.add_defer(() => @fs.remove(file_name))
    let (input, events) = run_lock_file_prog(group, file_name, Exclusive)
    input.put(()) // lock
    debug_inspect(events.get(), content="Acquire")
    inspect(file.text.read_all(), content="abcd")
    debug_inspect(events.try_get(), content="None")
    input.put(()) // unlock
  }
}
