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
async test "starvation" {
  let log = []
  @async_io.with_task_group() <| group => {
    group.spawn_bg() <| () => {
      @async_io.sleep(50)
      log.push("sleep completed")
    }
    group.spawn_bg() <| () => {
      let start = @async_io.now()
      while @async_io.now() - start < 100 {
        @async_io.pause()
      }
      log.push("busy wait completed")
    }
  }
  json_inspect(log, content=["sleep completed", "busy wait completed"])
}
