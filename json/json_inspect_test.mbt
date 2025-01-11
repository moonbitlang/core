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

test {
  @json.inspect!(1, content=1)
}

test {
  @json.inspect!({ "x": 1 }, content={ "x": 1 })
}

///|
struct P {
  x : Int
  y : Int
  color : Color
} derive(ToJson)

///|
enum Color {
  Red
  Green
  Blue
} derive(ToJson)

///|
struct Line {
  p1 : P
  p2 : P
  color : Color
} derive(ToJson)

test "json inspect" {
  let p1 = { x: 0, y: 0, color: Color::Red }
  let p2 = { x: 1, y: 2, color: Color::Green }
  @json.inspect!(p1, content={ "x": 0, "y": 0, "color": { "$tag": "Red" } })
  let line = { p1, p2, color: Color::Blue }
  @json.inspect!(line, content={
    "p1": { "x": 0, "y": 0, "color": { "$tag": "Red" } },
    "p2": { "x": 1, "y": 2, "color": { "$tag": "Green" } },
    "color": { "$tag": "Blue" },
  })
}
