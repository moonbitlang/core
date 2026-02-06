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
test "help and long help include groups and defaults" {
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
  let long = cmd.render_long_help()
  assert_true(long.contains("Groups:"))
  assert_true(long.contains("Arguments:"))
  assert_true(long.contains("Commands:"))
}

///|
test "parse branches and env errors" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("verbose").short('v'),
  )
  let mut text = ""
  try cmd.parse(argv=["-vh"]) catch {
    @arg_parser.Help::Short(t) => text = t
    _ => panic()
  } noraise {
    _ => panic()
  }
  assert_true(text.contains("Usage:"))
  let cmd2 = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("count").short('c').option(),
  )
  try cmd2.parse(argv=["-c"]) catch {
    @arg_parser.ArgumentError::MissingValue(opt) => inspect(opt, content="-c")
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
    @arg_parser.ArgumentError::InvalidValue(msg) =>
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
    @arg_parser.ArgumentError::InvalidValue(msg) =>
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
    @arg_parser.ArgumentError::UnknownArgument(arg, hint) =>
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

///|
test "default argv path" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("rest").index(0).multiple().last(),
  )
  let _ = cmd.parse() catch { _ => panic() }
}

///|
test "no- prefix unknown target errors" {
  let cmd = @arg_parser.Command::new("demo")
  try cmd.parse(argv=["--no-missing"]) catch {
    @arg_parser.ArgumentError::UnknownArgument(arg, _) =>
      inspect(arg, content="--no-missing")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "short option invalid bool errors" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("flag")
    .short('f')
    .option()
    .action(@arg_parser.ArgAction::SetTrue),
  )
  try cmd.parse(argv=["-fmaybe"]) catch {
    @arg_parser.ArgumentError::InvalidValue(msg) =>
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
}

///|
test "subcommand fallback to positional" {
  let sub = @arg_parser.Command::new("run")
  let cmd = @arg_parser.Command::new("root")
    .subcommand(sub)
    .arg(@arg_parser.Arg::new("name").index(0))
  let m = cmd.parse(argv=["value"]) catch { _ => panic() }
  assert_eq(m.value_of("name").unwrap(), "value")
}

///|
test "visible alias parses" {
  let sub = @arg_parser.Command::new("run").visible_alias("r")
  let root = @arg_parser.Command::new("root").subcommand(sub)
  let matches = root.parse(argv=["r"]) catch { _ => panic() }
  assert_eq(matches.subcommand_name().unwrap(), "run")
}

///|
test "help subcommand rejects option argument" {
  let sub = @arg_parser.Command::new("run")
  let root = @arg_parser.Command::new("root").subcommand(sub)
  try root.parse(argv=["help", "--nope"]) catch {
    @arg_parser.ArgumentError::InvalidArgument(msg) =>
      inspect(
        msg,
        content=(
          #|unexpected help argument: --nope
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "help subcommand unknown target" {
  let sub = @arg_parser.Command::new("run")
  let root = @arg_parser.Command::new("root").subcommand(sub)
  try root.parse(argv=["help", "nope"]) catch {
    @arg_parser.ArgumentError::InvalidArgument(msg) =>
      inspect(
        msg,
        content=(
          #|unknown subcommand: nope
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "help subcommand -h uses short help" {
  let sub = @arg_parser.Command::new("run")
  let root = @arg_parser.Command::new("root")
    .about("short root")
    .long_about("long root")
    .subcommand(sub)
  try root.parse(argv=["help", "-h"]) catch {
    @arg_parser.Help::Short(text) => {
      inspect(text.contains("short root"), content="true")
      inspect(text.contains("long root"), content="false")
    }
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "help subcommand -h errors when help flag disabled" {
  let sub = @arg_parser.Command::new("run")
  let root = @arg_parser.Command::new("root")
    .disable_help_flag()
    .subcommand(sub)
  try root.parse(argv=["help", "-h"]) catch {
    @arg_parser.ArgumentError::InvalidArgument(msg) =>
      inspect(msg, content="unexpected help argument: -h")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "help docs cover help-only and min-values required" {
  let cmd = @arg_parser.Command::new("demo")
    .arg(@arg_parser.Arg::new("mode").long("mode").help("mode help"))
    .arg(
      @arg_parser.Arg::new("tag")
      .long("tag")
      .option()
      .multiple()
      .min_values(1)
      .help("tag help"),
    )
  let text = cmd.render_help()
  assert_true(text.contains("mode help"))
  assert_true(text.contains("required"))
}

///|
test "group ignores non-members" {
  let cmd = @arg_parser.Command::new("demo")
    .group(@arg_parser.ArgGroup::new("mode"))
    .arg(@arg_parser.Arg::new("fast").long("fast").group("mode"))
    .arg(@arg_parser.Arg::new("extra").long("extra"))
  let matches = cmd.parse(argv=["--extra"]) catch { _ => panic() }
  assert_true(matches.get_flag("extra"))
}

///|
test "append action collects values" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("tag")
    .long("tag")
    .option()
    .action(@arg_parser.ArgAction::Append),
  )
  let matches = cmd.parse(argv=["--tag", "a", "--tag", "b"]) catch {
    _ => panic()
  }
  inspect(matches.values_of("tag").unwrap(), content="[\"a\", \"b\"]")
}

///|
test "settrue option parses false" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("flag")
    .long("flag")
    .option()
    .action(@arg_parser.ArgAction::SetTrue),
  )
  let matches = cmd.parse(argv=["--flag", "0"]) catch { _ => panic() }
  assert_false(matches.get_flag("flag"))
}

///|
test "setfalse option parses true" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("flag")
    .long("flag")
    .option()
    .action(@arg_parser.ArgAction::SetFalse),
  )
  let matches = cmd.parse(argv=["--flag", "true"]) catch { _ => panic() }
  assert_false(matches.get_flag("flag"))
}

///|
test "setfalse option invalid value errors" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("flag")
    .long("flag")
    .option()
    .action(@arg_parser.ArgAction::SetFalse),
  )
  try cmd.parse(argv=["--flag", "maybe"]) catch {
    @arg_parser.ArgumentError::InvalidValue(msg) =>
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
}

///|
test "env invalid for option errors" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("flag")
    .long("flag")
    .option()
    .action(@arg_parser.ArgAction::SetTrue)
    .env("FLAG"),
  )
  try cmd.parse(argv=[], env={ "FLAG": "nope" }) catch {
    @arg_parser.ArgumentError::InvalidValue(msg) =>
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
}

///|
test "env count for flag" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("count")
    .long("count")
    .action(@arg_parser.ArgAction::Count)
    .env("COUNT"),
  )
  let matches = cmd.parse(argv=[], env={ "COUNT": "2" }) catch { _ => panic() }
  assert_eq(matches.count_of("count"), 2)
  assert_true(matches.get_flag("count"))
}

///|
test "env count invalid value errors" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("count")
    .long("count")
    .action(@arg_parser.ArgAction::Count)
    .env("COUNT"),
  )
  try cmd.parse(argv=[], env={ "COUNT": "nope" }) catch {
    @arg_parser.ArgumentError::InvalidValue(msg) =>
      inspect(
        msg,
        content=(
          #|invalid int: nope
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "env setfalse flag" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("flag")
    .long("flag")
    .action(@arg_parser.ArgAction::SetFalse)
    .env("FLAG"),
  )
  let matches = cmd.parse(argv=[], env={ "FLAG": "true" }) catch {
    _ => panic()
  }
  assert_false(matches.get_flag("flag"))
}

///|
test "env set flag parses false" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("flag")
    .long("flag")
    .action(@arg_parser.ArgAction::Set)
    .env("FLAG"),
  )
  let matches = cmd.parse(argv=[], env={ "FLAG": "0" }) catch { _ => panic() }
  assert_false(matches.get_flag("flag"))
}

///|
test "env setfalse invalid value errors" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("flag")
    .long("flag")
    .action(@arg_parser.ArgAction::SetFalse)
    .env("FLAG"),
  )
  try cmd.parse(argv=[], env={ "FLAG": "nope" }) catch {
    @arg_parser.ArgumentError::InvalidValue(msg) =>
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
}

