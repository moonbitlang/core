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
test "join consumes the iterator once" {
  let calls = [0]
  let values : FixedArray[String] = ["a", "", "😀"]
  let source = Iter::new(() => {
    let index = calls[0]
    calls[0] += 1
    if index < values.length() {
      Some(values[index])
    } else {
      None
    }
  })
  inspect(source.join("|"), content="a||😀")
  inspect(calls[0], content="4")
}

///|
test "join preserves offset views and empty elements" {
  let left = "!a😀!"[1:4]
  let right = "!漢!"[1:2]
  let separator = "!🧵!"[1:3]
  let parts : FixedArray[StringView] = ["unused", left, "", right, "unused"]
  inspect(parts[1:4].join(separator), content="a😀🧵🧵漢")
  inspect(parts[1:4].iter().join(separator), content="a😀🧵🧵漢")
  inspect(parts[1:2].join(separator), content="a😀")
  inspect(parts[1:4].join(""), content="a😀漢")
  inspect(([] : FixedArray[String]).join(separator), content="")
  inspect((["", "", ""] : FixedArray[String]).join(""), content="")
}
