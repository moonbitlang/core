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
test "bench parse inherited globals with an override" (it : @bench.T) {
  let command = @argparse.Command(
    "app",
    options=[
      OptionArg("format", long="format", global=true, default_values=["text"]),
      OptionArg("root", long="root", global=true, default_values=["."]),
    ],
    subcommands=[
      Command("run", options=[
        OptionArg("format", long="format", global=true, default_values=["json"]),
        OptionArg("limit", long="limit", global=true, default_values=["10"]),
      ]),
    ],
  )
  let argv : ReadOnlyArray[String] = [
    "run", "--format", "plain", "--root", "/tmp", "--limit", "20",
  ]
  let env : Map[String, String] = Map([])
  it.bench(fn() { it.keep(try! command.parse(argv~, env~)) })
}