///|
test "env set invalid value errors" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("flag")
    .long("flag")
    .action(@arg_parser.ArgAction::Set)
    .env("FLAG"),
  )
  try cmd.parse(argv=[], env={ "FLAG": "nope" }) catch {
    @arg_parser.ArgumentError::InvalidValue(msg) =>
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
}

///|
test "env append on flag ignored" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("flag")
    .long("flag")
    .action(@arg_parser.ArgAction::Append)
    .env("FLAG"),
  )
  let matches = cmd.parse(argv=[], env={ "FLAG": "1" }) catch { _ => panic() }
  assert_false(matches.get_flag("flag"))
  match matches.source_of("flag") {
    None => ()
    Some(_) => panic()
  }
}

///|
test "sort positionals with descending indices" {
  let cmd = @arg_parser.Command::new("demo")
    .arg(@arg_parser.Arg::new("c").index(2))
    .arg(@arg_parser.Arg::new("b").index(1))
    .arg(@arg_parser.Arg::new("a").index(0))
  let matches = cmd.parse(argv=["x", "y", "z"]) catch { _ => panic() }
  assert_eq(matches.value_of("a").unwrap(), "x")
  assert_eq(matches.value_of("b").unwrap(), "y")
  assert_eq(matches.value_of("c").unwrap(), "z")
}

