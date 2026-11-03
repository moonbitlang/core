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
async test "Cmd sequence collects output and returns the last status" {
  let sleep = sleep_prog.wait()
  let cat = cat.wait()
  @async.with_task_group <| group => {
    let proc = @process.Cmd::sequence([
      Cmd(sleep, ["0", "-exit-code", "7", "-print-after-sleep", "first"]),
      Cmd(cat, []),
      Cmd(sleep, ["0", "-exit-code", "3"]),
    ]).spawn(group, stdin=FeedFromParent, stdout=Collect)
    group.spawn_bg() <| () => {
      defer proc.stdin.close()
      proc.stdin.text.write("second\n")
    }
    defer proc.stdout.close()
    inspect(
      proc.stdout.text.read_all().replace_all(old="\r\n", new="\n"),
      content=(
        #|first
        #|second
        #|
      ),
    )
    inspect(proc.wait(), content="3")
  }
}

///|
async test "Cmd copies constructor collections" {
  let extra_env = { "PROCESS_CMD_TEST": "before" }
  let cmd = @process.Cmd(
    dump_env_prog.wait(),
    [],
    extra_env~,
    inherit_env=false,
  )
  extra_env["PROCESS_CMD_TEST"] = "after"
  let result = cmd.run(stdout=Collect)
  inspect(
    result.stdout_text().trim(char_set="\r\n"),
    content="PROCESS_CMD_TEST=before",
  )
}

///|
async test "Cmd sequence respects per-command output redirection" {
  let output_file = "_build/process_cmd_sequence_redirect.txt"
  defer @fs.remove(output_file, allow_missing=true)
  let sleep = sleep_prog.wait()
  let result = @process.Cmd::sequence([
    Cmd(
      sleep,
      ["0", "-print-after-sleep", "redirected"],
      stdout=ToFile(output_file),
    ),
    Cmd(sleep, ["0", "-print-after-sleep", "collected"]),
  ]).run(stdout=Collect)
  inspect(
    @fs.read_text(output_file).trim(char_set="\r\n"),
    content="redirected",
  )
  inspect(result.stdout_text().trim(char_set="\r\n"), content="collected")
}

///|
async test "Cmd pipeline connects invocation-level file input and collection" {
  let input_file = "_build/process_cmd_pipeline_input.txt"
  defer @fs.remove(input_file, allow_missing=true)
  @fs.write_text(input_file, "alpha\nbeta\n")
  let cat = cat.wait()
  let result = (@process.Cmd(cat, []) | Cmd(cat, [])).run(
    stdin=FromFile(input_file),
    stdout=Collect,
  )
  inspect(result.exit_code, content="0")
  inspect(
    result.stdout_text().replace_all(old="\r\n", new="\n"),
    content=(
      #|alpha
      #|beta
      #|
    ),
  )
}

///|
async test "Cmd with_context redirects a composite pipeline" {
  let input_file = "_build/process_cmd_context_pipeline_input.txt"
  defer @fs.remove(input_file, allow_missing=true)
  @fs.write_text(input_file, "context input")
  let cat = cat.wait()
  let result = (@process.Cmd(cat, []) | Cmd(cat, []))
    .with_context(stdin=FromFile(input_file))
    .run(stdout=Collect)
  inspect(result.exit_code, content="0")
  inspect(result.stdout_text(), content="context input")
}

///|
async test "Cmd with_context applies cwd to a composite pipeline" {
  let cat = cat.wait()
  let result = (@process.Cmd(shell, ["-c", ls], extra_env={ "LC_ALL": "C" }) |
    Cmd(cat, []))
    .with_context(cwd="async/fs/test_directory/dir1")
    .run(stdout=Collect)
  let files = result
    .stdout_text()
    .trim(char_set="\n\r ")
    .replace_all(old="\r\n", new="\n")
    .split("\n")
    .to_array()
  files.sort()
  json_inspect(files, content=["file", "inner1"])
}

