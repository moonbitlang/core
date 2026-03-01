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
fn arg_min_max_for_validate(arg : Arg) -> (Int, Int?) raise ArgBuildError {
  if arg.info is Positional(num_args=Some(range), ..) {
    if range.lower < 0 {
      raise Unsupported("min values must be >= 0")
    }
    if range.upper is Some(max_value) {
      if max_value < 0 {
        raise Unsupported("max values must be >= 0")
      }
      if max_value < range.lower {
        raise Unsupported("max values must be >= min values")
      }
      if range.lower == 0 && max_value == 0 {
        raise Unsupported("empty value range (0..0) is unsupported")
      }
    }
    (range.lower, range.upper)
  } else {
    (0, None)
  }
}

///|
fn arg_min_max(arg : Arg) -> (Int, Int?) {
  match arg.info {
    Positional(num_args=Some(range), ..) => (range.lower, range.upper)
    _ => (0, None)
  }
}
