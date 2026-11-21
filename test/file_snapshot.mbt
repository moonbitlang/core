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
#derive(@debug.Debug)
priv enum SnapshotState {
  Fresh
  Comparing
  Submitted
}

///|
#derive(@debug.Debug)
priv struct Submission {
  mut state : SnapshotState
  mut baseline : String
  mut location : String
}

///|
/// A temporary output file managed by one test execution, not an open I/O handle.
/// Close all writers before submitting a snapshot and leave it unchanged afterwards.
struct File {
  path : String
  context : SnapshotContext
  submission : Submission
}

///|
#derive(@debug.Debug)
priv struct SnapshotContext {
  root : String
  baselines : String
  prefix : String
  mut closed : Bool
  // Track submission state rather than File objects: File owns this context,
  // so storing File here would introduce a reference cycle.
  files : Array[Submission]
  names : Map[String, Unit]
  results : Array[@json.Json]
}

///|
/// Return the stable path for ordinary file I/O. Reading this path never raises;
/// it does not extend the file's lifetime or permit changes after submission.
pub fn File::path(self : File) -> String {
  self.path
}

///|
/// Driver entry point. No file is opened until a candidate is requested.
#doc(hidden)
pub fn Test::start(name : String, file : String, index : Int32) -> Test {
  let snapshots = match
    (
      @env.get_env_var("MOON_TEST_ARTIFACT_DIR"),
      @env.get_env_var("MOON_TEST_SNAPSHOT_DIR"),
    ) {
    (Some(root), Some(baselines)) =>
      Some({
        root,
        baselines,
        prefix: @hex.encode(@utf8.encode(file)) + "-" + index.to_string(),
        closed: false,
        files: [],
        names: {},
        results: [],
      })
    _ => None
  }
  { name, buffer: StringBuilder(), snapshots, }
}

///|
/// Create an empty temporary file owned by this test. An unused file requires no
/// explicit disposal. Moon cleans it up with the execution's other artifacts.
/// Currently supports Wasm; other backends report an unsupported-I/O error.
pub fn Test::create_file(self : Test) -> File raise {
  guard self.snapshots is Some(context) else {
    fail(
      "file snapshots require a Moon test driver with candidate-file support",
    )
  }
  guard !context.closed else { fail("test context is closed") }
  let path = context.root +
    "/" +
    context.prefix +
    "-" +
    context.files.length().to_string() +
    ".actual"
  @snapshot_io.create(path)
  let submission = { state: Fresh, baseline: "", location: "", }
  context.files.push(submission)
  { path, context, submission, }
}

///|
/// Start a comparison. An interrupted comparison remains an error even
/// if its I/O exception is caught by the test body.
fn File::begin_snapshot(
  self : File,
  filename : String,
  loc : SourceLoc,
) -> String raise {
  let context = self.context
  guard !context.closed else { fail("test context is closed", loc~) }
  guard self.submission.state is Fresh else {
    fail("file snapshot already started", loc~)
  }
  guard !filename.contains("\\") &&
    !filename.contains(":") &&
    !filename.contains("\u0000") &&
    !filename.split("/").any(p => p.is_empty() || p == "." || p == "..") else {
    fail(
      "snapshot filename must be a relative path without empty, dot, or parent components",
      loc~,
    )
  }
  guard !context.names.contains(filename) else {
    fail("duplicate snapshot baseline: \{filename}", loc~)
  }
  context.names[filename] = ()
  self.submission.state = Comparing
  self.submission.baseline = filename
  self.submission.location = loc.to_string()
  context.baselines + "/" + filename
}

///|
/// Complete a comparison: -1 = equal, -2 = absent baseline, >=0 = first difference.
fn File::record_snapshot(self : File, offset : Int64) -> Unit raise {
  let context = self.context
  guard !context.closed else { fail("test context is closed") }
  guard self.submission.state is Comparing && offset >= -2 else {
    fail("invalid snapshot comparison completion")
  }
  self.submission.state = Submitted
  context.results.push({
    "expected": self.submission.baseline,
    "actual": self.path,
    "location": self.submission.location,
    "offset": offset.to_string(),
  })
}

///|
/// Compare the completed output to a baseline in bounded memory and register the
/// result with its test. Differences do not raise; I/O and lifecycle errors do.
/// Close writers before calling and never modify the submitted output afterwards.
#callsite(autofill(loc))
pub fn File::snapshot(
  self : File,
  filename~ : String,
  loc~ : SourceLoc,
) -> Unit raise {
  let baseline = self.begin_snapshot(filename, loc)
  self.record_snapshot(@snapshot_io.compare(self.path, baseline))
}

///|
/// Driver exit point. Unused files are harmless; started but unfinished
/// comparisons fail the test. The payload contains metadata, never file contents.
#doc(hidden)
pub fn Test::finish(self : Test, body_error : String) -> String {
  guard self.snapshots is Some(context) else { return body_error }
  context.closed = true
  let incomplete = context.files.count_if(f => f.state is Comparing)
  if context.results.is_empty() && incomplete == 0 {
    return body_error
  }
  let error = if body_error.is_empty() && incomplete > 0 {
    "\{incomplete} file snapshot comparison(s) did not complete"
  } else {
    body_error
  }
  let payload : @json.Json = {
    "body_error": error,
    "snapshots": @json.Json::array(context.results),
  }
  "@FILE_SNAPSHOTS " + payload.stringify()
}
