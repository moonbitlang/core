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
test "declarative parse basics" {
  let cmd = @argparse.Command("demo", args=[
    @argparse.FlagArg::new("verbose", short='v', long="verbose"),
    @argparse.OptionArg::new("count", long="count", env="COUNT"),
    @argparse.PositionalArg::new("name", index=0),
  ])
  let matches = cmd.parse(argv=["-v", "--count", "3", "alice"], env={}) catch {
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
  try cmd.parse(argv=["-h"], env={}) catch {
    @argparse.DisplayHelp::Short(text) => help = text
    _ => panic()
  } noraise {
    _ => panic()
  }
  inspect(help.contains("Usage:"), content="true")

  let mut version = ""
  try cmd.parse(argv=["--version"], env={}) catch {
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
    @argparse.OptionArg::new("mode", long="mode", requires=["config"]),
    @argparse.OptionArg::new("config", long="config"),
  ])

  try requires_cmd.parse(argv=["--mode", "fast"], env={}) catch {
    @argparse.ArgumentError::MissingRequired(name) =>
      inspect(name, content="config")
    _ => panic()
  } noraise {
    _ => panic()
  }

  let num_args_cmd = @argparse.Command("demo", args=[
    @argparse.OptionArg::new(
      "tag",
      long="tag",
      multiple=true,
      num_args=@argparse.ValueRange::new(lower=Some(2), upper=Some(2)),
    ),
  ])

  try num_args_cmd.parse(argv=["--tag", "a"], env={}) catch {
    @argparse.ArgumentError::TooFewValues(name, got, min) => {
      inspect(name, content="tag")
      inspect(got, content="1")
      inspect(min, content="2")
    }
    _ => panic()
  } noraise {
    _ => panic()
  }

  try
    num_args_cmd.parse(argv=["--tag", "a", "--tag", "b", "--tag", "c"], env={})
  catch {
    @argparse.ArgumentError::TooManyValues(name, got, max) => {
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
test "subcommand parsing" {
  let echo = @argparse.Command("echo", args=[
    @argparse.PositionalArg::new("msg", index=0),
  ])
  let root = @argparse.Command("root", subcommands=[echo])

  let matches = root.parse(argv=["echo", "hi"], env={}) catch { _ => panic() }
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
      @argparse.FlagArg::new(
        "verbose",
        short='v',
        long="verbose",
        about="Enable verbose mode",
      ),
      @argparse.OptionArg::new(
        "count",
        long="count",
        about="Repeat count",
        default_value="1",
      ),
      @argparse.PositionalArg::new(
        "name",
        index=0,
        about="Target name",
      ),
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
