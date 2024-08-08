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

test {
  let a : Float = 5.3
  let b : Float = 2.0
  inspect!(a==b, content="false")
  inspect!(a+b==7.3, content="true")
  inspect!((a-b).to_double(), content="3.3000001907348633")
  inspect!(a*b==10.6, content="true")
  inspect!(a/b==2.65, content="true")
  inspect!((0.36 : Float).sqrt().to_double(), content="0.6000000238418579")
  inspect!((3.6 : Float) !=0.6, content="true")
  inspect!((3.6 : Float).compare(0.6), content="1")
  inspect!((0.3 : Float).compare(0.6), content="-1")
  inspect!((0.3 : Float).to_double()==0.3, content="false")
  inspect!((0.3 : Float).reinterpret_as_int(), content="1050253722")
}