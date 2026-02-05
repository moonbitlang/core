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
test "arg builders and defaults" {
  let arg = @arg_parser.Arg::new("verbose")
    .short('v')
    .short_alias('q')
    .visible_short_alias('w')
    .flag()
  let cmd = @arg_parser.Command::new("demo").arg(arg)
  let m = cmd.parse(argv=["-w"]) catch { _ => panic() }
  assert_true(m.get_flag("verbose"))
  let cmd2 = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("mode")
    .long("mode")
    .option()
    .multiple()
    .default_values(["a", "b"]),
  )
  let m2 = cmd2.parse(argv=[]) catch { _ => panic() }
  inspect(m2.values_of("mode").unwrap(), content="[\"a\", \"b\"]")
  let cmd3 = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("tag").long("tag").option().multiple().num_values(1, 2),
  )
  let m3 = cmd3.parse(argv=["--tag", "x"]) catch { _ => panic() }
  assert_eq(m3.value_of("tag").unwrap(), "x")
}

///|
test "help and man include groups and defaults" {
  let sub = @arg_parser.Command::new("sub").visible_alias("s")
  let cmd = @arg_parser.Command::new("demo")
    .subcommand(sub)
    .group(@arg_parser.ArgGroup::new("mode").required())
    .group(@arg_parser.ArgGroup::new("color").multiple(value=false))
    .group(@arg_parser.ArgGroup::new("misc"))
    .arg(@arg_parser.Arg::new("req").index(0).required())
    .arg(@arg_parser.Arg::new("rest").index(1).multiple().required())
    .arg(@arg_parser.Arg::new("extra").index(2).multiple())
    .arg(
      @arg_parser.Arg::new("flag")
      .short('f')
      .visible_short_alias('g')
      .long("flag")
      .negatable(),
    )
    .arg(
      @arg_parser.Arg::new("opt")
      .long("opt")
      .option()
      .default_value("v")
      .env("OPT")
      .help("optional value"),
    )
    .arg(
      @arg_parser.Arg::new("size")
      .long("size")
      .option()
      .default_values(["s", "m"])
      .group("misc"),
    )
    .arg(@arg_parser.Arg::new("pos").group("mode"))
    .arg(@arg_parser.Arg::new("fast").long("fast").group("mode"))
    .arg(@arg_parser.Arg::new("slow").long("slow").group("mode"))
    .arg(@arg_parser.Arg::new("red").long("red").group("color"))
    .arg(@arg_parser.Arg::new("blue").long("blue").group("color"))
  let help = cmd.render_help()
  assert_true(help.contains("Groups:"))
  assert_true(help.contains("Arguments:"))
  assert_true(help.contains("Commands:"))
  assert_true(help.contains("default: v"))
  assert_true(help.contains("required"))
  assert_true(help.contains("--[no-]flag"))
  let man = cmd.render_help(mode=@arg_parser.HelpMode::Man)
  assert_true(man.contains("GROUPS"))
  assert_true(man.contains("ARGUMENTS"))
  assert_true(man.contains("COMMANDS"))
}

