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

pub struct AllThree {
  ints : Array[Int]
  floats : Array[Double]
  strings : Array[String]
} derive(Eq, Show)

fn array_to_json[T](
  arr : Array[T],
  ~f : (T) -> @json.T
) -> @json.T {
  Array(arr.map(f))
}

fn to_json(self : AllThree) -> @json.T {
  let { ints, floats, strings } = self
  {
    "ints": ints |> array_to_json(f=fn { x => Number(x.to_double()) }),
    "floats": floats |> array_to_json(f=fn { x => Number(x) }),
    "strings": strings |> array_to_json(f=fn { x => String(x) }),
  }
}

struct DecodeError {
  message : String
} derive(Eq, Show)

fn of_json(jv : @json.T) -> AllThree!DecodeError {
  match jv {
    { "ints": Array(ints), "floats": Array(floats), "strings": Array(strings) } => {
      let ints_result = []
      let floats_result = []
      let strings_result = []
      ints.each(
        fn {
          Number(n) => ints_result.push(n.to_int())
          _ => () // error handling here 
        },
      )
      floats.each(
        fn {
          Number(n) => floats_result.push(n)
          _ => () // error handling here 
        },
      )
      strings.each(
        fn {
          String(s) => strings_result.push(s)
          _ => () // error handling here 
        },
      )
      { ints: ints_result, floats: floats_result, strings: strings_result }
    }
    _ =>
      raise DecodeError::{
        message: "Expected an object of ints, floats, and strings",
      }
  }
}

test {
  let all_three = AllThree::{
    ints: [1, 2, 3],
    floats: [1.0, 2.0, 3.0],
    strings: ["a", "b", "c"],
  }
  let json = all_three.to_json()
  inspect!(
    of_json?(json),
    content=
      #|Ok({ints: [1, 2, 3], floats: [1.0, 2.0, 3.0], strings: ["a", "b", "c"]})
    ,
  )
}
