// Copyright 2024 International Digital Economy Academy
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

test "Double::to_uint" {
  inspect!(0.0.to_uint(), content="0")
  inspect!(1.0.to_uint(), content="1")
  inspect!(1.5.to_uint(), content="1")
  inspect!(1.9.to_uint(), content="1")
  inspect!(2.0.to_uint(), content="2")
  inspect!(2.5.to_uint(), content="2")
  inspect!(2.9.to_uint(), content="2")
  inspect!((-1.0).to_uint(), content="0")
  inspect!((-1.5).to_uint(), content="0")
  inspect!((-1.9).to_uint(), content="0")
  inspect!((-2.0).to_uint(), content="0")
  inspect!((-2.5).to_uint(), content="0")
  inspect!((-2.9).to_uint(), content="0")
  inspect!((0.0 / 0.0).to_uint(), content="0")
  inspect!((1.0 / 0.0).to_uint(), content="4294967295")
  inspect!((-1.0 / 0.0).to_uint(), content="0")
  inspect!(4294967295.0.to_uint(), content="4294967295")
  inspect!((-4294967296.0).to_uint(), content="0")
  inspect!(4294967296.0.to_uint(), content="4294967295")
}