///|
test "parse branches and env errors" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("verbose").short('v'),
  )
  let res : Result[@arg_parser.Matches, @arg_parser.CommandError] = try? cmd.parse(argv=[
      "-vh",
    ],
  )
  match res {
    Err(@arg_parser.CommandError::Help(text)) =>
      assert_true(text.contains("Usage:"))
    _ => panic()
  }
  let cmd2 = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("count").short('c').option(),
  )
  try cmd2.parse(argv=["-c"]) catch {
    @arg_parser.CommandError::Arg(@arg_parser.ArgumentError::MissingValue(opt)) =>
      inspect(opt, content="-c")
    _ => panic()
  } noraise {
    _ => panic()
  }
  let cmd3 = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("flag")
    .long("flag")
    .negatable()
    .action(@arg_parser.ArgAction::SetFalse),
  )
  let m3 = cmd3.parse(argv=["--no-flag"]) catch { _ => panic() }
  assert_true(m3.get_flag("flag"))
  let cmd4 = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("flag")
    .long("flag")
    .option()
    .action(@arg_parser.ArgAction::SetTrue),
  )
  try cmd4.parse(argv=["--flag", "maybe"]) catch {
    @arg_parser.CommandError::Arg(@arg_parser.ArgumentError::InvalidValue(msg)) =>
      inspect(
        msg,
        content=(
          #|invalid bool: maybe
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
  let cmd5 = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("verbose").long("verbose").env("VERBOSE"),
  )
  try cmd5.parse(argv=[], env={ "VERBOSE": "nope" }) catch {
    @arg_parser.CommandError::Arg(@arg_parser.ArgumentError::InvalidValue(msg)) =>
      inspect(
        msg,
        content=(
          #|invalid bool: nope
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
  let cmd6 = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("mode").long("mode").option().env("MODE"),
  )
  let m6 = cmd6.parse(argv=[], env={}) catch { _ => panic() }
  match m6.value_of("mode") {
    None => ()
    Some(_) => panic()
  }
}

///|
test "global aliases and merge semantics" {
  let sub = @arg_parser.Command::new("run")
  let root = @arg_parser.Command::new("root")
    .arg(
      @arg_parser.Arg::new("color")
      .long("color")
      .alias_name("colour")
      .visible_alias("hue")
      .short('c')
      .short_alias('C')
      .visible_short_alias('H')
      .global(),
    )
    .arg(@arg_parser.Arg::new("config").long("config").option().global())
    .arg(
      @arg_parser.Arg::new("verbose")
      .short('v')
      .action(@arg_parser.ArgAction::Count)
      .global(),
    )
    .subcommand(sub)
  let matches = root.parse(argv=[
    "--hue", "--config", "a", "-v", "run", "-v", "-v",
  ]) catch {
    _ => panic()
  }
  assert_true(matches.get_flag("color"))
  assert_eq(matches.value_of("config").unwrap(), "a")
  assert_eq(matches.count_of("verbose"), 3)
  let subm = matches.subcommand_matches("run").unwrap()
  assert_true(subm.get_flag("color"))
  assert_eq(subm.value_of("config").unwrap(), "a")
  assert_eq(subm.count_of("verbose"), 3)
}

///|
test "unknown short without hint" {
  let cmd = @arg_parser.Command::new("demo")
  try cmd.parse(argv=["-z"]) catch {
    @arg_parser.CommandError::Arg(
      @arg_parser.ArgumentError::UnknownArgument(arg, hint)
    ) =>
      match hint {
        None => inspect(arg, content="-z")
        Some(_) => panic()
      }
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "positionals ordering and hyphen values" {
  let cmd = @arg_parser.Command::new("demo")
    .arg(@arg_parser.Arg::new("b").index(1))
    .arg(@arg_parser.Arg::new("a").index(0))
    .arg(@arg_parser.Arg::new("rest").multiple())
  let m = cmd.parse(argv=["x", "y", "z"]) catch { _ => panic() }
  assert_eq(m.value_of("a").unwrap(), "x")
  assert_eq(m.value_of("b").unwrap(), "y")
  inspect(m.values_of("rest").unwrap(), content="[\"z\"]")
  let cmd2 = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("name").index(0).allow_hyphen_values(),
  )
  let m2 = cmd2.parse(argv=["--file"]) catch { _ => panic() }
  assert_eq(m2.value_of("name").unwrap(), "--file")
}

///|
test "matches helpers" {
  let m = @arg_parser.Matches::new()
  match m.value_of("x") {
    None => ()
    Some(_) => panic()
  }
  match m.source_of("x") {
    None => ()
    Some(_) => panic()
  }
  match m.value_sources_of("x") {
    None => ()
    Some(_) => panic()
  }
  match m.subcommand_name() {
    None => ()
    Some(_) => panic()
  }
  match m.subcommand_matches("x") {
    None => ()
    Some(_) => panic()
  }
  try m.get_one("x") catch {
    @arg_parser.ArgumentError::InvalidValue(msg) =>
      inspect(
        msg,
        content=(
          #|value not found: x
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
  let opt : String? = m.get_option("x") catch { _ => None }
  match opt {
    None => ()
    Some(_) => panic()
  }
  let arr : Array[String] = m.get_array("x")
  inspect(arr, content="[]")
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("tag").long("tag").option().multiple(),
  )
  let m2 = cmd.parse(argv=["--tag", "1", "--tag", "2"]) catch { _ => panic() }
  try m2.get_option("tag") catch {
    @arg_parser.ArgumentError::InvalidValueCount(msg) =>
      inspect(
        msg,
        content=(
          #|invalid value count for tag: 2
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
  try m2.get_one("tag") catch {
    @arg_parser.ArgumentError::InvalidValueCount(msg) =>
      inspect(
        msg,
        content=(
          #|invalid value count for tag: 2
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
  let tags : Array[String] = m2.get_array("tag")
  inspect(tags, content="[\"1\", \"2\"]")
  let cmd2 = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("flag").long("flag").option(),
  )
  let m3 = cmd2.parse(argv=["--flag", "maybe"]) catch { _ => panic() }
  assert_eq(m3.get_one("flag") catch { _ => "" }, "maybe")
  let m_true = cmd2.parse(argv=["--flag", "true"]) catch { _ => panic() }
  assert_eq(m_true.get_one("flag") catch { _ => "" }, "true")
  let m_false = cmd2.parse(argv=["--flag", "false"]) catch { _ => panic() }
  assert_eq(m_false.get_one("flag") catch { _ => "" }, "false")
}

///|
test "command args builder" {
  let cmd = @arg_parser.Command::new("demo").args([
    @arg_parser.Arg::new("a").long("a"),
    @arg_parser.Arg::new("b").long("b"),
  ])
  let m = cmd.parse(argv=["--a", "--b"]) catch { _ => panic() }
  assert_true(m.get_flag("a"))
  assert_true(m.get_flag("b"))
}

///|
test "visible alias does not duplicate subcommand names" {
  let sub = @arg_parser.Command::new("run").visible_alias("r")
  let cmd = @arg_parser.Command::new("root").subcommand(sub)
  try cmd.parse(argv=["run"]) catch {
    _ => panic()
  } noraise {
    _ => ()
  }
}
