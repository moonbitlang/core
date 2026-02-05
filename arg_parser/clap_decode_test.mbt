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
  let count_str = matches.get_one("count") catch { _ => "" }
  let count : Int = @strconv.parse_int(count_str) catch { _ => -1 }
  assert_eq(count, 3)
  let name : String = matches.get_one("name") catch { _ => "" }
  assert_eq(name, "alice")
}

///|
test "parse invalid int" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("count").long("count").option(),
  )
  let matches = cmd.parse(argv=["--count", "oops"]) catch { _ => panic() }
  let mut saw_invalid = false
  let _count : Int = @strconv.parse_int(
    matches.get_one("count") catch {
      _ => ""
    },
  ) catch {
    _ => {
      saw_invalid = true
      0
    }
  }
  assert_true(saw_invalid)
}

///|
struct Config {
  count : Int
  name : String
}

///|
impl FromMatches for Config with from_matches(m : @arg_parser.Matches) -> Config raise @arg_parser.ArgumentError {
  let count_str = m.get_one("count")
  let count = @strconv.parse_int(count_str) catch {
    _ =>
      raise @arg_parser.ArgumentError::InvalidValue("invalid int: " + count_str)
  }
  let name = m.get_one("name")
  Config::{ count, name }
}

///|
test "decode from matches" {
  let cmd = @arg_parser.Command::new("demo")
    .arg(@arg_parser.Arg::new("count").long("count").option())
    .arg(@arg_parser.Arg::new("name").index(0))
  let matches = cmd.parse(argv=["--count", "2", "alice"]) catch { _ => panic() }
  let cfg : Config = matches.decode() catch {
    _ => Config::{ count: 0, name: "" }
  }
  assert_eq(cfg.count, 2)
  assert_eq(cfg.name, "alice")
}
