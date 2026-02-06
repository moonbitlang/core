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
test "command builder does not mutate prior values" {
  let base = @arg_parser.Command::new("demo")
  let with_arg = base.arg(@arg_parser.Arg::new("count").long("count").option())
  inspect(base.render_help().contains("--count"), content="false")
  inspect(with_arg.render_help().contains("--count"), content="true")
  let sub = @arg_parser.Command::new("sub").about("sub")
  let with_sub = base.subcommand(sub)
  inspect(base.render_help().contains("Commands:"), content="false")
  inspect(with_sub.render_help().contains("Commands:"), content="true")
}

///|
test "validated getters" {
  let cmd = @arg_parser.Command::new("demo")
    .arg(@arg_parser.Arg::new("count").long("count").option())
    .arg(@arg_parser.Arg::new("name").index(0))
  let matches = cmd.parse(argv=["--count", "3", "alice"]) catch { _ => panic() }
  let count_str = matches.get_one("count").unwrap_or("")
  let count : Int = @strconv.parse_int(count_str) catch { _ => -1 }
  assert_eq(count, 3)
  let name : String = matches.get_one("name").unwrap_or("")
  assert_eq(name, "alice")
}

///|
test "parse invalid int" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("count").long("count").option(),
  )
  let matches = cmd.parse(argv=["--count", "oops"]) catch { _ => panic() }
  let count_str = matches.get_one("count").unwrap_or("")
  try @strconv.parse_int(count_str) catch {
    @strconv.StrConvError(err) => inspect(err, content="invalid syntax")
  } noraise {
    _ => panic()
  }
}

///|
struct Config {
  count : Int
  name : String
}

///|
impl FromMatches for Config with from_matches(m : @arg_parser.Matches) -> Config raise @arg_parser.ArgumentError {
  let count_str = match m.get_one("count") {
    Some(value) => value
    None =>
      raise @arg_parser.ArgumentError::InvalidValue("value not found: count")
  }
  let count = @strconv.parse_int(count_str) catch {
    _ =>
      raise @arg_parser.ArgumentError::InvalidValue("invalid int: " + count_str)
  }
  let name = match m.get_one("name") {
    Some(value) => value
    None =>
      raise @arg_parser.ArgumentError::InvalidValue("value not found: name")
  }
  Config::{ count, name }
}

///|
test "from_matches helper" {
  let cmd = @arg_parser.Command::new("demo")
    .arg(@arg_parser.Arg::new("count").long("count").option())
    .arg(@arg_parser.Arg::new("name").index(0))
  let matches = cmd.parse(argv=["--count", "2", "alice"]) catch { _ => panic() }
  let cfg : Config = @arg_parser.from_matches(matches) catch {
    _ => Config::{ count: 0, name: "" }
  }
  assert_eq(cfg.count, 2)
  assert_eq(cfg.name, "alice")
}
