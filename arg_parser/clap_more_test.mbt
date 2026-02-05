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
test "help plain" {
  let cmd = @arg_parser.Command::new("demo")
    .about("demo")
    .arg(@arg_parser.Arg::new("count").long("count").option())
    .arg(@arg_parser.Arg::new("name").index(0))
  let mut text = ""
  try cmd.parse(argv=["--help"]) catch {
    @arg_parser.Help::Help(t) => text = t
    _ => panic()
  } noraise {
    _ => panic()
  }
  inspect(text.contains("Usage: demo"), content="true")
  inspect(text.contains("Options:"), content="true")
}

///|
test "help man" {
  let cmd = @arg_parser.Command::new("demo").about("demo")
  let mut text = ""
  try cmd.parse(argv=["--help=man"]) catch {
    @arg_parser.Help::Help(t) => text = t
    _ => panic()
  } noraise {
    _ => panic()
  }
  inspect(text.contains("NAME"), content="true")
  inspect(text.contains("SYNOPSIS"), content="true")
  inspect(text.contains("OPTIONS"), content="true")
}

///|
test "user handles --version" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("version").long("version").help("show version"),
  )
  let matches = cmd.parse(argv=["--version"]) catch { _ => panic() }
  assert_true(matches.get_flag("version"))
}

///|
test "long inline value" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("count").long("count").option(),
  )
  let matches = cmd.parse(argv=["--count=3"]) catch { _ => panic() }
  assert_eq(matches.value_of("count").unwrap(), "3")
}

///|
test "missing value for option" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("count").long("count").option(),
  )
  try cmd.parse(argv=["--count"]) catch {
    @arg_parser.ArgumentError::MissingValue(opt) =>
      inspect(opt, content="--count")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "unknown option" {
  let cmd = @arg_parser.Command::new("demo")
  try cmd.parse(argv=["--nope"]) catch {
    @arg_parser.ArgumentError::UnknownArgument(opt, _) => inspect(opt, content="--nope")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "unknown option suggests closest" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("verbose").long("verbose"),
  )
  try cmd.parse(argv=["--verbsoe"]) catch {
    @arg_parser.ArgumentError::UnknownArgument(arg, hint) =>
      match hint {
        Some(value) => {
          inspect(arg, content="--verbsoe")
          inspect(value, content="--verbose")
        }
        None => panic()
      }
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "env fallback for option" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("mode")
    .long("mode")
    .option()
    .env("MODE")
    .default_value("slow"),
  )
  let matches = cmd.parse(argv=[], env={ "MODE": "fast" }) catch {
    _ => panic()
  }
  assert_eq(matches.value_of("mode").unwrap(), "fast")
  assert_eq(matches.source_of("mode").unwrap().to_string(), "Env")
}

///|
test "argv overrides env" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("mode")
    .long("mode")
    .option()
    .env("MODE")
    .default_value("slow"),
  )
  let matches = cmd.parse(argv=["--mode", "slow"], env={ "MODE": "fast" }) catch {
    _ => panic()
  }
  assert_eq(matches.value_of("mode").unwrap(), "slow")
  assert_eq(matches.source_of("mode").unwrap().to_string(), "Argv")
}

///|
test "env flag enables boolean" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("verbose").long("verbose").env("VERBOSE"),
  )
  let matches = cmd.parse(argv=[], env={ "VERBOSE": "1" }) catch {
    _ => panic()
  }
  assert_true(matches.get_flag("verbose"))
  assert_eq(matches.source_of("verbose").unwrap().to_string(), "Env")
}

///|
test "default value for option" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("mode").long("mode").option().default_value("fast"),
  )
  let matches = cmd.parse(argv=[]) catch { _ => panic() }
  assert_eq(matches.value_of("mode").unwrap(), "fast")
  assert_eq(matches.source_of("mode").unwrap().to_string(), "Default")
}

///|
test "default value for positional" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("name").index(0).default_value("guest"),
  )
  let matches = cmd.parse(argv=[]) catch { _ => panic() }
  assert_eq(matches.value_of("name").unwrap(), "guest")
  assert_eq(matches.source_of("name").unwrap().to_string(), "Default")
}

