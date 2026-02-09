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
fn empty_env() -> Map[String, String] {
  {}
}

///|
test "declarative parse basics" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.FlagArg("verbose", short='v', long="verbose"),
    @argparse.OptionArg("count", long="count", env="COUNT"),
    @argparse.PositionalArg("name", index=0),
  ])
  let matches = cmd.parse(argv=["-v", "--count", "3", "alice"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(matches.get_flag("verbose"))
  assert_eq(matches.get_one("count").unwrap_or(""), "3")
  assert_eq(matches.get_one("name").unwrap_or(""), "alice")
  inspect(matches.flags_map().get("verbose"), content="Some(true)")
  inspect(matches.values_map().get("name"), content="Some([\"alice\"])")
}

///|
test "display help and version" {
  let cmd = @argparse.Command("demo", about="demo app", version="1.2.3")

  let mut help = ""
  try cmd.parse(argv=["-h"], env=empty_env()) catch {
    @argparse.DisplayHelp::Short(text) => help = text
    _ => panic()
  } noraise {
    _ => panic()
  }
  inspect(help.contains("Usage:"), content="true")

  let mut version = ""
  try cmd.parse(argv=["--version"], env=empty_env()) catch {
    @argparse.DisplayVersion::Long(text) => version = text
    _ => panic()
  } noraise {
    _ => panic()
  }
  inspect(version, content="1.2.3")
}

///|
test "relationships and num args" {
  let requires_cmd = @argparse.Command("demo", args=[
    @argparse.OptionArg("mode", long="mode", requires=["config"]),
    @argparse.OptionArg("config", long="config"),
  ])

  try requires_cmd.parse(argv=["--mode", "fast"], env=empty_env()) catch {
    @argparse.ArgParseError::MissingRequired(name) =>
      inspect(name, content="config")
    _ => panic()
  } noraise {
    _ => panic()
  }

  let num_args_cmd = @argparse.Command("demo", args=[
    @argparse.OptionArg(
      "tag",
      long="tag",
      multiple=true,
      num_args=@argparse.ValueRange(lower=2, upper=2),
    ),
  ])

  try num_args_cmd.parse(argv=["--tag", "a"], env=empty_env()) catch {
    @argparse.ArgParseError::TooFewValues(name, got, min) => {
      inspect(name, content="tag")
      inspect(got, content="1")
      inspect(min, content="2")
    }
    _ => panic()
  } noraise {
    _ => panic()
  }

  try
    num_args_cmd.parse(argv=["--tag", "a", "--tag", "b", "--tag", "c"], env=empty_env())
  catch {
    @argparse.ArgParseError::TooManyValues(name, got, max) => {
      inspect(name, content="tag")
      inspect(got, content="3")
      inspect(max, content="2")
    }
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "arg groups required and multiple" {
  let cmd = @argparse.Command(
    "demo",
    groups=[@argparse.ArgGroup("mode", required=true, multiple=false)],
    args=[
      @argparse.FlagArg("fast", long="fast", group="mode"),
      @argparse.FlagArg("slow", long="slow", group="mode"),
    ],
  )

  try cmd.parse(argv=[], env=empty_env()) catch {
    @argparse.ArgParseError::MissingGroup(name) => inspect(name, content="mode")
    _ => panic()
  } noraise {
    _ => panic()
  }

  try cmd.parse(argv=["--fast", "--slow"], env=empty_env()) catch {
    @argparse.ArgParseError::GroupConflict(name) => inspect(name, content="mode")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "arg groups requires and conflicts" {
  let requires_cmd = @argparse.Command(
    "demo",
    groups=[
      @argparse.ArgGroup("mode", args=["fast"], requires=["output"]),
      @argparse.ArgGroup("output", args=["json"]),
    ],
    args=[
      @argparse.FlagArg("fast", long="fast"),
      @argparse.FlagArg("json", long="json"),
    ],
  )

  try requires_cmd.parse(argv=["--fast"], env=empty_env()) catch {
    @argparse.ArgParseError::MissingGroup(name) => inspect(name, content="output")
    _ => panic()
  } noraise {
    _ => panic()
  }

  let conflict_cmd = @argparse.Command(
    "demo",
    groups=[
      @argparse.ArgGroup("mode", args=["fast"], conflicts_with=["output"]),
      @argparse.ArgGroup("output", args=["json"]),
    ],
    args=[
      @argparse.FlagArg("fast", long="fast"),
      @argparse.FlagArg("json", long="json"),
    ],
  )

  try conflict_cmd.parse(argv=["--fast", "--json"], env=empty_env()) catch {
    @argparse.ArgParseError::GroupConflict(msg) =>
      inspect(msg.contains("mode conflicts with output"), content="true")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "subcommand parsing" {
  let echo = @argparse.Command("echo", args=[@argparse.PositionalArg("msg", index=0)])
  let root = @argparse.Command("root", subcommands=[echo])

  let matches = root.parse(argv=["echo", "hi"], env=empty_env()) catch { _ => panic() }
  assert_eq(matches.subcommand_name().unwrap_or(""), "echo")

  let sub = matches.subcommand_matches("echo").unwrap()
  assert_eq(sub.get_one("msg").unwrap_or(""), "hi")
  inspect(sub.values_map().get("msg"), content="Some([\"hi\"])")
}

///|
test "full help snapshot" {
  let cmd = @argparse.Command(
    "demo",
    about="Demo command",
    args=[
      @argparse.FlagArg(
        "verbose",
        short='v',
        long="verbose",
        about="Enable verbose mode",
      ),
      @argparse.OptionArg(
        "count",
        long="count",
        about="Repeat count",
        default_value="1",
      ),
      @argparse.PositionalArg("name", index=0, about="Target name"),
    ],
    subcommands=[@argparse.Command("echo", about="Echo a message")],
  )
  inspect(
    cmd.render_help(),
    content=(
      #|Usage: demo [options] <command> [name]
      #|
      #|Demo command
      #|
      #|Commands:
      #|  echo  Echo a message
      #|  help  Print help for the subcommand(s).
      #|
      #|Arguments:
      #|  name  Target name
      #|
      #|Options:
      #|  -h, --help       Show help information.
      #|  -v, --verbose    Enable verbose mode
      #|  --count <count>  Repeat count (default: 1)
    ),
  )
}

///|
test "value source precedence argv env default" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.OptionArg(
      "level",
      long="level",
      env="LEVEL",
      default_value="1",
    ),
  ])

  let from_default = cmd.parse(argv=[], env=empty_env()) catch { _ => panic() }
  inspect(from_default.get_one("level"), content="Some(\"1\")")
  inspect(from_default.value_source("level"), content="Some(Default)")

  let from_env = cmd.parse(argv=[], env={"LEVEL": "2"}) catch { _ => panic() }
  inspect(from_env.get_one("level"), content="Some(\"2\")")
  inspect(from_env.value_source("level"), content="Some(Env)")

  let from_argv = cmd.parse(argv=["--level", "3"], env={"LEVEL": "2"}) catch {
    _ => panic()
  }
  inspect(from_argv.get_one("level"), content="Some(\"3\")")
  inspect(from_argv.value_source("level"), content="Some(Argv)")
}

///|
test "omitted env does not read process environment by default" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.OptionArg("count", long="count", env="COUNT"),
  ])
  let matches = cmd.parse(argv=[]) catch { _ => panic() }
  inspect(matches.get_one("count"), content="None")
  inspect(matches.value_source("count"), content="None")
}

///|
test "aliases and multiple values" {
  let serve = @argparse.Command("serve", aliases=["srv"], visible_aliases=["run"])
  let cmd = @argparse.Command(
    "demo",
    args=[
      @argparse.OptionArg(
        "count",
        long="count",
        aliases=["times"],
        short_aliases=['c'],
        visible_aliases=["total"],
      ),
      @argparse.OptionArg("tag", long="tag", multiple=true),
    ],
    subcommands=[serve],
  )

  let alias_long = cmd.parse(argv=["--times", "2"], env=empty_env()) catch {
    _ => panic()
  }
  inspect(alias_long.get_one("count"), content="Some(\"2\")")

  let alias_short = cmd.parse(argv=["-c", "3"], env=empty_env()) catch {
    _ => panic()
  }
  inspect(alias_short.get_one("count"), content="Some(\"3\")")

  let multi = cmd.parse(argv=["--tag", "a", "--tag", "b"], env=empty_env()) catch {
    _ => panic()
  }
  inspect(multi.get_one("tag"), content="Some(\"a\")")
  inspect(multi.get_many("tag"), content="Some([\"a\", \"b\"])")

  let sub_alias = cmd.parse(argv=["srv"], env=empty_env()) catch { _ => panic() }
  inspect(sub_alias.subcommand_name(), content="Some(\"serve\")")
}

///|
test "negatable and conflicts" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.FlagArg("cache", long="cache", negatable=true),
    @argparse.FlagArg(
      "failfast",
      long="failfast",
      action=@argparse.FlagAction::SetFalse,
      negatable=true,
    ),
    @argparse.FlagArg("verbose", long="verbose", conflicts_with=["quiet"]),
    @argparse.FlagArg("quiet", long="quiet"),
  ])

  let no_cache = cmd.parse(argv=["--no-cache"], env=empty_env()) catch {
    _ => panic()
  }
  inspect(no_cache.get_flag("cache"), content="false")
  inspect(no_cache.value_source("cache"), content="Some(Argv)")

  let no_failfast = cmd.parse(argv=["--no-failfast"], env=empty_env()) catch {
    _ => panic()
  }
  inspect(no_failfast.get_flag("failfast"), content="true")

  try cmd.parse(argv=["--verbose", "--quiet"], env=empty_env()) catch {
    @argparse.ArgParseError::InvalidArgument(msg) =>
      inspect(msg.contains("conflicting arguments"), content="true")
    _ => panic()
  } noraise {
    _ => panic()
  }
}

///|
test "command policies" {
  let help_cmd = @argparse.Command("demo", arg_required_else_help=true)
  try help_cmd.parse(argv=[], env=empty_env()) catch {
    @argparse.DisplayHelp::Short(text) => inspect(text.contains("Usage:"), content="true")
    _ => panic()
  } noraise {
    _ => panic()
  }

  let sub_cmd = @argparse.Command(
    "demo",
    subcommand_required=true,
    subcommands=[@argparse.Command("echo")],
  )
  try sub_cmd.parse(argv=[], env=empty_env()) catch {
    @argparse.ArgParseError::MissingRequired(name) => inspect(name, content="subcommand")
    _ => panic()
  } noraise {
    _ => panic()
  }
}