///|
test "setfalse flag from argv" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("flag")
    .long("flag")
    .action(@arg_parser.ArgAction::SetFalse),
  )
  let matches = cmd.parse(argv=["--flag"]) catch { _ => panic() }
  assert_false(matches.get_flag("flag"))
}

///|
test "set flag action from argv" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("flag").long("flag").action(@arg_parser.ArgAction::Set),
  )
  let matches = cmd.parse(argv=["--flag"]) catch { _ => panic() }
  assert_true(matches.get_flag("flag"))
}

///|
test "get_option returns value" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("count").long("count").option(),
  )
  let matches = cmd.parse(argv=["--count", "1"]) catch { _ => panic() }
  assert_eq(matches.get_option("count").unwrap(), "1")
}

///|
test "positional-only settings with long errors" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("pos").index(0).long("pos"),
  )
  try cmd.parse(argv=[]) catch {
    @arg_parser.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|positional-only settings require no short/long/aliases
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "negatable option errors" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("flag").long("flag").option().negatable(),
  )
  try cmd.parse(argv=[]) catch {
    @arg_parser.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|negatable is only supported for flags
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "count option errors" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("count")
    .long("count")
    .option()
    .action(@arg_parser.ArgAction::Count),
  )
  try cmd.parse(argv=[]) catch {
    @arg_parser.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|count is only supported for flags
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "min values require value-taking arguments" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("flag").long("flag").min_values(1),
  )
  try cmd.parse(argv=[]) catch {
    @arg_parser.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|min/max values require value-taking arguments
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "max values less than min errors" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("tag").long("tag").option().min_values(2).max_values(1),
  )
  try cmd.parse(argv=[]) catch {
    @arg_parser.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|max values must be >= min values
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "max values less than one errors" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("tag").long("tag").option().max_values(0),
  )
  try cmd.parse(argv=[]) catch {
    @arg_parser.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|max values must be >= 1
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "multiple values require multiple or append" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("tag").long("tag").option().min_values(2),
  )
  try cmd.parse(argv=[]) catch {
    @arg_parser.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|multiple values require multiple/append
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "default values require value-taking arguments" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("flag").long("flag").default_value("x"),
  )
  try cmd.parse(argv=[]) catch {
    @arg_parser.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|default values require value-taking arguments
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "default_values require multiple or append" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("tag").long("tag").option().default_values(["a", "b"]),
  )
  try cmd.parse(argv=[]) catch {
    @arg_parser.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|default_values require multiple/append arguments
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "duplicate group errors" {
  let cmd = @arg_parser.Command::new("demo")
    .group(@arg_parser.ArgGroup::new("mode"))
    .group(@arg_parser.ArgGroup::new("mode"))
  try cmd.parse(argv=[]) catch {
    @arg_parser.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|duplicate group: mode
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "unknown group errors" {
  let cmd = @arg_parser.Command::new("demo")
    .group(@arg_parser.ArgGroup::new("other"))
    .arg(@arg_parser.Arg::new("fast").long("fast").group("mode"))
  try cmd.parse(argv=[]) catch {
    @arg_parser.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|unknown group: mode
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "unknown requires target errors" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("mode").long("mode").option().requires("config"),
  )
  try cmd.parse(argv=[]) catch {
    @arg_parser.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|unknown requires target: mode -> config
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "unknown conflicts_with target errors" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("verbose").long("verbose").conflicts_with("quiet"),
  )
  try cmd.parse(argv=[]) catch {
    @arg_parser.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|unknown conflicts_with target: verbose -> quiet
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "self requires errors" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("mode").long("mode").option().requires("mode"),
  )
  try cmd.parse(argv=[]) catch {
    @arg_parser.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|arg cannot require itself: mode
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "self conflicts_with errors" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("verbose").long("verbose").conflicts_with("verbose"),
  )
  try cmd.parse(argv=[]) catch {
    @arg_parser.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|arg cannot conflict with itself: verbose
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "duplicate arg name errors" {
  let cmd = @arg_parser.Command::new("demo")
    .arg(@arg_parser.Arg::new("dup").long("one"))
    .arg(@arg_parser.Arg::new("dup").long("two"))
  try cmd.parse(argv=[]) catch {
    @arg_parser.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|duplicate arg name: dup
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "duplicate short option errors" {
  let cmd = @arg_parser.Command::new("demo")
    .arg(@arg_parser.Arg::new("one").short('v'))
    .arg(@arg_parser.Arg::new("two").short('v'))
  try cmd.parse(argv=[]) catch {
    @arg_parser.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|duplicate short option: -v
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "help subcommand reserved name errors" {
  let cmd = @arg_parser.Command::new("root").subcommand(
    @arg_parser.Command::new("help"),
  )
  try cmd.parse(argv=[]) catch {
    @arg_parser.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|subcommand name reserved for built-in help: help (disable with disable_help_subcommand)
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "version flag reserved name errors" {
  let cmd = @arg_parser.Command::new("root")
    .version("1.0")
    .arg(@arg_parser.Arg::new("version").long("version"))
  try cmd.parse(argv=[]) catch {
    @arg_parser.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|option name reserved for built-in version: --version (disable with disable_version_flag)
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "help flag reserved name errors" {
  let cmd = @arg_parser.Command::new("root").arg(
    @arg_parser.Arg::new("help").long("help"),
  )
  try cmd.parse(argv=[]) catch {
    @arg_parser.ArgBuildError::Unsupported(msg) =>
      inspect(
        msg,
        content=(
          #|option name reserved for built-in help: --help (disable with disable_help_flag)
        ),
      )
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "version action requires text" {
  let cmd = @arg_parser.Command::new("root").arg(
    @arg_parser.Arg::new("ver")
    .long("ver")
    .action(@arg_parser.ArgAction::Version),
  )
  try cmd.parse(argv=[]) catch {
    @arg_parser.ArgBuildError::Unsupported(msg) =>
      inspect(msg, content="version action requires command version text")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "global values missing do not propagate" {
  let sub = @arg_parser.Command::new("run")
  let root = @arg_parser.Command::new("root")
    .arg(@arg_parser.Arg::new("config").long("config").option().global())
    .arg(@arg_parser.Arg::new("verbose").long("verbose").global())
    .subcommand(sub)
  let matches = root.parse(argv=["run"]) catch { _ => panic() }
  match matches.value_of("config") {
    None => ()
    Some(_) => panic()
  }
  assert_false(matches.get_flag("verbose"))
  let subm = matches.subcommand_matches("run").unwrap()
  match subm.value_of("config") {
    None => ()
    Some(_) => panic()
  }
  assert_false(subm.get_flag("verbose"))
}

///|
test "suggestion handles empty candidate" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("empty").long("").option(),
  )
  try cmd.parse(argv=["--unknown"]) catch {
    @arg_parser.ArgumentError::UnknownArgument(arg, hint) =>
      match hint {
        None => inspect(arg, content="--unknown")
        Some(_) => panic()
      }
    _ => panic()
  } noraise {
    _ => panic()
  }
}