///|
test "-- terminator treats following args as positional" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("name").index(0),
  )
  let matches = cmd.parse(argv=["--", "--count"]) catch { _ => panic() }
  assert_eq(matches.value_of("name").unwrap(), "--count")
}

///|
test "negative number positional parses without --" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("num").index(0),
  )
  let matches = cmd.parse(argv=["-12"]) catch { _ => panic() }
  assert_eq(matches.value_of("num").unwrap(), "-12")
}

///|
test "allow hyphen positional accepts dash values" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("name").index(0).allow_hyphen_values(),
  )
  let matches = cmd.parse(argv=["-file"]) catch { _ => panic() }
  assert_eq(matches.value_of("name").unwrap(), "-file")
}

///|
test "last positional captures option-like tokens" {
  let cmd = @arg_parser.Command::new("demo")
    .arg(@arg_parser.Arg::new("cmd").index(0))
    .arg(@arg_parser.Arg::new("args").index(1).multiple().last())
    .arg(@arg_parser.Arg::new("verbose").long("verbose"))
  let matches = cmd.parse(argv=["run", "--verbose", "-x"]) catch {
    _ => panic()
  }
  assert_eq(matches.value_of("cmd").unwrap(), "run")
  let rest = matches.values_of("args").unwrap()
  inspect(rest, content="[\"--verbose\", \"-x\"]")
  assert_false(matches.get_flag("verbose"))
}

///|
test "too many positional args" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("name").index(0),
  )
  try cmd.parse(argv=["a", "b"]) catch {
    @arg_parser.ArgumentError::TooManyPositionals => ()
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "multiple named values" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("tag").long("tag").option().multiple(),
  )
  let matches = cmd.parse(argv=["--tag", "a", "--tag", "b"]) catch {
    _ => panic()
  }
  let values = matches.values_of("tag").unwrap()
  inspect(values, content="[\"a\", \"b\"]")
}

///|
test "multiple positional captures rest" {
  let cmd = @arg_parser.Command::new("demo")
    .arg(@arg_parser.Arg::new("first").index(0))
    .arg(@arg_parser.Arg::new("rest").index(1).multiple())
  let matches = cmd.parse(argv=["x", "y", "z"]) catch { _ => panic() }
  assert_eq(matches.value_of("first").unwrap(), "x")
  let rest = matches.values_of("rest").unwrap()
  inspect(rest, content="[\"y\", \"z\"]")
}

///|
test "subcommand help and man" {
  let sub = @arg_parser.Command::new("echo")
    .about("echo help")
    .arg(@arg_parser.Arg::new("msg").index(0))
  let root = @arg_parser.Command::new("root").about("root help").subcommand(sub)
  let mut text_plain = ""
  try root.parse(argv=["echo", "--help"]) catch {
    @arg_parser.Help::Help(t) => text_plain = t
    _ => panic()
  } noraise {
    _ => panic()
  }
  inspect(text_plain.contains("Usage: echo"), content="true")
  let mut text_man = ""
  try root.parse(argv=["echo", "--help=man"]) catch {
    @arg_parser.Help::Help(t) => text_man = t
    _ => panic()
  } noraise {
    _ => panic()
  }
  inspect(text_man.contains("NAME"), content="true")
  inspect(text_man.contains("echo - echo help"), content="true")
}

///|
test "help subcommand shows target help" {
  let echo = @arg_parser.Command::new("echo").about("echo help")
  let tools = @arg_parser.Command::new("tools")
    .about("tools help")
    .subcommand(echo)
  let root = @arg_parser.Command::new("root")
    .about("root help")
    .subcommand(tools)
  let mut text_root = ""
  try root.parse(argv=["help"]) catch {
    @arg_parser.Help::Help(t) => text_root = t
    _ => panic()
  } noraise {
    _ => panic()
  }
  inspect(text_root.contains("Usage: root"), content="true")
  let mut text_nested = ""
  try root.parse(argv=["help", "tools", "echo"]) catch {
    @arg_parser.Help::Help(t) => text_nested = t
    _ => panic()
  } noraise {
    _ => panic()
  }
  inspect(text_nested.contains("Usage: echo"), content="true")
  let mut text_man = ""
  try root.parse(argv=["help", "tools", "echo", "--help=man"]) catch {
    @arg_parser.Help::Help(t) => text_man = t
    _ => panic()
  } noraise {
    _ => panic()
  }
  inspect(text_man.contains("NAME"), content="true")
  inspect(
    root.render_help().contains("Print help for the subcommand(s)."),
    content="true",
  )
}