///|
async test "Cmd with_context shares sequence output redirection" {
  let output_file = "_build/process_cmd_context_sequence_output.txt"
  defer @fs.remove(output_file, allow_missing=true)
  let sleep = sleep_prog.wait()
  let result = @process.Cmd::sequence([
      Cmd(sleep, ["0", "-print-after-sleep", "first"]),
      Cmd(sleep, ["0", "-print-after-sleep", "discarded"], stdout=Discard),
      Cmd(sleep, ["0", "-print-after-sleep", "last"]),
    ])
    .with_context(stdout=ToFile(output_file))
    .run(stdout=Collect)
  inspect(result.exit_code, content="0")
  inspect(result.stdout_text(), content="")
  inspect(
    @fs.read_text(output_file).replace_all(old="\r\n", new="\n"),
    content=(
      #|first
      #|last
      #|
    ),
  )
}

///|
async test "Cmd pipeline command redirection overrides the pipe without hanging" {
  let producer_input = "_build/process_cmd_pipeline_producer.txt"
  let consumer_input = "_build/process_cmd_pipeline_consumer.txt"
  defer @fs.remove(producer_input, allow_missing=true)
  defer @fs.remove(consumer_input, allow_missing=true)
  // This is deliberately larger than an operating-system pipe buffer. If the
  // unused read end is retained, the producer cannot finish writing it.
  @fs.write_text(producer_input, "x".repeat(1024 * 1024))
  @fs.write_text(consumer_input, "replacement")
  let cat = cat.wait()
  let result = @async.with_timeout(10000, () => {
    let cmd = @process.Cmd(cat, [], stderr=Discard) |
      Cmd(cat, [], stdin=FromFile(consumer_input))
    cmd.run(stdin=FromFile(producer_input), stdout=Collect)
  })
  // The producer's broken-pipe status is accepted by default, so pipefail
  // reports the consumer's status.
  inspect(result.exit_code, content="0")
  inspect(result.stdout_text(), content="replacement")
}

///|
async test "Cmd spawn keeps sequence redirections alive" {
  let cat = cat.wait()
  let sleep = sleep_prog.wait()
  @async.with_task_group() <| group => {
    let child = @process.Cmd::sequence([
      Cmd(cat, []),
      Cmd(sleep, ["0", "-print-after-sleep", "tail"]),
    ]).spawn(group, stdin=FeedFromParent, stdout=Collect)
    child.stdin.write(b"body\n")
    child.stdin.close()
    defer child.stdout.close()
    inspect(child.wait(), content="0")
    inspect(
      child.stdout.text.read_all().replace_all(old="\r\n", new="\n"),
      content=(
        #|body
        #|tail
        #|
      ),
    )
  }
}

///|
async test "Cmd cancellation reaches both pipeline branches" {
  let sleep = sleep_prog.wait()
  @async.with_timeout(10000, () => {
    @async.with_task_group() <| group => {
      let cmd = @process.Cmd(sleep, [
          "30000", "-stderr", "-print-after-init", "left started",
        ]) |
        Cmd(sleep, ["30000", "-stderr", "-print-after-init", "right started"])
      let child = cmd.spawn(group, stderr=Collect)
      defer child.stderr.close()
      let started = [
        child.stderr.text.read_until("\n").unwrap().trim().to_owned(),
        child.stderr.text.read_until("\n").unwrap().trim().to_owned(),
      ]
      started.sort()
      json_inspect(started, content=["left started", "right started"])
      child.cancel()
      let cancelled = child.stderr.text
        .read_all()
        .replace_all(old="\r\n", new="\n")
        .trim(char_set="\n")
        .split("\n")
        .to_array()
      cancelled.sort()
      json_inspect(cancelled, content=[
        "received termination signal", "received termination signal",
      ])
    }
  })
}

///|
async test "Cmd cancellation stops the first command in a sequence" {
  let sleep = sleep_prog.wait()
  @async.with_timeout(5000, () => {
    @async.with_task_group() <| group => {
      let child = @process.Cmd::sequence([
        Cmd(sleep, ["10000", "-print-after-init", "first started"]),
        Cmd(sleep, ["0", "-print-after-init", "second started"]),
      ]).spawn(group, stdout=Collect)
      defer child.stdout.close()
      debug_inspect(
        child.stdout.text.read_until("\n"),
        content=(
          #|Some("first started")
        ),
      )
      child.cancel()
      inspect(
        child.stdout.text
        .read_all()
        .replace_all(old="\r\n", new="\n")
        .trim(char_set="\n"),
        content="received termination signal",
      )
    }
  })
}

