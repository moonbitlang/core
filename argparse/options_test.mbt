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
test "long defaults to name when omitted" {
  let cmd = @argparse.Command("demo", flags=[FlagArg("verbose")], options=[
    OptionArg("count"),
  ])
  let matches = cmd.parse(argv=["--verbose", "--count", "3"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(matches.flags is { "verbose": true, .. })
  assert_true(matches.values is { "count": ["3"], .. })
}

///|
test "negatable flag preserves false state" {
  let cmd = @argparse.Command("demo", flags=[
    FlagArg("cache", long="cache", negatable=true),
  ])

  let no_cache = cmd.parse(argv=["--no-cache"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(no_cache.flags is { "cache": false, .. })
  assert_true(no_cache.flag_counts.get("cache") is None)
}

///|
test "value source precedence argv env default" {
  let cmd = @argparse.Command("demo", options=[
    OptionArg("level", long="level", env="LEVEL", default_values=["1"]),
  ])

  let from_default = cmd.parse(argv=[], env=empty_env()) catch { _ => panic() }
  assert_true(from_default.values is { "level": ["1"], .. })
  assert_true(from_default.sources is { "level": Default, .. })

  let from_env = cmd.parse(argv=[], env={ "LEVEL": "2" }) catch { _ => panic() }
  assert_true(from_env.values is { "level": ["2"], .. })
  assert_true(from_env.sources is { "level": Env, .. })

  let from_argv = cmd.parse(argv=["--level", "3"], env={ "LEVEL": "2" }) catch {
    _ => panic()
  }
  assert_true(from_argv.values is { "level": ["3"], .. })
  assert_true(from_argv.sources is { "level": Argv, .. })
}

///|
test "omitted env does not read process environment by default" {
  let cmd = @argparse.Command("demo", options=[
    OptionArg("count", long="count", env="COUNT"),
  ])
  let matches = cmd.parse(argv=[]) catch { _ => panic() }
  assert_true(matches.values is { "count"? : None, .. })
  assert_true(matches.sources is { "count"? : None, .. })
}

///|
test "options and multiple values" {
  let serve = @argparse.Command("serve")
  let cmd = @argparse.Command(
    "demo",
    options=[
      OptionArg("count", short='c', long="count"),
      OptionArg("tag", long="tag", action=Append),
    ],
    subcommands=[serve],
  )

  let long_count = cmd.parse(argv=["--count", "2"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(long_count.values is { "count": ["2"], .. })

  let short_count = cmd.parse(argv=["-c", "3"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(short_count.values is { "count": ["3"], .. })

  let multi = cmd.parse(argv=["--tag", "a", "--tag", "b"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(multi.values is { "tag": ["a", "b"], .. })

  let subcommand = cmd.parse(argv=["serve"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(subcommand.subcommand is Some(("serve", _)))
}

///|
test "flag does not accept inline value" {
  let cmd = @argparse.Command("demo", flags=[FlagArg("verbose", long="verbose")])
  inspect(
    @test.expect_error(() => cmd.parse(argv=["--verbose=true"], env=empty_env())),
    content=(
      #|error: unexpected argument '--verbose=true' found
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help  Show help information.
      #|  --verbose   
      #|
    ),
  )
}

///|
test "built-in long flags do not accept inline value" {
  let cmd = @argparse.Command("demo", version="1.2.3")

  inspect(
    @test.expect_error(() => cmd.parse(argv=["--help=1"], env=empty_env())),
    content=(
      #|error: unexpected argument '--help=1' found
      #|
      #|Usage: demo
      #|
      #|Options:
      #|  -h, --help     Show help information.
      #|  -V, --version  Show version information.
      #|
    ),
  )

  inspect(
    @test.expect_error(() => cmd.parse(argv=["--version=1"], env=empty_env())),
    content=(
      #|error: unexpected argument '--version=1' found
      #|
      #|Usage: demo
      #|
      #|Options:
      #|  -h, --help     Show help information.
      #|  -V, --version  Show version information.
      #|
    ),
  )
}

///|
test "count flags and sources with pattern matching" {
  let cmd = @argparse.Command("demo", flags=[
    FlagArg("verbose", short='v', long="verbose", action=Count),
  ])
  let matches = cmd.parse(argv=["-v", "-v", "-v"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(matches.flags is { "verbose": true, .. })
  assert_true(matches.flag_counts is { "verbose": 3, .. })
  assert_true(matches.sources is { "verbose": Argv, .. })
}

///|
test "append option action is publicly selectable" {
  let cmd = @argparse.Command("demo", options=[
    OptionArg("tag", long="tag", action=Append),
  ])
  let appended = cmd.parse(argv=["--tag", "a", "--tag", "b"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(appended.values is { "tag": ["a", "b"], .. })
  assert_true(appended.sources is { "tag": Argv, .. })
}

///|
test "negation parsing and invalid negation forms" {
  let cmd = @argparse.Command(
    "demo",
    flags=[FlagArg("cache", long="cache", negatable=true)],
    options=[OptionArg("path", long="path")],
  )

  let off = cmd.parse(argv=["--no-cache"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(off.flags is { "cache": false, .. })
  assert_true(off.sources is { "cache": Argv, .. })

  inspect(
    @test.expect_error(() => cmd.parse(argv=["--no-path"], env=empty_env())),
    content=(
      #|error: unexpected argument '--no-path' found
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help     Show help information.
      #|  --[no-]cache   
      #|  --path <path>  
      #|
    ),
  )

  inspect(
    @test.expect_error(() => cmd.parse(argv=["--no-missing"], env=empty_env())),
    content=(
      #|error: unexpected argument '--no-missing' found
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help     Show help information.
      #|  --[no-]cache   
      #|  --path <path>  
      #|
    ),
  )

  inspect(
    @test.expect_error(() => cmd.parse(argv=["--no-cache=1"], env=empty_env())),
    content=(
      #|error: unexpected argument '--no-cache=1' found
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help     Show help information.
      #|  --[no-]cache   
      #|  --path <path>  
      #|
    ),
  )

  let count_cmd = @argparse.Command("demo", flags=[
    FlagArg("verbose", long="verbose", action=Count, negatable=true),
  ])
  let reset = count_cmd.parse(
    argv=["--verbose", "--no-verbose"],
    env=empty_env(),
  ) catch {
    _ => panic()
  }
  assert_true(reset.flags is { "verbose": false, .. })
  assert_true(reset.flag_counts is { "verbose"? : None, .. })
  assert_true(reset.sources is { "verbose": Argv, .. })
}

///|
test "env parsing for settrue setfalse count and invalid values" {
  let cmd = @argparse.Command("demo", flags=[
    FlagArg("on", long="on", action=SetTrue, env="ON"),
    FlagArg("off", long="off", action=SetFalse, env="OFF"),
    FlagArg("v", long="v", action=Count, env="V"),
  ])

  let parsed = cmd.parse(argv=[], env={ "ON": "true", "OFF": "true", "V": "3" }) catch {
    _ => panic()
  }
  assert_true(parsed.flags is { "on": true, "off": false, "v": true, .. })
  assert_true(parsed.flag_counts is { "v": 3, .. })
  assert_true(parsed.sources is { "on": Env, "off": Env, "v": Env, .. })

  inspect(
    @test.expect_error(() => cmd.parse(argv=[], env={ "ON": "bad" })),
    content=(
      #|error: invalid value 'bad' for boolean flag; expected one of: 1, 0, true, false, yes, no, on, off
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help  Show help information.
      #|  --on        [env: ON]
      #|  --off       [env: OFF]
      #|  --v         [env: V]
      #|
    ),
  )

  inspect(
    @test.expect_error(() => cmd.parse(argv=[], env={ "OFF": "bad" })),
    content=(
      #|error: invalid value 'bad' for boolean flag; expected one of: 1, 0, true, false, yes, no, on, off
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help  Show help information.
      #|  --on        [env: ON]
      #|  --off       [env: OFF]
      #|  --v         [env: V]
      #|
    ),
  )

  inspect(
    @test.expect_error(() => cmd.parse(argv=[], env={ "V": "bad" })),
    content=(
      #|error: invalid value 'bad' for count; expected a non-negative integer
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help  Show help information.
      #|  --on        [env: ON]
      #|  --off       [env: OFF]
      #|  --v         [env: V]
      #|
    ),
  )

  inspect(
    @test.expect_error(() => cmd.parse(argv=[], env={ "V": "-1" })),
    content=(
      #|error: invalid value '-1' for count; expected a non-negative integer
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help  Show help information.
      #|  --on        [env: ON]
      #|  --off       [env: OFF]
      #|  --v         [env: V]
      #|
    ),
  )
}

///|
test "options consume exactly one value per occurrence" {
  let cmd = @argparse.Command("demo", options=[OptionArg("tag", long="tag")])
  let parsed = cmd.parse(argv=["--tag", "a"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "tag": ["a"], .. })
  assert_true(parsed.sources is { "tag": Argv, .. })

  inspect(
    @test.expect_error(() => {
      cmd.parse(argv=["--tag", "a", "b"], env=empty_env())
    }),
    content=(
      #|error: unexpected value 'b' found; no more were expected
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help   Show help information.
      #|  --tag <tag>  
      #|
    ),
  )
}

///|
test "set options reject duplicate occurrences" {
  let cmd = @argparse.Command("demo", options=[OptionArg("mode", long="mode")])
  inspect(
    @test.expect_error(() => {
      cmd.parse(argv=["--mode", "a", "--mode", "b"], env=empty_env())
    }),
    content=(
      #|error: argument '--mode' cannot be used multiple times
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help     Show help information.
      #|  --mode <mode>  
      #|
    ),
  )
}

///|
test "append options collect values across repeated occurrences" {
  let cmd = @argparse.Command("demo", options=[
    OptionArg("arg", long="arg", action=Append),
  ])
  let parsed = cmd.parse(argv=["--arg", "x", "--arg", "y"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "arg": ["x", "y"], .. })
  assert_true(parsed.sources is { "arg": Argv, .. })
}

///|
test "option parsing stops at the next option token" {
  let cmd = @argparse.Command(
    "demo",
    flags=[FlagArg("verbose", long="verbose")],
    options=[OptionArg("arg", short='a', long="arg")],
  )

  let stopped = cmd.parse(argv=["--arg", "x", "--verbose"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(stopped.values is { "arg": ["x"], .. })
  assert_true(stopped.flags is { "verbose": true, .. })

  inspect(
    @test.expect_error(() => {
      cmd.parse(argv=["--arg=x", "y", "--verbose"], env=empty_env())
    }),
    content=(
      #|error: unexpected value 'y' found; no more were expected
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help       Show help information.
      #|  --verbose        
      #|  -a, --arg <arg>  
      #|
    ),
  )

  inspect(
    @test.expect_error(() => {
      cmd.parse(argv=["-ax", "y", "--verbose"], env=empty_env())
    }),
    content=(
      #|error: unexpected value 'y' found; no more were expected
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help       Show help information.
      #|  --verbose        
      #|  -a, --arg <arg>  
      #|
    ),
  )
}

///|
test "options always require a value" {
  let cmd = @argparse.Command(
    "demo",
    flags=[FlagArg("verbose", long="verbose")],
    options=[OptionArg("opt", long="opt")],
  )
  inspect(
    @test.expect_error(() => {
      cmd.parse(argv=["--opt", "--verbose"], env=empty_env())
    }),
    content=(
      #|error: a value is required for '--opt' but none was supplied
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help   Show help information.
      #|  --verbose    
      #|  --opt <opt>  
      #|
    ),
  )

  let zero_value_required = @argparse.Command("demo", options=[
    OptionArg("opt", long="opt", required=true),
  ]).parse(argv=["--opt", "x"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(zero_value_required.values is { "opt": ["x"], .. })
}

///|
test "default argv path is reachable" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionArg("rest", num_args=ValueRange(lower=0), allow_hyphen_values=true),
  ])
  let _ = cmd.parse(env=empty_env()) catch { _ => panic() }
}

///|
test "options require one value per occurrence" {
  let with_value = @argparse.Command("demo", options=[
    OptionArg("tag", long="tag"),
  ]).parse(argv=["--tag", "x"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(with_value.values is { "tag": ["x"], .. })

  inspect(
    @test.expect_error(() => {
      @argparse.Command("demo", options=[OptionArg("tag", long="tag")]).parse(
        argv=["--tag"],
        env=empty_env(),
      )
    }),
    content=(
      #|error: a value is required for '--tag' but none was supplied
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help   Show help information.
      #|  --tag <tag>  
      #|
    ),
  )
}

///|
test "short options require one value before next option token" {
  let cmd = @argparse.Command("demo", flags=[FlagArg("verbose", short='v')], options=[
    OptionArg("x", short='x'),
  ])
  let ok = cmd.parse(argv=["-x", "a", "-v"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(ok.values is { "x": ["a"], .. })
  assert_true(ok.flags is { "verbose": true, .. })

  inspect(
    @test.expect_error(() => cmd.parse(argv=["-x", "-v"], env=empty_env())),
    content=(
      #|error: a value is required for '-x' but none was supplied
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help     Show help information.
      #|  -v, --verbose  
      #|  -x, --x <x>    
      #|
    ),
  )
}

///|
test "single-value options avoid consuming additional option values" {
  let cmd = @argparse.Command(
    "demo",
    flags=[FlagArg("verbose", long="verbose")],
    options=[OptionArg("one", long="one")],
  )

  let parsed = cmd.parse(argv=["--one", "x", "--verbose"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "one": ["x"], .. })
  assert_true(parsed.flags is { "verbose": true, .. })
}

///|
test "missing option values are reported when next token is another option" {
  let cmd = @argparse.Command(
    "demo",
    flags=[FlagArg("verbose", long="verbose")],
    options=[OptionArg("arg", long="arg")],
  )

  let ok = cmd.parse(argv=["--arg", "x", "--verbose"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(ok.values is { "arg": ["x"], .. })
  assert_true(ok.flags is { "verbose": true, .. })

  inspect(
    @test.expect_error(() => {
      cmd.parse(argv=["--arg", "--verbose"], env=empty_env())
    }),
    content=(
      #|error: a value is required for '--arg' but none was supplied
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help   Show help information.
      #|  --verbose    
      #|  --arg <arg>  
      #|
    ),
  )
}

///|
test "short-only set options use short label in duplicate errors" {
  let cmd = @argparse.Command("demo", options=[OptionArg("mode", short='m')])
  inspect(
    @test.expect_error(() => {
      cmd.parse(argv=["-m", "a", "-m", "b"], env=empty_env())
    }),
    content=(
      #|error: argument '--mode' cannot be used multiple times
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help         Show help information.
      #|  -m, --mode <mode>  
      #|
    ),
  )
}

///|
test "setfalse flags apply false when present" {
  let cmd = @argparse.Command("demo", flags=[
    FlagArg("failfast", long="failfast", action=SetFalse),
  ])
  let parsed = cmd.parse(argv=["--failfast"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.flags is { "failfast": false, .. })
  assert_true(parsed.sources is { "failfast": Argv, .. })
}

///|
test "non-bmp short option token does not panic" {
  let cmd = @argparse.Command("demo", flags=[FlagArg("party", short='🎉')])
  let parsed = cmd.parse(argv=["-🎉"], env=empty_env()) catch { _ => panic() }
  assert_true(parsed.flags is { "party": true, .. })
}

///|
test "option env values remain string values instead of flags" {
  let cmd = @argparse.Command("demo", options=[
    OptionArg("mode", long="mode", env="MODE"),
  ])
  let parsed = cmd.parse(argv=[], env={ "MODE": "fast" }) catch { _ => panic() }
  assert_true(parsed.values is { "mode": ["fast"], .. })
  assert_true(parsed.flags.get("mode") is None)
  assert_true(parsed.sources is { "mode": Env, .. })
}

///|
test "duplicate short-only set option reports the short flag label" {
  let cmd = @argparse.Command("demo", options=[
    OptionArg("mode", short='m', long=""),
  ])
  inspect(
    @test.expect_error(() => {
      cmd.parse(argv=["-m", "a", "-m", "b"], env=empty_env())
    }),
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
}

///|
test "boolean env flags accept falsy values" {
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
  inspect(
    @test.expect_error(() => cmd.parse(argv=["--=value"], env=empty_env())),
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
}

///|
test "long empty string disables long alias" {
  let cmd = @argparse.Command(
    "demo",
    flags=[FlagArg("verbose", short='v', long="")],
    options=[OptionArg("count", short='c', long="")],
  )

  let matches = cmd.parse(argv=["-v", "-c", "3"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(matches.flags is { "verbose": true, .. })
  assert_true(matches.values is { "count": ["3"], .. })

  inspect(
    @test.expect_error(() => cmd.parse(argv=["--verbose"], env=empty_env())),
    content=(
      #|error: unexpected argument '--verbose' found
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help  Show help information.
      #|  -v          
      #|  -c <count>  
      #|
    ),
  )

  inspect(
    @test.expect_error(() => cmd.parse(argv=["--count", "3"], env=empty_env())),
    content=(
      #|error: unexpected argument '--count' found
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help  Show help information.
      #|  -v          
      #|  -c <count>  
      #|
    ),
  )
}

///|
test "long and short value parsing branches" {
  let cmd = @argparse.Command("demo", options=[
    OptionArg("count", short='c', long="count"),
  ])

  let long_inline = cmd.parse(argv=["--count=2"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(long_inline.values is { "count": ["2"], .. })

  let short_inline = cmd.parse(argv=["-c=3"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(short_inline.values is { "count": ["3"], .. })

  let short_attached = cmd.parse(argv=["-c4"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(short_attached.values is { "count": ["4"], .. })

  inspect(
    @test.expect_error(() => cmd.parse(argv=["--count"], env=empty_env())),
    content=(
      #|error: a value is required for '--count' but none was supplied
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help           Show help information.
      #|  -c, --count <count>  
      #|
    ),
  )

  inspect(
    @test.expect_error(() => cmd.parse(argv=["-c"], env=empty_env())),
    content=(
      #|error: a value is required for '-c' but none was supplied
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help           Show help information.
      #|  -c, --count <count>  
      #|
    ),
  )
}

///|
test "option values reject hyphen tokens unless allow_hyphen_values is enabled" {
  let strict = @argparse.Command("demo", options=[
    OptionArg("pattern", long="pattern"),
  ])
  inspect(
    @test.expect_error(() => {
      strict.parse(argv=["--pattern", "-file"], env=empty_env())
    }),
    content=(
      #|error: a value is required for '--pattern' but none was supplied
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help           Show help information.
      #|  --pattern <pattern>  
      #|
    ),
  )

  let permissive = @argparse.Command("demo", options=[
    OptionArg("pattern", long="pattern", allow_hyphen_values=true),
  ])
  let parsed = permissive.parse(argv=["--pattern", "-file"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "pattern": ["-file"], .. })
  assert_true(parsed.sources is { "pattern": Argv, .. })
}

///|
test "options with allow_hyphen_values accept option-like single values" {
  let cmd = @argparse.Command(
    "demo",
    flags=[
      FlagArg("verbose", long="verbose"),
      FlagArg("cache", long="cache", negatable=true),
      FlagArg("quiet", short='q'),
    ],
    options=[OptionArg("arg", long="arg", allow_hyphen_values=true)],
  )

  let known_long = cmd.parse(argv=["--arg", "--verbose"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(known_long.values is { "arg": ["--verbose"], .. })
  assert_true(known_long.flags is { "verbose"? : None, .. })

  let negated = cmd.parse(argv=["--arg", "--no-cache"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(negated.values is { "arg": ["--no-cache"], .. })
  assert_true(negated.flags is { "cache"? : None, .. })

  let unknown_long_value = cmd.parse(
    argv=["--arg", "--mystery"],
    env=empty_env(),
  ) catch {
    _ => panic()
  }
  assert_true(unknown_long_value.values is { "arg": ["--mystery"], .. })

  let known_short = cmd.parse(argv=["--arg", "-q"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(known_short.values is { "arg": ["-q"], .. })
  assert_true(known_short.flags is { "quiet"? : None, .. })

  let cmd_with_rest = @argparse.Command(
    "demo",
    options=[OptionArg("arg", long="arg", allow_hyphen_values=true)],
    positionals=[
      PositionArg(
        "rest",
        num_args=ValueRange(lower=0),
        allow_hyphen_values=true,
      ),
    ],
  )
  let sentinel_stop = cmd_with_rest.parse(
    argv=["--arg", "x", "--", "tail"],
    env=empty_env(),
  ) catch {
    _ => panic()
  }
  assert_true(sentinel_stop.values is { "arg": ["x"], "rest": ["tail"], .. })
}

///|
test "defaults and value range helpers through public API" {
  let defaults = @argparse.Command("demo", options=[
    OptionArg("mode", long="mode", action=Append, default_values=["a", "b"]),
    OptionArg("one", long="one", default_values=["x"]),
  ])
  let by_default = defaults.parse(argv=[], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(by_default.values is { "mode": ["a", "b"], "one": ["x"], .. })
  assert_true(by_default.sources is { "mode": Default, "one": Default, .. })

  let upper_only = @argparse.Command("demo", options=[
    OptionArg("tag", long="tag", action=Append),
  ])
  let upper_parsed = upper_only.parse(
    argv=["--tag", "a", "--tag", "b", "--tag", "c"],
    env=empty_env(),
  ) catch {
    _ => panic()
  }
  assert_true(upper_parsed.values is { "tag": ["a", "b", "c"], .. })

  let lower_only = @argparse.Command("demo", options=[
    OptionArg("tag", long="tag"),
  ])
  let lower_absent = lower_only.parse(argv=[], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(lower_absent.values is { "tag"? : None, .. })

  inspect(
    @test.expect_error(() => lower_only.parse(argv=["--tag"], env=empty_env())),
    content=(
      #|error: a value is required for '--tag' but none was supplied
      #|
      #|Usage: demo [options]
      #|
      #|Options:
      #|  -h, --help   Show help information.
      #|  --tag <tag>  
      #|
    ),
  )

  let single_range = @argparse.ValueRange::single()
  inspect(
    single_range,
    content=(
      #|{lower: 1, upper: Some(1)}
    ),
  )
}