///|
test "disable help subcommand allows custom help" {
  let custom = @arg_parser.Command::new("help").about("custom help")
  let root = @arg_parser.Command::new("root")
    .subcommand(custom)
    .disable_help_subcommand()
  let matches = root.parse(argv=["help"]) catch { _ => panic() }
  assert_eq(matches.subcommand_name().unwrap(), "help")
}

///|
test "non-multiple keeps last option value" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("tag").long("tag").option(),
  )
  let matches = cmd.parse(argv=["--tag", "a", "--tag", "b"]) catch {
    _ => panic()
  }
  let values = matches.values_of("tag").unwrap()
  inspect(values, content="[\"b\"]")
}

///|
test "short option takes value" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("count").short('c').option(),
  )
  let matches = cmd.parse(argv=["-c", "3"]) catch { _ => panic() }
  assert_eq(matches.value_of("count").unwrap(), "3")
}

///|
test "short option attached value" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("count").short('c').option(),
  )
  let matches = cmd.parse(argv=["-c3"]) catch { _ => panic() }
  assert_eq(matches.value_of("count").unwrap(), "3")
}

///|
test "short group combines flags" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("verbose").short('v'),
  )
  let matches = cmd.parse(argv=["-vv"]) catch { _ => panic() }
  assert_true(matches.get_flag("verbose"))
}

///|
test "count action increments on repeats" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("verbose")
    .short('v')
    .long("verbose")
    .action(@arg_parser.ArgAction::Count),
  )
  let matches = cmd.parse(argv=["-vvv", "--verbose"]) catch { _ => panic() }
  assert_eq(matches.count_of("verbose"), 4)
  assert_true(matches.get_flag("verbose"))
}

///|
test "short group unknown flag errors" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("verbose").short('v'),
  )
  try cmd.parse(argv=["-vz"]) catch {
    @arg_parser.ArgumentError::UnknownArgument(arg, _) => inspect(arg, content="-z")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "negatable flag" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("verbose").long("verbose").negatable(),
  )
  let matches = cmd.parse(argv=["--no-verbose"]) catch { _ => panic() }
  assert_false(matches.get_flag("verbose"))
}

