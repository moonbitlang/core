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
async test "resolve localhost preference" {
  inspect(
    @socket.Addr::resolve("localhost", port=80, protocol=FavorV4),
    content="127.0.0.1:80",
  )
  inspect(
    @socket.Addr::resolve("localhost", port=80, protocol=OnlyV4),
    content="127.0.0.1:80",
  )
  inspect(
    @socket.Addr::resolve("localhost", port=80, protocol=FavorV6),
    content="[::1]:80",
  )
  inspect(
    @socket.Addr::resolve("localhost", port=80, protocol=OnlyV6),
    content="[::1]:80",
  )
}
