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
test "declaration order controls positional parsing" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionArg("first"),
    PositionArg("second"),
  ])

  let parsed = cmd.parse(argv=["a", "b"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "first": ["a"], "second": ["b"], .. })
}

///|
test "bounded non-last positional remains supported" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionArg("first", num_args=ValueRange(lower=1, upper=2)),
    PositionArg("second", num_args=@argparse.ValueRange::single()),
  ])

  let two = cmd.parse(argv=["a", "b"], env=empty_env()) catch { _ => panic() }
  assert_true(two.values is { "first": ["a"], "second": ["b"], .. })

  let three = cmd.parse(argv=["a", "b", "c"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(three.values is { "first": ["a", "b"], "second": ["c"], .. })
}

///|
test "positionals dash handling and separator" {
  let force_cmd = @argparse.Command("demo", positionals=[
    PositionArg("tail", num_args=ValueRange(lower=0), allow_hyphen_values=true),
  ])
  let forced = force_cmd.parse(argv=["a", "--x", "-y"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(forced.values is { "tail": ["a", "--x", "-y"], .. })

  let dashed = force_cmd.parse(argv=["--", "p", "q"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(dashed.values is { "tail": ["p", "q"], .. })

  let negative_cmd = @argparse.Command("demo", positionals=[PositionArg("n")])
  let negative = negative_cmd.parse(argv=["-9"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(negative.values is { "n": ["-9"], .. })

  inspect(
    @test.expect_error(() => {
      negative_cmd.parse(argv=["x", "y"], env=empty_env())
    }),
    content=(
      #|error: unexpected value 'y' for '<n>' found; no more were expected
      #|
      #|Usage: demo [n]
      #|
      #|Arguments:
      #|  n  
      #|
      #|Options:
      #|  -h, --help  Show help information.
      #|
    ),
  )
}

///|
test "variadic positional keeps accepting hyphen values after first token" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionArg("tail", num_args=ValueRange(lower=0), allow_hyphen_values=true),
  ])
  let parsed = cmd.parse(argv=["a", "-b", "--mystery"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "tail": ["a", "-b", "--mystery"], .. })
}

///|
test "allow_hyphen positional yields to a known short flag" {
  let cmd = @argparse.Command("demo", flags=[FlagArg("quiet", short='q')], positionals=[
    PositionArg("input", allow_hyphen_values=true),
  ])
  let flagged = cmd.parse(argv=["-q"], env=empty_env()) catch { _ => panic() }
  assert_true(flagged.flags is { "quiet": true, .. })
  assert_true(flagged.values is { "input"? : None, .. })

  let unknown = cmd.parse(argv=["-z"], env=empty_env()) catch { _ => panic() }
  assert_true(unknown.values is { "input": ["-z"], .. })
  assert_true(unknown.flags is { "quiet"? : None, .. })
}

///|
test "bounded positional does not greedily consume later required values" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionArg("first", num_args=ValueRange(lower=1, upper=2)),
    PositionArg("second", num_args=@argparse.ValueRange::single()),
  ])

  let two = cmd.parse(argv=["a", "b"], env=empty_env()) catch { _ => panic() }
  assert_true(two.values is { "first": ["a"], "second": ["b"], .. })

  let three = cmd.parse(argv=["a", "b", "c"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(three.values is { "first": ["a", "b"], "second": ["c"], .. })
}

///|
test "indexed non-last positional allows explicit single num_args" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionArg("first", num_args=@argparse.ValueRange::single()),
    PositionArg("second", num_args=@argparse.ValueRange::single()),
  ])

  let parsed = cmd.parse(argv=["a", "b"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "first": ["a"], "second": ["b"], .. })
}

///|
test "bounded positional can leave later optional positional empty" {
  let parsed = @argparse.Command("demo", positionals=[
    PositionArg("x", num_args=ValueRange(lower=0, upper=2)),
    PositionArg("y"),
  ]).parse(argv=["a"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "x": ["a"], "y"? : None, .. })
}

