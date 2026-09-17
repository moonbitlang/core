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
/// `print` is a deprecated alias of `println`, re-exported here so that an
/// unqualified `print(x)` resolves to a warning naming `println` instead of an
/// unbound-identifier error.
///
/// This is a compile-time guard: what `println` writes goes to stdout through
/// an intrinsic and cannot be captured in-process, so the test pins that the
/// unqualified name still resolves at the expected type. It is needed because
/// `#doc(hidden)` keeps `print` out of `pkg.generated.mbti`, so the generated
/// interface cannot serve as the guard.
#warnings("-deprecated")
test "print resolves as a deprecated alias of println" {
  let via_alias : (String) -> Unit = print
  let via_name : (String) -> Unit = println
  if false {
    via_alias("")
    via_name("")
  }
}
