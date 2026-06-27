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

// Black-box tests that exercise argparse behaviors not covered by the existing
// suites: required-group usage rendering, value-count validation, global
// argument merging across subcommands, and assorted error-message edge paths.

///|
test "required group with only hidden members reports a plain message" {
  let cmd = @argparse.Command(
    "demo",
    groups=[ArgGroup("mode", required=true, args=["fast"])],
    flags=[FlagArg("fast", long="fast", hidden=true)],
  )
  try cmd.parse(argv=[], env=empty_env()) catch {
    err =>
      inspect(
        err,
        content=(
          #|error: the following required argument group was not provided: 'mode'
          #|
          #|Usage: demo
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "required group usage lists every member shape" {
  let cmd = @argparse.Command(
    "demo",
    groups=[
      ArgGroup("g", required=true, args=["opt", "posm", "poss", "sf", "ef"]),
    ],
    flags=[FlagArg("sf", short='s', long=""), FlagArg("ef", long="", env="EF")],
    options=[OptionArg("opt", long="opt")],
    positionals=[
      PositionArg("posm", num_args=ValueRange(lower=0)),
      PositionArg("poss", num_args=ValueRange(lower=0, upper=1)),
    ],
  )
  try cmd.parse(argv=[], env=empty_env()) catch {
    err =>
      inspect(
        err,
        content=(
          #|error: the following required arguments were not provided:
          #|  <--opt <opt>|<posm...>|<poss>|-s|ef>
          #|
          #|Usage: demo [options] [posm...] [poss]
          #|
          #|Arguments:
          #|  posm...  
          #|  poss     
          #|
          #|Options:
          #|  -h, --help   Show help information.
          #|  -s           
          #|  --opt <opt>  
          #|
          #|Groups:
          #|  g [required]  -s, ef, --opt <opt>, posm, poss
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "positional default values exceeding num_args upper bound are rejected" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionArg("tags", num_args=ValueRange(lower=0, upper=2), default_values=[
      "a", "b", "c",
    ]),
  ])
  try cmd.parse(argv=[], env=empty_env()) catch {
    err =>
      inspect(
        err,
        content=(
          #|error: 'tags' allows at most 2 values but 3 were provided
          #|
          #|Usage: demo [tags...]
          #|
          #|Arguments:
          #|  tags...  [default: a, b, c]
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "earlier variadic positional reserves values for a later required one" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionArg("head", num_args=ValueRange(lower=0)),
    PositionArg("tail", num_args=ValueRange(lower=2)),
  ])
  try cmd.parse(argv=["only"], env=empty_env()) catch {
    err =>
      inspect(
        err,
        content=(
          #|error: 'tail' requires at least 2 values but only 1 were provided
          #|
          #|Usage: demo [head...] <tail...>
          #|
          #|Arguments:
          #|  head...  
          #|  tail...  
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "extra values past a bounded variadic positional report the variadic label" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionArg("items", num_args=ValueRange(lower=0, upper=2)),
  ])
  let ok = cmd.parse(argv=["a", "b"], env=empty_env()) catch { _ => panic() }
  assert_true(ok.values is { "items": ["a", "b"], .. })
  try cmd.parse(argv=["a", "b", "c"], env=empty_env()) catch {
    err =>
      inspect(
        err,
        content=(
          #|error: unexpected value 'c' for '<items...>' found; no more were expected
          #|
          #|Usage: demo [items...]
          #|
          #|Arguments:
          #|  items...  
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "duplicate short-only set option reports the short flag label" {
  let cmd = @argparse.Command("demo", options=[
    OptionArg("mode", short='m', long=""),
  ])
  try cmd.parse(argv=["-m", "a", "-m", "b"], env=empty_env()) catch {
    err =>
      inspect(
        err,
        content=(
          #|error: argument '-m' cannot be used multiple times
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|  -m <mode>   
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "boolean env flags accept falsey values" {
  let cmd = @argparse.Command("demo", flags=[
    FlagArg("on", long="on", action=SetTrue, env="ON"),
    FlagArg("off", long="off", action=SetFalse, env="OFF"),
  ])
  let parsed = cmd.parse(argv=[], env={ "ON": "0", "OFF": "no" }) catch {
    _ => panic()
  }
  assert_true(parsed.flags is { "on": false, "off": true, .. })
  assert_true(parsed.sources is { "on": Env, "off": Env, .. })
}

///|
test "unknown long flag with an empty name has no suggestion" {
  let cmd = @argparse.Command("demo", flags=[FlagArg("verbose", long="verbose")])
  try cmd.parse(argv=["--=value"], env=empty_env()) catch {
    err =>
      inspect(
        err,
        content=(
          #|error: unexpected argument '--' found
          #|
          #|Usage: demo [options]
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|  --verbose   
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "subcommand build errors surface as validation failures" {
  let cmd = @argparse.Command("demo", subcommands=[
    Command("child", flags=[FlagArg("x", long="x", requires=["missing"])]),
  ])
  try cmd.parse(argv=[], env=empty_env()) catch {
    err =>
      inspect(
        err,
        content=(
          #|error: command definition validation failed: unknown requires target: x -> missing
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "global flag cannot be redefined as an incompatible global option" {
  let cmd = @argparse.Command(
    "demo",
    flags=[FlagArg("shared", long="shared", global=true)],
    subcommands=[
      Command("child", options=[OptionArg("shared", long="shared", global=true)]),
    ],
  )
  try cmd.parse(argv=[], env=empty_env()) catch {
    err =>
      inspect(
        err,
        content=(
          #|error: command definition validation failed: global arg 'shared' is incompatible with inherited global definition
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "subcommand long option colliding with an inherited global is rejected" {
  let cmd = @argparse.Command(
    "demo",
    options=[OptionArg("opt", long="dup", global=true)],
    subcommands=[Command("child", flags=[FlagArg("other", long="dup")])],
  )
  try cmd.parse(argv=[], env=empty_env()) catch {
    err =>
      inspect(
        err,
        content=(
          #|error: command definition validation failed: arg 'other' long option --dup conflicts with inherited global 'opt'
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "compatible global flag can be redeclared in a subcommand" {
  let cmd = @argparse.Command(
    "demo",
    flags=[FlagArg("v", short='v', long="", global=true)],
    subcommands=[
      Command("child", flags=[FlagArg("v", short='v', long="", global=true)]),
    ],
  )
  let parsed = cmd.parse(argv=["-v", "child"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.flags is { "v": true, .. })
  assert_true(
    parsed.subcommand is Some(("child", sub)) && sub.flags is { "v": true, .. },
  )
}

///|
test "help subcommand cannot follow positional arguments" {
  let cmd = @argparse.Command("demo", positionals=[PositionArg("input")], subcommands=[
    Command("run"),
  ])
  try cmd.parse(argv=["raw", "help"], env=empty_env()) catch {
    err =>
      inspect(
        err,
        content=(
          #|error: subcommand 'help' cannot be used with positional arguments
          #|
          #|Usage: demo [input] [command]
          #|
          #|Commands:
          #|  run   
          #|  help  Print help for the subcommand(s).
          #|
          #|Arguments:
          #|  input  
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "render_help lists positional members inside argument groups" {
  let cmd = @argparse.Command(
    "demo",
    groups=[ArgGroup("inputs", args=["src"])],
    positionals=[PositionArg("src")],
  )
  inspect(
    cmd.render_help(),
    content=(
      #|Usage: demo [src]
      #|
      #|Arguments:
      #|  src  
      #|
      #|Options:
      #|  -h, --help  Show help information.
      #|
      #|Groups:
      #|  inputs  src
      #|
    ),
  )
}

///|
test "render_help tolerates a required env-only option" {
  let cmd = @argparse.Command("demo", options=[
    OptionArg("token", long="", env="TOKEN", required=true),
  ])
  inspect(
    cmd.render_help(),
    content=(
      #|Usage: demo
      #|
      #|Options:
      #|  -h, --help  Show help information.
      #|
    ),
  )
}

///|
test "global set option used in both parent and child argv conflicts" {
  let cmd = @argparse.Command(
    "demo",
    options=[OptionArg("mode", short='m', long="", global=true)],
    subcommands=[Command("run")],
  )
  try cmd.parse(argv=["-m", "a", "run", "-m", "b"], env=empty_env()) catch {
    err =>
      inspect(
        err,
        content=(
          #|error: argument '-m' cannot be used multiple times
          #|
          #|Usage: demo [options] [command]
          #|
          #|Commands:
          #|  run   
          #|  help  Print help for the subcommand(s).
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|  -m <mode>   
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
test "bounded variadic positional stops accepting hyphen tokens once full" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionArg(
      "items",
      num_args=ValueRange(lower=0, upper=2),
      allow_hyphen_values=true,
    ),
  ])
  try cmd.parse(argv=["a", "b", "-c"], env=empty_env()) catch {
    err =>
      inspect(
        err,
        content=(
          #|error: unexpected argument '-c' found
          #|
          #|Usage: demo [items...]
          #|
          #|Arguments:
          #|  items...  
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}

///|
// A leading variadic positional must reserve enough trailing tokens for a later
// positional with a minimum count, so a hyphen token is not mistaken for one of
// its values when the trailing slot still needs filling.
test "hyphen token is rejected while a later positional still needs values" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionArg("head", num_args=ValueRange(lower=0), allow_hyphen_values=true),
    PositionArg("tail", num_args=ValueRange(lower=2)),
  ])
  try cmd.parse(argv=["-x"], env=empty_env()) catch {
    err =>
      inspect(
        err,
        content=(
          #|error: unexpected argument '-x' found
          #|
          #|Usage: demo [head...] <tail...>
          #|
          #|Arguments:
          #|  head...  
          #|  tail...  
          #|
          #|Options:
          #|  -h, --help  Show help information.
          #|
        ),
      )
  } noraise {
    _ => panic()
  }
}
