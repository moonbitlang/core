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
let test_interface_index : @async.Lazy[UInt32] = Lazy(() => {
  let prog = @test_util.build_test_program("find_ipv6_test_interface")
  let result = @process.run(prog, [], stdout=@process.read_from_process())
  let index = @string.parse_uint(result.stdout_text().trim())
  guard index > 0 else {
    raise Failure("cannot find suitable network interface for testing")
  }
  index
})

///|
let test_interface : @async.Lazy[String] = Lazy(() => {
  @socket.if_indextoname(
    test_interface_index.wait(),
    context="fetch name of test network interface",
  ) catch {
    err => abort(err.to_string())
  }
})