///|
test "positionals keep declaration order with ranged positional" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionArg("late", num_args=ValueRange(lower=2, upper=2)),
    PositionArg("first"),
    PositionArg("mid"),
  ])

  let parsed = cmd.parse(argv=["a", "b", "c", "d"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(
    parsed.values is { "late": ["a", "b"], "first": ["c"], "mid": ["d"], .. },
  )
}

///|
test "mixed indexed and unindexed positionals keep inferred order" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionArg("first"),
    PositionArg("second"),
  ])

  let parsed = cmd.parse(argv=["a", "b"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "first": ["a"], "second": ["b"], .. })
}

///|
test "single positional parses without explicit index metadata" {
  let parsed = @argparse.Command("demo", positionals=[PositionArg("late")]).parse(
    argv=["x"],
    env=empty_env(),
  ) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "late": ["x"], .. })
}

///|
test "positional num_args lower bound rejects missing argv values" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionArg("first", num_args=ValueRange(lower=2, upper=3)),
  ])

  inspect(
    @test.expect_error(() => cmd.parse(argv=[], env=empty_env())),
    content=(
      #|error: 'first' requires at least 2 values but only 0 were provided
      #|
      #|Usage: demo <first...>
      #|
      #|Arguments:
      #|  first...  
      #|
      #|Options:
      #|  -h, --help  Show help information.
      #|
    ),
  )
}

///|
test "positional max clamp leaves trailing value for next positional" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionArg("items", num_args=ValueRange(lower=0, upper=2)),
    PositionArg("tail"),
  ])

  let parsed = cmd.parse(argv=["a", "b", "c"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "items": ["a", "b"], "tail": ["c"], .. })
}

///|
test "allow_hyphen positional treats unknown long token as value" {
  let cmd = @argparse.Command("demo", flags=[FlagArg("known", long="known")], positionals=[
    PositionArg("input", allow_hyphen_values=true),
  ])
  let parsed = cmd.parse(argv=["--mystery"], env=empty_env()) catch {
    _ => panic()
  }
  assert_true(parsed.values is { "input": ["--mystery"], .. })
}

///|
test "non-bmp hyphen token reports unknown argument without panic" {
  let cmd = @argparse.Command("demo", positionals=[PositionArg("value")])
  inspect(
    @test.expect_error(() => cmd.parse(argv=["-🎉"], env=empty_env())),
    content=(
      #|error: unexpected argument '-🎉' found
      #|
      #|Usage: demo [value]
      #|
      #|Arguments:
      #|  value  
      #|
      #|Options:
      #|  -h, --help  Show help information.
      #|
    ),
  )
}

///|
test "positional default values exceeding num_args upper bound are rejected" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionArg("tags", num_args=ValueRange(lower=0, upper=2), default_values=[
      "a", "b", "c",
    ]),
  ])
  inspect(
    @test.expect_error(() => cmd.parse(argv=[], env=empty_env())),
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
}

///|
test "earlier variadic positional reserves values for a later required one" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionArg("head", num_args=ValueRange(lower=0)),
    PositionArg("tail", num_args=ValueRange(lower=2)),
  ])
  inspect(
    @test.expect_error(() => cmd.parse(argv=["only"], env=empty_env())),
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
}

///|
test "extra values past a bounded variadic positional report the variadic label" {
  let cmd = @argparse.Command("demo", positionals=[
    PositionArg("items", num_args=ValueRange(lower=0, upper=2)),
  ])
  let ok = cmd.parse(argv=["a", "b"], env=empty_env()) catch { _ => panic() }
  assert_true(ok.values is { "items": ["a", "b"], .. })
  inspect(
    @test.expect_error(() => cmd.parse(argv=["a", "b", "c"], env=empty_env())),
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
  inspect(
    @test.expect_error(() => cmd.parse(argv=["a", "b", "-c"], env=empty_env())),
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
  inspect(
    @test.expect_error(() => cmd.parse(argv=["-x"], env=empty_env())),
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
}
