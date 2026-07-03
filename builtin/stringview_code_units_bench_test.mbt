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
let stringview_code_units_bench_size = 100_000

///|
let stringview_code_units_bench_source : String = "x" +
  String::make(stringview_code_units_bench_size, 'a') +
  "y"

///|
let stringview_code_units_bench_full : StringView = stringview_code_units_bench_source[1:stringview_code_units_bench_size +
  1]

///|
test "bench StringView::code_units small slice of large backing n=16/100000" (
  it : @bench.T,
) {
  let view = stringview_code_units_bench_source[10:26]
  it.bench(fn() { it.keep(view.code_units().length()) })
}

///|
test "bench StringView::code_units full slice n=100000" (it : @bench.T) {
  let view = stringview_code_units_bench_full
  it.bench(fn() { it.keep(view.code_units().length()) })
}
