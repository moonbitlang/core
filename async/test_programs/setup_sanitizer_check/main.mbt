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
#cfg(platform="windows")
let sanitizer_flags = "/Z7 /fsanitize=address"

///|
#cfg(not(platform="windows"))
let sanitizer_flags = "-fsanitize=address -g -fno-omit-frame-pointer"

///|
let link_config : String =
  $|  link: {
  $|    "native": {
  $|      "cc-flags": "\{sanitizer_flags}",
  $|      "stub-cc-flags": "\{sanitizer_flags}",
  $|    },
  $|  },

///|
async fn main {
  fn exclude(path : String) {
    match path {
      "./target" | "./_build" | "./examples/target" | "./examples/_build" =>
        true
      "./test_programs/dump_env" =>
        // This program may be run in an (almost) empty environment,
        // ASAN will not work with some linking related variables missing
        true
      _ => false
    }
  }

  @fs.walk(".", exclude~) <| ((path, files) => {
    for file in files {
      guard file is "moon.pkg" else {  }
      let full_path = "\{path}/\{file}"
      let content = @fs.read_text(full_path).split("\n")
      let transformed = StringBuilder()
      let mut found = false
      for line in content {
        transformed <+ "\{line}\n"
        if !found && line is "options(" {
          found = true
          transformed <+ "\{link_config}\n"
        }
      }
      if !found {
        transformed <+ "\noptions(\n\{link_config}\n)"
      }
      @fs.write_text(full_path, transformed.to_string())
    }
  })
}
