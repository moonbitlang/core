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
/// Captured output and exit status from a command or pipeline.
///
/// The representation is abstract; readers use the accessor methods. Text is
/// decoded as lossy UTF-8 so arbitrary process output cannot cancel a run;
/// `stdout_bytes` keeps standard output byte for byte.
struct Output {
  exit_code : Int32
  stdout : String
  stdout_bytes : Bytes
  stderr : String
} derive(@debug.Debug)

///|
/// The exit status: for a pipeline, the rightmost non-zero stage status, or
/// zero when every stage succeeded (pipefail).
pub fn Output::exit_code(self : Output) -> Int32 {
  self.exit_code
}

///|
/// Captured standard output of the final stage, decoded as lossy UTF-8.
pub fn Output::stdout(self : Output) -> String {
  self.stdout
}

///|
/// Captured standard output of the final stage, byte for byte.
pub fn Output::stdout_bytes(self : Output) -> Bytes {
  self.stdout_bytes
}

///|
/// Every stage's captured standard error, concatenated in stage order and
/// decoded as lossy UTF-8.
pub fn Output::stderr(self : Output) -> String {
  self.stderr
}

///|
/// Raise when the command or pipeline did not succeed.
///
/// This does not execute anything: `output` has already waited for every
/// process. It only checks `exit_code`.
///
/// # Example
/// ```mbt check
/// async test {
///   let output = @shell.Cmd("moonx", ["bobzhang/false@0.1.0"]).output()
///   inspect(output.exit_code(), content="1")
///   try output.check() catch {
///     _ => ()
///   } noraise {
///     _ => fail("expected a non-zero exit to raise")
///   }
/// }
/// ```
pub fn Output::check(self : Output) -> Unit raise {
  if self.exit_code != 0 {
    raise CommandFailed(self)
  }
}

///|
/// Errors reported internally by the process EDSL.
///
/// Callers choose between checked operations (`run` and `check`) and explicit
/// status inspection (`status` and `exit_code`) rather than depending on these
/// implementation-level categories.
priv suberror ShellError {
  EmptyProgram
  EmptyPipeline
  InvalidEnvironmentName(String)
  InvalidOutputLimit(Int32)
  OutputLimitExceeded(stream~ : String, limit~ : Int32)
  NulByte(String)
  StdinOnNonFirstStage(Int32)
  RedirectOnNonFinalStage(Int32)
  StdoutNotCaptured
  CommandFailed(Output)
} derive(@debug.Debug)
