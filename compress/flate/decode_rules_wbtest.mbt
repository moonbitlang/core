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
/// HLIT is validated immediately: a reserved value must not be hidden by a
/// missing HDIST field. The byte contains BFINAL=1, BTYPE=dynamic, HLIT=31 and
/// no further input.
test "reserved HLIT wins over a truncated HDIST" {
  let data : Bytes = [0xFD]
  let InflateError(kind, _) = @test.expect_error(() => inflate_all(data))
  @test.assert_eq(kind, Corrupt)
  let inflater = Inflater()
  let output = FixedArray::make(1, b'\x00')
  let InflateError(kind, _) = @test.expect_error(() => {
    inflater.step(data, output.mut_view())
  })
  @test.assert_eq(kind, Corrupt)
}