///|
async test "Cmd cancellation stops the last command in a sequence" {
  let sleep = sleep_prog.wait()
  @async.with_timeout(10000, () => {
    @async.with_task_group() <| group => {
      let child = @process.Cmd::sequence([
        Cmd(sleep, ["0", "-print-after-sleep", "first finished"]),
        Cmd(sleep, ["30000", "-print-after-init", "last started"]),
      ]).spawn(group, stdout=Collect)
      defer child.stdout.close()
      debug_inspect(
        child.stdout.text.read_until("\n"),
        content=(
          #|Some("first finished")
        ),
      )
      debug_inspect(
        child.stdout.text.read_until("\n"),
        content=(
          #|Some("last started")
        ),
      )
      child.cancel()
      inspect(
        child.stdout.text
        .read_all()
        .replace_all(old="\r\n", new="\n")
        .trim(char_set="\n"),
        content="received termination signal",
      )
    }
  })
}

///|
async test "Cmd spawn result cancellation stops a pipe of sequences" {
  let sleep = sleep_prog.wait()
  let accepted_exit_code : (Int32) -> Bool = _ => false
  @async.with_timeout(10000, () => {
    @async.with_task_group() <| group => {
      let left = @process.Cmd::sequence([
        Cmd(
          sleep,
          ["30000", "-stderr", "-print-after-init", "left started"],
          accepted_exit_code~,
        ),
        Cmd(sleep, ["0", "-stderr", "-print-after-init", "left tail started"]),
      ])
      let right = @process.Cmd::sequence([
        Cmd(
          sleep,
          ["30000", "-stderr", "-print-after-init", "right started"],
          accepted_exit_code~,
        ),
        Cmd(sleep, ["0", "-stderr", "-print-after-init", "right tail started"]),
      ])
      let child = (left | right).spawn(group, stderr=Collect)
      defer child.stderr.close()
      let started = [
        child.stderr.text.read_until("\n").unwrap().trim().to_owned(),
        child.stderr.text.read_until("\n").unwrap().trim().to_owned(),
      ]
      started.sort()
      json_inspect(started, content=["left started", "right started"])
      child.cancel()
      let cancelled = child.stderr.text
        .read_all()
        .replace_all(old="\r\n", new="\n")
        .trim(char_set="\n")
        .split("\n")
        .to_array()
      cancelled.sort()
      json_inspect(cancelled, content=[
        "received termination signal", "received termination signal",
      ])
    }
  })
}

///|
async test "Cmd accepted_exit_code accepts selected codes and reports rejection" {
  let sleep = sleep_prog.wait()
  let accepted_exit_code = code => code is 7
  let accepted_cmd = @process.Cmd(
    sleep,
    ["0", "-exit-code", "7"],
    accepted_exit_code~,
  )
  let accepted = accepted_cmd.run()
  inspect(accepted.exit_code, content="7")
  let rejected_args : ReadOnlyArray[_] = ["0", "-exit-code", "9"]
  let rejected_cmd = @process.Cmd(sleep, rejected_args, accepted_exit_code~)
  let err = @test.expect_error_async(() => rejected_cmd.run())
  match err {
    @process.CommandFailed(code, program~, args~) => {
      inspect(code, content="9")
      assert_eq(program, sleep)
      assert_eq(args, rejected_args)
    }
    err => fail("expected CommandFailed, got \{@debug.Repr(err)}")
  }
}

///|
async test "Cmd pipeline uses pipefail for rejected exit codes" {
  let sleep = sleep_prog.wait()
  let accepted_exit_code = code => code is 0
  let ok_cmd = @process.Cmd(sleep, ["0"], stdout=Discard)
  let fail7_args : ReadOnlyArray[String] = ["0", "-exit-code", "7"]
  let fail9_args : ReadOnlyArray[String] = ["0", "-exit-code", "9"]
  let fail7 = @process.Cmd(sleep, fail7_args, accepted_exit_code~)
  let fail9 = @process.Cmd(sleep, fail9_args, accepted_exit_code~)
  for
    (cmd, expected_code, expected_args) in [
      (fail7 | ok_cmd, 7, fail7_args),
      (ok_cmd | fail7, 7, fail7_args),
      (fail7 | fail9, 9, fail9_args),
    ] {
    let err = @test.expect_error_async(() => cmd.run(stdout=Discard))
    match err {
      @process.CommandFailed(code, program~, args~) => {
        assert_eq(code, expected_code)
        assert_eq(program, sleep)
        assert_eq(args, expected_args)
      }
      err => fail("expected CommandFailed, got \{@debug.Repr(err)}")
    }
  }
}

