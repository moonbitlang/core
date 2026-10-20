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
/// A sequence of commands connected by operating-system pipes.
///
/// Every stage is separately visible to the process host, and an empty
/// pipeline is rejected when execution is requested.
struct Pipeline {
  commands : Array[Cmd]
} derive(@debug.Debug)

///|
/// Describe a pipeline whose stages are connected by real pipes.
///
/// Only the first stage may carry `stdin`; the rest read from the previous
/// stage. `commands` is copied, so later changes to the caller's array do not
/// reach the pipeline.
///
/// # Example
/// ```mbt check
/// test {
///   let plan = @shell.Pipeline([
///     Cmd("printf", ["alpha\nbeta\n"]),
///     Cmd("grep", ["beta"]),
///   ])
///   debug_inspect(
///     plan,
///     content=(
///       #|{
///       #|  commands: [
///       #|    {
///       #|      program: "printf",
///       #|      arguments: ["alpha\nbeta\n"],
///       #|      cwd: None,
///       #|      env: {},
///       #|      inherit_env: true,
///       #|      stdin: None,
///       #|      stdout: Capture,
///       #|      stderr: Capture,
///       #|    },
///       #|    {
///       #|      program: "grep",
///       #|      arguments: ["beta"],
///       #|      cwd: None,
///       #|      env: {},
///       #|      inherit_env: true,
///       #|      stdin: None,
///       #|      stdout: Capture,
///       #|      stderr: Capture,
///       #|    },
///       #|  ],
///       #|}
///     ),
///   )
/// }
/// ```
pub fn Pipeline::Pipeline(commands : Array[Cmd]) -> Pipeline {
  { commands: commands.copy(), }
}
