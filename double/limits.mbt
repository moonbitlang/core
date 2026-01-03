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
pub let not_a_number : Double = 0x7FF8000000000001L.reinterpret_as_double()

///|
pub let infinity : Double = 0x7FF0000000000000L.reinterpret_as_double()

///|
pub let neg_infinity : Double = 0xFFF0000000000000L.reinterpret_as_double()

///|
pub let max_value : Double = 0x7FEFFFFFFFFFFFFFL.reinterpret_as_double()

///|
pub let min_value : Double = 0xFFEFFFFFFFFFFFFFL.reinterpret_as_double()

///|
pub let min_positive : Double = 0x0010000000000000L.reinterpret_as_double()