///|
test "no- flag rejected when not negatable" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("verbose").long("verbose"),
  )
  try cmd.parse(argv=["--no-verbose"]) catch {
    @arg_parser.ArgumentError::UnknownArgument(arg, _) => inspect(arg, content="--no-verbose")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "global arg usable after subcommand when marked global" {
  let sub = @arg_parser.Command::new("echo").arg(
    @arg_parser.Arg::new("msg").index(0),
  )
  let root = @arg_parser.Command::new("root")
    .arg(@arg_parser.Arg::new("verbose").long("verbose").global())
    .subcommand(sub)
  let matches = root.parse(argv=["echo", "--verbose", "hi"]) catch {
    _ => panic()
  }
  assert_true(matches.get_flag("verbose"))
  let subm = matches.subcommand_matches("echo").unwrap()
  assert_true(subm.get_flag("verbose"))
}

///|
test "root arg after subcommand errors when not global" {
  let sub = @arg_parser.Command::new("echo").arg(
    @arg_parser.Arg::new("msg").index(0),
  )
  let root = @arg_parser.Command::new("root")
    .arg(@arg_parser.Arg::new("verbose").long("verbose"))
    .subcommand(sub)
  try root.parse(argv=["echo", "--verbose", "hi"]) catch {
    @arg_parser.ArgumentError::UnknownArgument(arg, _) => inspect(arg, content="--verbose")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "global arg propagates into subcommand matches" {
  let sub = @arg_parser.Command::new("echo").arg(
    @arg_parser.Arg::new("msg").index(0),
  )
  let root = @arg_parser.Command::new("root")
    .arg(@arg_parser.Arg::new("verbose").long("verbose").global())
    .subcommand(sub)
  let matches = root.parse(argv=["--verbose", "echo", "hi"]) catch {
    _ => panic()
  }
  let subm = matches.subcommand_matches("echo").unwrap()
  assert_true(subm.get_flag("verbose"))
}

///|
test "short option takes value with equals" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("count").short('c').option(),
  )
  let matches = cmd.parse(argv=["-c=3"]) catch { _ => panic() }
  assert_eq(matches.value_of("count").unwrap(), "3")
}

///|
test "short group with value attached" {
  let cmd = @arg_parser.Command::new("demo")
    .arg(@arg_parser.Arg::new("verbose").short('v'))
    .arg(@arg_parser.Arg::new("count").short('c').option())
  let matches = cmd.parse(argv=["-vc3"]) catch { _ => panic() }
  assert_true(matches.get_flag("verbose"))
  assert_eq(matches.value_of("count").unwrap(), "3")
}

///|
test "short group with value in next argv" {
  let cmd = @arg_parser.Command::new("demo")
    .arg(@arg_parser.Arg::new("verbose").short('v'))
    .arg(@arg_parser.Arg::new("count").short('c').option())
  let matches = cmd.parse(argv=["-vc", "3"]) catch { _ => panic() }
  assert_true(matches.get_flag("verbose"))
  assert_eq(matches.value_of("count").unwrap(), "3")
}

///|
test "negation rejects inline values" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("verbose").long("verbose").negatable(),
  )
  try cmd.parse(argv=["--no-verbose=true"]) catch {
    @arg_parser.ArgumentError::InvalidArgument(arg) => inspect(arg, content="--no-verbose=true")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "global option last wins across subcommand boundary" {
  let sub = @arg_parser.Command::new("run")
  let root = @arg_parser.Command::new("root")
    .arg(@arg_parser.Arg::new("config").long("config").option().global())
    .subcommand(sub)
  let matches = root.parse(argv=["--config", "a", "run", "--config", "b"]) catch {
    _ => panic()
  }
  assert_eq(matches.value_of("config").unwrap(), "b")
  let subm = matches.subcommand_matches("run").unwrap()
  assert_eq(subm.value_of("config").unwrap(), "b")
}

///|
test "global option merges multiple values" {
  let sub = @arg_parser.Command::new("run")
  let root = @arg_parser.Command::new("root")
    .arg(@arg_parser.Arg::new("tag").long("tag").option().multiple().global())
    .subcommand(sub)
  let matches = root.parse(argv=["--tag", "a", "run", "--tag", "b"]) catch {
    _ => panic()
  }
  inspect(matches.values_of("tag").unwrap(), content="[\"a\", \"b\"]")
  let subm = matches.subcommand_matches("run").unwrap()
  inspect(subm.values_of("tag").unwrap(), content="[\"a\", \"b\"]")
}

///|
test "arg long alias parses" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("color").long("color").option().alias_name("colour"),
  )
  let matches = cmd.parse(argv=["--colour", "blue"]) catch { _ => panic() }
  assert_eq(matches.value_of("color").unwrap(), "blue")
}

///|
test "arg visible alias shows in help" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("color").long("color").visible_alias("colour"),
  )
  let text = cmd.render_help()
  assert_true(text.contains("--colour"))
}

///|
test "command alias parses" {
  let sub = @arg_parser.Command::new("run").alias_name("r")
  let root = @arg_parser.Command::new("root").subcommand(sub)
  let matches = root.parse(argv=["r"]) catch { _ => panic() }
  assert_eq(matches.subcommand_name().unwrap(), "run")
}

///|
test "command visible alias shows in help" {
  let sub = @arg_parser.Command::new("run").visible_alias("r")
  let root = @arg_parser.Command::new("root").subcommand(sub)
  let text = root.render_help()
  assert_true(text.contains("run, r"))
}

