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

///|
test "hyperbolic" {
  // sinh
  inspect!((1 : Float).sinh(), content="1.175201177597046")
  inspect!((2 : Float).sinh(), content="3.6268603801727295")
  inspect!((3 : Float).sinh(), content="10.017874717712402")
  inspect!((4 : Float).sinh(), content="27.2899169921875")

  // cosh
  inspect!((1 : Float).cosh(), content="1.5430806875228882")
  inspect!((2 : Float).cosh(), content="3.762195587158203")
  inspect!((3 : Float).cosh(), content="10.067662239074707")
  inspect!((4 : Float).cosh(), content="27.3082332611084")

  // tanh
  inspect!((0.3 : Float).tanh(), content="0.29131263494491577")
  inspect!((0.5 : Float).tanh(), content="0.46211716532707214")
  inspect!((0.8 : Float).tanh(), content="0.664036750793457")
  inspect!((1.0 : Float).tanh(), content="0.7615941762924194")
}

///|
test "inverse hyperbolic" {
  // asinh
  inspect!((1 : Float).asinh(), content="0.8813735842704773")
  inspect!((2 : Float).asinh(), content="1.4436354637145996")
  inspect!((3 : Float).asinh(), content="1.8184465169906616")
  inspect!((4 : Float).asinh(), content="2.094712495803833")

  // acosh
  inspect!((1 : Float).acosh(), content="0")
  inspect!((2 : Float).acosh(), content="1.316957950592041")
  inspect!((3 : Float).acosh(), content="1.7627471685409546")
  inspect!((4 : Float).acosh(), content="2.063436985015869")

  // atanh
  inspect!((0.3 : Float).atanh(), content="0.30951961874961853")
  inspect!((0.5 : Float).atanh(), content="0.5493061542510986")
  inspect!((0.8 : Float).atanh(), content="1.0986123085021973")
  inspect!((0.9 : Float).atanh(), content="1.4722193479537964")
}
