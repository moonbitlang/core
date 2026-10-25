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
#coverage.skip
#doc(hidden)
pub fn run_async_main(main : async () -> Unit) -> Unit {
  @event_loop.with_event_loop(() => main()) catch {
    @event_loop.KilledBySignal(signal) => terminate_process_by_signal(signal)
    err => {
      eprintln(err.to_string())
      exit(1)
    }
  }
}

///|
#unsafe_skip_stub_check
fn exit(code : Int32) = "moonbitlang/async" "runtime/exit"

///|
#unsafe_skip_stub_check
fn terminate_process_by_signal(signal : Int32) = "moonbitlang/async" "runtime/terminate_process_by_signal"