///|
test "hidden command omits from help but still parses" {
  let hidden = @arg_parser.Command::new("secret").hide()
  let visible = @arg_parser.Command::new("show")
  let root = @arg_parser.Command::new("root").subcommand(hidden).subcommand(visible)
  let text = root.render_help()
  assert_false(text.contains("secret"))
  assert_true(text.contains("show"))
  let matches = root.parse(argv=["secret"]) catch { _ => panic() }
  assert_eq(matches.subcommand_name().unwrap(), "secret")
}

///|
test "hidden arg omitted from help but still parses" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("secret").long("secret").hide(),
  )
  let text = cmd.render_help()
  assert_false(text.contains("--secret"))
  let matches = cmd.parse(argv=["--secret"]) catch { _ => panic() }
  assert_true(matches.get_flag("secret"))
}

///|
test "hide long help only hides in man" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("token").long("token").hide_long_help(),
  )
  let plain = cmd.render_help()
  assert_true(plain.contains("--token"))
  let man = cmd.render_help(mode=@arg_parser.HelpMode::Man)
  assert_false(man.contains("--token"))
}

///|
test "required arg group errors when empty" {
  let cmd = @arg_parser.Command::new("demo")
    .group(@arg_parser.ArgGroup::new("mode").required())
    .arg(@arg_parser.Arg::new("fast").long("fast").group("mode"))
    .arg(@arg_parser.Arg::new("slow").long("slow").group("mode"))
  try cmd.parse(argv=[]) catch {
    @arg_parser.ArgumentError::MissingGroup(name) =>
      inspect(name, content="mode")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "exclusive arg group rejects multiple" {
  let cmd = @arg_parser.Command::new("demo")
    .group(@arg_parser.ArgGroup::new("mode").multiple(value=false))
    .arg(@arg_parser.Arg::new("fast").long("fast").group("mode"))
    .arg(@arg_parser.Arg::new("slow").long("slow").group("mode"))
  try cmd.parse(argv=["--fast", "--slow"]) catch {
    @arg_parser.ArgumentError::GroupConflict(name) => inspect(name, content="mode")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "group accepts one member when exclusive" {
  let cmd = @arg_parser.Command::new("demo")
    .group(@arg_parser.ArgGroup::new("mode").multiple(value=false))
    .arg(@arg_parser.Arg::new("fast").long("fast").group("mode"))
    .arg(@arg_parser.Arg::new("slow").long("slow").group("mode"))
  let matches = cmd.parse(argv=["--fast"]) catch { _ => panic() }
  assert_true(matches.get_flag("fast"))
  assert_false(matches.get_flag("slow"))
}

///|
test "required option missing" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("mode").long("mode").option().required(),
  )
  try cmd.parse(argv=[]) catch {
    @arg_parser.ArgumentError::MissingRequired(name) => inspect(name, content="mode")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "min and max values enforced" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("tag")
    .long("tag")
    .option()
    .multiple()
    .min_values(2)
    .max_values(3),
  )
  try cmd.parse(argv=["--tag", "a"]) catch {
    @arg_parser.ArgumentError::TooFewValues(name, got, min) => {
      inspect(name, content="tag")
      inspect(got, content="1")
      inspect(min, content="2")
    }
    _ => panic()
  } noraise {
    _ => panic()
  }
  try cmd.parse(argv=[
    "--tag", "a", "--tag", "b", "--tag", "c", "--tag", "d",
  ]) catch {
    @arg_parser.ArgumentError::TooManyValues(name, got, max) => {
      inspect(name, content="tag")
      inspect(got, content="4")
      inspect(max, content="3")
    }
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "duplicate long option errors" {
  let cmd = @arg_parser.Command::new("demo")
    .arg(@arg_parser.Arg::new("one").long("dup"))
    .arg(@arg_parser.Arg::new("two").long("dup"))
  try cmd.parse(argv=[]) catch {
    @arg_parser.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|duplicate long option: --dup
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "duplicate subcommand alias errors" {
  let sub1 = @arg_parser.Command::new("run").alias_name("r")
  let sub2 = @arg_parser.Command::new("redo").alias_name("r")
  let cmd = @arg_parser.Command::new("root").subcommand(sub1).subcommand(sub2)
  try cmd.parse(argv=[]) catch {
    @arg_parser.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|duplicate subcommand: r
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}
