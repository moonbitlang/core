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

test "overflow" {
  inspect(0x8000000000000000L, content="-9223372036854775808")?
  inspect(-0x8000000000000000L, content="-9223372036854775808")?
  inspect(0x7fffffffffffffffL, content="9223372036854775807")?
  inspect(-0x7fffffffffffffffL, content="-9223372036854775807")?
}