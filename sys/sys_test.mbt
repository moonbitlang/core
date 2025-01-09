// Copyright 2025 International Digital Economy Academy
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

test "get_env_vars" {
  let (k, v) = ("THIS_IS_A_TEST_FOR_ENV_VAR", "IT_WORKS")
  let old_env = @sys.get_env_vars()[k]
  inspect!(
    old_env,
    content=
      #|None
    ,
  )
  @sys.set_env_var(k, v)
  let res = @sys.get_env_vars()[k]
  inspect!(
    res,
    content=
      #|Some("IT_WORKS")
    ,
  )
}
