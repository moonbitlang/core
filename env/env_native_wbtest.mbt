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
test "current_dir has no trailing NUL characters" {
  let dir = current_dir()
  guard dir is Some(path) else { fail("can't get current_dir") }
  assert_eq(path.find("\u0000"), None)
}

///|
test "env roundtrip with unique key on native" {
  let key = "MOONBIT_ENV_NATIVE_TEST_" + now().to_string()
  let value = "v_" + now().to_string()
  set_env_var(key, value)
  assert_eq(get_env_var(key), Some(value))
  unset_env_var(key)
  assert_eq(get_env_var(key), None)
}
