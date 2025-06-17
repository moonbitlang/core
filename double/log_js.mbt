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
#deprecated("use `@math.ln` instead")
#converage.skip
pub fn Double::ln(self : Double) -> Double = "Math" "log"

///|
#deprecated("use `@math.log2` instead")
#converage.skip
pub fn Double::log2(self : Double) -> Double = "Math" "log2"

///|
#deprecated("use `@math.log10` instead")
#converage.skip
pub fn Double::log10(self : Double) -> Double = "Math" "log10"

///|
#deprecated("use `@math.ln_1p` instead")
#converage.skip
pub fn Double::ln_1p(self : Double) -> Double = "Math" "log1p"
