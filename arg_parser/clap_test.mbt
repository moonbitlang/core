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
test "clap builder parsing" {
  let cmd = @arg_parser.Command::new("demo")
    .about("demo")
    .arg(
      @arg_parser.Arg::new("verbose")
      .short('v')
      .long("verbose")
      .action(@arg_parser.ArgAction::SetTrue),
    )
    .arg(@arg_parser.Arg::new("count").long("count").option())
    .arg(@arg_parser.Arg::new("name").index(0))
  let matches = cmd.parse(argv=["-v", "--count", "3", "alice"]) catch {
    _ => panic()
  }
  assert_true(matches.get_flag("verbose"))
  assert_eq(matches.get_one("count").unwrap_or(""), "3")
  assert_eq(matches.get_one("name").unwrap_or(""), "alice")
}

///|
test "clap subcommand" {
  let sub = @arg_parser.Command::new("echo").arg(
    @arg_parser.Arg::new("msg").index(0),
  )
  let cmd = @arg_parser.Command::new("root").subcommand(sub)
  let matches = cmd.parse(argv=["echo", "hi"]) catch { _ => panic() }
  assert_eq(matches.subcommand_name().unwrap(), "echo")
  let subm = matches.subcommand_matches("echo").unwrap()
  assert_eq(subm.get_one("msg").unwrap_or(""), "hi")
}
