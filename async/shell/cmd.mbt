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
/// Where a child process's standard input comes from.
///
/// `Text` is encoded as UTF-8. `Binary` is written verbatim, which is what a
/// child expecting a compressed or otherwise non-textual stream needs.
/// `FromFile` is the structured form of a shell's `< path`; the file must
/// already exist. `Inherit` hands the child the parent's own standard input,
/// which is what an interactive command needs; without it, standard input is
/// closed.
pub(all) enum Stdin {
  Text(String)
  Binary(Bytes)
  FromFile(String)
  Inherit
} derive(@debug.Debug)

///|
/// Where a child process's standard output or standard error goes.
///
/// `Capture` returns the stream to the caller: `output` collects it into
/// `Output`, `each_line` delivers stdout line by line, and `status` has no
/// return channel so it inherits instead. `Inherit` hands the stream to the
/// parent's own descriptor.
///
/// `ToFile` and `AppendToFile` are the structured forms of a shell's `> path`
/// and `>> path`. Both create the file if it is missing; `ToFile` truncates an
/// existing one. `Discard` is the structured `> /dev/null`: the stream goes to
/// the platform's null device. A redirected stream is absent from `Output`,
/// where it appears as an empty string.
pub(all) enum Redirect {
  Capture
  Inherit
  ToFile(String)
  AppendToFile(String)
  Discard
} derive(@debug.Debug)

///|
/// A shell-free process description.
///
/// `program` is an executable name or path. Every element of `arguments` is
/// passed as one literal argument. Shell operators such as `|`, `>`, `&&`,
/// `$()`, and `*` have no special meaning.
///
/// The representation is abstract and a `Cmd` is immutable once built. Its
/// derived `Debug` representation can be logged or snapshot-tested before it
/// runs.
struct Cmd {
  program : String
  arguments : Array[String]
  cwd : String?
  env : Map[String, String]
  inherit_env : Bool
  stdin : Stdin?
  stdout : Redirect
  stderr : Redirect
} derive(@debug.Debug)

///|
/// Describe one process.
///
/// Standard input is closed unless `stdin` is given, so a non-interactive run
/// cannot accidentally wait on ambient input. `env` adds to the inherited
/// environment; pass `inherit_env=false` to start from an empty one.
///
/// `stdout` and `stderr` default to `Capture`, so `output` collects them.
///
/// `arguments` and `env` are copied, so later changes to the caller's
/// collections do not reach the command.
///
/// # Example
/// ```mbt check
/// test {
///   let cmd = @shell.Cmd("git", ["status", "--short"], cwd="workspace")
///   debug_inspect(
///     cmd,
///     content=(
///       #|{
///       #|  program: "git",
///       #|  arguments: ["status", "--short"],
///       #|  cwd: Some("workspace"),
///       #|  env: {},
///       #|  inherit_env: true,
///       #|  stdin: None,
///       #|  stdout: Capture,
///       #|  stderr: Capture,
///       #|}
///     ),
///   )
/// }
/// ```
pub fn Cmd::Cmd(
  program : String,
  arguments : ArrayView[String],
  cwd? : String,
  env~ : Map[String, String] = {},
  inherit_env~ : Bool = true,
  stdin? : Stdin,
  stdout~ : Redirect = Capture,
  stderr~ : Redirect = Capture,
) -> Cmd {
  {
    program,
    arguments: arguments.to_owned(),
    cwd,
    env: env.copy(),
    inherit_env,
    stdin,
    stdout,
    stderr,
  }
}