///|
async test "Cmd pipeline rejection fails the task group without wait" {
  let sleep = sleep_prog.wait()
  let accepted_exit_code = code => code is 0
  let pipeline = @process.Cmd(
      sleep,
      ["0", "-exit-code", "7"],
      accepted_exit_code~,
    ) |
    Cmd(sleep, ["0"])
  let err = @test.expect_error_async() <| () => {
    @async.with_task_group() <| group => { let _ = pipeline.spawn(group) }
  }
  guard err is @process.CommandFailed(code, ..) else {
    fail("expected CommandFailed, got \{@debug.Repr(err)}")
  }
  inspect(code, content="7")
}

///|
async test "Cmd pipeline startup failure cancels already-started commands" {
  let sleep = sleep_prog.wait()
  let missing_program = "_build/process_cmd_missing_program"
  let pipeline = @process.Cmd(sleep, ["30000"]) | Cmd(missing_program, [])
  let run_error = @test.expect_error_async(() => {
    @async.with_timeout(5000, () => {
      pipeline.run(cancel_handler=@process.hard_cancel()) |> ignore
    })
  })
  inspect(run_error is @async.TimeoutError, content="false")
  let spawn_error = @test.expect_error_async(() => {
    @async.with_timeout(5000, () => {
      @async.with_task_group() <| group => {
        pipeline.spawn(group, cancel_handler=@process.hard_cancel()).wait()
        |> ignore
      }
    })
  })
  inspect(spawn_error is @async.TimeoutError, content="false")
}

///|
async test "Cmd sequence stops on rejection and propagates the final error" {
  let sleep = sleep_prog.wait()
  let accepted_exit_code = code => code is 0
  let ok_cmd = @process.Cmd(sleep, [
    "0", "-print-after-init", "ok cmd started", "-print-after-sleep", "ok cmd terminated",
  ])
  let fail_args : ReadOnlyArray[_] = [
    "0", "-exit-code", "7", "-print-after-init", "fail cmd started", "-print-after-sleep",
    "fail cmd terminated",
  ]
  let fail_cmd = @process.Cmd(sleep, fail_args, accepted_exit_code~)
  @async.with_task_group <| group => {
    let cmd1 = @process.Cmd::sequence([ok_cmd, fail_cmd])
    let (r, w) = @process.read_from_process()
    group.spawn_bg() <| () => {
      defer r.close()
      inspect(
        r.text.read_all().replace_all(old="\r\n", new="\n"),
        content=(
          #|ok cmd started
          #|ok cmd terminated
          #|fail cmd started
          #|fail cmd terminated
          #|
        ),
      )
    }
    defer w.close()
    let err = @test.expect_error_async(() => cmd1.run(stdout=Shared(w)))
    match err {
      @process.CommandFailed(code, program~, args~) => {
        inspect(code, content="7")
        assert_eq(program, sleep)
        assert_eq(args, fail_args)
      }
      err => fail("expected CommandFailed, got \{@debug.Repr(err)}")
    }
  }
  @async.with_task_group <| group => {
    let cmd1 = @process.Cmd::sequence([fail_cmd, ok_cmd])
    let (r, w) = @process.read_from_process()
    group.spawn_bg() <| () => {
      defer r.close()
      inspect(
        r.text.read_all().replace_all(old="\r\n", new="\n"),
        content=(
          #|fail cmd started
          #|fail cmd terminated
          #|
        ),
      )
    }
    defer w.close()
    let err = @test.expect_error_async(() => cmd1.run(stdout=Shared(w)))
    match err {
      @process.CommandFailed(code, program~, args~) => {
        inspect(code, content="7")
        assert_eq(program, sleep)
        assert_eq(args, fail_args)
      }
      err => fail("expected CommandFailed, got \{@debug.Repr(err)}")
    }
  }
}
