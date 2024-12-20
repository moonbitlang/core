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

///|
pub fn trunc(self : Float) -> Float = "(func (param $f f32) (result f32) (f32.trunc (local.get $f)))"

///|
pub fn ceil(self : Float) -> Float = "(func (param $f f32) (result f32) (f32.ceil (local.get $f)))"

///|
pub fn floor(self : Float) -> Float = "(func (param $f f32) (result f32) (f32.floor (local.get $f)))"

///|
// Round to nearest, ties to Ceiling
pub fn round(self : Float) -> Float {
  floor(self + 0.5)
}
